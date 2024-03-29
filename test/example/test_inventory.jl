# Assumptions
#
# * current working directory is the root directory of the project ("DocInventories") in this case
# * the documentation for the project has been built locally in `docs/build/`
# * the documentation has also been deployed online and is available at the `root_url` hard-coded in the script. Otherwise, do not call `check_url`
# * running on Unix (otherwise: adjust that path separator)

using HTTP
using URIs
using DocInventories
using DocumenterMarkdown

check_url(url) = HTTP.request("GET", url).status == 200

function check_locally(relative_url, fragment)
    filename = joinpath(@__DIR__, "build", relative_url)
    if isfile(filename)
        if isempty(fragment)
            return true
        else
            html = read(filename, String)
            fragment = URIs.unescapeuri(fragment)
            return occursin("#$fragment", html)
        end
    else
        println("File not found")
        return false
    end
end


inventory = Inventory(joinpath(@__DIR__, "build", "objects.inv"); root_url="https://juliadocs.org/DocInventories.jl/stable/")

for item in inventory
    url = DocInventories.uri(item; root_url="build/")
    relative_url = replace(DocInventories.uri(item), ".html" => ".md")
    fragment = ""
    if occursin("#", url)
        url, fragment = split(url, "#")
    end
    # @assert check_url(url)
    if occursin("#", relative_url)
        relative_url, fragment = split(relative_url, "#")
    end
    if isempty(relative_url)
        relative_url = "index.md"
    end
    if check_locally(relative_url, fragment)
        @test true
    else
        @warn "Cound not find $item"
        @test false
    end
end
