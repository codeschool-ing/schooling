---
title: O que o navegador guarda, e por quanto tempo
version: 1
---

O navegador guarda uma cópia de muito do que recebe, no seu **cache HTTP**, e da próxima vez que uma
página pede o mesmo endereço ele tem três escolhas: usar a cópia sem perguntar a ninguém, perguntar
ao servidor se a cópia ainda vale, ou buscar tudo de novo. **Quem decide é o servidor**, com
cabeçalhos em cada resposta, e o navegador obedece.

A primeira imagem que se costuma ter é a de que o cache acelera e não muda nada do que se vê: a
página carrega mais rápido e de resto é igual. Essa imagem falha justamente no caso que interessa a
quem testa. Quando a cópia é usada sem perguntar, **o servidor nem é consultado**, então uma mudança
feita no servidor desde então é invisível para aquele navegador, por mais certo que o servidor esteja
agora.

## Quatro cabeçalhos, e um status

| na resposta | o que o navegador pode fazer com a cópia |
|---|---|
| `Cache-Control: max-age=600` | usá-la por 600 segundos **sem perguntar**; depois disso, perguntar |
| `Cache-Control: no-cache` | guardá-la, mas **perguntar ao servidor antes de cada uso** |
| `Cache-Control: no-store` | não guardar nada; buscar de novo toda vez |
| `ETag: "…"` | uma impressão digital do conteúdo, para citar ao perguntar |

**`no-cache` é o do nome enganoso.** Não quer dizer *não guarde*; isso é `no-store`. Quer dizer
*guarde, e confira antes*. A conferência é uma requisição que leva a impressão digital num cabeçalho
`If-None-Match`, e o servidor tem duas respostas: `304 Not Modified`, sem corpo, que diz ao navegador
que a cópia ainda está certa; ou `200`, com o conteúdo novo e uma impressão digital nova.

## Os arquivos da própria loja

A aula 1 montou o servidor de modo que todo arquivo de `app/public/` leve `no-cache` e um `ETag`. O
`curl` não tem cache próprio, então mostra exatamente o que o servidor diz. Aqui `-D -` imprime os
cabeçalhos da resposta e `-o /dev/null` joga o corpo fora, com a loja rodando:

```
ana@laptop:~/quitanda$ curl -s -D - -o /dev/null http://localhost:3000/style.css
HTTP/1.1 200 OK
Cache-Control: no-cache
ETag: "39dfe74803f5"
Content-Type: text/css; charset=utf-8
Date: Sat, 10 Oct 2026 19:52:54 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked
```

Pergunte de novo citando essa impressão digital, como faria um navegador que tem a cópia:

```
ana@laptop:~/quitanda$ curl -s -D - -o /dev/null -H 'If-None-Match: "39dfe74803f5"' http://localhost:3000/style.css
HTTP/1.1 304 Not Modified
Cache-Control: no-cache
ETag: "39dfe74803f5"
Date: Sat, 10 Oct 2026 19:52:54 GMT
Connection: keep-alive
Keep-Alive: timeout=5
```

**Um `304` e nenhum corpo**: a folha de estilos não foi mandada uma segunda vez. Um navegador que
recebe essa resposta desenha a página com a sua cópia, e o custo foi uma ida e volta curta. Com
`max-age` o custo seria nenhuma ida e volta, e é por isso que os sites usam `max-age` longos para
arquivos cujo nome muda quando o conteúdo muda, como `app.3f9c1a.js`. Uma versão nova tem então um
endereço novo, e a cópia antiga nunca mais é pedida. Os arquivos da loja mantêm o nome, então são
conferidos toda vez.

## Onde mais uma cópia pode morar

O navegador não é o único lugar que guarda respostas. Uma **CDN** ou um proxy entre o navegador e o
servidor também pode guardar, para todos os visitantes de uma vez, e o `max-age` vale para eles a
menos que a resposta diga também `private`. Esse cache fica fora do navegador, e nada nesta aula o
esvazia. Uma página também pode rodar um **service worker**, um script que fica entre a página e a
rede e guarda as próprias cópias; a aula 5 trata dele.

O resto desta aula fica no cache do próprio navegador, porque é dentro dele que todo teste roda.
