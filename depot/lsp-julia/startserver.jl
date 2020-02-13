unquote(s) = length(s) >= 2 && (s[1] == '"' && s[end] == '"') ? s[2:end-1] : s

depotpath = unquote(Base.ARGS[1])
if !isempty(depotpath)
    empty!(DEPOT_PATH)
    pushfirst!(DEPOT_PATH, depotpath)
end

using LanguageServer
using SymbolServer

envpath = unquote(Base.ARGS[2])

server = LanguageServerInstance(stdin, stdout, false, envpath)
run(server)
