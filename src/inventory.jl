#=
# Inventory files

This file provides overloads to the Documenter.jl inventory finding functions which allow us
to write the Sphinx inventory file used by DocumenterInterLinks and Intersphinx.

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

function Documenter.getpage(ctx, navnode)
end