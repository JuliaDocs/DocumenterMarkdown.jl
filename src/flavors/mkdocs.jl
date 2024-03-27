# # MkDocs flavored markdown

# For MkDocs, we copy over the files in `assets/mkdocs`, which are a CSS file and a MathJax helper file.
# For this, we override the main entry point to `render` to copy these assets to the `build/assets` folder,
# if they do not currently exist.


function render(settings::MkDocsMarkdown, doc::Documenter.Document)
    @info "DocumenterMarkdown: rendering Markdown pages."
    mime = MIME"text/plain"()
    builddir = isabspath(doc.user.build) ? doc.user.build : joinpath(doc.user.root, doc.user.build)
    mkpath(builddir)
    # Copy over assets
    ASSET_PATH = joinpath(@__DIR__, "assets", "mkdocs")
    mkpath(joinpath(builddir, "assets"))
    for file in readdir(ASSET_PATH)
        cp(file, joinpath(builddir, "assets", file); force = false)
    end
    # Now, render the pages
    for (src, page) in doc.blueprint.pages
        # This is where you can operate on a per-page level.
        open(docpath(builddir, page.build), "w") do io
            for node in page.mdast.children
                render(settings, io, mime, node, page, doc)
            end
        end
    end
end

# Aside from the asset copying, the rendering process is the same as the default Markdown renderer.