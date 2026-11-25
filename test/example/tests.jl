# If the test build has not been run yet, we include it here
@isdefined(example_doc) || include("make.jl")

using Test

function list_files(root_dir)
    files = String[]
    for (root, _, dir_files) in walkdir(root_dir)
        root = relpath(root, root_dir)
        root == "." && (root = "")
        for file in dir_files
            push!(files, joinpath(root, file))
        end
    end
    return files
end
src_files = list_files(joinpath(@__DIR__, "src"))
#build_files = list_files(joinpath(@__DIR__, "build"))

@testset "example build" begin
    @test joinpath(@__DIR__, "build") |> isdir
    @test joinpath(@__DIR__, "build", "assets", "Documenter.css") |> isfile
    @test joinpath(@__DIR__, "build", "assets", "mathjaxhelper.js") |> isfile

    @test joinpath(@__DIR__, "build", "assets", "favicon.ico") |> isfile
    @test joinpath(@__DIR__, "build", "assets", "custom.js") |> isfile
    @test joinpath(@__DIR__, "build", "assets", "custom.css") |> isfile

    for path in src_files
        endswith(path, ".md") || continue
        @test isfile(joinpath(@__DIR__, "build", path))
    end

    @test joinpath(@__DIR__, "build", "man", "data.csv") |> isfile
    @test joinpath(@__DIR__, "build", "man", "julia.svg") |> isfile
end

# The content of the generated Markdown, not only the existence of the files. The
# strings are taken from the output of version 0.2 of this package (Documenter 0.27.25),
# which the output of a newer version should reproduce, except for the differences that
# are listed in CHANGELOG.md.
build(path...) = read(joinpath(@__DIR__, "build", path...), String)

@testset "example build: content" begin
    functions = build("lib", "functions.md")
    index = build("index.md")
    tutorial = build("man", "tutorial.md")
    style = build("man", "style.md")

    # headings with their anchors, and the legacy anchor with the suffix -1
    @test occursin("<a id='Functions'></a>", functions)
    @test occursin("<a id='Functions-1'></a>", functions)
    @test occursin("# Functions", functions)

    # a docstring: anchor, header with the binding and the category, body, source link
    @test occursin("<a id='Main.Mod.func-Tuple{Any}' href='#Main.Mod.func-Tuple{Any}'>#</a>",
                   functions)
    @test occursin("**`Main.Mod.func`** &mdash; *Method*.", functions)
    @test occursin("class='documenter-source'>source</a>", functions)
    # cross-references use the extension .md
    @test occursin("[`T`](functions.md#Main.Mod.T)", functions)
    # headers inside docstrings are replaced by bold text
    @test !occursin(r"^#+ .*\n.*\*\*`Main.Mod.func`\*\*"m, functions)

    # the contents list: nested, with links to the .md pages
    @test occursin("- [Documentation](index.md#Documentation)", index)
    @test occursin("    - [Index Page](index.md#Index-Page)", index)

    # code blocks, tables, admonitions, footnotes and images
    @test occursin("```julia-repl\njulia> using Base.Meta", tutorial)
    @test occursin("| object | implemented |      value |", tutorial)
    @test occursin("!!! note \"Bulleted lists in admonitions\"", style)
    @test occursin("[^longeq]:", style)
    @test count(r"!\[\]\([a-z]{7}\.(png|webp|jpeg|gif)\)", tutorial) == 4
    @test occursin(r"!\[\]\(julia\.svg\)|<svg", tutorial)

    # the code block of an element of an extension is written as it was, an element
    # without content leaves nothing
    extension = build("extension.md")
    @test occursin("```diagram\nA --> B\n```", extension)
    @test !occursin("ScriptBlock", extension)
end


# Without a remote repository (remotes = nothing, as for a repository that Documenter
# cannot map to source links) the docstrings have no source links. The anchor of a
# docstring must still start a paragraph of its own: it is an inline element and would
# continue the last paragraph of the previous docstring.
@testset "docstrings without source links" begin
    mktempdir() do dir
        mkpath(joinpath(dir, "src"))
        write(joinpath(dir, "src", "index.md"), """
            # Index

            ```@meta
            CurrentModule = $(Mod)
            ```

            ```@docs
            func
            T
            ```
            """)
        makedocs(; root=dir, sitename="no source links", format=Markdown(),
                 modules=[Mod], remotes=nothing, doctest=false,
                 warnonly=[:cross_references, :missing_docs])
        page = read(joinpath(dir, "build", "index.md"), String)
        @test count("<a id='Main.Mod.", page) == 2
        @test !occursin("class='documenter-source'", page)
        @test !occursin(r"[^\n]\n<a id='[^']+' href='#", page)
    end
end

# The docstrings as boxes: an admonition or a details block of the class `docstring`
# with the name and the category as the title and the docstring indented below.
@testset "docstrings as boxes" begin
    @test_throws ArgumentError Markdown(docstrings=:unknown)
    for (style, marker) in ((:admonition, "!!!"), (:details, "???+"))
        mktempdir() do dir
            mkpath(joinpath(dir, "src"))
            write(joinpath(dir, "src", "index.md"), """
                # Index

                ```@meta
                CurrentModule = $(Mod)
                ```

                ```@docs
                func
                T
                ```
                """)
            makedocs(; root=dir, sitename="boxes", format=Markdown(docstrings=style),
                     modules=[Mod], remotes=nothing, doctest=false,
                     warnonly=[:cross_references, :missing_docs])
            page = read(joinpath(dir, "build", "index.md"), String)
            id = "Main.Mod.func"
            # the anchor, the box with its title, and the indented body
            @test occursin("\n<a id='$id'></a>\n", page)
            @test occursin("\n$marker docstring \"[`Main.Mod.func`](#$id) &mdash; " *
                           "Function\"\n", page)
            @test occursin("\n    ```julia\n    func(x)\n    ```\n", page)
            @test count("docstring \"", page) == 2
            # nothing of the body is left at the start of a line
            @test !occursin(r"^```julia"m, page)
            @test !occursin("<a id='$id' href=", page)
        end
    end
end
