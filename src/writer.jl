# return the same file with the extension changed to .md
mdext(f) = string(splitext(f)[1], ".md")

function render(settings::AbstractMarkdown, doc::Documenter.Document)
    @info "DocumenterMarkdown: rendering Markdown pages.  Flavor: `$(typeof(settings))`."
    mime = MIME"text/plain"()
    builddir = isabspath(doc.user.build) ? doc.user.build : joinpath(doc.user.root, doc.user.build)
    for (src, page) in doc.blueprint.pages
        # This is where you can operate on a per-page level.
        open(docpath(builddir, page.build), "w") do io
            for node in page.mdast.children
                render(settings, io, mime, node, page, doc)
            end
        end
    end
    Documenter.HTMLWriter.write_inventory(doc, ___MarkdownContext(doc))
end


# This function catches all nodes and decomposes them to their elements.
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, page, doc; kwargs...)
    render(fmt, io, mime, node, node.element, page, doc; kwargs...)
end

# This function catches nodes dispatched with their children, and renders each child.
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, children::Documenter.MarkdownAST.NodeChildren{<: Documenter.MarkdownAST.Node}, page, doc; kwargs...)
    for child in children
        render(fmt, io, mime, child, child.element, page, doc; kwargs...)
    end
end

function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", vec::Vector, page, doc; kwargs...)
    for each in vec
        render(fmt, io, mime, each, page, doc; kwargs...)
    end
end

function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, anchor::Documenter.Anchor, page, doc; kwargs...)
    println(io, "\n<a id='", lstrip(Documenter.anchor_fragment(anchor), '#'), "'></a>")
    return render(fmt, io, mime, node, anchor.object, page, doc; kwargs...)
end


render(fmt::AbstractMarkdown, io::IO, ::MIME"text/plain", node::Documenter.MarkdownAST.Node, str::AbstractString, page, doc; kwargs...) = print(io, str)

# Metadata Nodes get dropped from the final output for every format but are needed throughout
# the rest of the build, and so we just leave them in place and print a blank line in their place.
render(fmt::AbstractMarkdown, io::IO, ::MIME"text/plain", n::Documenter.MarkdownAST.Node, node::Documenter.MetaNode, page, doc; kwargs...) = println(io, "\n")
# In the original AST, SetupNodes were just mapped to empty Markdown.MD() objects.
render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::MarkdownAST.Node, ::Documenter.SetupNode, page, doc; kwargs...) = nothing

# Raw nodes are used to insert raw HTML into the output. We just print it as is.
# TODO: what if the `raw` is not HTML?  That is not addressed here but we ought to address it...
function render(fmt::AbstractMarkdown, io::IO, ::MIME"text/plain", node::Documenter.MarkdownAST.Node, raw::Documenter.RawNode, page, doc; kwargs...)
    return raw.name in (:html, :markdown, :md) ? println(io, raw.text, "\n") : nothing
end

# Docs nodes are the nodes which contain docstrings!
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, docblock::Documenter.DocsNodesBlock, page, doc; kwargs...)
    render(fmt, io, mime, node, node.children, page, doc; kwargs...)
end

function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, docs::Documenter.DocsNodes, page, doc; kwargs...)
    for docstr in docs.docs
        render(fmt, io, mime, docstr, page, doc; kwargs...)
    end
end
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, docs::Documenter.DocsNode, page, doc; kwargs...)
    # @infiltrate
    anchor_id = Documenter.anchor_label(docs.anchor)
    # Docstring header based on the name of the binding and it's category.
    println(io,
        "<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>")
    anchor = "<a id='$(anchor_id)' href='#$(anchor_id)'>#</a>"
    header = "&nbsp;<b><u>$(docs.object.binding)</u></b> &mdash; <i>$(Documenter.doccat(docs.object))</i>."
    println(io, anchor, header, "\n\n")
    # Body. May contain several concatenated docstrings.
    renderdoc(fmt, io, mime, node, page, doc; kwargs...)
    return println(io, "</div>\n<br>")
end

function intelligent_language(lang::String)
    if lang == "ansi"
        "julia"
    elseif lang == "documenter-ansi"
        "ansi"
    else
        lang
    end
end


"""
"""
function renderdoc(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, page, doc; kwargs...)
    @assert node.element isa Documenter.DocsNode
    # The `:results` field contains a vector of `Docs.DocStr` objects associated with
    # each markdown object. The `DocStr` contains data such as file and line info that
    # we need for generating correct source links.
    for (docstringast, result) in zip(node.element.mdasts, node.element.results)
        println(io)
        render(fmt, io, mime, docstringast, docstringast.children, page, doc; kwargs...)
        println(io)
        # When a source link is available then print the link.
        url = Documenter.source_url(doc, result)
        if url !== nothing
            # This is how Documenter does it:
            # push!(ret.nodes, a[".docs-sourcelink", :target=>"_blank", :href=>url]("source"))
            # so clearly we should be inserting some form of HTML tag here, 
            # and defining its rendering in CSS?
            # TODO: switch to Documenter style here
            println(io, "\n", "[source]($url)", "\n")
        end
    end
end

function renderdoc(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, other, page, doc; kwargs...)
    # TODO: properly support non-markdown docstrings at some point.
    return render(fmt, io, mime, other, page, doc; kwargs...)
end

## Index, Contents, and Eval Nodes.

function render(fmt::AbstractMarkdown, io::IO, ::MIME"text/plain", node::Documenter.MarkdownAST.Node, index::Documenter.IndexNode, page, doc; kwargs...)
    for (object, _, page, mod, cat) in index.elements
        page = mdext(page)
        url = string("#", Documenter.slugify(object))
        println(io, "- [`", object.binding, "`](", replace(url, " " => "%20"), ")")
    end
    return println(io)
end

function render(fmt::AbstractMarkdown, io::IO, ::MIME"text/plain", node::Documenter.MarkdownAST.Node, contents::Documenter.ContentsNode, page, doc; kwargs...)
    for (count, path, anchor) in contents.elements
        path = mdext(path)
        header = anchor.object
        url = string(path, Documenter.anchor_fragment(anchor))
        link = Markdown.Link(anchor.id, replace(url, " " => "%20"))
        level = anchor.order
        print(io, "    "^(level - 1), "- ")
        linkfix = ".md#"
        println(io, replace(Markdown.plaininline(link), linkfix => "#"))
    end
    return println(io)
end

function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, evalnode::Documenter.EvalNode, page, doc; kwargs...)
    return evalnode.result === nothing ? nothing : render(fmt, io, mime, node, evalnode.result, page, doc; kwargs...)
end

function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, mcb::Documenter.MultiCodeBlock, page, doc; kwargs...)
    # See utils.jl
    return render(fmt, io, mime, node, join_multiblock(mcb), page, doc; kwargs...)
end


function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, d::Documenter.MultiOutput, page, doc; kwargs...)
    # @infiltrate
    return render(fmt, io, mime, node, node.children, page, doc; kwargs...)
end

function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, d::Documenter.MultiOutputElement, page, doc; kwargs...)
    return render(fmt, io, mime, node, d.element, page, doc; kwargs...)
end


function render(fmt::AbstractMarkdown, io::IO, ::MIME"text/plain", node::Documenter.MarkdownAST.Node, other, page, doc; kwargs...)
    println(io)
    linkfix = ".md#"
    return println(io, replace(Markdown.plain(other), linkfix => "#"))
end


# This is straight Markdown to Markdown, so no issues for most of these!

# Paragraphs - they have special regions _and_ plain text
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, ::MarkdownAST.Paragraph, page, doc; prenewline = true, kwargs...)
    prenewline && println(io)
    render(fmt, io, mime, node, node.children, page, doc; prenewline, kwargs...)
    println(io)
end
# Plain text
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, text::MarkdownAST.Text, page, doc; kwargs...)
    print(io, text.text)
end
# Bold text (strong)
# These are wrapper elements - so the wrapper doesn't actually contain any text, the current node's children do.
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, strong::MarkdownAST.Strong, page, doc; kwargs...)
    # @infiltrate
    print(io, "**")
    render(fmt, io, mime, node, node.children, page, doc; kwargs...)
    print(io, "**")
end
# Italic text (emph)
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, emph::MarkdownAST.Emph, page, doc; kwargs...)
    print(io, "_")
    render(fmt, io, mime, node, node.children, page, doc; kwargs...)
    print(io, "_")
end
# Links
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, link::MarkdownAST.Link, page, doc; kwargs...)
    # @infiltrate
    # For HTML links, use:
    # print(io, "<a href=\"$(link.destination)\">")
    # render(fmt, io, mime, node, node.children, page, doc; kwargs...)
    # print(io, "</a>")
    # However, we may have Markdown syntax in these links
    # so, we use markdown link syntax which can be parsed appropriately.
    print(io, "[")
    render(fmt, io, mime, node, node.children, page, doc; prenewline = false, kwargs...)
    print(io, "]($(replace(link.destination, " " => "%20")))")
end
# Code blocks
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, code::MarkdownAST.CodeBlock, page, doc; kwargs...)
    info = code.info
    if info ∈ ("julia-repl", "@doctest", "@repl")
        info = "julia"
    elseif info ∈ ("@example", )
        info = "julia"
    end
    render(fmt, io, mime, node, Markdown.Code(info, code.code), page, doc; kwargs...)
end
# Inline code
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, code::MarkdownAST.Code, page, doc; kwargs...)
    print(io, "`", code.code, "`")
end
# Headers
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, header::Documenter.AnchoredHeader, page, doc; kwargs...)
    anchor = header.anchor
    id = string(Documenter.anchor_label(anchor))
    # @infiltrate
    heading = first(node.children)
    println(io)
    print(io, "#"^(heading.element.level), " ")
    render(fmt, io, mime, node, heading.children, page, doc; kwargs...)
    print(io, " {#$(replace(id, " " => "-"))}")
    println(io)
end
# Thematic breaks
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, thematic::MarkdownAST.ThematicBreak, page, doc; kwargs...)
    println(io); println(io)
    println(io, "---")
    println(io)
end
# Admonitions
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, admonition::MarkdownAST.Admonition, page, doc; kwargs...)
    # Main.@infiltrate
    # First, render the node's children to an IOBuffer
    iob = IOBuffer()
    render(fmt, iob, mime, node, node.children, page, doc; kwargs...)
    # Then, shift that to the left by 4 spaces (1 tab)
    output = String(take!(iob)) 
    final_output = replace(output, "\n" => "\n    ")
    println(io, "\n!!! $(admonition.category) $(admonition.title)")
    println(io, final_output)
end
# Block quotes
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, q::MarkdownAST.BlockQuote, page, doc; kwargs...)
    # Main.@infiltrate
    iob = IOBuffer()
    render(fmt, iob, mime, node, node.children, page, doc; kwargs...)
    output = String(take!(iob))
    final_output = replace(output, "\n" => "\n> ")
    println(io, final_output)
end
# Inline math
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, math::MarkdownAST.InlineMath, page, doc; kwargs...)
    # Main.@infiltrate
    print(io, "\$", math.math, "\$")
end
# Display math 
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, math::MarkdownAST.DisplayMath, page, doc; kwargs...)
    # Main.@infiltrate
    println(io)
    println(io, "\$\$", math.math, "\$\$")
end
# Lists
# TODO: list ordering is broken!
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, list::MarkdownAST.List, page, doc; kwargs...)
    # @infiltrate
    bullet = list.type === :ordered ? "1. " : "- "
    iob = IOBuffer()
    for item in node.children
        render(fmt, iob, mime, item, item.children, page, doc; prenewline = false, kwargs...)
        eachline = split(String(take!(iob)), '\n')
        eachline[2:end] .= "  " .* eachline[2:end]
        print(io, bullet)
        println.((io,), eachline)
    end
end
# Tables
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, table::MarkdownAST.TableCell, page, doc; kwargs...)
    println("Encountered table cell!")
end
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, table::MarkdownAST.Table, page, doc; kwargs...)
    alignment_style = map(table.spec) do align
        if align == :right
            :r
        elseif align == :center
            :c
        elseif align == :left
            :l
        else
            @warn """
            Invalid alignment style $align encountered in a markdown table at:
            $(joinpath(doc.user.root, page.source))
            Valid alignment styles are `:left`, `:center`, and `:right`.

            Defaulting to left alignment.
            """
            :l
        end
    end
    # We create this IOBuffer in order to render to it.
    iob = IOBuffer() 
    # This will eventually hold the rendered table cells as Strings.
    cell_strings = Vector{Vector{String}}()
    current_row_vec = String[]
    # We iterate over the rows of the table, rendering each cell in turn.
    for (i, row) in enumerate(MarkdownAST.tablerows(node))
        current_row_vec = String[]
        push!(cell_strings, current_row_vec)
        for (j, cell) in enumerate(row.children)
            render(fmt, iob, mime, cell, cell.children, page, doc; kwargs...)
            push!(current_row_vec, String(take!(iob)))
        end
    end
    # Finally, convert to `Markdown.jl` table and render.
    println(io)
    println(io, Markdown.plain(Markdown.MD(Markdown.Table(cell_strings, alignment_style))))

end
# Images
# Here, we are rendering images as HTML.  It is my hope that at some point we figure out how to render them in Markdown, but for now, this is also perfectly sufficient.
function render(::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, image::MarkdownAST.Image, page, doc; kwargs...)
    println()
    url = replace(image.destination, "\\" => "/")
    print(io, "![")
    render(fmt, io, mime, node, node.children, page, doc; kwargs...)
    println(io, "]($(url))")
end

# ### Footnote Links

# This is literally emitting back to standard Markdown - we don't need any fancypants handling because the footnote will be at the bottom
# of the original Markdown page anyway.
function render(::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, link::MarkdownAST.FootnoteLink, page, doc; kwargs...)
    print(io, "[^", link.id, "]")
end

# This is literally emitting back to standard Markdown - we don't need any fancypants handling because the footnote will be at the bottom
# of the original Markdown page anyway.
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, footnote::MarkdownAST.FootnoteDefinition, page, doc; kwargs...)
    println(io)
    print(io, "[^", footnote.id, "]: ")
    render(fmt, io, mime, node, node.children, page, doc; prenewline = false, kwargs...)
    println(io)
end

# ### Interpolated Julia values
# This is pretty self-explanatory.  We just print the value of the interpolated Julia value, and warn in stdout that one has been encountered.
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::MarkdownAST.Node, value::MarkdownAST.JuliaValue, page, doc; kwargs...)
    @warn("""
    DocumenterMarkdown: Unexpected Julia interpolation in the Markdown. This probably means that you
    have an unbalanced or un-escaped \$ in the text.

    To write the dollar sign, escape it with `\\\$`

    We don't have the file or line number available, but we got given the value:

    `$(value.ref)` which is of type `$(typeof(value.ref))`
    """)
    println(io, value.ref)
end

# ### Documenter.jl page links
# We figure out the correct path to the page, and render it as a link in Markdown.
# TODO: generate a `Markdown.Link` object?  But that seems like overkill...
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, link::Documenter.PageLink, page, doc; kwargs...)
    # Main.@infiltrate
    path = if !isempty(link.fragment)
        "/" * replace(Documenter.pagekey(doc, link.page), ".md" => "") * "#" * string(link.fragment)
    else
        Documenter.pagekey(doc, link.page)
    end
    print(io, "[")
    render(fmt, io, mime, node, node.children, page, doc; kwargs...)
    print(io, "]($(replace(path, " " => "%20")))")
end

# Documenter.jl local links
function render(fmt::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, link::Documenter.LocalLink, page, doc; kwargs...)
    # Main.@infiltrate
    path = isempty(link.fragment) ? link.path : "$(Documenter.pagekey(doc, page))#$(link.fragment)"
    print(io, "[")
    render(fmt, io, mime, node, node.children, page, doc; kwargs...)
    print(io, "]($(replace(path, " " => "%20")))")
end

# Documenter.jl local images
function render(::AbstractMarkdown, io::IO, mime::MIME"text/plain", node::Documenter.MarkdownAST.Node, image::Documenter.LocalImage, page, doc; kwargs...)
    # Main.@infiltrate
    image_path = relpath(joinpath(doc.user.build, image.path), dirname(page.build))
    println(io)
    println(io, "![]($image_path)")
end