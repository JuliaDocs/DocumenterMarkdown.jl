# DocumenterMarkdown

| **Build Status**                                        |
|:-------------------------------------------------------:|
| [![][gha-img]][gha-url] [![][codecov-img]][codecov-url] |

This package provides a Markdown / MkDocs backend to [`Documenter.jl`][documenter].

**Package status:** Version 0.3 works with Documenter 1 (tested with 1.20) and Julia 1.10 or later.
Versions 0.2 work with Documenter 0.27 only; use them if you cannot update Documenter.
The Markdown that version 0.3 writes differs slightly from that of version 0.2, see the
[changelog](CHANGELOG.md).

Contributions are welcome by anyone who might be interested in using and developing this backend.

## Documentation

- [**DEVEL**][docs-dev-url] &mdash; *documentation of the in-development version.*

## Installation

The package can be added using the Julia package manager. From the Julia REPL, type `]` to
enter the Pkg REPL mode and run

```
pkg> add DocumenterMarkdown
```

## Usage

To enable the backend import the package in `make.jl` and then just pass `format = Markdown()`
to `makedocs`:

```julia
using Documenter
using DocumenterMarkdown
makedocs(format = Markdown(), ...)
```

By default each docstring is written as an anchor, a bold name and the text. With
`Markdown(docstrings = :details)` (or `:admonition`) it is written as a box with the name and
the category as its title, which MkDocs or [Zensical](https://zensical.org) show with a header
bar, and can fold (needs the extension `pymdownx.details`, or `admonition`); style the CSS
class `docstring` as you like.

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
