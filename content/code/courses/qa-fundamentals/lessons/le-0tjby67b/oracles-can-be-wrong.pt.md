---
title: Oráculos podem estar errados
version: 1
---

**Todo oráculo é uma afirmação sobre o que está certo, e afirmações podem estar erradas.** Quem testa e trata um
oráculo como a verdade para de fazer perguntas exatamente no momento em que uma pergunta é necessária.

## Como cada tipo falha

- **Uma especificação pode estar errada.** A primeira frase da Joana dizia *acima de 60*, e um programa que a seguisse
  ao pé da letra teria passado em toda verificação escrita a partir dela e ainda assim descumprido a lei. O oráculo e o
  programa concordavam, e os dois estavam errados.
- **Um exemplo combinado pode estar errado.** Se os três amigos tivessem escrito *60 paga R$ 36,00* num cartão verde,
  o esboço garantiria o defeito todo dia, automaticamente.
- **Uma referência pode compartilhar o defeito.** Se a tabela de preços impressa na bilheteria tivesse sido feita
  rodando o mesmo programa, comparar com ela só provaria que o programa concorda consigo mesmo.
- **Um oráculo humano pode estar errado, ou desatualizado.** A Célia sabe os preços que sempre cobrou. Na primeira
  quarta depois de a regra mudar, a expectativa dela era a regra antiga.
- **Uma relação pode estar errada.** *Uma sessão mais cedo nunca custa mais* vale para esta regra. Um cinema que
  cobrasse mais por uma sessão especial à meia-noite a quebraria de propósito.

## Quando dois oráculos discordam

O momento mais útil do teste muitas vezes não é uma falha, mas uma discordância: a regra diz uma coisa, o exemplo
outra, a bilheteria uma terceira. A aula 1 começou com uma, o código e o estatuto discordando aos sessenta.

Uma discordância não é algo que quem testa resolve sozinho. É informação para quem é dono da decisão:

1. **diga os dois oráculos e o que cada um diz**: *o esboço diz R$ 18,00, o cartaz na porta diz que a quarta é pela
   metade em cima de outros descontos*;
2. **diga o que o produto faz**: *o programa cobra R$ 18,00*;
3. **pergunte quem decide**: aqui, a Joana. A resposta dela vira um exemplo escrito, e o oráculo que estava errado é
   corrigido, neste caso o cartaz.

## Nomeando o oráculo no relato de defeito

Os relatos de defeito da aula 4 tinham *esperado* e *observado*. O hábito que esta aula acrescenta é uma terceira
linha: **segundo o quê**. Compare:

> **esperado:** R$ 18,00 · **observado:** R$ 9,00

> **esperado:** R$ 18,00, pela quinta frase da regra, *meia é o máximo que um ingresso é reduzido* · **observado:**
> R$ 9,00

O segundo pode ser conferido por qualquer um, discutido se a regra for lida de outro jeito, e fechado com uma
referência quando for corrigido. O primeiro pede a quem lê que confie na memória de quem testa sobre a regra, que é
exatamente o tipo de oráculo contra o qual esta seção vem alertando.

## Quem testa como colecionador de oráculos

O valor de quem testa está menos em rodar testes do que em saber **como dizer**. Cada aula deste curso acrescentou
oráculos à coleção da Lia: a regra, a bilheteria, o estatuto, os exemplos combinados, o errado implícito de uma queda,
as relações que uma regra implica, as pessoas que usam o produto. Quem começa a testar tem um ou dois. Quem tem
experiência pega cinco, percebe quando discordam, e sabe que a discordância em geral é onde o defeito está.
