# DocumenterMarkdown.jl changelog

## Version `v0.3.0`

* ![Breaking][badge-breaking] Requires Documenter 1 (it was 0.27) and Julia 1.10. The
  writer is rewritten for the MarkdownAST representation of the pages.
* The new keyword `Markdown(docstrings = :admonition)` or `:details` writes each docstring
  as a box (an admonition or a details block of the class `docstring`, with the name and the
  category as the title) that can be styled with CSS; the default `:plain` is as before.
* ![Breaking][badge-breaking] `pip` is removed (`Deps.pip` is gone in Documenter 1).
* The output differs from that of version 0.2:
  * links between pages and to local files are relative to the directory of the page
    that contains them (also in `@contents`); a link to the page itself without a
    fragment stays `#`;
  * the elements of extensions of Documenter that replace a code block and keep it in a
    field `codeblock` (e.g. the `mermaid` blocks of DocumenterMermaid) are written as that
    code block; elements without content are left out without a warning;
  * `[text](@id name)` anchors around inline content are not written: the content is
    written without the anchor;
  * the entries of an `@index` with the same name are in the order of Documenter 1;
  * every docstring starts with a blank line, so that its anchor starts a paragraph of its
    own also if the previous docstring has no source link (without a remote repository);
  * fewer blank lines around docstrings and at the end of code blocks, and line
    endings of the sources are normalized to LF (done by Documenter).

## Version `v0.2.1`

* Declare compatibility with Documenter 0.26. ([#5][github-5])

## Version `v0.2.0`

* ![Enhancement][badge-enhancement] Now defines and exports the `Markdown` type
  which should be passed to Documenter's `makedocs` as `makedocs(format = Markdown(), ...)`
  for specifying Markdown output ([#3][github-3]).

## Version `v0.1.0`

* Initial release.


[github-3]: https://github.com/JuliaDocs/DocumenterMarkdown.jl/pull/3
[github-5]: https://github.com/JuliaDocs/DocumenterMarkdown.jl/pull/5


[badge-breaking]: https://img.shields.io/badge/BREAKING-red.svg
[badge-deprecation]: https://img.shields.io/badge/deprecation-orange.svg
[badge-feature]: https://img.shields.io/badge/feature-green.svg
[badge-enhancement]: https://img.shields.io/badge/enhancement-blue.svg
[badge-bugfix]: https://img.shields.io/badge/bugfix-purple.svg

<!--
# Badges

![BREAKING][badge-breaking]
![Deprecation][badge-deprecation]
![Feature][badge-feature]
![Enhancement][badge-enhancement]
![Bugfix][badge-bugfix]
-->
