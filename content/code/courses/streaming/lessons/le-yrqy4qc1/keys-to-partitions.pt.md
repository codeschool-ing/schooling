---
title: Em que partição cai uma chave
version: 1
---

**Um produtor manda uma mensagem com chave para a partição indicada pelo hash da chave, e toda
mensagem com aquela chave vai para a mesma.** É a regra que a lição 2 pediu: uma chave, um log, para
que os eventos de uma loja fiquem na ordem em que a loja os escreveu. Mensagens sem chave são
espalhadas pelas partições, e não mantêm ordem nenhuma entre si.

A crença comum é que o broker faz isso. Não faz. **O produtor escolhe a partição, na biblioteca
cliente, antes de a mensagem sair do programa**, e o broker guarda o que recebe. Isso põe a função de
hash no cliente, e clientes diferentes trazem funções diferentes.

Um produtor pequeno deixa isso visível. Ele manda os pares `KEY=VALUE` que receber e imprime a
partição e o offset em que cada um foi guardado, que o broker informa assim que tem a mensagem. Salve
isto como `~/work/keys.py`:

```schooling-example
@same
--- O que ele faz. Manda os pares que você der, então o mesmo programa serve a esta seção e à de compactação.
--- O produtor, e a única configuração de que esta seção trata. **Se ela fica de fora, o cliente usa o próprio particionador padrão.**
--- O relatório de entrega. O cliente o chama uma vez por mensagem, depois que o broker respondeu, com a partição e o offset que a mensagem recebeu.
--- Uma mensagem por par. O `flush` espera todos os relatórios antes de o programa terminar.
```

Crie um tópico de três partições e mande uma mensagem por loja:

@@fence@@

Quatro das cinco lojas caíram na partição 1, Caruaru na partição 0, e **nada na partição 2**. Isso
não é defeito: cinco chaves distribuídas por hash em três baldes é uma amostra pequena, e uma divisão
desigual é o que uma amostra pequena dá. Mas quer dizer que um tópico de três partições é, para essas
chaves, um tópico de duas. Os offsets contam dentro de cada partição, e é por isso que a mensagem de
Caruaru está no offset 0 enquanto a de Natal está no 2.

**A mesma chave vai para a mesma partição enquanto o número de partições não mudar**, e essa é a
promessa inteira. Quem fez o hash foi o cliente: o cliente Python é construído sobre o librdkafka,
uma biblioteca em C, e o particionador padrão dele, `consistent_random`, calcula um CRC32 da chave.

## As ferramentas do próprio Kafka fazem outro hash

Agora mande as mesmas cinco chaves com o console producer do Kafka, que é escrito em Java, e leia o
tópico de volta com a partição e a chave de cada mensagem impressas. `parse.key=true` diz ao produtor
que cada linha é uma chave, um `:` e um valor:

@@fence@@

Leia a saída do consumidor pela chave. Recife, que o cliente Python pôs na partição 1, foi para a
partição **2** pelo Java; Olinda e João Pessoa foram para a partição 0 em vez da 1. Só Caruaru e Natal
coincidem, e a coincidência é sorte. **O cliente Java faz o hash das chaves com murmur2**, que é uma
função diferente do CRC32, então a mesma chave dá outro número.

Isso importa assim que dois programas em duas linguagens escrevem no mesmo tópico. Um caixa escrito
em Python e um serviço de retaguarda escrito em Java, os dois escrevendo as mudanças de estoque do
Recife, as poriam em duas partições, e a lição 2 mostrou o que ler os eventos de uma chave fora de
ordem faz. O librdkafka já traz a correção: `murmur2_random`, uma cópia do particionador do Java, que
é o que a opção `--partitioner` do `keys.py` configura:

@@fence@@

Recife na 2, Olinda e João Pessoa na 0, Caruaru e Natal na 1: exatamente onde o Java as pôs.
**Quando clientes de mais de uma linguagem escrevem no mesmo tópico, configure `partitioner` como
`murmur2_random` em todo cliente baseado no librdkafka**, entre eles o de Python, o de Go e o de .NET.
A parte `_random` é sobre mensagens sem chave, que ele espalha ao acaso. O resto deste curso mantém o
padrão onde só Python escreve, e o produtor da lição 4 usa `murmur2_random`, para que as vendas dele
cheguem às três partições.
