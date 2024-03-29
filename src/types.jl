#=
# Types

This module defines the types used in the DocumenterMarkdown package.

We begin with the settings holders.
=#

export JuliaMarkdown, GithubMarkdown, MkDocsMarkdown


"""
    abstract type AbstractMarkdown <: Documenter.Writer

Abstract type for Markdown writers.  Has subtypes.  Used to select the correct
Markdown flavor while rendering via dispatch in `Documenter.Selectors` methods.
"""
abstract type AbstractMarkdown <: Documenter.Writer end

"""
    JuliaMarkdown()

Settings struct for rendering Julia-flavored Markdown.
"""
struct JuliaMarkdown <: AbstractMarkdown end

"""
    GithubMarkdown()

Settings struct for rendering GitHub-flavored Markdown.

The only difference between this and Julia-flavored markdown 
is the admonition syntax.
"""
struct GithubMarkdown <: AbstractMarkdown end

"""
    MkDocsMarkdown()

Settings struct for rendering MkDocs-flavored Markdown.

There is no difference between this and Julia-flavored markdown.
"""
struct MkDocsMarkdown <: AbstractMarkdown end

#=
Now, we define the format type for Markdown rendering.

This is the main supertype, and it generally does not need subtypes,
so long as the format/settings struct inherits from [`AbstractMarkdown`](@ref).
=#

"""
    abstract type MarkdownFormat <: Documenter.Writer

Abstract type for Markdown writers.  Has subtypes.  Used to select the correct
Markdown flavor while rendering via dispatch.
"""
abstract type MarkdownFormat <: Documenter.FormatSelector end
Selectors.order(::Type{<: MarkdownFormat}) = 1.0
Selectors.matcher(::Type{<: MarkdownFormat}, fmt, _) = isa(fmt, AbstractMarkdown)
Selectors.runner(::Type{<: MarkdownFormat}, fmt, doc) = render(fmt, doc)
