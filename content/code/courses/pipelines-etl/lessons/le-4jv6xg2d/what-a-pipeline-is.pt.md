---
title: O que faz de um script um pipeline
version: 1
---

**Um pipeline não se define pelo que faz, mas por quantas vezes faz.** O SQL que a Ana rodou em
`warehouse-modeling` para montar o warehouse moveu dados de uma origem para um destino e os
transformou no caminho. Não era um pipeline. Rodou uma vez, com ela olhando, e se tivesse falhado no
meio ela teria visto, consertado e rodado de novo.

Um pipeline é o mesmo trabalho sem ninguém olhando, e essa única mudança exige quatro propriedades
de que o script de uma vez nunca precisou:

- **Ele roda de novo sozinho.** Toda noite, toda hora, ou toda vez que um arquivo chega. O que quer
  que o tenha iniciado, não foi uma pessoa.
- **Ele sabe o que já fez.** A execução de hoje à noite não pode copiar os pedidos de ontem uma
  segunda vez, nem pular os que chegaram durante a execução de ontem. A lição 4 chama isso de marca
  d'água.
- **Ele pode rodar duas vezes e dar a mesma resposta.** Uma execução falha às 3 da manhã, alguém a
  roda de novo às 9, e o warehouse não pode agora ter a noite em dobro. Essa propriedade tem nome,
  idempotência, e a lição 15 não trata de outra coisa.
- **Ele avisa quando falha, e onde.** Um job que morre em silêncio é pior que um que nunca rodou,
  porque o painel continua mostrando os números de ontem como se fossem os de hoje.

## Origem, passos, destino

Todo pipeline deste curso tem as mesmas três partes:

1. **Uma origem**, que é de outra pessoa e muda sem pedir licença: o banco da loja, uma API, um
   arquivo que um fornecedor deixa, um fluxo de eventos.
2. **Passos** que extraem, transformam e carregam, e a lição 2 trata da ordem em que eles vêm.
3. **Um destino** que as pessoas leem, aqui o warehouse `wh`. Quem o lê confia que o que vê está
   completo e atual, e não tem como conferir nenhuma das duas coisas.

**O destino é a metade para a qual as pessoas esquecem de projetar.** Um pipeline que escreve uma
linha por vez deixa os seus leitores olhando para meio dia enquanto trabalha. Um que escreve numa
tabela separada e a troca no fim nunca deixa. A diferença é invisível até a manhã em que um gerente
abre um relatório no minuto errado.

## De quem é o quê

A origem é da equipe que cuida dos caixas. O warehouse é de quem o lê. **O pipeline é da pessoa que
recebe o telefonema**, e numa equipe de dois essa é a pessoa que o escreveu. Tudo o que este curso
pede que você acrescente — uma verificação, uma retentativa, uma linha de log — é algo que essa
pessoa vai agradecer às 3 da manhã. A lição 10 é essa noite.
