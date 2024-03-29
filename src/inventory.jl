#=
# Inventory files

This file provides overloads to the Documenter.jl inventory finding functions which allow us
to write the Sphinx inventory file used by DocumenterInterLinks and Intersphinx.

By providing a Markdown context, you can use the `Documenter.HTMLWriters.write_inventory(doc, ___MarkdownContext(doc))` function 
and provide it a `___MarkdownContext` object to generate the inventory file.

In future, to accomodate e.g LaTeX or Typst formats, it is possible to override the `Documenter.HTMLWriters.geturl` function to 
return the correct flattened link for the given format.

=#

"""
    ___MarkdownContext(doc)

This is a struct which duplicates the Documenter.jl HTMLContext for the purposes of 
rendering a Sphinx inventory file.
"""
struct ___MarkdownContext
    settings::NamedTuple
    doc
end

function ___MarkdownContext(doc; inventory_version = Documenter.DOCUMENTER_VERSION)
    settings = (; prettyurls = false, inventory_version)
    ___MarkdownContext(settings, doc)
end

Documenter.HTMLWriter.getpage(ctx::___MarkdownContext, path) = ctx.doc.blueprint.pages[path]
Documenter.HTMLWriter.getpage(ctx::___MarkdownContext, navnode::Documenter.NavNode) = Documenter.HTMLWriter.getpage(ctx, navnode.page)