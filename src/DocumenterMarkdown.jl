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

# This is from the old Deps module:

"""
    pip(deps...)

Installs (as non-root user) all python packages listed in `deps`.

# Examples

```julia
using Documenter

makedocs(
    # ...
)

deploydocs(
    deps = Deps.pip("pygments", "mkdocs", "mkdocs-material"),
    # ...
)
```
"""
pip(deps...) = () -> map(dep -> run(`pip install --user $(dep)`), deps)

end # module
