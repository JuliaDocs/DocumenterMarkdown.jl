module DocumenterMarkdown
using Documenter: Documenter
using Documenter.Utilities: Selectors

const ASSETS = normpath(joinpath(@__DIR__, "..", "assets"))

include("MarkdownWriter.jl")
import .MarkdownWriter: Markdown
export Markdown

# Selectors interface in Documenter.Writers, for dispatching on different writers
abstract type MarkdownFormat <: Documenter.Writers.FormatSelector end
Selectors.order(::Type{MarkdownFormat}) = 1.0
Selectors.matcher(::Type{MarkdownFormat}, fmt, _) = isa(fmt, MarkdownWriter.Markdown)
Selectors.runner(::Type{MarkdownFormat}, fmt, doc) = MarkdownWriter.render(doc, fmt)

end # module
