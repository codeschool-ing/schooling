---
title: Os dois arquivos que o site serve, e os cabeçalhos que são conferidos
version: 1
---

**Um link verificado é verificado pelo site, então a prova dele são dois pequenos arquivos JSON em
endereços fixos do domínio.** O Android busca `/.well-known/assetlinks.json`; o iOS busca
`/.well-known/apple-app-site-association`, sem extensão. Cada um nomeia os apps autorizados a abrir os
links do site. O sistema os busca quando o app é instalado, compara com o app, e dali em diante manda
para ele os links que batem, ou não.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l11-verify\" aria-label=\"Como um link verificado é verificado, em quatro passos da esquerda para a direita. O app é instalado e declara um domínio. O sistema busca o arquivo do domínio por https: assetlinks.json no Android, apple-app-site-association no iOS. Ele compara o arquivo com o app: o pacote e a impressão digital do certificado no Android, o id do time e o bundle id no iOS. Se batem, os links para o domínio abrem o app; se não, abrem o navegador.\"><defs><marker id=\"l11-verify-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11-verify-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l11-verify-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"70\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"88.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o app é instalado,</text><text x=\"85.0\" y=\"101.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">e declara um domínio</text><rect x=\"190\" y=\"70\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"265.0\" y=\"88.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o sistema busca o</text><text x=\"265.0\" y=\"101.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivo do domínio</text><rect x=\"370\" y=\"70\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"88.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ele compara o arquivo</text><text x=\"445.0\" y=\"101.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">com o app</text><rect x=\"556\" y=\"30\" width=\"154\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"633.0\" y=\"46.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">bate: os links do</text><text x=\"633.0\" y=\"59.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">domínio abrem o app</text><rect x=\"556\" y=\"114\" width=\"154\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"633.0\" y=\"130.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">não bate: os links</text><text x=\"633.0\" y=\"143.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">abrem o navegador</text><path d=\"M160 95 L190 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-verify-ah-paper-dim)\"></path><path d=\"M340 95 L370 95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-verify-ah-paper-dim)\"></path><path d=\"M520 88 L556 56\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-verify-ah-phosphor)\"></path><path d=\"M520 102 L556 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-verify-ah-amber)\"></path><text x=\"265\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">por https, sem redirecionar</text><text x=\"265\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">assetlinks.json</text><text x=\"265\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">apple-app-site-association</text><text x=\"392\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">Android</text><text x=\"392\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">pacote + impressão</text><text x=\"392\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">digital do certificado</text><text x=\"392\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">iOS</text><text x=\"392\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">id do time +</text><text x=\"392\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">bundle id</text></svg>", "caption": "A verificação acontece quando o app é instalado, não quando um link é tocado. O toque só segue o que foi decidido ali.", "same": ["Android", "iOS", "bundle id"]}
```

## O que cada arquivo diz

**O arquivo do Android nomeia um pacote e a impressão digital do certificado com que o app é
assinado.** A documentação do Android sobre configurar associações de site dá o formato: uma lista de
declarações, cada uma com a relação `delegate_permission/common.handle_all_urls` e um alvo que nomeia o
`package_name` e as suas `sha256_cert_fingerprints`. A impressão digital é o que barra um impostor:
outro app pode copiar o nome do pacote, mas não consegue ser assinado com a chave do planner. O valor
abaixo é o exemplo impresso naquela documentação, não uma chave real; como a verdadeira é feita e
guardada é a aula 1 de `mobile-delivery`.

**O arquivo da Apple nomeia um id de app e os caminhos que ele pode abrir.** A documentação da Apple
sobre associated domains dá o formato: um objeto `applinks` cujo `details` lista `appIDs`, cada um o id
do time e o bundle id unidos por um ponto, e `components` que casam com partes da URL. `ABCDE12345` é o
id de time que o próprio exemplo da Apple usa. Os components do planner deixam `/course/*`, `/courses`
e `/week` abrirem o app, que é a mesma lista que o parser aceita, e todo outro caminho do site continua
sendo uma página web.

## Um site que os serve

Aqui está o site do planner, até onde as duas plataformas se importam com ele: os dois arquivos, uma
página web para cada curso, e um 404 para todo o resto. É o próprio módulo `http` do Node, sem nada
para instalar. Salve-o como `site.ts`:

```typescript
// site.ts: the planner's website, as far as the two platforms care about it
import { createServer } from "node:http";

// Android: which app may open this site's links, and the certificate it is
// signed with. The fingerprint is the example from Android's documentation.
const assetlinks = [{
  relation: ["delegate_permission/common.handle_all_urls"],
  target: {
    namespace: "android_app",
    package_name: "com.example.planner",
    sha256_cert_fingerprints: [
      "14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5",
    ],
  },
}];

// iOS: which app may open which paths. ABCDE12345 is the team id from
// Apple's documentation, not a real one.
const aasa = {
  applinks: {
    details: [{
      appIDs: ["ABCDE12345.com.example.planner"],
      components: [{ "/": "/course/*" }, { "/": "/courses" }, { "/": "/week" }],
    }],
  },
};

const files: Record<string, unknown> = {
  "/.well-known/assetlinks.json": assetlinks,
  "/.well-known/apple-app-site-association": aasa,
};

const server = createServer((req, res) => {
  res.sendDate = false; // no Date header, so every run prints the same
  const body = files[req.url ?? ""];
  if (body !== undefined) {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(body, null, 2) + "\n");
  } else if (req.url?.startsWith("/course/")) {
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    res.end("<h1>This course, on the web</h1>\n");
  } else {
    res.writeHead(404, { "Content-Type": "text/plain" });
    res.end("not found\n");
  }
});
server.listen(8011, "127.0.0.1", () => console.log("http://127.0.0.1:8011"));
```

Inicie-o num segundo terminal com `node site.ts`, que imprime o endereço em que escuta e continua
rodando até você apertar Ctrl+C. Depois, no primeiro terminal, peça cada arquivo do jeito que uma
plataforma pediria. `-i` imprime os cabeçalhos da resposta acima do corpo, e `-s` deixa o curl quieto
sobre o progresso:

```
ana@dev:~/planner$ curl -si http://127.0.0.1:8011/.well-known/assetlinks.json
HTTP/1.1 200 OK
Content-Type: application/json
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

[
  {
    "relation": [
      "delegate_permission/common.handle_all_urls"
    ],
    "target": {
      "namespace": "android_app",
      "package_name": "com.example.planner",
      "sha256_cert_fingerprints": [
        "14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5"
      ]
    }
  }
]
ana@dev:~/planner$ curl -si http://127.0.0.1:8011/.well-known/apple-app-site-association
HTTP/1.1 200 OK
Content-Type: application/json
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{
  "applinks": {
    "details": [
      {
        "appIDs": [
          "ABCDE12345.com.example.planner"
        ],
        "components": [
          {
            "/": "/course/*"
          },
          {
            "/": "/courses"
          },
          {
            "/": "/week"
          }
        ]
      }
    ]
  }
}
ana@dev:~/planner$ curl -si http://127.0.0.1:8011/.well-known/assetlinks
HTTP/1.1 404 Not Found
Content-Type: text/plain
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

not found
ana@dev:~/planner$ curl -si http://127.0.0.1:8011/course/sql
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

<h1>This course, on the web</h1>
```

## O que as plataformas conferem, e o que este servidor não consegue

**Três coisas nesses cabeçalhos são o que a busca de uma plataforma olha, e a documentação nomeia cada
uma.** O status é `200`; um arquivo ausente é um 404, como o de `assetlinks` sem a extensão, e um link
verificado contra um 404 não está verificado. O `Content-Type` é `application/json`, que a
documentação do Android exige com todas as letras. E não há redirecionamento: a documentação das duas
plataformas diz que o arquivo precisa ser servido sem nenhum, então um site que manda
`/.well-known/...` para o `www.` com um 301 não tem, para a verificação, arquivo nenhum.

**O que este servidor não consegue mostrar é a metade `https`.** As duas plataformas buscam o arquivo
por `https`, e a documentação da Apple pede um certificado válido. Este servidor fala `http` simples no
seu próprio computador, e nada na internet o alcança, então ele confere o status, o tipo e a ausência
de redirecionamento, e deixa o certificado para um host de verdade. Desde o iOS 14, acrescenta a
documentação da Apple, o aparelho nem busca o arquivo no seu servidor: pede a uma rede de entrega de
conteúdo que a Apple mantém, que o buscou de você.

**Os dois arquivos são a mesma promessa em dois vocabulários.** Cada um diz *este app, e nenhum outro,
pode abrir links para este domínio*. Cada um é público, de propósito: qualquer pessoa pode ler quais
apps um site garante, e tudo bem, porque uma impressão digital e um id de time não são segredos. Pare o
servidor com Ctrl+C antes de seguir.
