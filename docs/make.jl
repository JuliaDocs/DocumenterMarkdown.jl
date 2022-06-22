using Documenter: makedocs, deploydocs, Deps
using DocumenterMarkdown

makedocs(
    sitename = "DocumenterMarkdown",
)

deploydocs(
    repo = "github.com/JuliaDocs/DocumenterMarkdown.jl.git",
    deps   = Deps.pip("mkdocs", "pygments", "python-markdown-math"),
    make   = () -> run(`mkdocs build`),
    target = "site",
    push_preview = true,
)