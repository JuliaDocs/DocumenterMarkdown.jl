# DocumenterMarkdown

DocumenterMarkdown is an extension of the [Documenter](https://github.com/JuliaDocs/Documenter.jl)
Julia package, implementing the Markdown -> Markdown "writer" for building documentation sites.
The Markdown output can then be further processed with other tools, such as [MkDocs](https://www.mkdocs.org/).

This functionality used to be a part of the core Documenter, but now functions as an example on
how to implement alternative writers.

## Markdown & MkDocs

To have the Markdown output available, you need to add the DocumenterMarkdown package to the
documentation Julia environment (e.g. `docs/Project.toml`) as a dependency.
You also need to import the package in `make.jl`:

```
using DocumenterMarkdown
```

When `DocumenterMarkdown` is loaded, you can specify `format = Markdown()` in [`makedocs`](https://documenter.juliadocs.org/stable/lib/public/#Documenter.makedocs).
Documenter will then output a set of Markdown files to the `build` directory that can then
further be processed with [MkDocs](https://www.mkdocs.org/) into HTML pages.

MkDocs, of course, is not the only option you have -- any markdown to HTML converter should
work fine with some amount of setting up.

!!! note

    Markdown output used to be the default option (i.e. when leaving the `format` option
    unspecified). The default now is the HTML output.

### The MkDocs `mkdocs.yml` file

A MkDocs build is controlled by the `mkdocs.yml` configuration file. Add the file with the
following content to the `docs/` directory:

```yaml
site_name:        PACKAGE_NAME.jl
repo_url:         https://github.com/USER_NAME/PACKAGE_NAME.jl
site_description: Description...
site_author:      USER_NAME

theme: readthedocs

extra_css:
  - assets/Documenter.css

extra_javascript:
  - https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS_HTML
  - assets/mathjaxhelper.js

markdown_extensions:
  - extra
  - tables
  - fenced_code
  - mdx_math

docs_dir: 'build'

pages:
  - Home: index.md
```

If you have run Documenter and it has generated a `build/` directory, you can now try running
`mkdocs build` -- this should now generate the `site/` directory.
You should also add the `docs/site/` directory into your `.gitignore` file, which should now
look like:

```
docs/build/
docs/site/
```

This is only a basic skeleton. Read through the MkDocs documentation if you would like to
know more about the available settings.


### Deployment with MkDocs

To deploy MkDocs from a CI service, you also need to provide additional keyword arguments to
[`deploydocs`](https://documenter.juliadocs.org/stable/lib/public/#Documenter.deploydocs). Your [`deploydocs`](https://documenter.juliadocs.org/stable/lib/public/#Documenter.deploydocs) call should look something like

```julia
deploydocs(
    repo   = "github.com/USER_NAME/PACKAGE_NAME.jl.git",
    make   = () -> run(`mkdocs build`),
    target = "site"
)
```

* `make` specifies the function that calls `mkdocs` to perform the second build step
* `target`, which specified which files get copied to `gh-pages`, needs to point to the
  `site/` directory

The Python packages [mkdocs](https://www.mkdocs.org), `pygments` and
[`python-markdown-math`](https://github.com/mitya57/python-markdown-math) must be
installed before `docs/make.jl` runs, e.g. with
`pip install mkdocs pygments python-markdown-math` in a step of the CI workflow.
MkDocs builds the documentation, and `python-markdown-math` provides the `mdx_math`
markdown extension to exploit MathJax rendering of latex equations in markdown. (The
helper `Deps.pip` of earlier versions of Documenter, and of this package, is gone.)


### ``\LaTeX``: MkDocs and MathJax

To get MkDocs to display ``\LaTeX`` equations correctly we need to update several of this
configuration files described above.

The `python-markdown-math` package must be installed to allow for equations to be rendered
correctly (see above).

This package should also be installed locally so that you can preview the generated
documentation prior to pushing new commits to a repository.

```sh
$ pip install python-markdown-math
```

The `docs/mkdocs.yml` file must add the `python-markdown-math` extension, called `mdx_math`,
as well as two MathJax JavaScript files:

```yaml
# ...
markdown_extensions:
  - mdx_math
  # ...

extra_javascript:
  - https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS_HTML
  - assets/mathjaxhelper.js
# ...
```

**Final Remarks**

Following this guide and adding the necessary changes to the configuration files should
enable properly rendered mathematical equations within your documentation both locally and
when built and deployed from a CI service.
