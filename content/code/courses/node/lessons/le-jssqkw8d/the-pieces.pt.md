---
title: Do que o Node é feito
version: 1
---

**O Node não é um programa, e sim três, colados.** Saber qual parte faz o quê responde às perguntas que o resto desta aula faz. Por que uma requisição
consegue parar todas as outras? Por que um hash de senha e a leitura de um arquivo esperam na mesma
fila? E por que cem conexões abertas não custam thread nenhuma?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"O Node em camadas. No alto, o seu JavaScript e a biblioteca do Node rodam no V8, na thread principal. Abaixo deles os bindings em C++, depois a libuv com o event loop na mesma thread principal e um pool de quatro threads. Embaixo, o sistema operacional, que vigia sockets e timers para o loop e faz as leituras de arquivo para o pool.\"><rect x=\"20\" y=\"14\" width=\"680\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">o seu JavaScript</text><text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">node:http   node:fs   node:crypto   …</text><rect x=\"20\" y=\"82\" width=\"330\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">V8</text><text x=\"185\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">compila e roda; é dono do heap</text><rect x=\"370\" y=\"82\" width=\"330\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">bindings (C++)</text><text x=\"535\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">onde a chamada deixa de ser JavaScript</text><rect x=\"20\" y=\"144\" width=\"680\" height=\"92\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">libuv</text><rect x=\"40\" y=\"174\" width=\"300\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"190\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">o event loop</text><text x=\"190\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na thread principal, com o V8</text><rect x=\"380\" y=\"174\" width=\"300\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">o pool de threads</text><rect x=\"452\" y=\"202\" width=\"30\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"492\" y=\"202\" width=\"30\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"532\" y=\"202\" width=\"30\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"572\" y=\"202\" width=\"30\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"254\" width=\"680\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o sistema operacional</text><text x=\"190\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">vigia sockets e timers (epoll)</text><text x=\"530\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lê arquivos, resolve nomes</text><line x1=\"190\" y1=\"236\" x2=\"190\" y2=\"252\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"190.0,252.0 186.9,244.6 193.1,244.6\" fill=\"var(--amber)\"></polygon><line x1=\"530\" y1=\"236\" x2=\"530\" y2=\"252\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"530.0,252.0 526.9,244.6 533.1,244.6\" fill=\"var(--wire)\"></polygon></svg>", "caption": "O seu código e o loop dividem uma thread. As quatro threads do pool nunca rodam JavaScript.", "same": ["bindings (C++)"]}
```

De cima para baixo:

- **O V8** é o motor de JavaScript, o mesmo que o Chromium usa. Ele compila o seu código e o roda, e
  é dono do heap onde ficam os seus objetos. Ele não sabe nada de arquivos nem de sockets: sozinho,
  o JavaScript não consegue nem criar um timer.
- **A biblioteca do próprio Node**, tudo o que você importa como `node:alguma-coisa`, é escrita parte
  em JavaScript e parte em C++. A metade em C++, os *bindings*, é onde uma chamada como
  `fs.readFile` deixa de ser JavaScript e vira um pedido para a camada de baixo.
- **A libuv** é uma biblioteca em C que dá ao Node o **event loop** e um **pool de threads**. Ela pede
  ao sistema operacional que vigie sockets e timers, e quando o sistema não tem como fazer algo sem
  bloquear, como ler a maioria dos arquivos, ela faz isso numa das threads do pool.

O seu Node diz com qual versão de cada um foi construído:

```
ana@dev:~/server/loop$ node -p process.versions
{
  node: '22.22.0',
  acorn: '8.15.0',
  ada: '2.9.2',
  amaro: '1.1.4',
  ares: '1.34.6',
  brotli: '1.1.0',
  cjs_module_lexer: '2.1.0',
  cldr: '47.0',
  icu: '77.1',
  llhttp: '9.3.0',
  modules: '127',
  napi: '10',
  nbytes: '0.1.1',
  ncrypto: '0.0.1',
  nghttp2: '1.64.0',
  openssl: '3.5.4',
  simdjson: '3.13.0',
  simdutf: '6.4.2',
  sqlite: '3.50.4',
  tz: '2025b',
  undici: '6.23.0',
  unicode: '16.0',
  uv: '1.51.0',
  uvwasi: '0.0.23',
  v8: '12.4.254.21-node.33',
  zlib: '1.3.1-470d3a2',
  zstd: '1.5.7'
}
```

`v8` e `uv` são as duas peças acima. O resto são bibliotecas que o Node carrega dentro dele:
`openssl` para TLS e `crypto`, `zlib` para a compressão da aula 8, `llhttp`, o parser que lê uma
requisição HTTP na aula 5, `undici`, o cliente por trás do `fetch`. **Nenhuma delas é instalada à
parte**; todas vieram no tarball que você descompactou na aula 1.

## Uma thread para o seu código

A parte que mais importa para todo o resto: **o V8 roda o seu JavaScript em uma thread**, a thread
principal, e o loop da libuv roda nessa mesma thread. Quando o loop tem um callback pronto, ele o
chama, o V8 o roda até o fim, e só então o loop procura o próximo. As threads do pool nunca rodam
JavaScript. Elas fazem o trabalho em C por baixo de algumas funções do Node e devolvem o resultado
ao loop, que então chama o seu callback na thread principal.

Então "o Node tem uma thread só" é meia verdade. O seu código tem. O processo não, e uma seção mais
abaixo conta as threads dele.
