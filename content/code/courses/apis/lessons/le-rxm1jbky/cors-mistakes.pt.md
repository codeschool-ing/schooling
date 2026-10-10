---
title: Erros de CORS, e o que o CORS não é
version: 1
---

**Todo erro comum de CORS vem de tratar os cabeçalhos como um obstáculo a contornar, e não como uma
declaração sobre quem pode ler.** Uma página falha com uma mensagem vermelha, alguém procura a
mensagem, e a primeira resposta que a faz sumir é a que vai para produção. Quatro dessas respostas
valem ser reconhecidas, porque cada uma faz o erro sumir e cada uma está errada.

## Refletir qualquer origem que chegar

O conserto mais rápido copia o `Origin` da requisição para `Access-Control-Allow-Origin`, diga ele o
que disser. Toda página passa a funcionar, inclusive toda página de todo outro site. Numa API pública
isso é só o `*` escrito por extenso; com credenciais, deixa qualquer site que o usuário visite ler os
dados dele através do navegador dele. O `secure.py` confere a origem contra o conjunto antes de
nomeá-la, então uma origem de que ele nunca ouviu falar não recebe nada:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books/1 -H 'Origin: https://other.example' | grep -iE '^(HTTP|access-control|vary)'
HTTP/1.1 200 OK
Vary: Origin
```

A verificação precisa comparar **strings inteiras**. Um teste como "a origem termina em
`shelf.example`" aceita `https://notshelf.example`, um domínio que qualquer um pode registrar, e uma
expressão regular com o ponto sem escape ou sem âncoras tem o mesmo buraco. Um conjunto de origens
exatas, como `ORIGINS`, não tem nenhum.

## `*` com credenciais

Quando uma página pede que cookies ou autenticação HTTP sejam enviados (`credentials: "include"` no
`fetch`), o servidor precisa responder `Access-Control-Allow-Credentials: true`. E **os navegadores recusam `*`
nesse caso**: a especificação exige que uma resposta com credenciais nomeie uma origem
exata. A recusa é de propósito. Um curinga numa API que reconhece os usuários deixaria todo site da
internet ler os dados de todo usuário, então o navegador não o aceita. A saída que as pessoas
encontram em seguida é o primeiro erro, refletir a origem. A certa é a lista.

## A origem `null`

O navegador manda `Origin: null` de lugares que não têm origem de verdade: uma página aberta de um
endereço `file://`, um `iframe` com sandbox, alguns redirecionamentos. Permitir `null` porque ele
apareceu num teste com um arquivo local permite todos esses, e qualquer um pode pôr um `iframe` com
sandbox em qualquer página que publique. O `secure.py` trata `null` como mais uma origem fora da
lista:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books/1 -H 'Origin: null' | grep -iE '^(HTTP|access-control|vary)'
HTTP/1.1 200 OK
Vary: Origin
```

## Esquecer o `Vary: Origin`

Quando a resposta depende do `Origin`, um cache entre o navegador e o servidor precisa saber disso, ou
guarda a resposta feita para uma página e a entrega a outra. A página A recebe uma resposta que nomeia
a página A, o cache a guarda, e a página B é recusada por um motivo que não consegue achar; ou, na
ordem inversa, a resposta que não dizia nada chega à página A. `Vary: Origin` diz a todo cache para
guardar uma cópia por origem. O `secure.py` o manda em **toda** resposta, inclusive nas que não têm
`Access-Control-Allow-Origin`, como as duas transcrições acima mostram, porque "esta origem não pode
ler" depende do `Origin` tanto quanto o contrário. O curso `servers-cache` é sobre esses caches.

## O CORS não é controle de acesso

O erro por baixo dos quatro é acreditar que o CORS protege a API. Eis o curl, dizendo ser uma página
de uma origem em que o `secure.py` nunca confiou, mudando o estoque:

```
ana@api:~/shelf$ curl -s -X PATCH localhost:8000/v1/books/1 -H 'Origin: https://other.example' -H 'Content-Type: application/json' -d '{"stock": 0}'
{"id": 1, "title": "Dom Casmurro", "stock": 0}
```

E sem `Origin` nenhum, que é o que todo programa que não é navegador manda:

```
ana@api:~/shelf$ curl -s -X PATCH localhost:8000/v1/books/1 -H 'Content-Type: application/json' -d '{"stock": 12}'
{"id": 1, "title": "Dom Casmurro", "stock": 12}
```

**As duas funcionaram, porque o CORS só diz ao navegador o que mostrar a uma página; ele nunca impede
que uma requisição seja respondida.** Um cliente que não é navegador ignora os cabeçalhos, e um
cliente que quer se comportar mal não é navegador. O que decide se uma requisição pode mudar o estoque
é autenticação e autorização, as lições 7 a 11, conferidas no servidor em toda requisição, seja qual
for o `Origin`. O CORS decide uma coisa mais estreita: se o navegador de uma pessoa autenticada vai
deixar uma página ler a sua API em nome dessa pessoa.
