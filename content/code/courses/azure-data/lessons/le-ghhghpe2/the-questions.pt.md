---
title: Seis perguntas, feitas em ordem
version: 1
---

**O jeito errado de escolher um armazenamento é começar pelo armazenamento.** "Usamos SQL Server",
"o Cosmos DB escala", "põe no lake" são respostas que chegaram antes da pergunta, e cada uma acerta
para alguma carga e sai cara para o resto. Cada armazenamento deste curso é bom num formato de leitura
e escrita e fraco em outros, então a escolha começa pelo formato da carga e deixa os armazenamentos
saírem dele.

**Seis perguntas, nesta ordem, porque cada uma estreita aquilo entre o que a seguinte precisa
decidir.**

**1. Qual é o padrão de acesso?** Como os dados são gravados, e como são lidos: um item pela chave, um
punhado de itens sob uma chave, linhas juntadas entre tabelas dentro de uma transação, arquivos
inteiros lidos do começo ao fim, uma varredura de milhões de linhas para calcular um total, eventos
que chegam para sempre. Essa pergunta decide a maioria das escolhas sozinha, e é a mais pulada. A
lição 11 desenhou um contêiner do Cosmos DB escrevendo as consultas antes de escolher a chave de
partição; essa disciplina é a primeira pergunta feita a todo armazenamento.

**2. Quão rápido uma resposta precisa vir?** Um checkout espera milissegundos; um relatório noturno
espera minutos e ninguém se importa. Abaixo de um milissegundo, a resposta é um cache, a lição 15. Em
poucos milissegundos em qualquer escala, um armazenamento de documentos lido pela chave, ou um banco
relacional com o índice certo. Segundos servem para uma consulta SQL serverless sobre o lake e estão
longe de servir para um cliente apertando um botão.

**3. De que consistência o leitor precisa?** Uma leitura precisa ver a gravação que acabou de
acontecer, ou pode estar um instante atrás? Um cliente que acabou de pagar espera ver o pedido; um
painel das vendas de ontem não se importa com o último segundo. Várias linhas mudadas juntas, todas ou
nenhuma, é o território do banco relacional, e o Cosmos DB oferece isso dentro de uma partição lógica.
Os cinco níveis da lição 12 são o vocabulário desta pergunta, e uma réplica de leitura, um cache e um
lake estão todos, por projeto, atrás da sua origem.

**4. Qual o tamanho, e quão rápido cresce?** Gigabytes ou terabytes, cem requisições por segundo ou
cem mil, e acima de tudo se a carga é estável ou em picos. Um banco relacional único cresce passando
para mais vCores até a camada não ter mais, com o Hyperscale da lição 8 como caminho além disso; o
Cosmos DB e o Blob Storage crescem se espalhando, sem máquina para ficar pequena, desde que a chave de
partição da lição 11 espalhe; um warehouse cresce por capacidade comprada em unidades.

**5. Quem o opera?** Todo armazenamento tem trabalho que não some: tamanhos a escolher, índices a
manter, chaves a trocar, uma chave de partição que ficou quente, capacidade a ajustar depois de um
pico. Os serviços gerenciados tiram muito disso e nenhum tira tudo. Uma equipe de três deveria contar
os armazenamentos que já opera antes de acrescentar um, porque cada novo é um novo conjunto de falhas
para aprender às três da manhã.

**6. Quanto custa, com esta carga?** Por último, porque um preço só quer dizer algo depois que a carga
é conhecida: um armazenamento barato por requisição pode ser caro por mês, e um que custa dinheiro a
cada hora pode ser barato por requisição quando está ocupado. A tabela de preços da lição 1 responde a
esta pergunta só depois que as cinco primeiras disseram o que multiplicar.

## Por que a ordem importa

**Feita primeiro, a pergunta do preço escolhe mal.** Um pool SQL serverless cobrado por terabyte
processado parece mais barato que um banco cobrado a cada hora, e é, para uma pergunta feita uma vez
por dia sobre o lake. Para a tela "meus pedidos" de um cliente, aberta três milhões de vezes por mês,
ele é lento e, como a seção depois da próxima calcula, também não é barato. O padrão de acesso já o
tinha descartado antes de o preço ser lido; ler o preço primeiro o teria escolhido.

**E as perguntas são feitas por carga, não por empresa.** A Quitanda não é "uma empresa de SQL Server"
nem "uma empresa de Cosmos DB". O checkout, os carrinhos, o stream de cliques, o arquivo e os
relatórios dos analistas são cargas com respostas diferentes para a primeira pergunta, e as duas
próximas seções dão a cada uma o seu armazenamento.
