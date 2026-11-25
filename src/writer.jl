using Base64: base64decode
using MarkdownAST: MarkdownAST, Node
import ANSIColoredPrinters

# import Markdown as MarkdownStdlib
module _Markdown
    import Markdown
end
const MarkdownStdlib = _Markdown.Markdown

"""
    Markdown(; docstrings = :plain)

Output format for `makedocs(format = Markdown(), ...)`: one `.md` file per page in the
build directory.

The keyword `docstrings` selects how the docstrings of `@docs` and `@autodocs` blocks are
written:

- `:plain` (the default): an anchor and the name with the category in bold, then the
  text of the docstring.
- `:admonition`: a box, an admonition of the class `docstring` (`!!! docstring "title"`),
  with the name and the category as the title and the docstring as the body.
- `:details`: the same as a box that can be folded and is open at first
  (`???+ docstring "title"`).

The boxes need the Markdown extension `admonition` (`:admonition`) or
`pymdownx.details` (`:details`) and can be styled with the CSS class `docstring`.
"""
struct Markdown <: Documenter.Writer
    docstrings::Symbol

    function Markdown(; docstrings::Symbol=:plain)
        docstrings in (:plain, :admonition, :details) ||
            throw(ArgumentError("Markdown: `docstrings` must be :plain, :admonition or " *
                                ":details, got :$docstrings"))
        new(docstrings)
    end
end

# The Markdown format of the document (it holds the settings of the writer).
function markdown_settings(doc::Documenter.Document)
    i = findfirst(f -> f isa Markdown, doc.user.format)
    i === nothing ? Markdown() : doc.user.format[i]
end

# return the same file with the extension changed to .md
mdext(f) = string(splitext(f)[1], ".md")

function render(doc::Documenter.Document, settings::Markdown=Markdown())
    @info "DocumenterMarkdown: rendering Markdown pages."
    copy_assets(doc)
    for (src, page) in doc.blueprint.pages
        open(mdext(page.build), "w") do io
            render(io, page.mdast.children, page, doc)
        end
    end
end

function copy_assets(doc::Documenter.Document)
    @debug "copying assets to build directory."
    assets = ASSETS
    if isdir(assets)
        builddir = joinpath(doc.user.build, "assets")
        isdir(builddir) || mkdir(builddir)
        for each in readdir(assets)
            src = joinpath(assets, each)
            dst = joinpath(builddir, each)
            ispath(dst) && @warn "DocumenterMarkdown: overwriting '$dst'."
            cp(src, dst; force = true)
        end
    else
        error("assets directory '$(abspath(assets))' is missing.")
    end
end

# The children of a node, one after the other.
function render(io::IO, children, page, doc)
    for node in children
        render(io, node, node.element, page, doc)
    end
end

# A heading with its anchor: the anchor first, then the legacy anchor with the suffix -1,
# as the Markdown backend of Documenter 0.27 did.
function render(io::IO, node::Node, ah::Documenter.AnchoredHeader, page, doc)
    id = Documenter.anchor_label(ah.anchor)
    println(io, "\n<a id='", id, "'></a>")
    ah.anchor.nth == 1 && println(io, "\n<a id='", id, "-1'></a>")
    render(io, node.children, page, doc)
end

# Metadata nodes (@meta blocks) and setup nodes (@setup blocks) have no output.
render(io::IO, ::Node, ::Union{Documenter.MetaNode,Documenter.SetupNode}, page, doc) =
    println(io, "\n")

# The directory of the output file of a page, relative to the build directory.
function pagedir(page, doc)
    dir = dirname(relpath(page.build, doc.user.build))
    isempty(dir) ? "." : dir
end

# Links to the paths of the build directory are written relative to the directory of the
# page (with the extension .md for pages), as in the Markdown backend of Documenter 0.27.
relative(path, page, doc) = replace(relpath(path, pagedir(page, doc)), "\\" => "/")

# A copy of the children of `node` as the children of `parent`, with the Documenter
# elements inside plain elements (links and images) replaced by elements of MarkdownAST,
# which the standard library `Markdown` knows. They cannot be copied as they are: a
# `PageLink` holds the whole page. An `AnchoredInline` (`[text](@id name)`) is replaced
# by its content: there is no standard library element for an anchor around inline
# content.
function copy_children!(parent::Node, node::Node, page, doc)
    for child in node.children
        e = child.element
        if e isa Documenter.AnchoredInline
            copy_children!(parent, child, page, doc)
            continue
        end
        copy = Node(plainelement(e, page, doc))
        copy_children!(copy, child, page, doc)
        push!(parent.children, copy)
    end
    return parent
end

function plainelement(e, page, doc)
    # a link to the page itself without a fragment stays `#`, as written
    ownpath = relpath(page.build, doc.user.build)
    e isa Documenter.PageLink && isempty(e.fragment) &&
        relpath(e.page.build, doc.user.build) == ownpath && return MarkdownAST.Link("#", "")
    e isa Documenter.LocalLink && isempty(e.fragment) &&
        mdext(e.path) == mdext(ownpath) && return MarkdownAST.Link("#", "")
    e isa Documenter.PageLink &&
        return MarkdownAST.Link(
            relative(mdext(relpath(e.page.build, doc.user.build)), page, doc) *
            (isempty(e.fragment) ? "" : "#" * e.fragment), "")
    e isa Documenter.LocalLink &&
        return MarkdownAST.Link(
            relative(e.path, page, doc) * (isempty(e.fragment) ? "" : "#" * e.fragment), "")
    e isa Documenter.LocalImage && return MarkdownAST.Image(relative(e.path, page, doc), "")
    return deepcopy(e)
end

# The standard library `Markdown` of a list of nodes (blocks).
function stdlib_markdown(nodes, page, doc)
    root = Node(MarkdownAST.Document())
    for node in nodes
        copy = Node(plainelement(node.element, page, doc))
        copy_children!(copy, node, page, doc)
        push!(root.children, copy)
    end
    convert(MarkdownStdlib.MD, root)
end

# The standard library `Markdown` of the inline content of the children of `node`, as a
# string (e.g. the text of a link).
function inline_text(node::Node, page, doc)
    par = Node(MarkdownAST.Paragraph())
    copy_children!(par, node, page, doc)
    strip(MarkdownStdlib.plain(stdlib_markdown([par], page, doc)))
end

# Plain Markdown elements (headings, paragraphs, code blocks, ...): the subtree is
# converted to the standard library `Markdown` and written.
function render(io::IO, node::Node, ::MarkdownAST.AbstractElement, page, doc)
    println(io)
    MarkdownStdlib.plain(io, stdlib_markdown([node], page, doc))
    println(io)
end


## Documentation nodes

render(io::IO, node::Node, ::Documenter.DocsNodesBlock, page, doc) =
    render(io, node.children, page, doc)

function render(io::IO, node::Node, docs::Documenter.DocsNode, page, doc)
    style = markdown_settings(doc).docstrings
    id = Documenter.anchor_label(docs.anchor)
    name = Documenter.bindingstring(docs.object.binding)
    category = Documenter.doccat(docs.object)
    if style === :plain
        # Docstring header based on the name of the binding and its category.
        anchor = "<a id='$id' href='#$id'>#</a>"
        header = "**`$name`** &mdash; *$category*."
        # The blank line first: if the previous docstring has no source link, the anchor,
        # an inline element, would otherwise continue its last paragraph.
        println(io)
        println(io, anchor, "\n", header, "\n\n")
    else
        # A box: the anchor for links, then an admonition or a details block with the
        # name (a link to the anchor) and the category as its title.
        title = replace("[`$name`](#$id) &mdash; $category", '"' => "&quot;")
        println(io, "\n<a id='$id'></a>\n")
        println(io, style === :details ? "???+" : "!!!", " docstring \"", title, "\"\n")
    end
    # Body. May contain several concatenated docstrings.
    for (docstring, result) in zip(docs.mdasts, docs.results)
        body = IOBuffer()
        md = dropheaders(stdlib_markdown(docstring.children, page, doc))
        MarkdownStdlib.plain(body, md)
        # When a source link is available then print the link.
        url = Documenter.source_url(doc, result)
        if url !== nothing
            link = "<a target='_blank' href='$url' class='documenter-source'>source</a><br>"
            println(body, "\n", link, "\n")
        end
        text = String(take!(body))
        if style === :plain
            print(io, text)
        else
            # the body of the box is indented by 4 spaces
            for line in split(text, '\n')
                println(io, isempty(line) ? "" : "    " * line)
            end
        end
    end
end


## Index, Contents, and Eval nodes

function render(io::IO, ::Node, index::Documenter.IndexNode, page, doc)
    for (object, _, page, mod, cat) in index.elements
        page = mdext(page)
        url = string(page, "#", Documenter.slugify(object))
        println(io, "- [`", Documenter.bindingstring(object.binding), "`](", url, ")")
    end
    println(io)
end

function render(io::IO, ::Node, contents::Documenter.ContentsNode, page, doc)
    for (count, path, anchor) in contents.elements
        header = first(anchor.node.children)
        # headers above the requested minimal depth are left out
        level = header.element.level - contents.mindepth + 1
        level < 1 && continue
        url = string(mdext(path), Documenter.anchor_fragment(anchor))
        print(io, "    "^(level - 1), "- [", inline_text(header, page, doc), "](", url, ")")
        println(io)
    end
    println(io)
end

function render(io::IO, ::Node, node::Documenter.EvalNode, page, doc)
    node.result === nothing || render(io, node.result.children, page, doc)
end

# The code blocks of a @repl block, one after the other, as one code block.
function render(io::IO, node::Node, mcb::Documenter.MultiCodeBlock, page, doc)
    io2 = IOBuffer()
    codeblocks = [n.element::MarkdownAST.CodeBlock for n in node.children]
    for (i, block) in enumerate(codeblocks)
        print(io2, block.code)
        if i != length(codeblocks)
            println(io2)
            findnext(x -> x.info == mcb.language, codeblocks, i + 1) == i + 1 &&
                println(io2)
        end
    end
    code = Node(MarkdownAST.CodeBlock(mcb.language, String(take!(io2))))
    render(io, code, code.element, page, doc)
end

# The output of an @example block: the code block, then the results.
render(io::IO, node::Node, ::Documenter.MultiOutput, page, doc) =
    render(io, node.children, page, doc)

render(io::IO, ::Node, moe::Documenter.MultiOutputElement, page, doc) =
    Base.invokelatest(render_output, io, moe.element, page, doc)

# Select the "best" representation for Markdown output.
function render_output(io::IO, d::Dict{MIME,Any}, page, doc)
    filename = String(rand('a':'z', 7))
    if haskey(d, MIME"text/markdown"())
        println(io, d[MIME"text/markdown"()])
    elseif haskey(d, MIME"text/html"())
        println(io, d[MIME"text/html"()])
    elseif haskey(d, MIME"image/svg+xml"())
        # NOTE: It seems that we can't simply save the SVG images as a file and include
        # them as browsers seem to need to have the xmlns attribute set in the <svg> tag
        # if you want to include it with <img>. However, setting that attribute is up to
        # the code creating the SVG image.
        println(io, d[MIME"image/svg+xml"()])
    else
        for ext in ("png", "webp", "jpeg", "gif")
            mime = MIME("image/$ext")
            haskey(d, mime) || continue
            write(joinpath(dirname(page.build), "$(filename).$ext"),
                  base64decode(d[mime]))
            println(io, "![]($(filename).$ext)\n")
            return
        end
        if haskey(d, MIME"text/plain"())
            text = d[MIME"text/plain"()]
            out = repr(MIME"text/plain"(),
                       ANSIColoredPrinters.PlainTextPrinter(IOBuffer(text)))
            println(io)
            MarkdownStdlib.plain(io, MarkdownStdlib.Code(out))
            println(io)
        else
            error("this should never happen.")
        end
    end
    return nothing
end

function render(io::IO, ::Node, raw::Documenter.RawNode, page, doc)
    raw.name === :html && println(io, "\n", raw.text, "\n")
end


## Markdown utilities

# Remove all header nodes from a markdown object and replace them with bold font.
# Only for use in `text/plain` output, since we'll use some css to make these less
# obtrusive in the HTML rendering instead of using this hack.
function dropheaders(md::MarkdownStdlib.MD)
    out = MarkdownStdlib.MD()
    out.meta = md.meta
    out.content = map(dropheaders, md.content)
    out
end
dropheaders(h::MarkdownStdlib.Header) =
    MarkdownStdlib.Paragraph([MarkdownStdlib.Bold(h.text)])
dropheaders(x) = x
dropheaders(v::Vector) = map(dropheaders, v)

# The other elements of Documenter and of its extensions.
function render(io::IO, node::Node, element::Union{Documenter.AbstractDocumenterBlock,
                                                    Documenter.AbstractDocumenterInline},
                page, doc)
    if hasfield(typeof(element), :codeblock) &&
       getfield(element, :codeblock) isa MarkdownAST.CodeBlock
        # An extension that replaces a code block by an element of its own, e.g.
        # DocumenterMermaid: the original code block is written, as it was.
        code = Node(getfield(element, :codeblock))
        render(io, code, code.element, page, doc)
    elseif fieldcount(typeof(element)) == 0
        # An element without content, e.g. a script that only the HTML output needs.
    else
        @warn "DocumenterMarkdown: the element $(typeof(element)) on page " *
              "'$(page.source)' is not supported and is left out."
    end
end
