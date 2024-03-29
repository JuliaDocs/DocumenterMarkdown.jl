# DocumenterMarkdown

| **Build Status**                                        |
|:-------------------------------------------------------:|
| [![][gha-img]][gha-url] [![][codecov-img]][codecov-url] |

This package provides a Markdown / MkDocs backend to [`Documenter.jl`][documenter].

Right now, this package is not actively maintained. However, contributions are welcome by anyone
who might be interested in using and developing this backend.

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
