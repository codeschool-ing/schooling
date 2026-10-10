---
title: Versionamento
version: 1
---

**Depois que um cliente depende da sua API, você pode acrescentar e não pode tirar.** Um campo novo numa
resposta é invisível para um cliente que não o lê. Um campo removido, renomeado ou com o tipo mudado
quebra todo cliente que o lia, no dia do deploy, sem que nenhum deles tenha mudado uma linha. Mudanças
do segundo tipo são **mudanças incompatíveis** (*breaking changes*), e um número de versão é como uma API
faz uma delas sem quebrar ninguém: o formato antigo fica onde estava, e o novo ganha um endereço novo.

O shelf tem duas versões de um recurso. A versão 2 trocou o preço, de um número de centavos para um
objeto com valor e moeda, porque a loja quer vender em euros um dia:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/books/1
{"id": 1, "isbn": "9786500000016", "title": "Dom Casmurro", "author_id": 1, "year": 1899, "price_cents": 3990, "stock": 12}
ana@api:~/shelf$ curl -s localhost:8000/v2/books/1
{"id": 1, "isbn": "9786500000016", "title": "Dom Casmurro", "author_id": 1, "year": 1899, "stock": 12, "price": {"amount_cents": 3990, "currency": "BRL"}}
```

Isso é uma mudança incompatível, e basta uma pequena. Um cliente da versão 1 lê `price_cents` e não
recebe nada da versão 2; um cliente que o multiplica pela quantidade passa a multiplicar um valor que
não existe. A mesma linha do banco alimenta as duas: as versões são duas **representações** de um
recurso, e é isso que torna barato manter a antiga viva enquanto os clientes migram.

O shelf mantém a versão 2 somente leitura, e diz isso com um 405 e um cabeçalho `Allow`, e não com
silêncio:

```
ana@api:~/shelf$ curl -si -X PATCH localhost:8000/v2/books/1 -H 'Content-Type: application/json' -d '{"stock": 11}'
HTTP/1.1 405 Method Not Allowed
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:07:53 GMT
Content-Type: application/json
Content-Length: 36
Allow: GET

{"error": "version 2 is read-only"}
```

## Onde a versão fica

Há três lugares comuns, e cada um deles está em uso em algum lugar grande:

| onde | aparência | a favor | contra |
|---|---|---|---|
| **o caminho** | `/v2/books/1` | visível em todo log, link e relato de bug; trivial de rotear | o "mesmo" recurso tem dois endereços |
| um cabeçalho | `Api-Version: 2` | o endereço continua sendo o do recurso | invisível num link; os caches precisam saber que a resposta varia por ele |
| o media type | `Accept: application/vnd.shelf.v2+json` | o mais fiel ao HTTP: um recurso, duas representações | o mais difícil de ler, digitar e depurar |

**O caminho é a escolha usual e um bom padrão**, porque a propriedade que mais importa quando algo quebra
de madrugada é conseguir ver a versão na linha do log. O shelf a coloca no caminho.

## Aposentando uma versão

Uma versão é uma promessa com data de validade, e o padrão usual anuncia a data na própria resposta.
Dois cabeçalhos, `Deprecation` e `Sunset`, dizem que uma versão está de saída e quando deixa de
responder. Um cliente que os registra em log avisa os donos dele sem que ninguém precise ler um e-mail. Depois você olha os seus próprios logs, conta quem ainda chama a versão antiga, e só a desliga
quando esse número for zero ou a data tiver passado.

**A maioria das mudanças nunca deveria precisar de versão.** Acrescentar um campo, acrescentar um
endpoint, aceitar um parâmetro opcional: nada disso quebra um cliente escrito com bom senso, e a aula 2
é sobre escrever os dois lados para que não quebre. Uma versão é para a mudança que você não conseguiu
evitar, e uma API que está na `v7` depois de dois anos fez seis mudanças que um pouco de reflexão teria
tornado aditivas.
