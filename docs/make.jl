using Documenter, DocumenterMarkdown

makedocs(
    sitename = "DocumenterMarkdown",
)

deploydocs(
    repo = "github.com/JuliaDocs/DocumenterMarkdown.jl.git",
    deps   = Deps.pip("mkdocs", "pygments", "python-markdown-math"),
    make   = () -> run(`mkdocs build`),
    target = "site",
)