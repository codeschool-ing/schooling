---
title: A linha que ninguém fatura
version: 1
---

Das quatro linhas, **a operação é a que se esconde**, e na Coreto é também a maior. A pilha
auto-hospedada custa R$ 475.200 de operação em três anos, contra R$ 151.200 das máquinas: três
reais de pessoas para cada real de hardware. Uma comparação que a deixa de fora não cometeu um erro
pequeno. Deixou de fora três quartos do custo de uma das opções.

## Por que ela se esconde

Ninguém decide escondê-la. Ela se esconde pelo jeito como é gasta.

**Chega em pedaços.** Ninguém gasta 1.056 horas com a pilha de observabilidade de uma vez. Alguém
passa uma tarde de terça numa atualização, outra pessoa é acordada de madrugada porque os discos de
log encheram, alguém responde às perguntas do time de Checkout sobre uma métrica sumida, e antes de
cada grande abertura de vendas alguém acrescenta capacidade porque o volume de logs sobe com o
tráfego. Cada pedaço é pequeno e parece parte do trabalho, e a soma nunca é escrita em lugar
nenhum.

**É paga por outro orçamento.** A fatura do fornecedor sai da linha de licenças e software, onde
alguém revisa cada item. Os salários dos engenheiros saem da folha, que é paga quer eles operem um
armazém de logs, quer construam outra coisa. A aula 11 desmonta o orçamento de engenharia linha por
linha; aqui basta ver que as duas opções saem de linhas diferentes, e só uma delas é examinada
quando a decisão é tomada.

**Quem faz o trabalho o conta como trabalho.** Pergunte à Plataforma quanto custa a pilha e a
primeira resposta honesta é o hardware, porque as horas são simplesmente o que o time faz. A Rafaela
teve de fazer a pergunta de outro jeito — quanto do último trimestre foi para mantê-la rodando? —
para conseguir um número.

## Medindo

A operação pode ser medida com as mesmas ferramentas que a aula 5 usou para os juros de uma dívida,
porque é o mesmo tipo de custo: horas pagas a cada sprint enquanto a coisa existir.

| fonte | o que ela dá |
|---|---|
| um registro de horas mantido por um ou dois meses | o total honesto, se as pessoas registrarem os pedaços pequenos além dos grandes |
| os acionamentos de plantão sobre a própria pilha | o trabalho noturno, de que ninguém se lembra de dia |
| tickets e perguntas no chat encaminhados ao time | a carga de suporte que os outros times põem nela |
| o histórico de atualizações | quantas atualizações por ano, e quanto tempo cada uma levou |

O time da Rafaela manteve um registro de horas e o conferiu com os acionamentos e o histórico de
atualizações. Deu 60% de um engenheiro: **1.056 horas por ano, R$ 158.400 a R$ 150 por hora.** Os
60% não são uma pessoa. São fatias das semanas de várias pessoas, e esse é o outro motivo de ninguém
os ter visto.

A operação do serviço hospedado foi estimada do mesmo jeito, a partir do que a própria implantação
do fornecedor pede de um cliente: um décimo de engenheiro, 176 horas por ano. **Hospedado não é
operação zero**, e uma planilha que põe zero ali comete o erro espelhado.

## "A gente paga eles de qualquer jeito"

A objeção aparece toda vez: os engenheiros da Plataforma estão na folha façam o que fizerem, então as
horas deles são de graça. Ela está errada de um jeito que vale dizer com precisão. O salário é pago
de qualquer jeito; **as horas só se gastam uma vez.** Uma hora no armazém de logs é uma hora que não
vai para o trabalho para o qual o time de Plataforma existe — e na Coreto essa lista inclui o teste
de carga que reproduz uma abertura de vendas, uma das quatro ações da estratégia da aula 1. A aula
13 precifica esse tipo de perda como custo de oportunidade. Para um TCO a regra é mais simples: a
hora de uma pessoa é convertida pelos mesmos R$ 150 seja lá o que ela estaria fazendo, para que a
fatura do hospedado e as horas do auto-hospedado fiquem na mesma unidade.

## O que ela faz com a resposta

Ponha as duas linhas de operação ao lado das duas de licença:

| | hospedado | auto-hospedado |
|---|---|---|
| licença, três anos | R$ 275.400 | R$ 151.200 |
| operação, três anos | R$ 79.200 | R$ 475.200 |

Só pela licença, auto-hospedar ganha por R$ 124.200. A linha de operação vai no sentido contrário
por R$ 396.000. **A linha que ninguém fatura é mais de três vezes a diferença para a qual todo mundo
estava olhando.** A próxima seção põe as quatro linhas na sua planilha e soma.
