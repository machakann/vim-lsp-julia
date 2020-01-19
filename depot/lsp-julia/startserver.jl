empty!(DEPOT_PATH)
pushfirst!(DEPOT_PATH, joinpath(@__DIR__, "julia_pkgdir"))
using LanguageServer
using SymbolServer

unquote(s) = length(s) >= 2 && (s[1] == '"' && s[end] == '"') ? s[2:end-1] : s
envpath = unquote(Base.ARGS[1])
depotpath = unquote(Base.ARGS[2])

server = LanguageServerInstance(stdin, stdout, false, envpath, depotpath)
run(server)
