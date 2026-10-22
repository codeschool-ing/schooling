---
title: O que veio junto
version: 1
---

**Leia os cinco programas de novo com as aulas deste curso ao lado, e quase nada neles é novo.** A
sintaxe é, e os nomes que cada linguagem dá às coisas. O que um servidor *faz* é igual em todos, porque
é do HTTP e do sistema operacional, não do JavaScript:

| a ideia | neste curso | em cada uma das cinco |
|---|---|---|
| um pedido é um método, um caminho, cabeçalhos e um corpo | aulas 5 e 6 | o handler recebe exatamente isso |
| um código de status diz como foi | aula 7 | `send_response(404)`, `WriteHeader`, `sendResponseHeaders`, `http_response_code`, `statusCode:` |
| JSON é texto com um content type | aulas 5 e 7 | cada uma define `content-type: application/json` sozinha |
| a configuração vem do ambiente | aula 9 | `os.environ`, `os.Getenv`, `System.getenv`, `$_SERVER`, `Environment` |
| uma thread bloqueada para o que ela atende | aulas 2 e 10 | os modelos de concorrência acima |
| parar no `SIGTERM` sem derrubar pedidos | aula 10 | o ASP.NET Core faz; o `Server.Shutdown` do Go; os outros pelos servidores deles |
| estado guardado na memória quebra com várias cópias | aula 10 | o mesmo, menos o PHP, que não guarda nenhum |
| pacotes, um manifesto e um lockfile | aula 4 | `pip` e `pyproject.toml`, `go.mod`, Maven, Composer, NuGet |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas camadas. A de baixo, que passa de uma linguagem para outra: HTTP, códigos de status, JSON, configuração pelo ambiente, sinais e desligamento gracioso, estado fora do processo, pacotes com lockfile. A de cima, aprendida de novo em cada linguagem: sintaxe, o framework, as bibliotecas, as ferramentas e as mensagens de erro.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">aprendido de novo em cada linguagem</text><text x=\"360\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sintaxe · o framework · as bibliotecas · as ferramentas · as mensagens de erro</text><rect x=\"20\" y=\"110\" width=\"680\" height=\"100\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">levado adiante, deste curso</text><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">HTTP · códigos de status · JSON · configuração pelo ambiente</text><text x=\"360\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SIGTERM e uma parada graciosa · estado fora do processo · um lockfile</text></svg>", "caption": "A camada de baixo é o que um servidor é; a de cima é como uma linguagem o escreve."}
```

A linha da configuração é a que vale ver rodando, porque é dela que todo deploy depende. O mesmo
`PORT`, dado a cinco das seis ao mesmo tempo, num terminal; o PHP recebe a porta na linha de comando e
fica de fora desta:

```
ana@dev:~/server/other$ (cd node && PORT=4001 node hello.mjs) & (cd python && PORT=4002 python3 hello.py) & (cd go && PORT=4003 ./hello) & (cd java && PORT=4004 java Hello.java) & (cd csharp && PORT=4005 dotnet run --no-build) & wait
2026/10/22 20:12:23 go on :4003
python on :4002
node on :4001
Using launch settings from /home/ana/server/other/csharp/Properties/launchSettings.json...
java on :4004
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://127.0.0.1:4005
info: Microsoft.Hosting.Lifetime[0]
      Application started. Press Ctrl+C to shut down.
info: Microsoft.Hosting.Lifetime[0]
      Hosting environment: Development
info: Microsoft.Hosting.Lifetime[0]
      Content root path: /home/ana/server/other/csharp
127.0.0.1 - - [22/Oct/2026 20:12:24] "GET /hello?name=port-4002 HTTP/1.1" 200 -
^C
```

E num segundo:

```
ana@dev:~/server/other$ for p in 4001 4002 4003 4004 4005; do curl -s "http://127.0.0.1:$p/hello?name=port-$p"; done
{"hello":"port-4001"}
{"hello": "port-4002"}
{"hello":"port-4003"}

{"hello":"port-4004"}
{"hello":"port-4005"}
```

**Cinco linguagens, uma variável, cinco respostas**, cada uma na porta que lhe disseram. Um gerenciador
de processos, uma plataforma de contêineres ou uma unit do systemd da aula 10 inicia qualquer uma delas
do mesmo jeito: um comando, um ambiente, e `SIGTERM` para parar.

**O que não vem junto é o ecossistema.** Qual framework usar, como o middleware dele é escrito, qual
pacote faz JSON ou conversa com um banco, o que as mensagens de erro querem dizer, onde a documentação
do runtime esconde aquilo de que você precisa: cada um disso é aprendido de novo, e cada um leva o tempo
que a aula 1 disse que levaria. A diferença é que você estaria aprendendo *o jeito do Go de fazer* algo
que já entende, o que é uma fração de aprender a coisa.
