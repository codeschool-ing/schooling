---
title: Simples não é o mesmo que fácil
version: 1
---

"Mantenha simples" é um conselho com que todo mundo concorda, o que é sinal de que cada pessoa o
ouve de um jeito. Na maior parte das vezes ele é entendido como "faça o que é familiar" ou "faça o
que é mais rápido hoje". **Rich Hickey, numa palestra de 2011 chamada "Simple Made Easy", separou
essas duas palavras, e a separação é uma das ferramentas mais úteis que uma arquiteta tem para
discutir um design.**

## Duas palavras, dois eixos

**Simples** vem do latim *simplex*, uma dobra, e Hickey a usa para uma coisa que não está
entrelaçada com outras: um papel, um conceito, um motivo para mudar. O oposto é *complexo*,
trançado junto. Ele ressuscitou um velho verbo inglês para o ato de tornar as coisas complexas, *to
complect*, entrançar, e a palavra pegou entre quem assistiu à palestra. A simplicidade é uma
propriedade da própria coisa. Dá para olhar um design e contar com o que cada parte está
emaranhada, e duas pessoas contando vão concordar quase sempre.

**Fácil** vem, segundo Hickey, de uma raiz que quer dizer perto, à mão. Fácil é o que está próximo de
nós: familiar, já instalado, dentro das habilidades que temos hoje. **Fácil é relativo a uma pessoa,
e simples não é.** Uma plataforma de streaming é fácil para quem opera uma há cinco anos e difícil
para quem nunca operou, e é exatamente tão emaranhada nos dois casos.

Como as duas coisas são independentes, toda escolha fica em algum ponto dos dois eixos ao mesmo
tempo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"Uma grade dois por dois. Colunas: difícil, pouco familiar hoje; e fácil, à mão. Linhas: simples, uma dobra; e complexo, entrelaçado. Simples e difícil: vale o esforço, Tracking avisa Payments por uma interface que é dele. Simples e fácil: pode usar, uma chamada de função dentro do monólito. Complexo e difícil: evite, um cluster de streaming novo para os eventos de um time. Complexo e fácil, em destaque: a armadilha, Payments lê direto as tabelas do Tracking.\"><defs><marker id=\"simpleeasy-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"255\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">difícil: pouco familiar hoje</text><text x=\"535\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">fácil: à mão</text><text x=\"60\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">simples</text><text x=\"60\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma dobra</text><text x=\"60\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">complexo</text><text x=\"60\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">entrelaçado</text><rect x=\"120\" y=\"64\" width=\"270\" height=\"128\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"255\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">vale o esforço</text><text x=\"255\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Tracking avisa Payments</text><text x=\"255\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">por uma interface que é dele</text><rect x=\"400\" y=\"64\" width=\"270\" height=\"128\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">pode usar</text><text x=\"535\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uma chamada de função</text><text x=\"535\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">dentro do monólito</text><rect x=\"120\" y=\"204\" width=\"270\" height=\"128\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"255\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">evite</text><text x=\"255\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um cluster de streaming novo</text><text x=\"255\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">para os eventos de um time</text><rect x=\"400\" y=\"204\" width=\"270\" height=\"128\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">a armadilha</text><text x=\"535\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Payments lê direto</text><text x=\"535\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">as tabelas do Tracking</text></svg>", "caption": "As duas palavras de Hickey como dois eixos, com escolhas que a Carreto de fato enfrentou. O canto em destaque é o que parece bom senso no dia em que é escolhido."}
```

O canto que causa problema é o de baixo à direita, fácil e complexo: a escolha que está à mão hoje e
trança as coisas para o futuro. O de cima à esquerda, simples e difícil no começo, é onde se gasta
boa parte do trabalho de uma arquiteta, convencendo um time de que a opção pouco familiar vai custar
menos toda vez que o código mudar.

## Como uma escolha fácil emaranha um sistema

Quando Payments precisou saber pela primeira vez que uma entrega tinha sido comprovada, o caminho
fácil era óbvio. O banco de dados do Tracking estava ali, um usuário só de leitura já existia, e uma
consulta à tabela de comprovantes funcionou no primeiro dia. **Era fácil, e trançou dois times
através de uma tabela.** Seis meses depois o Tracking não conseguia renomear uma coluna sem quebrar
Payments, e uma migração rotineira do Tracking chegou a parar os repasses por 40 minutos numa tarde
de sexta.

O caminho simples, em que o Tracking avisa Payments por uma interface que é dele e que ele pode
manter estável, levou cerca de uma semana para ser construído. Essa semana comprou uma propriedade
de que toda mudança posterior se beneficia: os dois times podem mudar o que é interno sem pedir
licença um ao outro. O registro de decisão da aula 5 é exatamente sobre essa pergunta, e a aula 9
transforma a regra geral num padrão que uma máquina consegue verificar.

**Simples não quer dizer menos caixas.** Dividir um monólito em serviços pode desemaranhar as coisas,
quando cada serviço é dono de um conceito e dos próprios dados. Também pode emaranhar mais, quando os
serviços dividem um banco de dados ou precisam ser implantados juntos, o formato que se costuma
chamar de monólito distribuído: todos os custos dos serviços da aula 2 de `architecture`, e nada da
independência. As remoções da seção anterior foram simplificações porque cada uma tirou uma trança:
a capacidade de cotar do Pricing não depende mais de o pricing-floor estar no ar. Tirar uma caixa e
deixar os emaranhados dela para trás não teria simplificado nada.

## Comece simples e deixe crescer

John Gall, no livro *Systemantics*, de 1975, formulou isso como lei: um sistema complexo que
funciona invariavelmente evoluiu de um sistema simples que funcionava, e um sistema complexo
desenhado do zero nunca funciona e não há remendo que o faça funcionar. É um aforismo, não uma
medição, e descreve bem a história da Carreto. O monólito funcionou desde o primeiro ano, e os
serviços que mereceram o lugar, o Tracking primeiro, foram recortados dele quando uma carga real
exigiu. Os que não mereceram foram, na maioria, desenhados de antemão, para cargas que nunca vieram.

## Escolha tecnologia sem graça

O mesmo argumento vale para tecnologia, e Dan McKinley o fez num ensaio de 2015 chamado "Choose
Boring Technology", escrito a partir dos anos dele na Etsy. O recurso dele é a **ficha de inovação**.
Uma empresa recebe poucas, umas três, para gastar com tecnologia nova para ela, e cada banco de dados,
linguagem ou plataforma nova gasta uma. Gaste-as onde a empresa está tentando ser diferente, e use
tecnologia sem graça em todo o resto.

Sem graça não quer dizer ruim. Quer dizer que os modos de falha da tecnologia são conhecidos, pela
empresa e pela internet: quando ela quebra às três da manhã, alguém já viu aquela quebra e escreveu o
que fazer. Os modos de falha de uma tecnologia nova são desconhecidos até ela falhar, e o custo dela
é pago pela empresa inteira enquanto ela rodar, enquanto o benefício vai para o time que a quis.
McKinley também argumentou que uma empresa é mais bem servida por um conjunto pequeno de ferramentas
que todos conhecem a fundo do que pela melhor ferramenta para cada trabalho, porque cada ferramenta
acrescentada torna o sistema como um todo mais difícil de operar.

Renata encontrou as fichas da Carreto já gastas no inventário. Uma foi bem gasta: o armazenamento de
posições GPS do Tracking, que recebe cerca de 270 escritas por segundo no pico, o tipo de carga em
que a escolha sem graça se esgota. Outra foi gasta no cluster de busca do load-search, para uma tela
usada por 4% dos embarcadores. Quando o time do Matching propôs depois um banco de dados de grafos
para escolher os motoristas candidatos, ela não recusou. Pediu que escrevessem o que ele compraria
que o PostgreSQL não conseguiria no volume da Carreto, e que tentassem primeiro a versão em
PostgreSQL. Ela atingiu a meta deles em uma semana, e a ficha ficou na gaveta.

**Duas perguntas resumem a aula para qualquer proposta que acrescenta alguma coisa.** Com o que isto
vai ficar emaranhado? E vale uma das poucas fichas que a empresa tem? A matriz de decisão da aula 6 é
onde essas respostas são pesadas contra os benefícios, e a aula 17 mostra como fica um sistema quando
ninguém as fez por muito tempo.
