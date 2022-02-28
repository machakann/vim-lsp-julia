unquote(s) = length(s) >= 2 && (s[1] == '"' && s[end] == '"') ? s[2:end-1] : s
projectpath = unquote(Base.ARGS[1])
basepath = unquote(Base.ARGS[2])

function get_envpath(projectpath)
    !isempty(projectpath) && return projectpath
    return dirname(something(
               get(Base.load_path(), 1, nothing),
               Base.load_path_expand("@v#.#")
           ))
end
envpath = get_envpath(projectpath)

depotpath = joinpath(basepath, "depot")
pushfirst!(DEPOT_PATH, depotpath)
using Pkg
lsppath = joinpath(depotpath, "environments", "lsp")
Pkg.activate(lsppath)

using LanguageServer
runserver(stdin, stdout, envpath)
