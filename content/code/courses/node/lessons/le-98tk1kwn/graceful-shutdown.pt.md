---
title: Parar sem derrubar um pedido
version: 1
---

**Um servidor é parado muitas vezes na vida**, a cada deploy, a cada reinício e a cada máquina trocada,
e cada parada chega como `SIGTERM`. O padrão do Node é sair na hora, o que derruba todo pedido que
ainda estava sendo respondido: um visitante ganha uma conexão quebrada, e uma escrita que estava pela
metade nunca termina. **Um desligamento gracioso** faz tudo em ordem:

1. parar de aceitar conexões novas;
2. deixar terminar os pedidos que já estão abertos;
3. sair quando nada sobrar, ou depois de um prazo se algo travar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Uma linha do tempo de um desligamento gracioso. O SIGTERM chega; o servidor para de aceitar conexões na hora; um pedido que já estava aberto continua até responder; quando nada sobra o processo sai com 0. Um prazo de dez segundos depois do sinal forçaria a saída se um pedido nunca terminasse.\"><line x1=\"40\" y1=\"150\" x2=\"690\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"690.0,150.0 682.6,153.1 682.6,146.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"690\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text><line x1=\"200\" y1=\"40\" x2=\"200\" y2=\"160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"200\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">SIGTERM</text><rect x=\"40\" y=\"60\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aceitando conexões</text><rect x=\"200\" y=\"60\" width=\"210\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"305\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fechado a novas: o curl ganha 7</text><rect x=\"120\" y=\"105\" width=\"290\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"265\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">/slow, aberto antes do sinal, termina</text><line x1=\"410\" y1=\"40\" x2=\"410\" y2=\"160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"410\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">loop vazio: sai com 0</text><line x1=\"620\" y1=\"40\" x2=\"620\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"2 4\"></line><text x=\"620\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">10 s: sai com 1 mesmo assim</text><text x=\"620\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só se algo travar</text></svg>", "caption": "Parar de aceitar trabalho, terminar o que já foi aceito, e deixar o loop acabar sozinho."}
```

Um servidor pequeno com uma rota lenta mostra os três passos:

```schooling-example
{"language": "javascript", "file": "graceful.js", "parts": [
 {"code": "// graceful.js: a server that finishes what it started before it exits.\nimport http from \"node:http\";\n\nconst server = http.createServer((req, res) => {\n  const ms = req.url === \"/slow\" ? 3000 : 0;\n  setTimeout(() => res.end(`done ${req.url} after ${ms} ms`), ms);\n});\nserver.listen(3000, \"127.0.0.1\", () => console.log(`pid ${process.pid} on :3000`));", "note": "O `/slow` leva três segundos para responder, tempo de sobra para mandar um sinal no meio."},
 {"code": "function shutdown(signal) {\n  console.log(`${signal}: no new connections; finishing the ones open`);\n  server.close(() => console.log(\"every connection closed; the loop is empty, so node exits\"));", "note": "**O `server.close()` para de escutar na hora** e chama de volta quando a última conexão aberta termina. As conexões keep-alive ociosas são fechadas por ele; as ocupadas ficam para terminar."},
 {"code": "  setTimeout(() => {\n    console.error(\"still busy after 10 s; exiting anyway\");\n    process.exit(1);\n  }, 10_000).unref();\n}", "note": "**O prazo.** Um pedido que nunca acaba não pode manter o processo vivo para sempre. O `unref()` faz este timer não manter o loop rodando sozinho, então quando todo o resto acaba o Node sai sem esperar por ele."},
 {"code": "process.once(\"SIGTERM\", shutdown);\nprocess.once(\"SIGINT\", shutdown);", "note": "O mesmo para o Ctrl-C. É `once`, então um segundo Ctrl-C cai no padrão do Node e para na hora, que é o que quer dizer uma pessoa que aperta duas vezes."}
]}
```

**Nada chama o `process.exit()` no caminho bom.** Quando o servidor fecha e o pedido lento já
respondeu, não sobra nada para o event loop, e o Node termina como qualquer programa terminado, com
toda escrita pendente concluída. Num terminal:

```
ana@dev:~/server/procs$ node graceful.js; echo "exit code $?"
pid 14583 on :3000
SIGTERM: no new connections; finishing the ones open
every connection closed; the loop is empty, so node exits
exit code 0
```

E num segundo, um pedido lento com um `SIGTERM` mandado meio segundo depois, e então um pedido novo:

```
ana@dev:~/server/procs$ curl -s http://127.0.0.1:3000/slow & sleep 0.5; kill -TERM 14583
ana@dev:~/server/procs$ curl -s http://127.0.0.1:3000/fast; echo "curl exit code $?"

curl exit code 7
ana@dev:~/server/procs$ wait
done /slow after 3000 ms
```

**O pedido lento foi respondido inteiro, depois do sinal**, e o novo não achou ninguém escutando: o
código de saída 7 do curl quer dizer que ele não conseguiu conectar. Depois o servidor saiu com 0,
sozinho.

## O serviço links

O `server.js` ganha a mesma forma. O store da aula 8 não precisa de nada a mais: um save em andamento
é uma escrita pendente, e o loop não acaba enquanto ela estiver pendente, então deixar o Node sair
sozinho é também o que mantém o arquivo inteiro.

```javascript
// server.js
import { config, summary } from "./src/config.js";
import { createApp } from "./src/app.js";

const server = createApp().listen(config.port, config.host, () => {
  console.log(`links on http://${config.host}:${config.port}`, summary());
});

function shutdown(signal) {
  console.log(`${signal}: closing; requests already open are finished first`);
  server.close(() => console.log("closed"));
  setTimeout(() => process.exit(1), 10_000).unref();
}
process.once("SIGTERM", shutdown);
process.once("SIGINT", shutdown);
```

```
ana@dev:~/server/links$ npm start

> links@0.1.0 start
> node --env-file-if-exists=.env server.js

links on http://127.0.0.1:3000 {
  production: false,
  host: '127.0.0.1',
  port: 3000,
  dataFile: '/home/ana/server/links/data/links.json',
  adminKey: '(set, 32 characters)'
}
SIGINT: closing; requests already open are finished first
closed
^C
```

O Ctrl-C agora diz o que está fazendo em vez de sumir. Os dez segundos são uma escolha, não uma
regra. Um gerenciador de serviço espera um tempo depois do `SIGTERM` antes de mandar o `SIGKILL`, o
systemd 90 segundos por padrão e o Docker dez, e o prazo do próprio programa precisa acabar antes, ou
é o `SIGKILL` que encerra o desligamento. No Docker isso quer dizer um prazo menor aqui ou uma espera
maior lá.
