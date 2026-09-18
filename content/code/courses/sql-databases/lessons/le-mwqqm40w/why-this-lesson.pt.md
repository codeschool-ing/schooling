---
title: Por que uma aula sobre um motor que você talvez nunca instale
version: 1
---

A aula 12 comparou quatro motores e terminou dizendo que havia um quinto que não cabia na
comparação. É este, e o motivo de ele ganhar uma aula própria não é ser melhor ou pior. É que
**o Oracle Database é caro de um jeito específico, e esse jeito muda a forma dos sistemas
construídos sobre ele.**

Tudo das aulas 1 a 11 se aplica a ele. É um banco relacional com chaves, junções, transações,
índices e um planejador, e os hábitos que este curso construiu são os hábitos certos lá. O que
muda é o mundo em volta.

## Onde ele de fato está

Não no laptop de ninguém, e não por trás da maioria dos sites. O Oracle está onde grandes
organizações guardam os registros que não podem perder:

- bancos e seguradoras — o núcleo bancário, apólices, sinistros
- operadoras de telefonia — cobrança e provisionamento
- governos — tributos, cadastros, sistemas de saúde
- grandes varejistas e indústrias, normalmente por baixo de um ERP como o SAP ou o da própria Oracle

O fio comum é um sistema que foi comprado ou construído entre quinze e trinta anos atrás, guarda
dados com peso legal, e vem funcionando. Ninguém nessas organizações está escolhendo Oracle este
ano. Escolheram uma vez, e tudo desde então foi construído ao lado daquela decisão.

**Então a habilidade que esta aula ensina não é rodar Oracle.** Uma organização grande tem
administradores de banco de dados, e não serão você. A habilidade é ser o desenvolvedor que escreve
SQL correto e razoável contra um sistema cujas regras não são as que a internet supõe — e que
consegue dizer quais das coisas estranhas em volta são decisões técnicas e quais são consequências
de um contrato.

## Um aviso sobre esta aula, e ele importa

Toda outra aula deste curso rodou seus exemplos num servidor e mostrou o que voltou. As
transcrições das aulas 9 a 12 são reais: um PostgreSQL, um MySQL, um MariaDB e um SQLite, cada um
carregado com a loja da aula 1, com a saída colada sem edição.

**Esta aula não tem um Oracle para rodar.** Não existe um Oracle Database gratuito e
redistribuível que possa ocupar o mesmo lugar que aqueles quatro ocuparam, e inventar uma sessão de
terminal seria pior que inútil: pareceria exatamente com as outras e seria uma invenção.

Então esta aula **descreve** em vez de capturar. Onde ela diz o que o Oracle imprime, isso é uma
descrição de comportamento documentado e a própria frase diz isso. Não há nenhum bloco de código
nesta aula que se apresente como uma sessão, e onde aparece SQL é SQL para escrever e não a
transcrição dele rodando. Conferir qualquer coisa disto contra uma instância de verdade vale a
pena, e é o tipo de coisa para fazer na primeira semana em algum lugar que tenha uma.

## A ordem

A licença vem em segundo, antes do SQL, e essa ordem é o argumento da aula. Boa parte do que
surpreende as pessoas num sistema Oracle — onde a lógica mora, por que não há uma réplica de
relatório, por que ninguém olhou os relatórios de desempenho — decorre do que o contrato custa e
não do que o motor faz.

Depois o dialeto, que tem armadilhas de verdade; o PL/SQL, onde costuma estar a lógica de um
sistema corporativo; como leituras e transações diferem; como ele é operado e por quem; e o que
você de fato pode fazer como desenvolvedor que não tem as chaves.
