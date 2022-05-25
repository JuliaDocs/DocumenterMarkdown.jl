using Test
using DocumenterMarkdown

@testset "DocumenterMarkdown" begin
    include("example/make.jl")
    include("example/tests.jl")
end
