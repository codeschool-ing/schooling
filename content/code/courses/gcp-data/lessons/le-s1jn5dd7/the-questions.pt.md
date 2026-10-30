---
title: Seis perguntas, feitas em ordem
version: 1
---

**O jeito errado de escolher um armazenamento é começar pelo armazenamento.** "Usamos PostgreSQL",
"o BigQuery escala", "põe no Firestore" são respostas que chegaram antes da pergunta, e cada uma
está certa para alguma carga de trabalho e sai cara para o resto. Todo armazenamento deste curso é
bom numa forma de ler e escrever e ruim em outras, então a escolha começa pela forma da carga e
deixa os armazenamentos saírem dela.

**Seis perguntas, nesta ordem, porque cada uma estreita o que a seguinte tem para decidir.**

**1. Qual é o padrão de acesso?** Como o dado é escrito, e como é lido: um documento pelo id, um
intervalo de linhas sob uma chave, linhas juntadas entre tabelas dentro de uma transação, arquivos
inteiros lidos do começo ao fim, uma varredura de milhões de linhas para calcular um total. É a
pergunta que decide a maioria das escolhas sozinha, e a mais pulada. O Bigtable da aula 11 foi
desenhado escrevendo as leituras antes da chave de linha, e o Firestore da aula 10 não responde a
nenhuma consulta sem um índice para ela; essa disciplina é a primeira pergunta feita a todo
armazenamento.

**2. Quão rápido uma resposta precisa vir?** O checkout de uma loja espera milissegundos; um
relatório noturno espera minutos e ninguém liga. Abaixo de um milissegundo, a resposta é um cache.
Em poucos milissegundos em qualquer escala, um armazenamento de documentos ou de coluna larga, ou um
banco relacional com o índice certo. Segundos servem para o BigQuery, e estão longe de servir para
um cliente apertando um botão.

**3. Que consistência o leitor precisa?** Uma leitura precisa ver a escrita que acabou de acontecer,
ou pode estar um instante atrás? Um cliente que acabou de pagar espera ver o pedido; um painel das
vendas de ontem não liga para o último segundo. Transações que mudam várias linhas de uma vez e
precisam dar todas certo ou todas errado são território relacional, que o Spanner estende entre
regiões, a um preço. Uma réplica de leitura, um cache e um warehouse carregado durante a noite estão
todos, por desenho, atrás da origem.

**4. Quão grande, e com que rapidez cresce?** Gigabytes ou terabytes, cem requisições por segundo ou
cem mil, e acima de tudo se a carga é constante ou cheia de picos. O Cloud SQL cresce indo para uma
máquina maior até não haver maior; o Spanner, o Bigtable e o Firestore crescem se espalhando, por
nós, por unidades de processamento ou por nada que você veja; o BigQuery cresce por slots, que são
máquinas de outra pessoa pelo tempo de uma consulta.

**5. Quem opera?** Todo armazenamento tem trabalho que não some: tamanhos para escolher, versões para
atualizar, índices para manter, vacuum para vigiar, capacidade para ajustar. Os serviços gerenciados
tiram muito disso e nenhum tira tudo. Um time de três pessoas deveria contar os armazenamentos que
já roda antes de acrescentar mais um.

**6. Quanto custa, nesta carga de trabalho?** Por último, porque um preço só significa algo depois
que a carga é conhecida: um armazenamento barato por operação pode sair caro por mês, e um que custa
dinheiro parado pode sair barato por operação quando está ocupado. As páginas de preço só respondem
a esta pergunta depois que as cinco primeiras disseram o que multiplicar.

## Por que a ordem importa

**Feita primeiro, a pergunta do preço escolhe mal.** O preço sob demanda do BigQuery por tebibyte
parece mais barato do que um banco que custa dinheiro toda hora, e é, para uma pergunta feita uma vez
por dia sobre o warehouse. Para a tela "meus pedidos" de um cliente, aberta cem mil vezes por dia, é
um desastre em latência e em custo, e a seção depois da próxima faz essa conta. O padrão de acesso já
tinha descartado o BigQuery antes de o preço ser lido; ler o preço primeiro o teria escolhido.

**E as perguntas são feitas por carga de trabalho, não por empresa.** A Quitanda não é "uma empresa
de Firestore" nem "uma empresa de PostgreSQL". O checkout, os carrinhos, o fluxo de cliques, o
arquivo e os relatórios dos analistas são cinco cargas com cinco respostas diferentes à primeira
pergunta, e as duas próximas seções dão a cada uma o seu armazenamento.
