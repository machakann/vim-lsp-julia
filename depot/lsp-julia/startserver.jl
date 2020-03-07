using LanguageServer, LanguageServer.SymbolServer

unquote(s) = length(s) >= 2 && (s[1] == '"' && s[end] == '"') ? s[2:end-1] : s
envpath = unquote(Base.ARGS[1])

runserver(stdin, stdout, envpath)
