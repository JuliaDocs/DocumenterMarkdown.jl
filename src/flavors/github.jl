# # Github-flavored markdown

# In Github-flavored markdown, the syntax for admonitions is 
# slightly different.  They are implemented using quotes and 
# an indicator string at the top, and the category is always
# uppercase.

# So, we need to convert the admonition AST nodes to the
# appropriate syntax.

function render(fmt::GithubMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, admonition::Documenter.MarkdownAST.Admonition, page, doc; kwargs...)
    category = admonition.category
    if category == "note"
        category = "Note"
    end
    println(io, "\n> [!$(uppercase(category))]")
    iob = IOBuffer()
    render(fmt, iob, mime, node, node.children, page, doc; kwargs...)
    println(io, replace(String(take!(iob)), "\n" => "\n> "))
end