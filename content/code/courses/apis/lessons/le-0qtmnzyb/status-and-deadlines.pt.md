---
title: Códigos de status, prazos e metadados
version: 1
---

**Toda chamada gRPC termina com um status: um código de uma lista fixa de dezessete, e uma
mensagem.** Os códigos são do próprio gRPC, numerados de 0 a 16, e não são os do HTTP. A seção sobre
HTTP/2 mostra que o status HTTP de uma chamada gRPC que falhou continua sendo 200; o que o cliente
usa para decidir é este código, e o `except grpc.RpcError` do cliente o imprime com a mensagem.

Três recusas do depósito, cada uma com um código diferente: um livro que não existe, uma reserva de
nenhum exemplar, e uma reserva de mais exemplares do que A Hora da Estrela tem:

```
ana@api:~/shelf$ python3 stock_client.py get 9786500000099
NOT_FOUND no book with ISBN '9786500000099'
ana@api:~/shelf$ python3 stock_client.py reserve 9786500000016 0
INVALID_ARGUMENT copies must be 1 or more
ana@api:~/shelf$ python3 stock_client.py reserve 9786500000030 5
FAILED_PRECONDITION only 2 copies on the shelf
```

A ideia errada que vale nomear aqui é a de que a segunda e a terceira são o mesmo erro.
**`INVALID_ARGUMENT` diz que a requisição está errada seja qual for o estado do sistema**: zero
exemplares nunca é uma reserva. **`FAILED_PRECONDITION` diz que a requisição está certa e o sistema
não está num estado de aceitá-la**: cinco exemplares passam a ser possíveis no dia em que chega uma
entrega. Um cliente mostra o primeiro a quem digitou, e trata o segundo esperando, repondo o estoque
ou oferecendo menos.

## Os códigos, comparados aos do HTTP

| código gRPC | número | quer dizer | HTTP mais próximo |
|---|---|---|---|
| `OK` | 0 | deu certo | 200 |
| `INVALID_ARGUMENT` | 3 | a requisição está errada do jeito que está | 400 |
| `DEADLINE_EXCEEDED` | 4 | o cliente parou de esperar | 504 |
| `NOT_FOUND` | 5 | a coisa nomeada não existe | 404 |
| `ALREADY_EXISTS` | 6 | criaria uma segunda | 409 |
| `PERMISSION_DENIED` | 7 | quem chama é conhecido e não tem permissão | 403 |
| `RESOURCE_EXHAUSTED` | 8 | uma cota ou um limite acabou | 429 |
| `FAILED_PRECONDITION` | 9 | não neste estado | 400 |
| `UNIMPLEMENTED` | 12 | não existe esse método aqui | 501 |
| `INTERNAL` | 13 | o servidor quebrou | 500 |
| `UNAVAILABLE` | 14 | não deu para alcançá-lo, ou ele está recusando carga | 503 |
| `UNAUTHENTICATED` | 16 | nenhuma credencial válida | 401 |

Os outros são `CANCELLED`, `UNKNOWN`, `ABORTED`, `OUT_OF_RANGE` e `DATA_LOSS`. A coluna da direita é
o mapeamento que um gateway JSON usa, e ele não é um para um: vários códigos gRPC caem no 400.

## Uma falha dentro de um stream

O `Restock` roda a entrega inteira numa transação. Envie uma caixa de Dom Casmurro e depois uma
caixa de um livro que não existe, e a chamada falha na segunda:

```
ana@api:~/shelf$ python3 stock_client.py restock 9786500000016 5 9786500000099 1
NOT_FOUND no book with ISBN '9786500000099'
ana@api:~/shelf$ python3 stock_client.py get 9786500000016
isbn: "9786500000016"
title: "Dom Casmurro"
copies: 10
availability: IN_STOCK
```

Dom Casmurro ainda tem os dez exemplares de antes. **A primeira caixa foi desfeita junto com a
segunda**, porque o `abort` levantou a exceção dentro do bloco `with` do servidor, e essa é uma
decisão que o servidor tomou, não algo que o gRPC faz por você: um servidor que gravasse caixa por
caixa teria ficado com os cinco.

## UNAVAILABLE: ninguém respondeu

Pare o servidor com `Ctrl+C` no segundo terminal e chame de novo:

```
ana@api:~/shelf$ python3 stock_client.py get 9786500000016; echo "exit $?"
UNAVAILABLE failed to connect to all addresses; last error: UNKNOWN: ipv4:127.0.0.1:50051: Failed to connect to remote host: Connection refused
exit 1
```

**`UNAVAILABLE` é o código para tentar de novo**, depois de uma pausa que cresce a cada vez, porque
a requisição estava certa e, aqui, nunca chegou a um servidor. É o único código desta seção que diz
para tentar outra vez. Para uma chamada que muda algo, como o `Reserve`, repetir só é seguro quando a
falha veio antes de o servidor ver a chamada, como esta. Repetir um `NOT_FOUND` faz a mesma
pergunta sobre os mesmos dados; repetir um `INVALID_ARGUMENT` envia o mesmo erro de novo. Suba o
servidor outra vez antes de continuar.

## Prazos

**Um prazo é o momento em que o cliente para de esperar, e no gRPC ele viaja com a chamada.** O
`timeout=2` do cliente vira um cabeçalho `grpc-timeout`, então o servidor sabe quanto tempo tem; em
Python, `context.time_remaining()` o devolve. Quando o tempo acaba, o cliente recebe
`DEADLINE_EXCEEDED`, que é a linha que encerrou o watch na seção anterior, e o servidor vê a chamada
cancelada, que é por que o `is_active()` virou falso e o laço parou.

A ideia errada comum é a de que um timeout é assunto particular do cliente. Aqui ele faz parte da
chamada, por um motivo que aparece com três serviços em fila: quando o depósito chama um fornecedor
para responder a um caixa, ele deve repassar **o que sobra** do prazo do caixa, e não começar um
novo. Senão o fornecedor continua trabalhando numa resposta que ninguém espera mais.

Dois avisos vêm junto. **O gRPC não põe prazo nenhum se você não puser**, e uma chamada sem prazo
pode esperar para sempre por um servidor que parou de responder. E **`DEADLINE_EXCEEDED` não quer
dizer que nada aconteceu**: um `Reserve` cujo prazo venceu pode ter tirado os exemplares um
milissegundo antes, e só perguntando de novo o cliente fica sabendo.

## Metadados

**Metadados são uma lista de chaves e valores que viaja ao lado da mensagem**, nos cabeçalhos
HTTP/2, e é para lá que vai o que diz respeito à chamada e não ao livro. O cliente envia
`x-till: till-1` em toda chamada, e o interceptor do servidor o imprimiu em toda linha. Aqui está o
segundo terminal como estava antes de você parar o servidor:

```
/shelf.stock.v1.Stock/GetStock from till-1
/shelf.stock.v1.Stock/Reserve from till-1
/shelf.stock.v1.Stock/GetStock from till-1
/shelf.stock.v1.Stock/WatchStock from till-1
/shelf.stock.v1.Stock/Reserve from till-1
/shelf.stock.v1.Stock/Reserve from till-1
/shelf.stock.v1.Stock/Restock from till-1
/shelf.stock.v1.Stock/GetStock from till-1
/shelf.stock.v1.Stock/Reserve from till-1
/shelf.stock.v1.Stock/Reserve from till-1
/shelf.stock.v1.Stock/Restock from till-1
/shelf.stock.v1.Stock/GetStock from till-1
```

As chaves são minúsculas, e uma chave terminada em `-bin` leva bytes em vez de texto. **As
credenciais vão aqui**, numa entrada `authorization`, que é o assunto da aula 7; um token dentro da
mensagem de requisição teria de ser acrescentado a toda mensagem que o serviço tem.
