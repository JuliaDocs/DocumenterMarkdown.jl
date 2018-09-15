module DocumenterMarkdown

using Documenter

function __init__()
    if !isdefined(Documenter.Writers, :enable_backend)
        @warn """Incompatible Documenter version.

        Documenter.Writers is missing the enable_backend() function.
        """
        return
    end
    Documenter.Writers.enable_backend(:markdown)
    nothing
end

end # module
