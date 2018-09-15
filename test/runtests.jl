using Test
using Documenter

@test isdefined(Documenter.Writers, :enable_backend)
@test isdefined(Documenter.Writers, :backends_enabled)

@test Documenter.Writers.backends_enabled[:markdown] === false

using DocumenterMarkdown

@test Documenter.Writers.backends_enabled[:markdown] === true
