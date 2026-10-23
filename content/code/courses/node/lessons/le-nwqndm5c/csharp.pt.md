---
title: C#
version: 1
---

**O C# é a linguagem da Microsoft, e o .NET, o runtime dela, roda no Linux há anos**; o ASP.NET Core, o
framework web dela, está entre os mais rápidos que existem. Das cinco, é a que tem o código mais
parecido com o JavaScript moderno: o `async` e o `await` chegaram primeiro ao C#, e o JavaScript os
pegou emprestados.

```sh
sudo apt install dotnet-sdk-10.0   # Ubuntu and WSL
brew install dotnet                # a Mac, with Homebrew (not run for this course)
```

O .NET 10 é a versão atual de longo prazo. Como no Java, o root instalou o pacote antes da sessão. Um
projeto começa de um template, e o `web` é o menor servidor:

```
ana@dev:~/server/other$ dotnet new web -o csharp

Welcome to .NET 10.0!
---------------------
SDK Version: 10.0.113

----------------
Installed an ASP.NET Core HTTPS development certificate.
To trust the certificate, run 'dotnet dev-certs https --trust'
Learn about HTTPS: https://aka.ms/dotnet-https

----------------
Write your first app: https://aka.ms/dotnet-hello-world
Find out what's new: https://aka.ms/dotnet-whats-new
Explore documentation: https://aka.ms/dotnet-docs
Report issues and find source on GitHub: https://github.com/dotnet/core
Use 'dotnet --help' to see available commands or visit: https://aka.ms/dotnet-cli
--------------------------------------------------------------------------------------
The template "ASP.NET Core Empty" was created successfully.

Processing post-creation actions...
Restoring /home/ana/server/other/csharp/csharp.csproj:
  Determining projects to restore...
  Restored /home/ana/server/other/csharp/csharp.csproj (in 71 ms).
Restore succeeded.
```

A primeira execução do `dotnet` imprime boas-vindas, cria um certificado de desenvolvimento para HTTPS,
e então cria o projeto e o **restaura**, que é o `npm install`: o template não pede nada além do próprio
ASP.NET Core, que veio com o SDK. O programa é um arquivo só, e ele substitui o que o template
escreveu:

```schooling-example
{"language": "csharp", "file": "Program.cs", "parts": [
 {"code": "// Program.cs: the same server in C#, with ASP.NET Core's minimal API.\nvar builder = WebApplication.CreateBuilder(args);\nvar app = builder.Build();", "note": "**Um builder, depois um app**, do jeito que o `express()` cria um. O ASP.NET Core lê a configuração dele aqui, de arquivos e do ambiente."},
 {"code": "app.MapGet(\"/hello\", (string? name) => new { hello = name ?? \"world\" });", "note": "**Uma rota é uma função, e os parâmetros dela são preenchidos a partir do pedido**: o `name` vem da query string porque nada mais tem esse nome. O objeto devolvido é escrito como JSON."},
 {"code": "app.MapGet(\"/slow\", async () =>\n{\n    await Task.Delay(1000);\n    return new { slept = 1000 };\n});", "note": "**`async` e `await`, como no JavaScript.** O `Task.Delay` é o `setTimeout` como promise; a thread fica livre enquanto ele espera."},
 {"code": "app.MapFallback((HttpContext ctx) =>\n    Results.Json(new { error = $\"nothing at {ctx.Request.Path}\" }, statusCode: 404));", "note": "O que não casou com nada acima: um 404 explícito com corpo JSON, como os outros cinco mandam."},
 {"code": "var port = Environment.GetEnvironmentVariable(\"PORT\") ?? \"3000\";\napp.Run($\"http://127.0.0.1:{port}\");", "note": "O `Environment.GetEnvironmentVariable` é o `process.env`, e o `$\"…\"` é um template literal."}
]}
```

```
ana@dev:~/server/other/csharp$ dotnet build 2>&1 | tail -3
    0 Error(s)

Time Elapsed 00:00:04.84
```

```
ana@dev:~/server/other/csharp$ dotnet run --no-build
Using launch settings from /home/ana/server/other/csharp/Properties/launchSettings.json...
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://127.0.0.1:3000
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
info: Microsoft.Hosting.Lifetime[0]
      Hosting environment: Development
info: Microsoft.Hosting.Lifetime[0]
      Content root path: /home/ana/server/other/csharp
info: Microsoft.Hosting.Lifetime[0]
      Application is shutting down...
```

```
ana@dev:~/server/other/csharp$ curl -s 'http://127.0.0.1:3000/hello?name=ana'
{"hello":"ana"}
ana@dev:~/server/other/csharp$ curl -s -w ' %{http_code}\n' http://127.0.0.1:3000/nope
{"error":"nothing at /nope"} 404
ana@dev:~/server/other/csharp$ time (for i in $(seq 10); do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/slow & done; wait)
200 200 200 200 200 200 200 200 200 200 
real	0m1.019s
user	0m0.037s
sys	0m0.018s
ana@dev:~/server/other/csharp$ pgrep -a csharp
1434 /home/ana/server/other/csharp/bin/Debug/net10.0/csharp
ana@dev:~/server/other/csharp$ kill -TERM 1434
```

**As mesmas respostas, e um segundo para dez pedidos lentos**, porque o `await` liberou a thread para o
próximo pedido exatamente como faria no Node. Os dois últimos comandos acharam o programa que o `dotnet
run` tinha iniciado, o que o `dotnet build` fez, e mandaram a ele um `SIGTERM`, como o gerenciador de
serviço da aula 10 faria.

**Duas linhas do log dele são lições deste curso com outros nomes.** O `Hosting environment:
Development` é o `NODE_ENV`: o ASP.NET Core lê o `ASPNETCORE_ENVIRONMENT`, o template o definiu para
desenvolvimento, e um servidor o define como `Production`. E o `Application is shutting down...` é o
desligamento gracioso da aula 10, que o framework faz sozinho: ele para de aceitar conexões e dá às
abertas um tempo para terminar, 30 segundos por padrão.

| o quê | em termos de Node |
|---|---|
| ASP.NET Core | Express, com injeção de dependências, configuração e logs incluídos |
| NuGet, e o arquivo `.csproj` | `npm` e `package.json` |
| `dotnet run`, `dotnet build`, `dotnet test` | `node`, um passo de build, `node --test` |
| Entity Framework Core | uma biblioteca de banco; os cursos de banco de dados cobrem a ideia |
