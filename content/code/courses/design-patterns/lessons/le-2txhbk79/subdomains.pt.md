---
title: "Subdomínios: central, de suporte e genérico"
version: 1
---

**Um negócio é vários negócios menores, e eles não merecem o mesmo cuidado.** O DDD chama cada um de
*subdomínio* e os separa em três tipos: o **central** (*core*), que é a razão de a organização existir
e onde ela difere de todo mundo; os **de suporte**, de que ela precisa e que ninguém vende; e os
**genéricos**, que toda organização tem e que alguém já faz bem. O sentido da separação é decidir
onde gastar as melhores pessoas e o maior cuidado de projeto.

O erro que isso evita é tratar o sistema inteiro como igualmente importante. Uma equipe que aplica
todos os padrões das lições 11 e 12 à tela de redefinir senha gastou o cuidado onde ele não rende
nada. Uma equipe que constrói as regras de empréstimo tão depressa quanto a tela de senha economizou
tempo no único lugar onde não podia.

## Os subdomínios da biblioteca

| subdomínio | tipo | por quê | o que fazer com ele |
|---|---|---|---|
| empréstimo: empréstimos, reservas, renovações, multas | central | as regras que as bibliotecárias discutem e ajustam; o motivo de os sócios virem a esta biblioteca | construir em casa, com todo o cuidado das lições 11 e 12 |
| catálogo: descrever títulos, assuntos, busca | de suporte | necessário e próprio de bibliotecas, mas o mesmo trabalho que toda biblioteca faz | construir de forma simples, ou adaptar uma ferramenta; importar registros em vez de digitá-los |
| aquisições: encomendar exemplares a fornecedores | de suporte | poucos pedidos por mês, regras do tamanho de uma planilha | um módulo pequeno, ou um formulário e uma planilha |
| login, pagamento por cartão e Pix, e-mail e SMS | genérico | toda organização tem, e especialistas fazem melhor | comprar ou usar um serviço; escrever só a cola |

**O central é pequeno, e o que o define é a diferença.** O empréstimo tem poucas centenas de linhas
neste curso, menos do que o catálogo precisaria para uma busca decente. Ele é o central porque uma
mudança de regra ali, um empréstimo mais longo para estudantes ou um dia de tolerância antes de a
multa começar, é uma decisão que a biblioteca toma sobre si mesma. Ninguém toma uma decisão dessas
sobre como uma senha é guardada.

O mesmo raciocínio diz o que não construir. Receber o pagamento de uma multa envolve bandeiras de
cartão, Pix, estornos, contestações e regulação. Uma biblioteca que escreve o próprio tratamento de
pagamentos gastou esforço num subdomínio genérico, e ainda vai fazer pior do que um provedor que não
faz outra coisa. **Genérico é o central de outra pessoa**: para o provedor de pagamentos, pagamento é
o central.

## Subdomínios mudam de lugar

A separação é um julgamento sobre o negócio de hoje. Suponha que a biblioteca decida que o que vai
diferenciá-la são recomendações: dizer a cada sócio o que ler em seguida, com base no que os vizinhos
pegaram. Recomendações nem estavam em pauta; agora são o central, e recebem o cuidado. Um subdomínio
também pode cair: se a prefeitura oferecer a todas as bibliotecas um catálogo compartilhado, o
catálogo vira genérico da noite para o dia, e o movimento certo é adotá-lo.

## Problema e solução

Um subdomínio é parte do **problema**: ele existe com ou sem software. A próxima seção apresenta o
lado da **solução**, o contexto delimitado, que é uma fronteira no código. Os dois muitas vezes se
alinham um para um, e os da biblioteca se alinham, mas são coisas diferentes. Um subdomínio pode ser
dividido entre dois modelos, e um sistema legado pode cobrir três subdomínios num só modelo
emaranhado. Manter as duas palavras separadas é o que deixa você dizer o que está errado num sistema
assim.
