---
title: Arquitetura corporativa: o portfólio inteiro
version: 1
---

A arquitetura corporativa tem uma reputação, e a reputação são fichários. Um departamento que
produz frameworks, modelos de referência e comitês de aprovação, cujos documentos ninguém num time
de entrega leu. Essa versão existe, e a aula 17 a nomeia como a torre de marfim. **O trabalho por
baixo dela é mais simples e necessário: olhar tudo o que a empresa roda, contra o que a empresa
precisa ser capaz de fazer, num horizonte de anos.** Num banco com cinco mil engenheiros isso pede
um departamento. Na Carreto, pede uma página, uma planilha e alguns dias por trimestre.

## O que ela decide

A arquitetura de aplicação pergunta como um sistema é construído, e a de solução pergunta como
vários sistemas entregam um resultado. **A arquitetura corporativa pergunta quais sistemas a empresa
deveria ter**, e o que eles deveriam compartilhar. As decisões dela têm esta cara:

- quais capacidades de negócio a empresa tem, e qual sistema é o que provê cada uma;
- em quais sistemas investir, quais manter como estão e quais desligar;
- o que todos os times compartilham em vez de escolher sozinhos: o provedor de nuvem, a pilha de
  observabilidade, o message broker, o jeito como os serviços se autenticam entre si;
- quais capacidades construir, quais comprar e quais deixar com um parceiro;
- como o cenário de tecnologia deveria estar daqui a três anos, e o que precisa acontecer antes.

O horizonte entrega o nível. **Uma decisão neste nível é julgada de três a cinco anos à frente**,
pela capacidade da empresa de ainda mudar de direção barato quando a estratégia mudar. É uma
pergunta diferente de saber se uma funcionalidade sai neste trimestre, e ela pede outro leitor.

## O mapa de capacidades

O artefato central é um **mapa de capacidades**: uma lista do que o negócio faz, escrita em palavras
do negócio e não em nomes de sistemas, com cada capacidade associada aos sistemas que a proveem
hoje. "Cotar um frete" é uma capacidade; "o serviço Pricing" é um sistema que a provê. Manter os
dois separados é o ponto, porque uma capacidade fica estável por anos enquanto os sistemas debaixo
dela mudam.

A Renata montou o primeiro mapa da Carreto no segundo mês, numa planilha, em duas tardes perguntando
aos tech leads e uma conferindo as respostas contra o código. Um pedaço dele:

| capacidade | sistemas que a proveem hoje | dono |
|---|---|---|
| publicar uma carga | Shipper app, o módulo de cargas do monólito | Shipper |
| cotar um frete | serviço Pricing | Pricing |
| oferecer uma carga aos motoristas | serviço Matching | Matching |
| emitir o CT-e | o módulo fiscal do monólito; um script dentro do Payments | ninguém sozinho |
| notificar um motorista | o serviço de push do Driver app; SMS do monólito; o notificador próprio do Matching | três times |
| provar uma entrega | serviço Tracking | Tracking |
| pagar um motorista | Payments | Payments |

Duas linhas pararam a reunião em que ela mostrou o mapa. **O CT-e era emitido de dois lugares**: o
módulo fiscal do monólito para a maioria das cargas, e um script dentro do Payments para um tipo de
carga que o monólito nunca suportou, escrito às pressas dois anos antes. Quando as autoridades
fiscais mudarem o leiaute do CT-e, os dois vão ter de mudar, e só um time sabia que o segundo
existia. **Notificar um motorista tinha três implementações**, cada uma com as próprias regras sobre
quando um motorista pode receber mensagem à noite, e assim um motorista podia ser acordado às duas
da manhã por uma delas e protegido disso pelas outras duas.

Nada nessas linhas era segredo. Cada time conhecia a própria parte. **O mapa foi o primeiro lugar
em que alguém conseguiu vê-las lado a lado**, e isso é quase tudo o que este nível faz.

## O portfólio e os veredictos

O segundo artefato é o **portfólio de aplicações**: uma linha por sistema, com o dono, quanto custa
para rodar, como está de saúde, e um veredicto. Um conjunto comum de veredictos cabe em quatro
palavras: investir (fazer crescer), manter (cuidar, mudar só quando preciso), migrar (levar o que
ele faz para outro lugar) e aposentar (desligar). O portfólio da Carreto lista o monólito, os
serviços tirados dele, os scripts e os produtos de fora, e escrevê-lo foi a primeira vez que alguém
contou todos eles. A aula 12 conta os serviços e pergunta de quantos uma empresa de cinquenta
engenheiros precisa; aqui o ponto é só que a contagem não existia antes.

Os veredictos são onde a arquitetura corporativa encontra o dinheiro. Sílvio Matos, o diretor
financeiro, nunca tinha visto o gasto de engenharia organizado por sistema, e o portfólio deixou
ele fazer a pergunta que lhe importava: quais destes estamos pagando para manter vivos sem motivo?
`tech-strategy` aula 9 coloca preço nisso direito, como custo total de propriedade; esta aula só
precisa que a lista exista.

## Padrões compartilhados, e quem é dono deles

**O terceiro resultado é o pequeno conjunto de coisas que todos os times compartilham.** Na Carreto,
o time de Platform da Paula Reis roda a maioria delas: a conta de nuvem, os pipelines de CI, logs e
métricas, o message broker. A arquitetura corporativa decide que essas coisas são compartilhadas, e
o Platform faz do compartilhamento o caminho mais fácil; o padrão pega porque poupa trabalho a cada
time, e não porque um comitê aprovou. A aula 9 trata de escrever padrões assim e de garanti-los, e a
aula 10 dá nome aos formatos de time, entre eles o time de plataforma.

Um padrão neste nível justifica o lugar que ocupa ao evitar um custo que só aparece entre times.
Sete times escolhendo sete formatos de log é ótimo para cada time e caro na primeira noite em que um
incidente atravessa três serviços e ninguém consegue seguir uma requisição por eles. Um formato,
escolhido uma vez, sai barato para todo mundo.

## Os frameworks, pelo nome

Organizações grandes costumam conduzir a arquitetura corporativa com um framework. O mais conhecido
é o **TOGAF**, The Open Group Architecture Framework, que descreve um ciclo para desenvolver uma
arquitetura corporativa (o Architecture Development Method dele) e as camadas que ela cobre:
negócio, dados, aplicação e tecnologia. O framework de Zachman é mais antigo e é uma classificação
dos documentos que uma empresa pode manter, e não um método. `architecture-modeling` ensina os dois,
nas aulas 8 e 10; este curso não.

O que importa aqui é a relação entre os frameworks e o trabalho. **Um framework é uma lista de
verificação para uma organização grande que precisa que todo mundo descreva as coisas do mesmo
jeito**, e no tamanho da Carreto segui-lo por inteiro produziria documentos mais rápido do que
alguém conseguiria ler. A Renata pega emprestado o vocabulário (capacidade, portfólio, camadas de
negócio e de tecnologia) e nada da cerimônia.

## Três níveis, uma pessoa

Numa empresa de cinquenta engenheiros, os três níveis raramente são três pessoas. **A Renata
trabalha nos três, em proporções diferentes, e a habilidade está em saber a qual deles uma pergunta
pertence.** O primeiro trimestre dela ficou mais ou menos assim: cerca de um dia por semana em
perguntas de aplicação, quase todas revisões que os times pediram; cerca de três dias em trabalho de
solução, acima de tudo o pagamento em 24 horas; e o resto no mapa, no portfólio e nos padrões
compartilhados.

As proporções não são regra e vão mudar. Conforme a Carreto crescer, o trabalho de solução vai
precisar de mais gente, e um dia a empresa pode contratar um arquiteto para cada grupo de times e
deixar uma pessoa no portfólio. O que continua fixo é a diferença entre as perguntas:

| | aplicação | solução | corporativa |
|---|---|---|---|
| pergunta | como este sistema é construído? | como estes sistemas entregam este resultado? | quais sistemas deveríamos ter? |
| horizonte | de meses a dois anos | um programa, e depois a vida dele | de três a cinco anos |
| quem lê | o time e quem o chama | vários times, produto, financeiro, parceiros | diretoria, financeiro, todos os tech leads |
| o que escreve | visão de componentes, contratos, ADRs no repositório | visões de contexto e contêineres, orçamentos, ADRs entre times | mapa de capacidades, portfólio, padrões compartilhados |

**Uma pergunta respondida no nível errado é mal respondida.** Tratar a emissão duplicada do CT-e
como um bug do Payments teria consertado um script e deixado o próximo aparecer; tratar o cache do
Matching da primeira seção como uma política de cache da empresa inteira teria gastado um mês num
padrão para resolver um problema que um campo de contrato resolveu. A tabela é menos uma taxonomia
do que um conjunto de perguntas a fazer antes de começar o trabalho.
