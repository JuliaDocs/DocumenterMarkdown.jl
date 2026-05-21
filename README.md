# DocumenterMarkdown

| **Build Status**                                        |
|:-------------------------------------------------------:|
| [![][gha-img]][gha-url] [![][codecov-img]][codecov-url] |

This package provides a Markdown / MkDocs backend to [`Documenter.jl`][documenter].
It renders Documenter's docstrings, cross-references, `@autodocs`, `@index`, `@contents`,
`@example` blocks, etc. to plain `.md` files that can be fed into a static-site
generator such as [MkDocs](https://www.mkdocs.org/) (with [Material](https://squidfunk.github.io/mkdocs-material/) recommended).

**Package status:** Starting with version `0.3.0` the package targets Documenter `≥ 1.0`.
Older releases (`0.2.x` and earlier) still support Documenter `0.27`. Contributions are welcome.

## Installation

The package can be added using the Julia package manager. From the Julia REPL, type `]` to
enter the Pkg REPL mode and run

```
pkg> add DocumenterMarkdown
```

## Usage

Import the package in `make.jl` and pass `format = Markdown()` to `makedocs`:

```julia
using Documenter
using DocumenterMarkdown
makedocs(sitename = "MyPackage", format = Markdown(), ...)
```

This produces `.md` files under `build/`. Point an MkDocs configuration at that
directory to render the final site:

```yaml
# mkdocs.yml
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

Then build:

```
julia --project=docs docs/make.jl
mkdocs build
```

### Notes on the generated markdown

- Headings are emitted with Pandoc-style `{#anchor-id}` attributes; the
  `attr_list` extension (default in `mkdocs-material`) wires them up as anchors.
- Docstring entries use raw `<a id="..."></a>` HTML anchors so they don't
  pollute the page TOC.
- Cross-references and `@ref` links are rewritten to `*.md#anchor` so they
  resolve under both `use_directory_urls: true` and `false`.
- Math uses `$...$` / `$$...$$` (rendered via `pymdownx.arithmatex`).
- Admonitions use the standard MkDocs `!!! category "title"` syntax.

[documenter]: https://github.com/JuliaDocs/Documenter.jl
[documenter-docs]: https://Documenter.juliadocs.org/stable/

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://DocumenterMarkdown.juliadocs.org/stable

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://DocumenterMarkdown.juliadocs.org/dev

[gha-img]: https://github.com/JuliaDocs/DocumenterMarkdown.jl/actions/workflows/CI.yml/badge.svg?branch=master
[gha-url]: https://github.com/JuliaDocs/DocumenterMarkdown.jl/actions/workflows/CI.yml

[codecov-img]: https://codecov.io/gh/JuliaDocs/DocumenterMarkdown.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/JuliaDocs/DocumenterMarkdown.jl
