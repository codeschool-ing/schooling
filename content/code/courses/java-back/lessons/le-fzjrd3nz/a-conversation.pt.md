---
title: Primeiro o comportamento, numa conversa
version: 1
---

A imagem comum do desenvolvimento orientado a comportamento é a de uma ferramenta de teste: instala
o Cucumber, escreve os testes em inglês, e isso é BDD. É o contrário. O **desenvolvimento orientado
a comportamento** (*behaviour-driven development*, BDD) é o hábito de combinar exemplos concretos do
que o software deve fazer *antes* de o código existir, escritos em palavras que as pessoas que o
pediram assinariam embaixo. O Cucumber é uma ferramenta que transforma esses exemplos em testes
depois. Uma equipe pode praticar BDD com um quadro branco e nenhuma ferramenta, e uma equipe pode
instalar o Cucumber e não praticar nada disso.

## Os exemplos vêm de pessoas

O hábito nasceu do desenvolvimento guiado por testes. Dan North o descreveu em 2006, depois de ver
equipes discutindo o que era um "teste" quando a pergunta de verdade era o que o software deveria
fazer. A unidade de trabalho dele é uma reunião curta, muitas vezes chamada de **três amigos**
(*three amigos*): alguém que sabe o que o negócio quer, alguém que vai construir e alguém que vai
tentar quebrar. Os três pegam uma regra e pedem exemplos dela.

A livraria tem uma regra assim, e a aula 14 a tornou verdadeira no código: *a loja nunca vende um
exemplar que não tem*. Pedindo exemplos, os três escreveriam algo assim:

- Cinco exemplares de *The War of the Worlds* em estoque. Uma cliente pede dois. O pedido é aceito
  por 6400 centavos, e sobram três exemplares.
- Cinco exemplares de *Persuasion*. Uma cliente pede seis. O pedido é recusado, e os cinco
  exemplares continuam lá.

Aí quem testa pergunta o que acontece com **nenhum** exemplar, e quem conhece o negócio responde
que é a mesma recusa. Essa resposta custou uma frase. Descoberta depois do lançamento, a mesma
pergunta vira um relato de defeito, uma correção e uma implantação. **Achar as perguntas que a regra
deixou em aberto é o objetivo da conversa**, e isso acontece antes de alguém escrever um método.

Os exemplos têm a mesma forma: uma situação de partida, uma coisa que alguém faz, e o que dá para
ver depois. Essa forma é a gramática inteira da linguagem que o Cucumber lê, e ela tem nomes:
**Given**, **When** e **Then** (dado, quando, então).

## O que o Cucumber acrescenta à conversa

Sem uma ferramenta, os exemplos acabam num chamado, e o código se afasta deles em silêncio. O
Cucumber os mantém honestos. Os exemplos são escritos em **Gherkin**, um formato de texto puro com
poucas palavras-chave, num arquivo `.feature` que mora no repositório ao lado do código. Cada linha
de um cenário é ligada a um método Java, e o arquivo roda como um teste. O mesmo texto passa a ser
duas coisas ao mesmo tempo: o registro do que foi combinado, e uma verificação que quebra o build
quando o código deixa de concordar.

Esse papel duplo é o que se chama de **documentação viva**. Um documento de requisitos diz o que
alguém quis um dia; um arquivo de *feature* que passou hoje de manhã diz o que o software faz hoje.

Você vai encontrar o Cucumber onde pessoas que não são desenvolvedoras leem os testes: equipes em
que quem testa automatiza critérios de aceitação, donos de produto que revisam cenários em pull
requests, e bancos e seguradoras, onde um auditor pode perguntar qual regra um teste prova. O
Gherkin é compartilhado entre linguagens: o próprio Cucumber começou em Ruby e tem implementações
para JavaScript e Go além da JVM, e ferramentas como o Behave, em Python, e o Reqnroll, em .NET,
leem os mesmos arquivos.

## Onde ele fica entre os testes deste curso

A aula 18 testa uma classe, a aula 19 um serviço com um banco de verdade, e a aula 20 a API HTTP
por fora. O Cucumber não acrescenta um quarto tipo de teste: os cenários desta aula chamam a mesma
API do jeito que os testes da aula 20 chamam. O que ele acrescenta é uma camada de **frases** por
cima, para que alguém que não lê Java consiga ler o que está sendo verificado, e mudar.

Essa camada tem um preço, em arquivos e em indireção, e a última seção desta aula faz a conta.
Antes, o arquivo de *feature*.
