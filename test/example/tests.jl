# If the test build has not been run yet, we include it here
@isdefined(example_doc) || include("make.jl")

using Test

@testset "example build" begin
    @test joinpath(@__DIR__, "build") |> isdir
    @test joinpath(@__DIR__, "build", "index.md") |> isfile
    @test joinpath(@__DIR__, "build", "assets", "Documenter.css") |> isfile
    @test joinpath(@__DIR__, "build", "assets", "mathjaxhelper.js") |> isfile
end
