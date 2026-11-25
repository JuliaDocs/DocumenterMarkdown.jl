using Test

using Documenter, DocumenterMarkdown

# Modules `Mod` and `AutoDocs`
module Mod
    
    """
        func(x)

    [`T`](@ref)
    """
    func(x) = x

    """
        T

    [`func(x)`](@ref)
    """
    mutable struct T end

    @doc raw"""
    Inline: ``\frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2}``

    Display equation:

    ```math
    \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2}
    ```

    !!! note "Long equations in admonitions"

        Inline: ``\frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2}``

        Display equation:

        ```math
        \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2}
        ```

    Long equations in footnotes.[^longeq-footnote]

    [^longeq-footnote]:

        Inline: ``\frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2}``

        Display equation:

        ```math
        \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2} + \frac{1+2+3+4+5+6}{\sigma^2}
        ```
    """
    function long_equations_in_docstrings end
end

"`AutoDocs` module."
module AutoDocs
    module Pages
        include("pages/a.jl")
        include("pages/b.jl")
        include("pages/c.jl")
        include("pages/d.jl")
        include("pages/e.jl")
    end

    "Function `f`."
    f(x) = x

    "Constant `K`."
    const K = 1

    "Type `T`."
    mutable struct T end

    "Macro `@m`."
    macro m() end

    "Module `A`."
    module A
        "Function `A.f`."
        f(x) = x

        "Constant `A.K`."
        const K = 1

        "Type `B.T`."
        mutable struct T end

        "Macro `B.@m`."
        macro m() end
    end

    "Module `B`."
    module B
        "Function `B.f`."
        f(x) = x

        "Constant `B.K`."
        const K = 1

        "Type `B.T`."
        mutable struct T end

        "Macro `B.@m`."
        macro m() end
    end

    module Filter
        "abstract super type"
        abstract type Major end

        "abstract sub type 1"
        abstract type Minor1 <: Major end

        "abstract sub type 2"
        abstract type Minor2 <: Major end

        "random constant"
        qq = 3.14

        "random function"
        function qqq end
    end
end

# An extension of Documenter like DocumenterMermaid: it replaces the code blocks of the
# language `diagram` by an element of its own, which keeps the code block in the field
# `codeblock`, and adds an element without content to every page.
module Extension
    using Documenter: Documenter, Selectors
    using MarkdownAST: MarkdownAST, Node

    abstract type DiagramExpander <: Documenter.Expanders.ExpanderPipeline end
    Selectors.matcher(::Type{DiagramExpander}, node, page, doc) =
        Documenter.iscode(node, "diagram")
    Selectors.order(::Type{DiagramExpander}) = 7.9
    function Selectors.runner(::Type{DiagramExpander}, node, page, doc)
        node.element = DiagramBlock(node.element)
        return
    end
    struct DiagramBlock <: Documenter.AbstractDocumenterBlock
        codeblock::MarkdownAST.CodeBlock
    end

    struct ScriptBlock <: Documenter.AbstractDocumenterBlock end
    abstract type ScriptBuilder <: Documenter.Builder.DocumentPipeline end
    Selectors.order(::Type{ScriptBuilder}) = 5.5
    function Selectors.runner(::Type{ScriptBuilder}, doc::Documenter.Document)
        for page in values(doc.blueprint.pages)
            push!(page.mdast.children, Node(ScriptBlock()))
        end
    end
end

@info "Building example docs."
example_doc = makedocs(
    format = Markdown(),
    modules = [Mod, AutoDocs],
    doctest = false,
    debug  = true,
    # the pages contain links and footnotes that Documenter 1 reports as errors
    # (e.g. "some:path" as a Windows path, a footnote without a definition)
    warnonly = [:cross_references, :footnote],
);

