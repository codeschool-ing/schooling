---
title: O processador do change feed e o gatilho do Functions
version: 1
---

**O que falta ao `processor.py` é o que o processador do change feed da Microsoft oferece**: muitas
cópias do leitor dividindo um feed sem ler a mesma faixa duas vezes, e assumindo uma faixa quando a
cópia que a tinha morre. Esta seção é ensinada a partir da documentação da Microsoft e não foi executada.
O processador faz parte das bibliotecas de .NET e Java, e a versão 4.17.1 da biblioteca Python não tem
nenhum. Uma busca por ele no pacote instalado não encontra nada, e o que o Python oferece é o modelo de
puxar que esta lição usou, `query_items_change_feed`, com faixas do feed para dividir o trabalho à mão.

## Quatro partes

| parte | o que é |
|---|---|
| o contêiner monitorado | o contêiner cujo feed é lido, o `orders` da Quitanda |
| o contêiner de leases | um segundo contêiner do Cosmos DB com um documento por faixa do feed: quem é o dono, e o token de continuação |
| as instâncias de computação | as cópias do programa, numa máquina ou em muitas, cada uma com um nome |
| o delegate | a sua função, chamada com cada lote de mudanças |

**Um lease é o blob de checkpoint do `processor.py` com um dono escrito nele.** Cada instância pega
leases até as faixas ficarem divididas por igual, lê as faixas que tem, chama o delegate com cada lote,
e grava o token de continuação novo no lease só depois que o delegate retornou. Uma instância que para de
renovar os leases os perde, e outra os pega a partir do último token. Inicie uma segunda instância e os
leases são rebalanceados entre as duas; pare-a e eles voltam.

**A ordem do último passo é a mesma do processador desta lição, e a consequência também**: um delegate
que falha, ou uma instância que morre, depois do trabalho e antes de o lease ser atualizado quer dizer
que o lote é entregue de novo. O processador do change feed é pelo menos uma vez, e o delegate tem de ser
seguro para rodar duas vezes na mesma mudança. O processador vem também com um estimador, que informa o
quanto os leases estão atrasados, e esse atraso é o número em que pôr um alerta: um consumidor que parou
parece exatamente um contêiner sem nada de novo para dizer.

## O gatilho do Azure Functions

**O gatilho do Cosmos DB no Azure Functions é o processador do change feed com a hospedagem feita para
você.** Ele precisa do mesmo contêiner de leases, pega os mesmos leases, e chama a sua função com cada
lote. O Functions acrescenta instâncias conforme os leases pedem, até uma por lease, porque um lease é
lido por uma instância de cada vez. O que ele não muda é a entrega: uma função que falha depois de fazer
parte do trabalho pode ver o lote de novo, então a regra desta lição vale sem mudança. Defina valores com
chave em alguma coisa da mudança, nunca some a um total corrente.

## O que custa

Ler o feed é ler o contêiner: toda página custa unidades de requisição da vazão do contêiner
monitorado, então um consumidor ocupado disputa com a aplicação o mesmo orçamento da lição 13. O
contêiner de leases é um contêiner como outro qualquer, com vazão e conta próprias e pequenas. E todo
consumidor é um leitor separado com os próprios leases, então cinco consumidores de um feed o leem cinco
vezes. Muitas vezes esse é o projeto certo, uma visão, um índice de busca e uma cópia para o lago, cada
um no seu ritmo, e ainda são cinco leituras a planejar.
