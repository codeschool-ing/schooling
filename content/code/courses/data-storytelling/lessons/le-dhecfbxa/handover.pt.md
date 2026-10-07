---
title: Reproduzível, documentado, versionado
version: 1
---

Uma análise vive mais que a reunião para a qual foi feita. Seis meses depois alguém pergunta de onde vieram
os 41,5%, ou o conselho quer os mesmos números do segundo semestre, ou a analista mudou de área. **Uma análise
que outra pessoa não consegue rodar de novo é coisa de uma vez só, por melhor que tenha sido.**

## O que uma passagem contém

- **Os dados, ou como obtê-los.** A consulta que produziu as vinte e quatro linhas, ou a exportação, com a data
  em que foi tirada.
- **As definições**, a tabela da aula 4, como documento, e não na memória da analista.
- **Cada conta como algo que roda.** A planilha com as fórmulas, e não uma cópia dos valores; um script, se o
  trabalho foi feito em código.
- **As entregas, datadas.** O deck e a página como foram apresentados, e cada versão posterior com o que mudou.
- **Um registro de decisões.** Uma linha por decisão: o que foi decidido, por quem, quando e por quê. *"27 de
  outubro: estender à capital a partir de novembro. Paulo. Critério atingido da semana 4 em diante;
  salvaguarda segurou."*

## Este curso faz isso

Todo número deste curso sobre os clientes da Faro pode ser recalculado a partir das vinte e quatro linhas do
`faro.csv`, a tabela que você salvou na aula 1, e as aulas que calculam um deles mostram a fórmula. Os fatos que
a tabela não guarda, como o preço de uma caixa, a margem, as entregas de renovação e as taxas semanais do
piloto, são ditos uma vez, na aula que os apresenta, e reaproveitados dali. **Nada é redigitado**, e é por isso
que um número da aula 11 e o mesmo número da aula 4 não podem discordar.

Esse é o padrão a buscar, e ele não exige programação: uma planilha cujos números vêm todos de fórmulas sobre
uma aba de dados é reproduzível. O que quebra a reprodutibilidade é o número digitado à mão num
slide, que ninguém consegue rastrear e ninguém atualiza quando os dados mudam.

## Versões

Nomeie as versões pela data, não por "final": `first-delivery-2025-08-15.pptx`, não `final-v3-AGORA-VAI.pptx`.
Guarde a versão que foi apresentada, sem mudar, mesmo depois de melhorá-la, porque **a decisão foi tomada sobre
aquela versão**, e uma pergunta futura sobre a decisão tem de ser respondida a partir dela.
