unquote(s) = length(s) >= 2 && (s[1] == '"' && s[end] == '"') ? s[2:end-1] : s

depotpath = unquote(Base.ARGS[1])
empty!(DEPOT_PATH)
pushfirst!(DEPOT_PATH, depotpath)

using LanguageServer
using SymbolServer

envpath = unquote(Base.ARGS[2])
olddepotpath = unquote(Base.ARGS[3])

server = LanguageServerInstance(stdin, stdout, false, envpath, olddepotpath)
run(server)
