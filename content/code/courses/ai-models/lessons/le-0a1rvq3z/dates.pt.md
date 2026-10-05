---
title: Duas datas por modelo
version: 1
---

Todo modelo da tabela da Anthropic traz duas datas, e elas respondem às duas perguntas de tempo das
aulas 1 e 2.

```
ana@desk:~/desk$ python lab/card.py all "Reliable knowledge cutoff" Retirement
# https://platform.claude.com/docs/en/about-claude/models/overview, read 2026-10-05
Claude Fable 5.1
  Reliable knowledge cutoff   Jun 2026
  Retirement                  Not sooner than September 1, 2027
Claude Opus 5.5
  Reliable knowledge cutoff   Jun 2026
  Retirement                  Not sooner than September 22, 2027
Claude Sonnet 5.5
  Reliable knowledge cutoff   Jun 2026
  Retirement                  Not sooner than September 28, 2027
Claude Haiku 4.5
  Reliable knowledge cutoff   Feb 2025
  Retirement                  Not sooner than October 15, 2026
```

**Reliable knowledge cutoff** (corte de conhecimento confiável) é a data da aula 1 seção 06: o que se
pode confiar que o modelo sabe sobre o mundo. Os três modelos mais novos param em junho de 2026; o
Haiku 4.5 em fevereiro de 2025, dezesseis meses antes. Para a classificação e a extração da ana essa
diferença não custa nada, como a aula 1 argumentou. Para uma tarefa sobre acontecimentos,
bibliotecas ou produtos recentes, seria a primeira coisa a pesar.

**Retirement** (aposentadoria) é a data da aula 2 seção 06, e a redação é precisa: *not sooner than*,
não antes de. É um piso, uma promessa de que o modelo vai responder pelo menos até ali, e não uma data
em que ele vai parar. No dia em que isto foi lido, **o piso do Haiku 4.5 estava a dez dias**. Depois de
15 de outubro de 2026 a Anthropic pode aposentá-lo quando anunciar, e a avaliação que a ana rodou
nele deixa de garantir qualquer coisa.

A tabela do LiteLLM traz outro conjunto de datas, para outros modelos:

```
ana@desk:~/desk$ sheet retiring --provider anthropic
# LiteLLM model sheet at 21881c57, 4472 entries
3 entries carry a deprecation date
2026-06-09  claude-mythos-preview                              anthropic
2026-11-30  claude-sonnet-4-5                                  anthropic
2026-11-30  claude-sonnet-4-5-20250929                         anthropic
```

O Sonnet 4.5, que a tabela comparativa já não mostra, tem uma data de descontinuação de fato na
tabela: 30 de novembro de 2026. As duas fontes não se contradizem. Uma lista os modelos atuais e os
pisos deles; a outra lista nomes mais antigos e os dias em que eles acabam.

## O que a ana faz com isso

- Ela trata o **Haiku 4.5 como um modelo de futuro curto**. Se ele vencer a avaliação ela pode usá-lo,
  e põe a avaliação do substituto no calendário agora, antes de o piso passar.
- Ela roda os casos da aula 5 no **identificador datado** `claude-haiku-4-5-20251001`, o que a tabela
  imprime, para a execução nomear exatamente o que mediu. A seção 04 mostra o apelido ao lado.
- Ela confere a página de novo antes de depender dela, porque o "read 2026-10-05" no topo de toda
  captura é a idade de todo fato desta aula.
