module DocumenterMarkdown
using Documenter: Documenter
using Documenter.Utilities: Selectors

const ASSETS = normpath(joinpath(@__DIR__, "..", "assets"))

include("writer.jl")
export Markdown

# Selectors interface in Documenter.Writers, for dispatching on different writers
abstract type MarkdownFormat <: Documenter.Writers.FormatSelector end
Selectors.order(::Type{MarkdownFormat}) = 1.0
Selectors.matcher(::Type{MarkdownFormat}, fmt, _) = isa(fmt, Markdown)
Selectors.runner(::Type{MarkdownFormat}, fmt, doc) = render(doc, fmt)

end # module
