using Test
using DocumenterMarkdown

@testset "DocumenterMarkdown" begin
    @testset "Make" include("example/make.jl")
    @testset "Test" include("example/tests.jl")
    @testset "Inventory" include("example/test_inventory.jl")
end
