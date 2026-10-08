---
title: Por que os seus próprios casos
version: 1
---

Todas as aulas até aqui terminaram no mesmo lugar: qualidade precisa ser medida, e só no seu próprio
trabalho. Esta aula é a medição, e é a parte do curso que sobrevive a todo produto que as aulas
6 a 20 citam. Um modelo que você escolhe este ano vai ser aposentado; os casos que você escreve
para escolhê-lo vão escolher o substituto.

## O que um benchmark não diz

Um benchmark público responde "como este modelo se sai nestas perguntas". É a resposta certa para a
pergunta errada, por três motivos que bastam, cada um, sozinho:

- **As perguntas não são as suas.** Os e-mails da Lantern Books são curtos, informais, às vezes em
  português, e sobre cinco coisas. Nenhum benchmark é feito deles.
- **Os rótulos não são os seus.** Se "can they leave it with a neighbour?" é sobre o status de um
  pedido ou sobre o endereço dele é uma decisão da loja. Um modelo que discorda da loja está errado
  para a loja, pense o benchmark o que pensar.
- **O formato não é o seu.** O seu programa lê a resposta. Um benchmark que avalia o significado de
  uma resposta aprova um modelo que escreve "Refund." onde o seu código espera `refund`.

## O que é um caso

Um **caso** são três coisas anotadas juntas:

1. **uma entrada**, exatamente como o programa vai mandar: aqui, o e-mail de um cliente;
2. **a saída esperada**, decidida por uma pessoa que conhece a tarefa: o rótulo, ou o número do
   pedido;
3. **como julgar uma resposta contra ela**: igualdade exata, igualdade depois de uma arrumação, ou
   uma verificação que um programa consegue fazer.

Quarenta deles, passados por cada candidato e pontuados do mesmo jeito, dão um número por modelo que
significa alguma coisa para a Lantern Books. Isso é uma **avaliação**, e o resto desta aula monta
uma: o conjunto (seção 03), a pontuação (04), o harness (05), e como ler o que sai (06 a 10).

**Os candidatos são três modelos abertos pequenos na sua própria máquina.** O `llama3.2:3b` é o
modelo do curso; o `llama3.2:1b` é o menor que a aula 1 apontou para um computador mais fraco; e o
`qwen2.5:3b`, de outra família no mesmo tamanho, está aqui porque uma avaliação precisa de
candidatos para comparar, e só esta aula o usa. Baixe-o antes da seção 05 com `ollama pull
qwen2.5:3b`; com menos memória, rode os outros dois. Eles fazem o papel das linhas hospedadas da
matriz da aula 4, que pedem chave, e **as respostas deles são reais**: toda nota abaixo é o que eles
escreveram, na máquina em que o curso foi gravado. Com uma chave, o mesmo harness roda nos
candidatos hospedados sem mudança.
