---
title: C#
version: 1
---

**C# is Microsoft's language, and .NET, its runtime, has run on Linux for years**; ASP.NET Core, its
web framework, is among the fastest there is. Of the five it is the one whose code looks most like
modern JavaScript: `async` and `await` came to C# first, and JavaScript borrowed them.

```sh
sudo apt install dotnet-sdk-10.0   # Ubuntu and WSL
brew install dotnet                # a Mac, with Homebrew (not run for this course)
```

.NET 10 is the current long-term release. As with Java, root installed the package before the
session. A project starts from a template, `web` being the smallest server:

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

The first run of `dotnet` prints a welcome, makes a development certificate for HTTPS, and then
creates the project and **restores** it, which is `npm install`: the template asks for nothing beyond
ASP.NET Core itself, which came with the SDK. The program is one file, and it replaces the one the
template wrote:

```schooling-example
{"language": "csharp", "file": "Program.cs", "parts": [
 {"code": "// Program.cs: the same server in C#, with ASP.NET Core's minimal API.\nvar builder = WebApplication.CreateBuilder(args);\nvar app = builder.Build();", "note": "**A builder, then an app**, the way `express()` makes one. ASP.NET Core reads its own configuration here, from files and from the environment."},
 {"code": "app.MapGet(\"/hello\", (string? name) => new { hello = name ?? \"world\" });", "note": "**A route is a function, and its parameters are filled from the request**: `name` comes from the query string because nothing else is called that. The object returned is written as JSON."},
 {"code": "app.MapGet(\"/slow\", async () =>\n{\n    await Task.Delay(1000);\n    return new { slept = 1000 };\n});", "note": "**`async` and `await`, as in JavaScript.** `Task.Delay` is `setTimeout` as a promise; the thread is free while it waits."},
 {"code": "app.MapFallback((HttpContext ctx) =>\n    Results.Json(new { error = $\"nothing at {ctx.Request.Path}\" }, statusCode: 404));", "note": "Whatever matched nothing above: an explicit 404 with a JSON body, as the other five send."},
 {"code": "var port = Environment.GetEnvironmentVariable(\"PORT\") ?? \"3000\";\napp.Run($\"http://127.0.0.1:{port}\");", "note": "`Environment.GetEnvironmentVariable` is `process.env`, and `$\"…\"` is a template literal."}
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

**The same answers, and one second for ten slow requests**, because `await` freed the thread for the
next request exactly as it would in Node. The last two commands found the program `dotnet run` had
started, the one `dotnet build` made, and sent it `SIGTERM`, as lesson 10's service manager would.

**Two lines in its log are this course's lessons under other names.** `Hosting environment:
Development` is `NODE_ENV`: ASP.NET Core reads `ASPNETCORE_ENVIRONMENT`, the template set it for
development, and a server sets it to `Production`. And `Application is shutting down...` is lesson
10's graceful shutdown, which the framework does by itself: it stops taking connections and gives the
open ones time to finish, 30 seconds by default.

| what | in Node terms |
|---|---|
| ASP.NET Core | Express, with dependency injection, configuration and logging included |
| NuGet, and the `.csproj` file | `npm` and `package.json` |
| `dotnet run`, `dotnet build`, `dotnet test` | `node`, a build step, `node --test` |
| Entity Framework Core | a database library; the database courses cover the idea |
