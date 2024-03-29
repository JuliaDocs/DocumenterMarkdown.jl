# Flavors

"Flavor"s are simply flavor implementations of markdown.  The default functions implement Julia flavored markdown, and any fallbacks also fall back to Julia flavored markdown.  

In order to override the defaults for your format (`YourMarkdownFormat <: DocumenterMarkdown.MarkdownFormat`), you may override the following methods:

- `render(doc)`
- `render(fmt, io, ...)`
- `renderdoc(fmt, io, ...)`
- `render_mime(fmt, io, ...)`

## Defining a simple override

The way this works is that Documenter dispatches on the settings you send in to the `format` keyword in `makedocs` to find the appropriate `Format` type.