
"""
    docpath(file, mdfolder)

This function takes the filename `file`, and returns a file path in the `mdfolder` directory which has the same tree as the `src` directory.  This is used to ensure that the Markdown files are output in the correct location for Vitepress to find them.

"""
function docpath(builddir, file)
    path = relpath(file, builddir)
    filename = mdext(path)
    return joinpath(builddir, filename) 
end

"""
    join_multiblock(mcb::Documenter.MultiCodeBlock)

Joins a `Documenter` multi-code block, splitting by defined language.

Returns a `Vector` (potentially of length 1) of `Markdown.Code` objects.
"""
function join_multiblock(mcb::Documenter.MultiCodeBlock)
    if mcb.language == "ansi"
        # Return a vector of Markdown code blocks
        # where each block is a single line of the output or input.
        # Basically, we iterate through the code,
        # and whenever the language changes, we
        # start a new code block and push the old one to the array!
        codes = Markdown.Code[]
        current_language = first(mcb.content).language
        current_string = ""
        for thing in mcb.content
            # reset the buffer and push the old code block
            if thing.language != current_language
                # Remove this if statement if you want to 
                # include empty code blocks in the output.
                if isempty(thing.code) 
                    current_string *= "\n\n"
                    continue
                end
                push!(codes, Markdown.Code(intelligent_language(current_language), current_string))
                current_string = ""
                current_language = thing.language # reset the current language
            end
            # push the current code to `io`
            current_string *= thing.code
        end
        # push the last code block
        push!(codes, Markdown.Code(intelligent_language(current_language), current_string))
        return codes

    end
    # else
        io = IOBuffer()
        for (i, thing) in enumerate(mcb.content)
            print(io, thing.code)
            if i != length(mcb.content)
                println(io)
                if findnext(x -> x.language == mcb.language, mcb.content, i + 1) == i + 1
                    println(io)
                end
            end
        end
        return [Markdown.Code(mcb.language, String(take!(io)))]
    # end
end