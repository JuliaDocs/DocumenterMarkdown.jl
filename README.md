# DocumenterMarkdown

| **Build Status**                                        |
|:-------------------------------------------------------:|
| [![][gha-img]][gha-url] [![][codecov-img]][codecov-url] |

This package provides a Markdown / MkDocs backend to [`Documenter.jl`][documenter].

**Package status:** Currently, the package does not work with the 0.28 branch of Documenter, and
therefore the latest versions of Documenter do not have a Markdown backend available.
Older, released versions of this package can still be used together with older versions of Documenter (0.27
and earlier) to enable the Markdown backend built in to those versions of Documenter.

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
