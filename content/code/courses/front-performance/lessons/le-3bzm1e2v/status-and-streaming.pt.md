---
title: Do que o streaming abre mão
version: 1
---

**Uma resposta começa pelo seu status e pelos seus cabeçalhos, então o streaming se compromete com
eles antes de a página estar pronta.** Esse é o preço de mandar cedo, e a aula 2 já o pagou uma vez sem
saber: o Next.js chamou `notFound()` numa página pré-renderizada em parte, e respondeu 200, porque o 200
tinha saído com a casca.

O `curl -i` imprime os cabeçalhos antes do corpo, e o `sed` para na linha em branco que os termina:

```
@@
```

Não há `Content-Length`, porque o servidor não sabia o tamanho quando começou.
**`Transfer-Encoding: chunked` é o jeito do HTTP/1.1 de mandar um corpo em pedaços**, cada um com o
seu tamanho na frente. O HTTP/2 e o HTTP/3 têm quadros para a mesma coisa e nenhum cabeçalho para ela.

## Quatro coisas a decidir antes do primeiro byte

1. **O status.** O `stream.ts` procura o curso antes de escrever qualquer coisa, então um curso
   desconhecido é um 404. Tudo o que pode fazer uma página não existir, ou exigir login, ou mudar de
   endereço, tem de ser conhecido antes de o streaming começar, ou a resposta é um 200 com um erro
   desenhado dentro.
2. **Os cabeçalhos.** Um cookie, um redirecionamento, um cabeçalho de cache que depende do que a parte
   lenta acha: nenhum pode ser acrescentado depois de o corpo começar.
3. **Como uma falha aparece.** Se a consulta lenta falha depois de a casca ter ido, o servidor só
   consegue mandar um erro no corpo, dentro do marcador, e fechar a resposta. A página deve dizer algo
   útil nesse lugar, e o monitoramento deve saber que a requisição falhou, mesmo que o seu status diga
   200.
4. **O que fica entre o servidor e o navegador.** Um proxy, uma CDN ou uma camada de compressão que
   **acumula** a resposta segura todos os pedaços até o fim, e então os manda de uma vez: a página chega
   como se nunca tivesse sido mandada em streaming, e nada avisa. O Nginx, por exemplo, acumula as
   respostas do servidor atrás dele a não ser que isso seja desligado, e é por isso que servidores que
   fazem streaming costumam mandar um cabeçalho como `X-Accel-Buffering: no`. O único jeito de saber é
   medir pelo caminho real, com o `chunks.ts` ou com o navegador, e não contra o `localhost`.

## Quando vale a pena

O streaming compensa quando uma página tem uma parte lenta e uma rápida, e a rápida é útil sozinha: um
título, a navegação, a primeira tela de uma página de produto cujas avaliações vêm depois. Ele não
compensa quando a parte lenta é a página, um resultado de busca por exemplo, onde um marcador só adia
o momento em que a pessoa descobre que ainda não há nada para ver. A aula 5 dá um número a essa
diferença: a parte rápida é a que decide quão cedo a página parece carregar.
