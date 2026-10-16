---
title: Quatro definições e o que elas têm em comum
version: 1
---

Pergunte a uma sala de engenheiros o que é arquitetura de software e três respostas aparecem
depressa: o diagrama na wiki, o design de alto nível e o que quer que o arquiteto tenha decidido.
**A primeira é um retrato da coisa, a segunda só empurra a pergunta para a expressão "alto nível", e
a terceira anda em círculo.** Quem estuda o assunto há mais de trinta anos também não concorda numa
frase só, mas as definições se sobrepõem, e a sobreposição é útil.

## Quatro definições

**A norma.** A ISO/IEC/IEEE 42010, a norma internacional para descrever arquiteturas, define a
arquitetura na edição de 2011 como os "fundamental concepts or properties of a system in its
environment embodied in its elements, relationships, and in the principles of its design and
evolution" — os conceitos ou propriedades fundamentais de um sistema no seu ambiente, encarnados nos
seus elementos, nas suas relações e nos princípios do seu projeto e da sua evolução. É uma frase de
comitê, e cada trecho dela foi discutido. Três importam aqui: *elementos*, *relações* e *no seu
ambiente*. A norma não diz que a arquitetura é um documento. Um documento a descreve.

**O livro-texto.** Len Bass, Paul Clements e Rick Kazman, em *Software Architecture in Practice*,
definem a arquitetura de software de um sistema como "o conjunto de estruturas necessárias para
raciocinar sobre o sistema", formadas por elementos de software, pelas relações entre eles e pelas
propriedades de ambos. Duas palavras fazem o trabalho. *Estruturas* está no plural: um sistema tem
uma estrutura de módulos (como o código é dividido), uma estrutura de execução (o que roda e como
conversa) e uma estrutura de alocação (onde roda e que time é dono), e nenhuma delas sozinha é a
arquitetura. *Raciocinar* diz para que servem as estruturas — prever como o sistema vai se comportar
quando for carregado, atacado, alterado ou quebrado.

**O custo da mudança.** Grady Booch resumiu numa linha que é citada mais do que qualquer outra:
"Toda arquitetura é design, mas nem todo design é arquitetura. A arquitetura representa as decisões
de design significativas que dão forma a um sistema, em que significativo se mede pelo custo da
mudança." É a definição que você usa numa terça-feira à tarde, porque ela dá um teste.

**O que importa.** Martin Fowler, na coluna "Who Needs an Architect?", de 2003, relata uma
observação de Ralph Johnson: arquitetura trata "the important stuff. Whatever that is." — das coisas
importantes, sejam elas quais forem. Parece piada e é um argumento sério. Johnson também descreveu a
arquitetura como o entendimento compartilhado que os desenvolvedores experientes têm do design do
sistema, e isso a coloca na cabeça das pessoas, além do código. O que conta como importante depende
do sistema, então nenhuma lista de "assuntos arquiteturais" resolve a questão de antemão.

## O que elas têm em comum

Postas lado a lado, as quatro definições compartilham quatro ideias:

| | elementos | relações | ambiente | custo da mudança |
|---|---|---|---|---|
| ISO/IEC/IEEE 42010 | elementos | relações | "no seu ambiente" | "evolução" |
| Bass, Clements e Kazman | elementos de software | relações entre eles | propriedades necessárias para raciocinar | implícito em "raciocinar" |
| Booch | — | — | — | a medida de "significativo" |
| Johnson, via Fowler | — | — | o que torna algo importante | "as coisas importantes" |

**Elementos e relações** são a estrutura: as peças e como elas se ligam. **Ambiente** é tudo a que a
estrutura responde — os usuários, os reguladores, os times, quem está de plantão. **Custo da
mudança** é o que separa uma decisão arquitetural de uma comum. A seção 04 e a seção 05 desta aula
tratam de relações e ambiente, uma de cada vez. Esta seção fica com as outras duas: os elementos,
que vêm em mais de uma estrutura, e o custo da mudança, o teste que Renata usa primeiro.

## Três estruturas na Carreto

O plural fica mais fácil de ver na Carreto, onde as três estruturas contam três histórias diferentes
sobre o mesmo sistema.

**A estrutura de módulos** é como o código é dividido. Dentro do monólito há cerca de trinta apps
Django — `loads`, `quotes`, `invoices`, `drivers` e assim por diante — e as regras sobre quem pode
importar quem existem só na cabeça das pessoas. Fora dele, cada serviço separado é uma base de
código própria.

**A estrutura de execução** é o que roda e como conversa: o monólito, os 14 serviços implantáveis (o
monólito entre eles), o broker, os bancos, e as chamadas e mensagens entre eles. É a estrutura em
que um incidente acontece, e a seção 04 desta aula trata das linhas dela.

**A estrutura de alocação** é onde cada peça roda e quem é dono dela: que máquinas, que conta de
nuvem e qual dos sete times responde quando ela quebra. Dois pedaços de código podem estar lado a
lado na estrutura de módulos e pertencer a times diferentes nesta, e foi assim que a Carreto acabou
com três times editando uma tabela.

Nenhuma das três é "a" arquitetura. **Uma pergunta sobre velocidade se responde pela estrutura de
execução; uma pergunta sobre quem pode mudar o quê, pelas estruturas de módulos e de alocação**, e
quem faz arquitetura precisa transitar entre elas.

## O teste, aplicado na Carreto

Na primeira semana como arquiteta, Renata faz uma lista de decisões que já existem no sistema da
Carreto, tomadas por alguém em algum momento e nunca registradas. Ela não pergunta se cada uma é "de
alto nível". Ela pergunta quanto custaria mudá-la.

| decisão já presente no sistema | custo aproximado de mudar | arquitetural? |
|---|---|---|
| o Pricing usa uma biblioteca de cliente HTTP e não outra | uns dois dias de um engenheiro | não |
| as telas do app Driver são feitas com um framework de UI | meses para o time do Driver, mas só para esse time | para o app Driver, sim; para a Carreto, quase nada |
| Payments, Matching e o app Shipper leem e escrevem a tabela `loads` do monólito | quatro a seis meses de três times, com migrações em produção | sim |
| o Tracking é dono do seu banco e ninguém mais se conecta a ele | já foi pago; desfazer seria uma escolha, não um custo | sim, e uma boa |
| as cotações são calculadas em reais com duas casas decimais | pequeno no código, grande nos dados: toda cotação e toda fatura gravadas | sim, embora ninguém pense nela assim |

Três coisas aparecem nessa tabela. **O tamanho de uma decisão não é o tamanho do código.** A
precisão da moeda são poucas linhas e toca cada registro financeiro que a Carreto guarda. **Quem é
afetado importa tanto quanto quanto tempo leva.** O framework de UI é caro para um time e quase de
graça para todos os outros, e é por isso que a aula 4 separa a arquitetura de uma aplicação da
arquitetura que atravessa várias. E **algumas decisões arquiteturais nunca foram tomadas de
propósito**: ninguém decidiu que três times compartilhariam a tabela `loads`. Cada time precisava
dos dados, a tabela estava lá, e o acoplamento chegou uma consulta de cada vez.

## Todo sistema tem uma

Esse último ponto leva àquele de onde parte a próxima aula. **Um sistema tem uma arquitetura, quer
alguém a tenha desenhado, escolhido ou saiba qual é, quer não.** A tabela `loads` compartilhada é
parte da arquitetura da Carreto hoje, embora nenhum documento a mencione. A pergunta nunca é se um
sistema tem arquitetura; é se quem trabalha nele sabe qual é, e se alguém a está decidindo de
propósito.

É esse o trabalho que Tomás acabou de dar a Renata. A aula 3 pergunta que trabalho é esse e de onde
vem a autoridade dele. Antes disso, a aula 2 tira do caminho três coisas que costumam ser
confundidas com arquitetura.
