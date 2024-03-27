#=
# MIME rendering

This file contains utilities to render various objects as different MIME types within Markdown.

## MIME priority

The `mime_priority` function is used to determine the priority of a given MIME type.  This is used to select the best MIME type for rendering a given element.  Priority is in ascending order, i.e., 1 has more priority than 0.

What happens is that the output dictionary that Documenter returns is sorted by the output of `mime_priority` on its keys.

As a general rule, the closer the MIME type is to plain text (meaning it can encode less information), the lower the priority.  

For example, showing a video is strictly more preferable to showing an image, which is itself more preferable to showing the unmodified Julia REPL show output.

=#

"""
    mime_priority(mime::MIME)::Float64

This function returns a priority for a given MIME type, which
is used to select the best MIME type for rendering a given
element.  Priority is in ascending order, i.e., 1 has more priority than 0.
"""
function mime_priority end
mime_priority(::MIME"text/plain") = 0.0
mime_priority(::MIME"text/markdown") = 1.0
mime_priority(::MIME"text/html") = 2.0
mime_priority(::MIME"text/latex") = 2.5
mime_priority(::MIME"image/svg+xml") = 3.0
mime_priority(::MIME"image/png") = 4.0
mime_priority(::MIME"image/webp") = 5.0
mime_priority(::MIME"image/jpeg") = 6.0
mime_priority(::MIME"image/png+lightdark") = 7.0
mime_priority(::MIME"image/jpeg+lightdark") = 8.0
mime_priority(::MIME"image/svg+xml+lightdark") = 9.0
mime_priority(::MIME"image/gif") = 10.0
mime_priority(::MIME"video/mp4") = 11.0
mime_priority(::MIME) = Inf

#=
## MIME rendering

Now, we define functions to render mime types.
=#


function render_mime(flavor::AbstractMarkdown, io::IO, mime::MIME, node, element, page, doc; kwargs...)
    @warn("DocumenterMarkdown: Unknown MIME type $mime provided and no alternatives given.  Ignoring render!")
end

function render_mime(flavor::AbstractMarkdown, io::IO, mime::MIME"text/markdown", node, element, page, doc; kwargs...)
    println(io, element)
end

function render_mime(flavor::AbstractMarkdown, io::IO, mime::MIME"text/html", node, element, page, doc; kwargs...)
    println(io, element)
end

function render_mime(flavor::AbstractMarkdown, io::IO, mime::MIME"image/svg+xml", node, element, page, doc; kwargs...)
    # NOTE: It seems that we can't simply save the SVG images as a file and include them
    # as browsers seem to need to have the xmlns attribute set in the <svg> tag if you
    # want to include it with <img>. However, setting that attribute is up to the code
    # creating the SVG image.
    image_text = element
    # Additionally, Vitepress complains about the XML version and encoding string below,
    # so we just remove this bad hombre!
    bad_hombre_string = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" |> lowercase
    location = findfirst(bad_hombre_string, lowercase(image_text))    
    if !isnothing(location) # couldn't figure out how to do this in one line - maybe regex?  A question for later though.
        image_text = replace(image_text, image_text[location] => "")
    end
    println(io, "<img src=\"data:image/svg+xml;base64," * base64encode(image_text) * "\"/>")
end

function render_mime(flavor::AbstractMarkdown, io::IO, mime::MIME"image/png", node, element, page, doc; md_output_path, kwargs...)
    filename = String(rand('a':'z', 7))
    write(joinpath(doc.user.build, md_output_path, dirname(relpath(page.build, doc.user.build)), "$(filename).png"),
        base64decode(element))
    println(io, "![]($(filename).png)")
end

function render_mime(flavor::AbstractMarkdown, io::IO, mime::MIME"image/webp", node, element, page, doc; md_output_path, kwargs...)
    filename = String(rand('a':'z', 7))
    write(joinpath(doc.user.build, md_output_path, dirname(relpath(page.build, doc.user.build)), "$(filename).webp"),
        base64decode(element))
    println(io, "![]($(filename).webp)")
end

function render_mime(flavor::AbstractMarkdown, io::IO, mime::MIME"image/jpeg", node, element, page, doc; md_output_path, kwargs...)
    filename = String(rand('a':'z', 7))
    write(joinpath(doc.user.build, md_output_path, dirname(relpath(page.build, doc.user.build)), "$(filename).jpeg"),
        base64decode(element))
    println(io, "![]($(filename).jpeg)")
end

# function render_mime(flavor::AbstractMarkdown, io::IO, mime::MIME"image/png+lightdark", node, element, page, doc; md_output_path, kwargs...)
#     fig_light, fig_dark, backend = element
#     filename = String(rand('a':'z', 7))
#     write(joinpath(doc.user.build, md_output_path, dirname(relpath(page.build, doc.user.build)), "$(filename)_light.png"), fig_light)
#     write(joinpath(doc.user.build, md_output_path, dirname(relpath(page.build, doc.user.build)), "$(filename)_dark.png"), fig_dark)
#     println(io,
#         """
#         ![]($(filename)_light.png){.light-only}
#         ![]($(filename)_dark.png){.dark-only}
#         """
#     )
# end

# function render_mime(flavor::AbstractMarkdown, io::IO, mime::MIME"image/jpeg+lightdark", node, element, page, doc; md_output_path, kwargs...)
#     fig_light, fig_dark, backend = element
#     filename = String(rand('a':'z', 7))
#     Main.Makie.save(joinpath(doc.user.build, md_output_path, dirname(relpath(page.build, doc.user.build)), "$(filename)_light.jpeg"), fig_light)
#     Main.Makie.save(joinpath(doc.user.build, md_output_path, dirname(relpath(page.build, doc.user.build)), "$(filename)_dark.jpeg"), fig_dark)
#     println(io,
#         """
#         ![]($(filename)_light.jpeg){.light-only}
#         ![]($(filename)_dark.jpeg){.dark-only}
#         """
#     )
# end

# function render_mime(flavor::AbstractMarkdown, io::IO, mime::MIME"image/svg+xml+lightdark", node, element, page, doc; md_output_path, kwargs...)
#     fig_light, fig_dark, backend = element
#     filename = String(rand('a':'z', 7))
#     Main.Makie.save(joinpath(doc.user.build, md_output_path, dirname(relpath(page.build, doc.user.build)), "$(filename)_light.svg"), fig_light)
#     Main.Makie.save(joinpath(doc.user.build, md_output_path, dirname(relpath(page.build, doc.user.build)), "$(filename)_dark.svg"), fig_dark)
#     println(io,
#         """
#         <img src = "$(filename)_light.svg" style=".light-only"></img>
#         <img src = "$(filename)_dark.svg" style=".dark-only"></img>
#         """
#     )
# end

function render_mime(flavor::AbstractMarkdown, io::IO, mime::MIME"image/gif", node, element, page, doc; md_output_path, kwargs...)
    filename = String(rand('a':'z', 7))
    write(joinpath(doc.user.build, md_output_path, dirname(relpath(page.build, doc.user.build)), "$(filename).gif"),
        base64decode(element))
    println(io, "![]($(filename).gif)")
end

function render_mime(flavor::AbstractMarkdown, io::IO, mime::MIME"video/mp4", node, element, page, doc; md_output_path, kwargs...)
    filename = String(rand('a':'z', 7))
    write(joinpath(doc.user.build, md_output_path, dirname(relpath(page.build, doc.user.build)), "$(filename).mp4"),
        base64decode(element))
    println(io, "<video src='$filename.mp4' controls='controls' autoplay='autoplay'></video>")
end

function render_mime(flavor::AbstractMarkdown, io::IO, mime::MIME"text/plain", node, element, page, doc; kwargs...)
    return render(io, mime, node, Markdown.Code(element), page, doc; kwargs...)
end