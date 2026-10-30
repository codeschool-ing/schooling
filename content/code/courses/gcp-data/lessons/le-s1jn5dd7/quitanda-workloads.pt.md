---
title: As cargas de trabalho da Quitanda, cada uma com o seu armazenamento
version: 1
---

**A Quitanda roda sobre vários armazenamentos, e cada um está lá porque uma carga de trabalho o
pediu.** Esta seção passa pelas cargas que o curso encontrou, faz a cada uma as seis perguntas e dá
a resposta com o motivo. Onde dois armazenamentos ficaram perto, diz qual pergunta decidiu.

## Checkout e pedidos: Cloud SQL para PostgreSQL, com alta disponibilidade

**Um pedido é uma transação entre várias tabelas**: o pedido, os itens, o estoque de cada produto, o
registro do pagamento. Ou tudo dá certo ou nada dá, e o cliente que acabou de pagar espera ver o
pedido na tela seguinte, então a primeira e a terceira perguntas apontam para um banco relacional. A
carga é de algumas centenas de pedidos por hora no pico da noite, que um escritor dá conta com
folga, e a aula 7 pôs um standby numa segunda zona de São Paulo atrás dele. O AlloyDB, da aula 8,
justifica o preço quando o mesmo banco também precisa responder a consultas analíticas pesadas, e a
Quitanda manda essas para o BigQuery. **Decidido por: padrão de acesso e consistência.**

## Spanner, considerado e não escolhido

**O Spanner é o armazenamento para uma carga relacional que um escritor não aguenta**, ou que precisa
aceitar escritas em várias regiões ao mesmo tempo com a mesma resposta em todas. A Quitanda entrega
numa cidade. As escritas dela cabem numa máquina com anos de crescimento pela frente, e a aula 9
precificou o que o Spanner cobra pela capacidade de processamento, usada ou não. Escolhê-lo agora
seria pagar por uma escala que ninguém tem. **Decidido por: escala, que não o pediu.**

## Carrinhos e sessões: Firestore, com uma política de TTL

**Um carrinho é lido e escrito por uma chave, o cliente, muitas vezes em poucos minutos, e depois
abandonado.** Nada o junta a coisa alguma até ele virar pedido, e nesse momento é copiado para o
Cloud SQL. Esse é o ramo do Firestore: um documento pelo id, milissegundos, uma carga que dá picos
nas noites de sexta sem nada para dimensionar, e uma política de TTL que apaga os carrinhos
abandonados sozinha depois de um dia, cobrada como exclusões por TTL, que são baratas. Pôr os
carrinhos no Cloud SQL funcionaria, e encheria o banco com que o negócio funciona de linhas que
ninguém guarda. **Decidido por: padrão de acesso e os picos.**

## A página do catálogo: Memorystore na frente do Cloud SQL

**Os mesmos poucos milhares de produtos são lidos milhões de vezes por dia e mudados algumas.** A
fonte da verdade continua sendo o Cloud SQL, onde os produtos moram com preços e estoque; um cache
do Memorystore na frente dele responde a página em menos de um milissegundo e tira as leituras do
banco. Quando um preço muda, a aplicação apaga a entrada do cache, e a leitura seguinte a preenche
de novo a partir do Cloud SQL, que é o cache-aside da aula 12. **Decidido por: latência, com a fonte
da verdade intacta.**

## O fluxo de cliques do aplicativo: Pub/Sub, depois BigQuery, com Bigtable para o passado recente

**Eventos que não param**, algumas centenas por segundo no pico, vão para um tópico do Pub/Sub, como
a aula 19 montou, para que cada consumidor os leia no próprio ritmo. O Dataflow, nas aulas 21 e 22,
os agrupa em janelas por tempo do evento e escreve os agregados no BigQuery e os eventos brutos no
Cloud Storage. O único consumidor que precisa de "os últimos cinquenta cliques deste cliente, agora"
os lê do Bigtable, chaveados pelo cliente e por um timestamp invertido, o desenho da aula 11.
**Decidido por: padrão de acesso, que são três padrões diferentes sobre os mesmos eventos.**

## As exportações noturnas e o arquivo legal: Cloud Storage, por classe

**Arquivos que precisam ser guardados por anos, lidos em lote por jobs, nunca atualizados linha a
linha**, são do Cloud Storage, e as aulas 1 a 5 montaram para eles o layout do bucket, as classes e
o ciclo de vida. Os registros fiscais que precisam ser guardados por anos e quase nunca são lidos
vão para a classe Archive, sob uma política de retenção travada, como as aulas 2 e 3 montaram: o
armazenamento mais barato da tabela de preços, com um mínimo de um ano e uma taxa de recuperação por
GiB lido, o que é aceitável para um documento que um auditor pede uma vez. **Decidido por: preço,
depois que o padrão de acesso permitiu.**

## As perguntas dos analistas: BigQuery, sob demanda até um painel perguntar o dia inteiro

**As perguntas são varreduras e agregações sobre meses de pedidos e cliques**, que é o ramo
analítico, e a escolha dentro dele é entre pagar por byte e pagar por slot. Sob demanda, uma
pergunta que varre 20 GiB custa 20 ÷ 1.024 × US$ 11,25, cerca de 22 centavos, depois do TiB gratuito
do mês, e nada entre uma pergunta e outra. Um painel atualizado por quarenta analistas o dia inteiro
é outra carga, e a aula 14 encontrou o volume a partir do qual uma reserva de slots custa menos que
os bytes. As aulas 15 e 16 são como os bytes ficam pequenos de qualquer jeito. **Perguntas ocasionais
são do modelo sob demanda; um painel que faz as mesmas perguntas o dia inteiro é dos slots.**
**Decidido por: preço, no volume que o padrão de acesso produz.**

## Uma regra sobre todos eles

**Uma fonte da verdade por fato, e toda outra cópia derivada dela.** O pedido mora no Cloud SQL; a
cópia do BigQuery veio do Datastream na aula 25, a do cache veio de uma leitura, e o carrinho do
Firestore virou pedido sendo copiado. Quando dois armazenamentos discordam, a fonte da verdade está
certa por definição, e um desenho que não sabe dizer qual é ela para um dado fato não terminou de
ser desenhado.
