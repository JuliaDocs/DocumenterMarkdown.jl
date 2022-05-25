# If the test build has not been run yet, we include it here
@isdefined(example_doc) || include("make.jl")

using Test

@testset "example build" begin
    @test joinpath(@__DIR__, "build") |> isdir
    @test joinpath(@__DIR__, "build", "index.md") |> isfile
    @test joinpath(@__DIR__, "build", "assets", "Documenter.css") |> isfile
    @test joinpath(@__DIR__, "build", "assets", "mathjaxhelper.js") |> isfile
end


# Testset from Documenter's test/examples:

# @testset "Markdown" begin
#     doc = Main.examples_markdown_doc

#     @test isa(doc, Documenter.Documents.Document)

#     let build_dir  = joinpath(examples_root, "builds", "markdown"),
#         source_dir = joinpath(examples_root, "src")

#         @test isdir(build_dir)
#         @test isdir(joinpath(build_dir, "assets"))
#         @test isdir(joinpath(build_dir, "lib"))
#         @test isdir(joinpath(build_dir, "man"))

#         @test isfile(joinpath(build_dir, "index.md"))
#         @test isfile(joinpath(build_dir, "assets", "mathjaxhelper.js"))
#         @test isfile(joinpath(build_dir, "assets", "Documenter.css"))
#         @test isfile(joinpath(build_dir, "assets", "custom.css"))
#         @test isfile(joinpath(build_dir, "assets", "custom.js"))
#         @test isfile(joinpath(build_dir, "lib", "functions.md"))
#         @test isfile(joinpath(build_dir, "man", "tutorial.md"))
#         @test isfile(joinpath(build_dir, "man", "data.csv"))
#         @test isfile(joinpath(build_dir, "man", "julia.svg"))

#         @test (==)(
#             read(joinpath(source_dir, "man", "data.csv"), String),
#             read(joinpath(build_dir,  "man", "data.csv"), String),
#         )
#     end

#     @test doc.user.root   == examples_root
#     @test doc.user.source == "src"
#     @test doc.user.build  == "builds/markdown"
#     @test doc.user.clean  == true
#     @test doc.user.format == [Documenter.Writers.MarkdownWriter.Markdown()]

#     @test realpath(doc.internal.assets) == realpath(joinpath(dirname(@__FILE__), "..", "..", "assets"))

#     @test length(doc.blueprint.pages) == 21

#     let headers = doc.internal.headers
#         @test Documenter.Anchors.exists(headers, "Documentation")
#         @test Documenter.Anchors.exists(headers, "Documentation")
#         @test Documenter.Anchors.exists(headers, "Index-Page")
#         @test Documenter.Anchors.exists(headers, "Functions-Contents")
#         @test Documenter.Anchors.exists(headers, "Tutorial-Contents")
#         @test Documenter.Anchors.exists(headers, "Index")
#         @test Documenter.Anchors.exists(headers, "Tutorial")
#         @test Documenter.Anchors.exists(headers, "Function-Index")
#         @test Documenter.Anchors.exists(headers, "Functions")
#         @test Documenter.Anchors.isunique(headers, "Functions")
#         @test Documenter.Anchors.isunique(headers, "Functions", joinpath("builds", "markdown", "lib", "functions.md"))
#         let name = "Foo", path = joinpath("builds", "markdown", "lib", "functions.md")
#             @test Documenter.Anchors.exists(headers, name, path)
#             @test !Documenter.Anchors.isunique(headers, name)
#             @test !Documenter.Anchors.isunique(headers, name, path)
#             @test length(headers.map[name][path]) == 4
#         end
#     end

#     @test length(doc.internal.objects) == 42
# end
