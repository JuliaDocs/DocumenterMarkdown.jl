# DocumenterMarkdown

This package enables the Markdown / MkDocs backend of [`Documenter.jl`][documenter].

## Installation

The package is currently unregistered and must be added via URL in the package manager.
From the Julia REPL, type `]` to enter the Pkg REPL mode and run

```
pkg> add https://github.com/JuliaDocs/DocumenterMarkdown.jl.git
```

## Usage

To enable the backend import the package in `make.jl` and then just pass `format = :markdown`
to `makedocs`:

```julia
using Documenter
using DocumenterMarkdown
makedocs(format = :markdown, ...)
```

[documenter]: https://github.com/JuliaDocs/Documenter.jl
