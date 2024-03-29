struct VitepressMarkdown <: Documenter.Flavor end

function render(fmt::VitepressMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, admonition::MarkdownAST.Admonition, page, doc; kwargs...)
    # Main.@infiltrate
    category = admonition.category
    if category == "note" # Julia markdown says note, but Vitepress says tip
        category = "tip"
    end
    println(io, "\n::: $(category) $(admonition.title)")
    render(fmt, io, mime, node, node.children, page, doc; kwargs...)
    println(io, "\n:::")
end

# Here, we are rendering images as HTML.  It is my hope that at some point we figure out how to render them in Markdown, but for now, this is also perfectly sufficient.
function render(::VitepressMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, image::MarkdownAST.Image, page, doc; kwargs...)
    println()
    url = replace(image.destination, "\\" => "/")
    print(io, "<img src=\"", url, "\" alt=\"")
    render(fmt, io, mime, node, node.children, page, doc; kwargs...)
    println(io, "\">")
end