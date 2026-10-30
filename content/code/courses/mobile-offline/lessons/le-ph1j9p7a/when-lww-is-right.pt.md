---
title: Quando a última escrita vence é a regra certa
version: 1
---

**A última escrita vence é certa quando o valor mais novo é a verdade inteira e o mais antigo não
vale nada.** Isso é uma propriedade do dado, não do app, então a pergunta é feita por campo: um
planner pode usar a regra com segurança em algumas colunas e perder trabalho com ela em outras.

## Onde ela é certa

- **Uma configuração.** A hora do lembrete diário, o tema, o primeiro dia da semana. Se a Ana põe o
  lembrete às 8:00 no celular e às 7:30 no tablet, a escolha mais recente é o que ela quer, e perder
  as 8:00 não custa nada que ela tenha feito.
- **Um campo que uma pessoa muda de um lugar só.** O nome de um curso num planner pessoal é editado
  raramente e pela dona; duas edições concorrentes são improváveis, e quando acontecem qualquer
  resultado serve.
- **Um valor substituído por inteiro.** A cor de um curso, uma foto de perfil, um idioma escolhido.
  Ninguém edita meia cor.

## Onde ela perde trabalho

| dado | duas mudanças concorrentes | o que a última escrita vence guarda |
|---|---|---|
| um contador, como o total de minutos estudados | +30 no celular, +45 no tablet | uma delas: 30 ou 45 minutos somados, nunca 75 |
| uma lista guardada num campo, como as etiquetas de um curso | um aparelho acrescenta `exam`, o outro acrescenta `weekly` | uma etiqueta |
| um texto que duas pessoas editam, como anotações compartilhadas | cada uma acrescenta um parágrafo | um parágrafo |
| uma linha com campos independentes, como uma sessão | minutos num aparelho, feita no outro | uma das duas mudanças |

O contador é a falha mais limpa, porque a aritmética a mostra. Os dois incrementos foram feitos em
cima do mesmo valor de partida, então cada aparelho manda o seu total, e o servidor guarda um total.
**Quarenta e cinco minutos de estudo somem de uma estatística, e quem os estudou não tem como
descobrir.** A aula 15 constrói um contador que não perde incremento, mandando incrementos por
aparelho em vez de totais.

A linha da sessão é o caso desta aula, e tem o conserto mais barato: carimbar cada campo em vez da
linha, e aplicar a regra campo a campo. Os `minutes` do celular e o `done` do tablet então
sobrevivem os dois, porque nunca competiram. A aula 14 faz isso direito, contra a versão de que os
dois aparelhos partiram, para conseguir distinguir também o único caso que continua sendo um
conflito de verdade: os dois aparelhos mudando o mesmo campo.

**Então escolha a regra coluna por coluna, e escreva a escolha ao lado do esquema.** A última
escrita vence numa configuração é uma decisão; numa contagem, é um bug que todo relatório construído
em cima dela vai repetir.
