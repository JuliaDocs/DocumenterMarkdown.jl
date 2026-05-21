# DocumenterMarkdown

`DocumenterMarkdown` is a [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)
backend that emits one Markdown (`.md`) file per source page instead of the default
HTML site. The generated files are designed to be fed straight into
[MkDocs](https://www.mkdocs.org/) (typically with the
[Material](https://squidfunk.github.io/mkdocs-material/) theme) for the final
HTML rendering.

This is useful when you want Documenter's docstring extraction, cross-reference
resolution, `@autodocs`, `@docs`, `@index`, `@contents` and `@example` blocks,
but you (or your team) prefer the MkDocs ecosystem for the final site build.

## Installation

```
pkg> add DocumenterMarkdown
```

## Usage

In your package's `docs/make.jl`:

```julia
using Documenter
using DocumenterMarkdown

makedocs(
    sitename = "MyPackage",
    format = Markdown(),
    modules = [MyPackage],
)
```

This produces `.md` files under `docs/build/`. Point an MkDocs configuration at
that directory to render the final site:

```yaml
# docs/mkdocs.yml
site_name: MyPackage
docs_dir: build
theme:
  name: material
markdown_extensions:
  - admonition
  - attr_list
  - footnotes
  - tables
  - def_list
  - pymdownx.arithmatex:
      generic: true
  - pymdownx.tilde
extra_javascript:
  - https://polyfill.io/v3/polyfill.min.js?features=es6
  - https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js
```

Then, from the `docs/` directory:

```
julia --project=. make.jl   # Julia → build/*.md
mkdocs build                # build/  → site/
```

## How the markdown is shaped

- Section headings are emitted with Pandoc-style `{#anchor-id}` attributes.
  MkDocs's `attr_list` extension (enabled by default in `mkdocs-material`)
  wires these up as in-page anchors.
- Docstring entries (`@docs`, `@autodocs`) are preceded by raw `<a id="..."></a>`
  HTML anchors so they don't pollute the page's TOC.
- Cross-references and `@ref` links are rewritten to `*.md#anchor` form so
  they resolve under either `use_directory_urls: true` or `false`.
- Math uses `$...$` (inline) and `$$...$$` (display), rendered via the
  `pymdownx.arithmatex` extension.
- Admonitions use the standard MkDocs `!!! category "title"` syntax — the
  source `!!! note` admonitions Julia/Documenter authors are used to writing
  pass through unchanged.

## API reference

```@docs
DocumenterMarkdown.Markdown
```
