---
title: Seis perguntas, feitas em ordem
version: 1
---

**O jeito errado de escolher um store é começar pelo store.** "A gente usa PostgreSQL", "o DynamoDB
escala", "joga no lake" são respostas que chegaram antes da pergunta, e cada uma delas está certa para
algum workload e sai cara para o resto. Cada store deste curso é bom num formato de leitura e escrita e
ruim em outros, então a escolha começa pelo formato do workload e deixa os stores saírem dele.

**Seis perguntas, nesta ordem, porque cada uma estreita aquilo entre o que a próxima precisa
decidir.**

**1. Qual é o padrão de acesso?** Como os dados são escritos, e como são lidos: um item pela chave,
uma faixa de itens sob uma chave, linhas juntadas entre tabelas dentro de uma transação, arquivos
inteiros lidos do começo ao fim, uma varredura de milhões de linhas para calcular um total. É a
pergunta que decide a maioria das escolhas sozinha, e a que mais se pula. O DynamoDB da lição 9 foi
desenhado escrevendo as consultas antes da tabela; essa disciplina é a primeira pergunta feita a todo
store.

**2. Com que rapidez uma resposta precisa chegar?** O checkout de uma loja espera milissegundos; um
relatório noturno espera minutos e ninguém se importa. Abaixo de um milissegundo, a resposta é um
cache. Em poucos milissegundos em qualquer escala, um store chave-valor ou um banco relacional com o
índice certo. Segundos servem para um warehouse ou para o Athena, e estão longe de servir para um
cliente apertando um botão.

**3. De que consistência o leitor precisa?** Uma leitura precisa ver a escrita que acabou de
acontecer, ou pode estar um instante atrás? Um cliente que acabou de pagar espera ver o pedido; um
painel das vendas de ontem não liga para o último segundo. Transações que mudam várias linhas de uma
vez e precisam dar todas certo ou todas errado são território relacional, e o DynamoDB as oferece de
forma mais estreita. Uma réplica de leitura, um cache e um lake ficam todos, por desenho, atrás da
origem.

**4. Qual o tamanho, e com que rapidez cresce?** Gigabytes ou terabytes, cem requisições por segundo
ou cem mil, e sobretudo se a carga é constante ou tem picos. Um banco relacional cresce indo para uma
máquina maior até não haver maior; o DynamoDB e o S3 crescem se espalhando, sem máquina para ficar
pequena; um warehouse cresce acrescentando nós ou unidades de capacidade.

**5. Quem opera?** Todo store tem trabalho que não some: tamanhos a escolher, versões a atualizar,
índices a manter, vacuum a vigiar, capacidade a ajustar. Os serviços gerenciados tiram boa parte
disso e nenhum tira tudo. Uma equipe de três deveria contar os stores que já opera antes de
acrescentar um.

**6. Quanto custa, neste workload?** Por último, porque um preço só quer dizer algo depois de o
workload ser conhecido: um store barato por requisição pode ser caro por mês, e um que custa dinheiro
parado pode ser barato por requisição quando está ocupado. A tabela de preços responde a esta pergunta
só depois de as cinco primeiras dizerem o que multiplicar.

## Por que a ordem importa

**Feita primeiro, a pergunta do preço escolhe mal.** Os 9.00 por terabyte do Athena parecem mais
baratos que um banco que custa dinheiro toda hora, e são, para uma pergunta feita uma vez por dia
sobre o lake. Para a tela "meus pedidos" de um cliente, aberta cem mil vezes por dia, é um desastre de
latência e de custo, e a seção depois da próxima faz essa conta. O padrão de acesso já tinha excluído
o Athena antes de o preço ser lido; ler o preço primeiro o teria incluído.

**E as perguntas são feitas por workload, não por empresa.** A Quitanda não é "uma empresa DynamoDB"
nem "uma empresa PostgreSQL". O checkout, os carrinhos, o fluxo de cliques, o arquivo e os relatórios
dos analistas são cinco workloads com cinco respostas diferentes à primeira pergunta, e as duas
próximas seções dão a cada um o seu store.
