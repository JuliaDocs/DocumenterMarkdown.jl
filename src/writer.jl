using Documenter: Documenter
using MarkdownAST: MarkdownAST, Node
import ANSIColoredPrinters
using Base64: base64decode

"""
    Markdown()

Documenter output format that emits one Markdown (`.md`) file per source page
into the `build/` directory, ready to be consumed by a static-site generator
such as [MkDocs](https://www.mkdocs.org/).

Pass an instance as the `format` keyword to [`Documenter.makedocs`](https://documenter.juliadocs.org/stable/lib/public/#Documenter.makedocs):

```julia
using Documenter
using DocumenterMarkdown
makedocs(sitename = "MyPackage", format = Markdown(), modules = [MyPackage])
```

The generated markdown uses Pandoc-style `{#anchor}` heading attributes,
`!!! category "title"` admonitions, `\$...\$` / `\$\$...\$\$` math, and
`*.md#anchor` cross-references — all of which `mkdocs-material` renders out of
the box with the `attr_list`, `admonition`, `pymdownx.arithmatex`, and related
extensions enabled. See the [README](https://github.com/JuliaDocs/DocumenterMarkdown.jl#usage)
for a complete `mkdocs.yml` example.
"""
struct Markdown <: Documenter.Writer
end

# Return the same file with the extension changed to .md.
mdext(f) = string(splitext(f)[1], ".md")

# ──────────────────────────────────────────────────────────────────────────────
# Entry point
# ──────────────────────────────────────────────────────────────────────────────

function render(doc::Documenter.Document, ::Markdown)
    @info "DocumenterMarkdown: rendering Markdown pages."
    mime = MIME"text/plain"()
    for (src, page) in doc.blueprint.pages
        open(mdext(page.build), "w") do io
            for node in page.mdast.children
                render(io, mime, node, page, doc)
            end
        end
    end
end

# ──────────────────────────────────────────────────────────────────────────────
# Universal dispatch
# ──────────────────────────────────────────────────────────────────────────────

render(io::IO, mime::MIME"text/plain", node::Node, page, doc; kwargs...) =
    render(io, mime, node, node.element, page, doc; kwargs...)

function render(io::IO, mime::MIME"text/plain", node::Node,
                children::MarkdownAST.NodeChildren, page, doc; kwargs...)
    for child in children
        render(io, mime, child, page, doc; kwargs...)
    end
end

# Fallback: error loudly so unimplemented elements surface during testing.
function render(io::IO, mime::MIME"text/plain", node::Node,
                element::MarkdownAST.AbstractElement, page, doc; kwargs...)
    error("DocumenterMarkdown: unimplemented element type $(typeof(element))")
end

# ──────────────────────────────────────────────────────────────────────────────
# Documenter element nodes
# ──────────────────────────────────────────────────────────────────────────────

# Wraps a heading; emit `## Heading {#anchor-id}` so MkDocs `attr_list` picks up the ID.
function render(io::IO, mime::MIME"text/plain", node::Node,
                ah::Documenter.AnchoredHeader, page, doc; kwargs...)
    heading_node = first(node.children)
    heading = heading_node.element::MarkdownAST.Heading
    id = lstrip(Documenter.anchor_fragment(ah.anchor), '#')
    print(io, "\n", "#"^heading.level, " ")
    for child in heading_node.children
        render(io, mime, child, page, doc; kwargs...)
    end
    println(io, " {#", id, "}\n")
end

# Container of one or more DocsNode children.
render(io::IO, mime::MIME"text/plain", node::Node,
       ::Documenter.DocsNodesBlock, page, doc; kwargs...) =
    render(io, mime, node, node.children, page, doc; kwargs...)

# A single docstring entry. Renders:
#   <a id='anchor'></a> (+ optional legacy id-1)
#   **`Mod.foo`** — *Function*.
#
#   <docstring body>
#   <source link>
function render(io::IO, mime::MIME"text/plain", node::Node,
                docs::Documenter.DocsNode, page, doc; kwargs...)
    id = lstrip(Documenter.anchor_fragment(docs.anchor), '#')
    println(io, "<a id='", id, "'></a>")
    if docs.anchor.nth == 1
        println(io, "<a id='", id, "-1'></a>")
    end
    binding = Documenter.bindingstring(docs.object.binding)
    cat = Documenter.doccat(docs.object)
    println(io, "**`", binding, "`** &mdash; *", cat, "*.\n")
    for (md_node, result) in zip(docs.mdasts, docs.results)
        for child in md_node.children
            render(io, mime, child, page, doc; kwargs...)
        end
        url = try
            Documenter.source_url(doc, result)
        catch
            nothing
        end
        if url !== nothing
            println(io, "\n<a target='_blank' href='", url,
                        "' class='documenter-source'>source</a><br>\n")
        end
    end
end

# `@index` block: bullet list of cross-references to docstrings.
function render(io::IO, mime::MIME"text/plain", node::Node,
                index::Documenter.IndexNode, page, doc; kwargs...)
    for (object, _, pagepath, mod, cat) in index.elements
        url = string(mdext(pagepath), "#", Documenter.slugify(object))
        println(io, "- [`", object.binding, "`](", url, ")")
    end
    println(io)
end

# `@contents` block: nested bullet list of in-document headings.
function render(io::IO, mime::MIME"text/plain", node::Node,
                contents::Documenter.ContentsNode, page, doc; kwargs...)
    for (_, pagepath, anchor) in contents.elements
        path = mdext(pagepath)
        heading = anchor.object::MarkdownAST.Heading
        frag = Documenter.anchor_fragment(anchor)
        # `anchor.node` wraps the heading (via AnchoredHeader); we want just the
        # heading's inline children rendered, not its `#`-prefixed line form.
        heading_node = first(anchor.node.children)
        buf = IOBuffer()
        for child in heading_node.children
            render(buf, mime, child, page, doc; kwargs...)
        end
        text = strip(String(take!(buf)))
        println(io, "    "^(heading.level - 1), "- [", text, "](", path, frag, ")")
    end
    println(io)
end

# `@eval` block result — the result is an MDAST node (or nothing).
function render(io::IO, mime::MIME"text/plain", node::Node,
                ev::Documenter.EvalNode, page, doc; kwargs...)
    ev.result === nothing && return
    for child in ev.result.children
        render(io, mime, child, page, doc; kwargs...)
    end
end

# `@repl` rendering: a single fenced code block joining all child snippets.
function render(io::IO, mime::MIME"text/plain", node::Node,
                mcb::Documenter.MultiCodeBlock, page, doc; kwargs...)
    println(io, "```", mcb.language)
    first_one = true
    for child in node.children
        cb = child.element::MarkdownAST.CodeBlock
        first_one || println(io)
        print(io, cb.code)
        first_one = false
    end
    println(io, "\n```\n")
end

# `@example` output container — recurse into its child MultiOutputElements.
render(io::IO, mime::MIME"text/plain", node::Node,
       ::Documenter.MultiOutput, page, doc; kwargs...) =
    render(io, mime, node, node.children, page, doc; kwargs...)

# A single output rendering: usually a Dict{MIME,Any} with several representations.
function render(io::IO, mime::MIME"text/plain", node::Node,
                moe::Documenter.MultiOutputElement, page, doc; kwargs...)
    el = moe.element
    if el isa AbstractDict
        render_mime_dict(io, mime, el, page, doc)
    else
        # Fallback: try to render directly. If it's a Documenter or MDAST element
        # this should hit one of the typed methods above; otherwise stringify.
        if el isa MarkdownAST.AbstractElement
            # Wrap in a transient Node so dispatch works.
            tmp = Node(el)
            render(io, mime, tmp, page, doc; kwargs...)
        else
            println(io, el)
        end
    end
end

# MIME-priority ladder for `@example` outputs.
function render_mime_dict(io::IO, mime::MIME"text/plain", d::AbstractDict, page, doc)
    filename = String(rand('a':'z', 7))
    if haskey(d, MIME"text/markdown"())
        println(io, d[MIME"text/markdown"()])
    elseif haskey(d, MIME"text/html"())
        println(io, d[MIME"text/html"()])
    elseif haskey(d, MIME"image/svg+xml"())
        # Browsers need the xmlns attribute set in the <svg> tag for inline SVG;
        # the producer of the SVG is responsible for that. Emit inline.
        println(io, d[MIME"image/svg+xml"()])
    elseif haskey(d, MIME"image/png"())
        write(joinpath(dirname(page.build), "$(filename).png"),
              base64decode(d[MIME"image/png"()]))
        println(io, "![]($(filename).png)\n")
    elseif haskey(d, MIME"image/webp"())
        write(joinpath(dirname(page.build), "$(filename).webp"),
              base64decode(d[MIME"image/webp"()]))
        println(io, "![]($(filename).webp)\n")
    elseif haskey(d, MIME"image/jpeg"())
        write(joinpath(dirname(page.build), "$(filename).jpeg"),
              base64decode(d[MIME"image/jpeg"()]))
        println(io, "![]($(filename).jpeg)\n")
    elseif haskey(d, MIME"image/gif"())
        write(joinpath(dirname(page.build), "$(filename).gif"),
              base64decode(d[MIME"image/gif"()]))
        println(io, "![]($(filename).gif)\n")
    elseif haskey(d, MIME"text/plain"())
        text = d[MIME"text/plain"()]
        out = repr(MIME"text/plain"(),
                   ANSIColoredPrinters.PlainTextPrinter(IOBuffer(text)))
        println(io, "```")
        print(io, out)
        println(io, "\n```\n")
    else
        error("DocumenterMarkdown: no renderable MIME in $(collect(keys(d)))")
    end
end

# `@meta` blocks are not rendered (their effect is on Globals during expansion).
render(io::IO, ::MIME"text/plain", ::Node, ::Documenter.MetaNode, page, doc; kwargs...) =
    println(io)

# `@setup` blocks have no visible output.
render(io::IO, ::MIME"text/plain", ::Node, ::Documenter.SetupNode, page, doc; kwargs...) =
    nothing

# `@raw <name>` block: pass through verbatim for html and markdown targets.
function render(io::IO, ::MIME"text/plain", ::Node,
                raw::Documenter.RawNode, page, doc; kwargs...)
    if raw.name === :html || raw.name === :markdown
        println(io, "\n", raw.text, "\n")
    end
end

# ──────────────────────────────────────────────────────────────────────────────
# MarkdownAST block elements
# ──────────────────────────────────────────────────────────────────────────────

# Bare Heading (not wrapped in AnchoredHeader — rare, e.g. inside docstrings).
function render(io::IO, mime::MIME"text/plain", node::Node,
                h::MarkdownAST.Heading, page, doc; kwargs...)
    print(io, "\n", "#"^h.level, " ")
    for child in node.children
        render(io, mime, child, page, doc; kwargs...)
    end
    println(io, "\n")
end

function render(io::IO, mime::MIME"text/plain", node::Node,
                ::MarkdownAST.Paragraph, page, doc; kwargs...)
    for child in node.children
        render(io, mime, child, page, doc; kwargs...)
    end
    println(io, "\n")
end

function render(io::IO, mime::MIME"text/plain", node::Node,
                cb::MarkdownAST.CodeBlock, page, doc; kwargs...)
    println(io, "```", cb.info)
    print(io, cb.code)
    endswith(cb.code, '\n') || println(io)
    println(io, "```\n")
end

function render(io::IO, mime::MIME"text/plain", node::Node,
                bq::MarkdownAST.BlockQuote, page, doc; kwargs...)
    buf = IOBuffer()
    for child in node.children
        render(buf, mime, child, page, doc; kwargs...)
    end
    body = String(take!(buf))
    for line in eachline(IOBuffer(body); keep=false)
        println(io, "> ", line)
    end
    println(io)
end

# `MarkdownAST.List` has fields `type::Symbol` (`:bullet` or `:ordered`) and
# `tight::Bool` plus `start::Int` (ordered lists). Children are `Item`s.
function render(io::IO, mime::MIME"text/plain", node::Node,
                list::MarkdownAST.List, page, doc; kwargs...)
    idx = 0
    start = isdefined(list, :start) ? list.start : 1
    ordered = list.type === :ordered
    for child in node.children
        idx += 1
        marker = ordered ? string(start + idx - 1, ". ") : "- "
        buf = IOBuffer()
        for sub in child.children
            render(buf, mime, sub, page, doc; kwargs...)
        end
        body = strip(String(take!(buf)))
        # First line gets the marker; subsequent lines indented by the marker width.
        indent = " "^length(marker)
        lines = split(body, '\n')
        if isempty(lines)
            println(io, marker)
        else
            println(io, marker, lines[1])
            for l in lines[2:end]
                println(io, isempty(l) ? "" : indent * l)
            end
        end
    end
    println(io)
end

# Item is handled by its parent List loop above; provide a no-op direct dispatch
# in case an Item appears without a List wrapper (shouldn't happen, but safe).
render(io::IO, mime::MIME"text/plain", node::Node,
       ::MarkdownAST.Item, page, doc; kwargs...) =
    foreach(c -> render(io, mime, c, page, doc; kwargs...), node.children)

function render(io::IO, mime::MIME"text/plain", node::Node,
                ad::MarkdownAST.Admonition, page, doc; kwargs...)
    println(io, "!!! ", ad.category, " \"", ad.title, "\"")
    buf = IOBuffer()
    for child in node.children
        render(buf, mime, child, page, doc; kwargs...)
    end
    body = String(take!(buf))
    for line in eachline(IOBuffer(body); keep=false)
        println(io, "    ", line)
    end
    println(io)
end

function render(io::IO, ::MIME"text/plain", ::Node,
                m::MarkdownAST.DisplayMath, page, doc; kwargs...)
    println(io, "\n", "\$\$", m.math, "\$\$\n")
end

function render(io::IO, ::MIME"text/plain", ::Node,
                h::MarkdownAST.HTMLBlock, page, doc; kwargs...)
    println(io, "\n", h.html, "\n")
end

render(io::IO, ::MIME"text/plain", ::Node,
       ::MarkdownAST.ThematicBreak, page, doc; kwargs...) =
    println(io, "\n---\n")

function render(io::IO, mime::MIME"text/plain", node::Node,
                ::MarkdownAST.FootnoteDefinition, page, doc; kwargs...)
    fn = node.element::MarkdownAST.FootnoteDefinition
    print(io, "[^", fn.id, "]: ")
    for child in node.children
        render(io, mime, child, page, doc; kwargs...)
    end
    println(io)
end

# ──────────────────────────────────────────────────────────────────────────────
# MarkdownAST inline elements
# ──────────────────────────────────────────────────────────────────────────────

render(io::IO, ::MIME"text/plain", ::Node, t::MarkdownAST.Text, page, doc; kwargs...) =
    print(io, t.text)

function render(io::IO, mime::MIME"text/plain", node::Node,
                ::MarkdownAST.Strong, page, doc; kwargs...)
    print(io, "**")
    for child in node.children
        render(io, mime, child, page, doc; kwargs...)
    end
    print(io, "**")
end

function render(io::IO, mime::MIME"text/plain", node::Node,
                ::MarkdownAST.Emph, page, doc; kwargs...)
    print(io, "*")
    for child in node.children
        render(io, mime, child, page, doc; kwargs...)
    end
    print(io, "*")
end

function render(io::IO, mime::MIME"text/plain", node::Node,
                ::MarkdownAST.Strikethrough, page, doc; kwargs...)
    print(io, "~~")
    for child in node.children
        render(io, mime, child, page, doc; kwargs...)
    end
    print(io, "~~")
end

render(io::IO, ::MIME"text/plain", ::Node,
       c::MarkdownAST.Code, page, doc; kwargs...) =
    print(io, "`", c.code, "`")

function render(io::IO, mime::MIME"text/plain", node::Node,
                link::MarkdownAST.Link, page, doc; kwargs...)
    print(io, "[")
    for child in node.children
        render(io, mime, child, page, doc; kwargs...)
    end
    print(io, "](", rewrite_link(link.destination), ")")
end

function render(io::IO, mime::MIME"text/plain", node::Node,
                img::MarkdownAST.Image, page, doc; kwargs...)
    print(io, "![")
    for child in node.children
        render(io, mime, child, page, doc; kwargs...)
    end
    print(io, "](", img.destination, ")")
end

render(io::IO, ::MIME"text/plain", ::Node,
       m::MarkdownAST.InlineMath, page, doc; kwargs...) =
    print(io, "\$", m.math, "\$")

render(io::IO, ::MIME"text/plain", ::Node,
       h::MarkdownAST.HTMLInline, page, doc; kwargs...) =
    print(io, h.html)

render(io::IO, ::MIME"text/plain", ::Node,
       ::MarkdownAST.SoftBreak, page, doc; kwargs...) =
    print(io, "\n")

render(io::IO, ::MIME"text/plain", ::Node,
       ::MarkdownAST.LineBreak, page, doc; kwargs...) =
    print(io, "\\\n")

render(io::IO, ::MIME"text/plain", ::Node,
       fl::MarkdownAST.FootnoteLink, page, doc; kwargs...) =
    print(io, "[^", fl.id, "]")

render(io::IO, ::MIME"text/plain", ::Node,
       ::MarkdownAST.Backslash, page, doc; kwargs...) =
    print(io, "\\")

# Cross-reference link to another documentation page; `pl.page` is the target
# Page, `pl.fragment` an in-page anchor (may be empty, never includes the `#`).
function render(io::IO, mime::MIME"text/plain", node::Node,
                pl::Documenter.PageLink, page, doc; kwargs...)
    print(io, "[")
    for child in node.children
        render(io, mime, child, page, doc; kwargs...)
    end
    target = mdext(relpath(pl.page.build, dirname(page.build)))
    print(io, "](", target, _hashify(pl.fragment), ")")
end

# Link to a local file (not a documentation page). `ll.path` is relative to
# the docs source root; we re-anchor it relative to the current page.
function render(io::IO, mime::MIME"text/plain", node::Node,
                ll::Documenter.LocalLink, page, doc; kwargs...)
    print(io, "[")
    for child in node.children
        render(io, mime, child, page, doc; kwargs...)
    end
    target = _local_path_relative(ll.path, page, doc)
    print(io, "](", target, _hashify(ll.fragment), ")")
end

# Ensure a fragment string is prefixed with `#` (or empty).
_hashify(frag::AbstractString) =
    isempty(frag) || startswith(frag, '#') ? frag : "#" * frag

function render(io::IO, mime::MIME"text/plain", node::Node,
                li::Documenter.LocalImage, page, doc; kwargs...)
    print(io, "![")
    for child in node.children
        render(io, mime, child, page, doc; kwargs...)
    end
    target = _local_path_relative(li.path, page, doc)
    print(io, "](", target, ")")
end

# Build a path relative to the current page's directory in the build tree.
# `path` is interpreted as relative to the docs source root (== build root).
function _local_path_relative(path::AbstractString, page, doc)
    abs_target = joinpath(doc.user.build, path)
    return relpath(abs_target, dirname(page.build))
end

# `JuliaValue` is the result of `$(expr)` interpolation in a docstring.
# After expansion `.ref` typically holds the rendered value.
function render(io::IO, ::MIME"text/plain", ::Node,
                jv::MarkdownAST.JuliaValue, page, doc; kwargs...)
    print(io, jv.ref === nothing ? string(jv.ex) : string(jv.ref))
end

# ──────────────────────────────────────────────────────────────────────────────
# Tables
# ──────────────────────────────────────────────────────────────────────────────

# A `MarkdownAST.Table` has `spec::Vector{Symbol}` of alignments (:left, :right,
# :center, :nothing) and children TableHeader + TableBody. Rows are
# `MarkdownAST.TableRow`, cells are `MarkdownAST.TableCell`.
function render(io::IO, mime::MIME"text/plain", node::Node,
                table::MarkdownAST.Table, page, doc; kwargs...)
    println(io)
    aligns = table.spec
    headerprinted = false
    for section in node.children
        if section.element isa MarkdownAST.TableHeader
            for row in section.children
                _render_table_row(io, mime, row, page, doc; kwargs...)
            end
            _render_table_alignments(io, aligns)
            headerprinted = true
        elseif section.element isa MarkdownAST.TableBody
            for row in section.children
                _render_table_row(io, mime, row, page, doc; kwargs...)
            end
        end
    end
    headerprinted || _render_table_alignments(io, aligns)
    println(io)
end

function _render_table_row(io::IO, mime::MIME"text/plain", row::Node, page, doc; kwargs...)
    print(io, "|")
    for cell in row.children
        print(io, " ")
        for child in cell.children
            render(io, mime, child, page, doc; kwargs...)
        end
        print(io, " |")
    end
    println(io)
end

function _render_table_alignments(io::IO, aligns)
    print(io, "|")
    for a in aligns
        if a === :left
            print(io, " :--- |")
        elseif a === :right
            print(io, " ---: |")
        elseif a === :center
            print(io, " :---: |")
        else
            print(io, " --- |")
        end
    end
    println(io)
end

# ──────────────────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────────────────

# Documenter's cross-reference resolver emits HTML-style page URLs like
# `man/tutorial/#anchor` (which assume `use_directory_urls: true` style HTML).
# For MkDocs we want `man/tutorial.md#anchor` so resolution works under either
# URL scheme. Leave external URLs and bare fragments alone.
function rewrite_link(dest::AbstractString)
    isempty(dest) && return dest
    # External or scheme-qualified URL: pass through.
    occursin(r"^[a-zA-Z][a-zA-Z0-9+.\-]*://", dest) && return dest
    startswith(dest, "#") && return dest
    startswith(dest, "mailto:") && return dest
    # Split on '#' for path + fragment.
    hash = findfirst('#', dest)
    path = hash === nothing ? dest : dest[1:hash-1]
    frag = hash === nothing ? "" : dest[hash:end]
    isempty(path) && return dest
    # If the path looks like a Documenter-rendered HTML page (trailing `/` or
    # `.html`), rewrite to `.md`. Otherwise leave untouched.
    if endswith(path, '/')
        path = chop(path) * ".md"
    elseif endswith(path, ".html")
        path = chop(path; tail=5) * ".md"
    end
    return path * frag
end
