---
title: Um destino que não se importa de ver um evento duas vezes
version: 1
---

**Uma operação é idempotente quando fazê-la duas vezes deixa o mesmo resultado que fazê-la uma.**
"Some 990 ao total" não é: duas vezes dá 1.980. "O pagamento do pedido `o-303` é 990" é: gravado duas
vezes, continua dizendo 990. A entrega pelo menos uma vez é inofensiva para um destino cujas gravações
são do segundo tipo, e esta seção inteira é sobre como transformar o primeiro tipo no segundo.

## Uma chave que nomeia o pagamento, não o momento

**O modo `upsert` do `totals.py` grava cada pagamento como um blob com o nome do id do pedido**,
sobrescrevendo o que estiver lá, e calcula os totais no fim somando os blobs. A mesma queda, o mesmo
reinício:

```
ana@laptop:~/azure$ python totals.py upsert 5
seq 0  o-301 c-17   4590  written under its order id
seq 1  o-302 c-02  12800  written under its order id
seq 2  o-303 c-17    990  written under its order id
  checkpoint at seq 2
seq 3  o-303 c-17    990  written under its order id
seq 4  o-304 c-05   2350  written under its order id
  crash
ana@laptop:~/azure$ python totals.py upsert
seq 3  o-303 c-17    990  written under its order id
seq 4  o-304 c-05   2350  written under its order id
seq 5  o-305 c-02   1500  written under its order id
  checkpoint at seq 5
seq 6  o-306 c-17   7200  written under its order id
totals: c-02 14300  c-05 2350  c-17 12780
```

**A repetição aconteceu exatamente como antes**: a segunda execução começou depois do checkpoint no
número de sequência 2 e tratou o 3 e o 4 de novo. Desta vez não fez mal nenhum. A segunda cópia de
`o-303` e o `o-304` repetido foram gravados sobre blobs de mesmo nome com o mesmo conteúdo, e a
duplicata do produtor foi para o mesmo lugar que o original. **Os totais são os corretos**: 12.780,
14.300 e 2.350. Nada no leitor detectou uma duplicata; a forma da gravação tornou desnecessário
detectar.

A ideia vale para todo destino que a Quitanda tem. No Azure SQL Database é um `MERGE`, ou um insert
numa tabela cuja chave primária é o id do pedido, onde o segundo insert é recusado pela chave. No
Cosmos DB é um upsert de um documento cujo `id` é o id do pedido, a operação que o programa da lição 1
usou. A Microsoft documenta que a saída do Stream Analytics para o Cosmos DB grava desse jeito, pelo
id do documento, o que torna essa saída segura para repetir. No lake é um arquivo com o nome do que
ele contém, como a faixa de números de sequência que guarda, e não da hora em que foi gravado: um
arquivo com o nome da hora ganha um nome novo a cada repetição e fica no lake duas vezes.

## Recusar a segunda gravação

**Sobrescrever é um jeito de ser idempotente; recusar é o outro.** O Blob Storage aceita a ordem de
criar um blob só se não existir nenhum com aquele nome, com a condição `If-None-Match: *`, que a linha
de comando escreve `--if-none-match '*'`. Gravando `o-301` de novo desse jeito, depois da execução
acima:

```
ana@laptop:~/azure$ echo 4590 > o-301.json && az storage blob upload -c sink-upsert -n o-301 -f o-301.json --if-none-match '*' 2>&1 | tail -2
ErrorCode:BlobAlreadyExists
If you want to overwrite the existing one, please add --overwrite in your command.
```

**Recusado, com `BlobAlreadyExists`**, e um leitor que captura esse erro e segue em frente tratou a
duplicata sem fazer nada. Os dois jeitos diferem quando a segunda cópia não é idêntica: sobrescrever
mantém a última versão gravada, recusar mantém a primeira. Para um pagamento, que nunca muda, qualquer
um serve; para um registro corrigido depois de enviado, a escolha é uma decisão sobre qual cópia é a
verdade.

## Sobrescrever, não incrementar

**Onde um destino precisa guardar um número acumulado, guarde aquilo de que ele é calculado.** O modo
`add` guardava um total e o incrementava, que é a única forma que nenhuma repetição aguenta. O modo
`upsert` guarda os pagamentos e calcula o total quando perguntado. Isso custa uma soma sobre os
pagamentos na hora da leitura, o que para a Quitanda são alguns milhares de linhas por cliente, e
compra um total certo não importa quantas vezes o stream seja repetido.

**E desenhe os eventos para facilitar o destino.** Um evento que leva o estado novo, "o pedido `o-303`
está pago, 990 centavos", é idempotente de aplicar; um evento que leva uma mudança, "some 990 a
`c-17`", não é. Quando o produtor é seu para desenhar, o primeiro tipo é de longe o conserto mais
barato.
