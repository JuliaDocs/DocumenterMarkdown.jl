# DocumenterMarkdown.jl changelog

## Version `v0.3.0`

* ![BREAKING][badge-breaking] Rewritten to target Documenter `1.x`. Earlier
  releases (`0.2.x`) remain compatible with Documenter `0.27`.
* ![Feature][badge-feature] Output is tailored for [MkDocs](https://www.mkdocs.org/):
  headings use Pandoc-style `{#anchor}` attributes (via the `attr_list`
  extension), admonitions use the `!!! category "title"` form, math uses
  `$...$` / `$$...$$` (via `pymdownx.arithmatex`), and cross-references
  resolve to `*.md#anchor`.
* ![BREAKING][badge-breaking] The vestigial `Documenter.css` and
  `mathjaxhelper.js` assets are no longer copied into `build/`; an MkDocs theme
  provides its own styling and math rendering.
* ![BREAKING][badge-breaking] The `dropheaders` behaviour that rewrote
  in-docstring headings to bold paragraphs has been removed. Use the MkDocs
  TOC plugin's `toc_depth` setting to control which heading levels appear in
  the page outline.

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
