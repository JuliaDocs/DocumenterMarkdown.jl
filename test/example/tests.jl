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
    # @test joinpath(@__DIR__, "build", "assets", "Documenter.css") |> isfile
    # @test joinpath(@__DIR__, "build", "assets", "mathjaxhelper.js") |> isfile

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