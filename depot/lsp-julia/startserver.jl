unquote(s) = length(s) >= 2 && (s[1] == '"' && s[end] == '"') ? s[2:end-1] : s
projectpath = unquote(Base.ARGS[1])
basepath = unquote(Base.ARGS[2])

depotpath = joinpath(basepath, "depot")
pushfirst!(DEPOT_PATH, depotpath)
using Pkg
lsppath = joinpath(depotpath, "environments", "lsp")
Pkg.activate(lsppath)

using LanguageServer
runserver(stdin, stdout, projectpath)
