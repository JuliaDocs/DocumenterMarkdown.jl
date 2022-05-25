using Documenter, DocumenterMarkdown

example_doc = makedocs(
    sitename = "DocumenterMarkdown test",
    format = Markdown(),
)

# Markdown build from Documenter's test/examples
#
# examples_markdown_doc = if "markdown" in EXAMPLE_BUILDS
#     @info("Building mock package docs: MarkdownWriter")
#     @quietly makedocs(
#         format = Markdown(),
#         debug = true,
#         root  = examples_root,
#         build = "builds/markdown",
#         doctest = false,
#         expandfirst = expandfirst,
#     )
# else
#     @info "Skipping build: Markdown"
#     @debug "Controlling variables:" EXAMPLE_BUILDS get(ENV, "DOCUMENTER_TEST_EXAMPLES", nothing)
#     nothing
# end
