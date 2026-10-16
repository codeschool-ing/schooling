---
title: O que Cunningham quis dizer com dívida
version: 1
---

"Dívida técnica" é usada na maioria das organizações de engenharia para falar de código de que
alguém não gosta: código velho, código feio, código escrito por um time que já foi embora. Na
Coreto, a expressão era a linha 6 da primeira versão da aula 1, "pagar a dívida técnica", e ninguém
sabia dizer qual dívida nem por quê. **Usada assim, a expressão nomeia um sentimento, e um
sentimento não se prioriza contra uma funcionalidade.** A metáfora foi criada para algo mais
estreito e mais útil, e é a versão estreita que permite pedir dinheiro.

## De onde vem a expressão

Ward Cunningham a apresentou num relato de experiência na conferência OOPSLA, em 1992, sobre um
produto de gestão de carteiras que seu time estava construindo. O argumento dele, parafraseado:
entregar código antes de entender o problema por completo é como tomar um empréstimo. Um pouco disso
acelera o desenvolvimento, desde que seja pago logo, retrabalhando o código para refletir o que o
time aprendeu. O perigo é o empréstimo que nunca é pago, porque cada minuto gasto trabalhando em
código que não está bem certo é juro sobre ele — e uma organização inteira pode parar só por causa
dos juros.

Três coisas nisso se perdem com facilidade.

**A dívida é tomada de propósito, para aprender mais rápido.** O time de Cunningham entregava código
que refletia o entendimento daquele momento, sabendo que estaria errado de jeitos que ainda não dava
para ver, porque entregar era como iam descobrir. A dívida é a distância entre o código e o que eles
entenderam depois.

**Tomar emprestado é uma boa decisão.** Uma empresa que nunca toma crédito cresce mais devagar que
uma que toma bem. Um time que se recusa a entregar até o desenho ficar perfeito não está evitando
dívida; está pagando o custo de atraso no lugar dela, que a aula 13 põe em dinheiro.

**O perigo está em não pagar.** O empréstimo está bem. O empréstimo deixado nos livros por anos,
enquanto todo mundo trabalha em volta dele, é o que para uma organização.

## O que a metáfora oferece

Ela traz duas palavras que as finanças já usam, e a aula 5 transforma as duas em horas e reais.

**Principal** é o trabalho necessário para eliminar a dívida: retrabalhar o código até que ele
reflita o que o time sabe hoje. Paga-se uma vez.

**Juros** são o custo extra que a dívida acrescenta a cada trabalho que encosta nela, enquanto ela
existir: a mudança mais demorada, a revisão a mais, o incidente, o contorno. Pagam-se de novo e de
novo, por quem mexer no código em seguida.

As palavras importam porque quem decide orçamento as entende. Otávio, o CFO da Coreto, nunca leu o
módulo de reservas e nunca vai ler. Ele sabe exatamente o que significa carregar um empréstimo cujos
juros são maiores que o custo de quitá-lo.

## Bagunça não é empréstimo

O sentido estreito exclui algo que o uso do dia a dia inclui. **Código escrito com descuido, por
gente que poderia ter feito melhor e escolheu não fazer, não é um empréstimo tomado para aprender
mais rápido.** Ninguém ganhou nada com ele. Ele ainda cobra juros, e é por isso que autores
posteriores alargaram o termo para cobri-lo, e a próxima seção usa esse mapa mais largo. Mas vale
manter a diferença à vista, por um motivo prático: um empréstimo deliberado vem com um plano de
pagamento, e uma bagunça não vem com nenhum. O primeiro precisa de uma data de pagamento. A segunda
precisa de uma mudança no modo como o time trabalha, ou vai voltar.

## Onde a metáfora engana

Toda metáfora para em algum lugar, e esta para em três lugares que vale conhecer.

**Dívida em que ninguém mexe não cobra juros.** Um empréstimo bancário custa dinheiro todo mês, faça
você o que fizer. Um módulo mal desenhado que ninguém muda há anos custa quase nada, porque o juro só
é pago quando alguém trabalha nele. Parte da dívida técnica nunca precisa ser paga, e quitá-la mesmo
assim é gastar principal para economizar um juro que nunca ia ser cobrado.

**Ninguém manda extrato.** O banco diz todo mês quanto o empréstimo custou. A dívida técnica não manda
conta: os juros se espalham por centenas de mudanças, cada uma um pouco mais lenta do que deveria, e
ninguém os soma. É por isso que a dívida fica invisível até alguém medi-la, e medi-la é a aula 5.

**Quem toma o empréstimo e quem paga são pessoas diferentes.** Quem tomou o empréstimo muitas vezes
já saiu. Na Coreto, o código de reserva de assentos que trava linhas no banco foi escrito nos
primeiros anos da empresa. Quem paga os juros hoje é o time de Reservas e cada comprador cujo assento
sumiu durante uma abertura de vendas, e nenhum deles escolheu isso.

## O registro da Coreto, com nomes

Quando Davi perguntou aos times quais dívidas de fato os atrasavam, em vez de código de que apenas
não gostavam, voltaram quatro com nome, cada uma com um time capaz de dizer quanto ela lhe custava:

- o travamento das reservas de assento no módulo de reservas;
- o gerador de ingressos em PDF feito à mão;
- a suíte de testes ponta a ponta instável;
- a réplica antiga de relatórios.

Quatro é uma lista curta para um monólito de nove anos, e é curta de propósito. A próxima seção
pergunta como cada uma das quatro surgiu, porque a resposta diz o que a Coreto deveria mudar para
tomar emprestado melhor da próxima vez.
