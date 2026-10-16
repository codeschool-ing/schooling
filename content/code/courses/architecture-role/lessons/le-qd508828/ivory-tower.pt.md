---
title: A torre de marfim, e o porteiro na entrada
version: 1
---

**O arquiteto da torre de marfim decide longe das pessoas que vivem com as decisões.** As decisões
podem até ser boas. Chegam prontas, sem que os times tenham sido consultados e sem que o arquiteto
tenha visto o que os times veem, então são ignoradas em silêncio ou seguidas direto contra uma
parede. O arquiteto de PowerPoint está separado do código; a torre de marfim está separada das
pessoas. Os dois costumam andar juntos, mas uma torre pode ficar em cima de diagramas perfeitamente
corretos.

## Como se parece

Imagine Renata publicando um padrão por memorando: *a partir de 1º de março, toda chamada entre
serviços passa pelo broker de mensagens*. Ela tem bons motivos. Chamadas síncronas entre serviços
tinham causado duas falhas em cascata naquele ano, e a aula 1 mostrou o quanto o conector muda a
forma como um sistema falha. Ela escreve o memorando sozinha, anuncia na reunião geral e publica na
wiki.

Diego Araújo, tech lead do app do Driver, fica sabendo pelo memorando. O login do app pergunta ao
backend se os documentos do motorista estão válidos, e precisa da resposta em menos de dois segundos
numa conexão 3G em algum ponto de uma rodovia de Mato Grosso. Um broker no meio dessa chamada
acrescenta um salto, uma segunda forma de falhar e nenhum benefício. Diego pede uma exceção. O
Payments também, para o callback do banco, e o Pricing, para as cotações. **Em dois meses, seis dos
sete times têm exceções.** Um padrão do qual seis times em sete estão dispensados não é um padrão; a
aula 9 o chamaria de diretriz que ninguém segue, com papelada.

Os sintomas:

- **Os padrões chegam sem um motivo ou um dono com quem os times possam discutir** (aula 9).
- **Os requisitos são supostos em vez de levantados.** A torre conhece o sistema como ele lhe foi
  descrito, não como ele é usado; ninguém perguntou a Diego sobre o 3G na rodovia (aula 7).
- **O fórum de arquitetura é uma transmissão.** O arquiteto apresenta, as perguntas são recebidas, e
  nada do que foi dito na sala muda a decisão (aula 10).
- **Os times param de mencionar os seus contornos.** A arquitetura oficial e a real se afastam, e a
  segunda é invisível lá da torre.

## Por que acontece

**Usa-se autoridade formal onde era preciso autoridade conquistada.** A aula 3 separou as duas: um
cargo consegue fazer as pessoas obedecerem por um tempo, e só um histórico as faz concordar. O
memorando se apoia inteiro na primeira.

**Decidir sozinho é mais rápido, uma vez.** Consultar sete times leva quinze dias; escrever um
memorando leva uma tarde. Os quinze dias economizados são gastos depois várias vezes em exceções,
contornos e na conversa que deveria ter acontecido antes.

**O arquiteto senta com os executivos e não com os times.** Nada na semana da torre a põe perto de
uma escala de plantão, de um chamado de suporte ou do celular de um motorista.

**O arquiteto acredita que o valor do papel é a resposta.** A aula 11 argumentou que é a qualidade
do processo de decisão: perguntar antes de responder, e ajudar um time a decidir em vez de decidir
por ele.

## Quanto custa

As decisões são ignoradas, então a empresa acaba com **duas arquiteturas, a declarada e a real**, e
planeja em cima da primeira. Decisões ruins não são pegas, porque a pessoa que conhecia a restrição
(Diego, com o login em 3G) nunca foi consultada. E os times aprendem que o fórum é teatro, o que
torna a próxima decisão boa mais difícil de ser adotada do que a última ruim.

## A alternativa

- **Passe a decisão pelo processo de aconselhamento** (aula 3). O memorando vira uma proposta enviada
  ao fórum e aos tech leads, com uma data até a qual os conselhos são esperados. A restrição de Diego
  chega antes da decisão, e o padrão sai como "assíncrono por padrão entre serviços de back-end, com
  estes casos nomeados para chamadas síncronas", com o qual os times conseguem viver.
- **Vá aonde as decisões caem.** Uma semana por trimestre dentro de um time, pareando no código dele
  (aula 15), lendo os relatórios de incidente, participando do planejamento. A torre não enxerga uma
  rodovia de Mato Grosso; uma sessão de pareamento com o time do Driver enxerga.
- **Escreva o motivo e acolha a exceção.** O processo de exceções da aula 9, com data de validade,
  transforma uma discordância em informação em vez de num contorno silencioso.

## O porteiro: a torre que desceu até a porta

O porteiro é a distância oposta com o mesmo resultado. **O arquiteto porteiro está muito perto dos
times e insiste em aprovar tudo o que eles fazem**: cada documento de desenho, cada biblioteca nova,
cada pull request que mexe em dois serviços. Nada acontece sem a assinatura dela.

O sintoma é uma fila. Suponha que 25 desenhos cheguem à mesa de Renata num mês e cada um espere
quatro dias úteis por ela; são **100 dias úteis de espera por mês**, espalhados por sete times, e
nada disso aparece em painel nenhum. Os times passam a desenhar para passar na revisão em vez de para
resolver o problema, e dividem o trabalho de formas estranhas para ficar abaixo de qualquer que seja
o limite da revisão. A causa costuma ser compreensível — um incidente que uma revisão teria pegado,
ou o medo de perder o controle do todo conforme a empresa cresce — e a reação é um portão na frente
de tudo, em vez de na frente do que importa.

A alternativa usa o que a aula 16 construiu. **A tabela de direitos de decisão diz quais decisões
são do arquiteto**, e são duas linhas em sete. Padrões que uma máquina consegue conferir são
conferidos por uma (aula 9). A revisão de desenho fica para o que atravessa as fronteiras entre
times (aula 11), e o resto fica com os times, que conhecem o próprio código melhor do que qualquer
revisor conheceria.

A torre de marfim e o porteiro parecem opostos, um longe demais e outro perto demais. O que eles
têm em comum é a crença de que o julgamento do arquiteto precisa ser aplicado pessoalmente a cada
decisão, em vez de ser embutido na forma como os times decidem.
