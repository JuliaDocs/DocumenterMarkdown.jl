using Documenter
using DocumenterMarkdown

makedocs(
    sitename = "DocumenterMarkdown",
    format = Markdown(),
    modules = [DocumenterMarkdown],
    pages = [
        "Home" => "index.md",
    ],
    checkdocs = :exports,
)

deploydocs(
    repo = "github.com/JuliaDocs/DocumenterMarkdown.jl.git",
    target = "site",
    deps = DocumenterMarkdown.pip("mkdocs", "mkdocs-material", "pymdown-extensions"),
    make = () -> run(`mkdocs build`),
    push_preview = true,
)
