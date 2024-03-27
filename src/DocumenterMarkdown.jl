module DocumenterMarkdown

import Documenter: Documenter, Builder, Expanders, Selectors, MarkdownAST
import Base64: base64decode, base64encode
import Markdown

import ANSIColoredPrinters

include("types.jl")
include("utils.jl")
include("inventory.jl")
include("writer.jl")
include("mime_rendering.jl")

include("flavors/github.jl")
include("flavors/mkdocs.jl")

# Selectors interface in Documenter.Writers, for dispatching on different writers

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
