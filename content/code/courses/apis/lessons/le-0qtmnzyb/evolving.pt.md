---
title: Mudando o schema
version: 1
---

**Acrescente campos com números novos, nunca mude o que um número significa, e reserve o número de
um campo que você remove.** Essas três regras são quase tudo, e elas decorrem do fato que as seções
anteriores ficaram apontando: os bytes levam números, e cada leitor traz os próprios nomes. Um
servidor e os clientes dele são atualizados em dias diferentes, então por um tempo toda mudança é
lida por alguém que tem o `.proto` antigo.

A ideia errada vem do JSON de novo: a de que **renomear** um campo é a mudança perigosa e
**renumerar** é um detalhe. É o contrário. Um nome novo com o número antigo envia exatamente os
mesmos bytes, e um cliente antigo os lê perfeitamente. O mesmo nome com um número novo é, no fio, um
campo removido e outro diferente acrescentado.

## A próxima versão do depósito

O depósito decide que o título de um livro pertence ao catálogo, não ao estoque, e que um caixa
prefere saber em que ponto das estantes o livro está. O próximo `StockLevel` dele tira `title` e
acrescenta `location`. Só essa mensagem muda, então o arquivo abaixo traz só ela e o enum que ela usa.
Salve-o como `next/stock.proto`, num diretório próprio para que ele não substitua o primeiro:

```
// shelf/next/stock.proto
// StockLevel as the warehouse's next release sends it. Nothing else changes.
syntax = "proto3";

package shelf.stock.v1;

enum Availability {
  AVAILABILITY_UNSPECIFIED = 0;
  IN_STOCK = 1;
  LOW = 2;
  SOLD_OUT = 3;
}

message StockLevel {
  reserved 2;
  reserved "title";
  string isbn = 1;
  int32 copies = 3;
  Availability availability = 4;
  string location = 5;
}
```

O `title` sumiu, e duas linhas `reserved` ficam onde ele estava: o número 2 e o nome `title` não
podem voltar a ser usados nesta mensagem. O `location` fica com o 5, um número que ninguém nunca usou.

## Um cliente antigo lê uma mensagem nova

O servidor novo escreve um nível com o `next/stock.proto`; um cliente antigo o lê com o primeiro:

```
ana@api:~/shelf$ echo 'isbn: "9786500000016" copies: 12 availability: IN_STOCK location: "A3"' | protoc -I next --encode=shelf.stock.v1.StockLevel next/stock.proto > new.bin
ana@api:~/shelf$ protoc --decode=shelf.stock.v1.StockLevel stock.proto < new.bin
isbn: "9786500000016"
copies: 12
availability: IN_STOCK
5: "A3"
```

Nada falhou. **O cliente antigo não tem `title`**, então o código dele vê uma string vazia, que é o
preço de remover um campo: compatível no fio, e ainda assim uma mudança que a tela de alguém pode
mostrar. **E ele guardou o campo 5 sem saber o nome dele.** A decodificação crua mostra o que os
bytes traziam:

```
ana@api:~/shelf$ protoc --decode_raw < new.bin
1: "9786500000016"
3: 12
4: 1
5: "A3"
```

Um campo desconhecido não é jogado fora. Um código antigo que lê uma mensagem, muda um campo e a
escreve adiante mantém os campos que não entendeu, o que importa quando uma mensagem passa por um
serviço construído antes de o campo existir. Aqui um código Python antigo tira um exemplar da
contagem e escreve a mensagem de novo:

```
ana@api:~/shelf$ python3 -c 'import sys, stock_pb2; m = stock_pb2.StockLevel.FromString(sys.stdin.buffer.read()); m.copies -= 1; sys.stdout.buffer.write(m.SerializeToString())' < new.bin | protoc --decode_raw
1: "9786500000016"
3: 11
4: 1
5: "A3"
```

O `copies` foi de 12 para 11, e o `5: "A3"` continua lá.

## Por que um número nunca é reaproveitado

Suponha que alguém, mais tarde, queira um `location` com um número menor e escolha o 2, porque está
livre. Todo cliente ainda no primeiro `stock.proto` leria a localização como o **título**, porque os bytes
de uma string no campo 2 são exatamente o que ele espera, então ele imprimiria `A3` onde deveria
estar o nome de um livro, e nada em lugar nenhum acusaria erro. O `reserved` é o que impede isso, e o
`protoc` recusa o arquivo:

```
ana@api:~/shelf$ sed 's/location = 5/location = 2/' next/stock.proto > reuse.proto
ana@api:~/shelf$ protoc reuse.proto -o /dev/null
reuse.proto: Field "location" uses reserved number 2.
reuse.proto: Suggested field numbers for shelf.stock.v1.StockLevel: 5
```

## O que é seguro

| mudança | um leitor antigo | veredito |
|---|---|---|
| acrescentar um campo com número novo | o pula, ou o guarda como desconhecido | seguro |
| remover um campo e reservar o número | vê o valor zero | seguro no fio; confira quem o lia |
| renomear um campo, mesmo número | não vê diferença | seguro no fio; quebra o código que usa o nome, e o JSON |
| mudar o tipo de um campo | lê os bytes errado, ou falha | quebra |
| reaproveitar um número | lê o campo novo como o antigo | quebra, e em silêncio |
| mudar o nome de um método ou as mensagens dele | recebe `UNIMPLEMENTED` ou lixo | quebra |

Uma mudança das três últimas linhas é um pacote novo, `shelf.stock.v2`, servido ao lado do `v1` até o
último cliente mudar, que é a regra de versionamento da aula 1 aplicada a um arquivo de contrato.
