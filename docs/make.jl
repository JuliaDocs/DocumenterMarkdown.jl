using Documenter: makedocs, deploydocs
using DocumenterMarkdown

makedocs(
    sitename = "DocumenterMarkdown",
    format = Markdown(),
)

deploydocs(
    repo = "github.com/JuliaDocs/DocumenterMarkdown.jl.git",
    # the Python packages mkdocs, pygments and python-markdown-math must be installed
    make   = () -> run(`mkdocs build`),
    target = "site",
    push_preview = true,
)