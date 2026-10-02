---
title: Uma lista para uma funcionalidade que usa um modelo
version: 1
---

O curso montou uma funcionalidade da loja por vez. Antes de qualquer uma delas chegar a um cliente,
**as mesmas perguntas valem**, e cada uma aponta de volta para uma aula que mostrou a falha e o
conserto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Nove perguntas a responder antes de uma funcionalidade que usa um modelo sair, cada uma com as aulas que a tratam: custo, aulas 2 e 10; qualidade, 4 e 5; fatos, 6; ferramentas, 7 e 8; falhas, 9 e 10; dados, 10 e 11; saída, 11; dependências, 11; desligar, 11.\"><defs><marker id=\"ck-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">custo</text><text x=\"125.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aulas 2, 10</text><rect x=\"250\" y=\"16\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">qualidade</text><text x=\"355.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aulas 4, 5</text><rect x=\"480\" y=\"16\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">fatos</text><text x=\"585.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aula 6</text><rect x=\"20\" y=\"80\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ferramentas</text><text x=\"125.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aulas 7, 8</text><rect x=\"250\" y=\"80\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">falhas</text><text x=\"355.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aulas 9, 10</text><rect x=\"480\" y=\"80\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">dados</text><text x=\"585.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aulas 10, 11</text><rect x=\"20\" y=\"144\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">saída</text><text x=\"125.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aula 11</text><rect x=\"250\" y=\"144\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">dependências</text><text x=\"355.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aula 11</text><rect x=\"480\" y=\"144\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">desligar</text><text x=\"585.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aula 11</text></svg>", "caption": "Toda pergunta aponta de volta para uma aula que mostrou a falha e o conserto."}
```

## Antes de sair

- **Custo**: os tokens por requisição contados, o mês com preço, um orçamento e um limite na chave
  (aulas 2 e 10).
- **Qualidade**: uma avaliação com casos reais, rodada a cada mudança no prompt ou no modelo (aulas
  4 e 5).
- **Fatos**: respostas apoiadas em fontes recuperadas e citações conferidas por código onde fatos
  importam (aula 6).
- **Ferramentas**: cada tarefa com só o que precisa; esquemas cobrados; escritas aprovadas por uma
  pessoa ou limitadas por regras; chaves de idempotência em tudo o que muda estado (aulas 7 e 8).
- **Falhas**: timeouts definidos, repetições entendidas, um fallback testado quebrando o primeiro
  provedor, streams parciais marcados (aulas 9 e 10).
- **Dados**: menos mandado, o resto redigido, os termos do provedor lidos para o plano em uso, logs
  sem conteúdo (aulas 10 e 11).
- **Saída**: escapada para onde vai, nunca colada em SQL ou num shell, conferida atrás de promessas
  que nenhum resultado de ferramenta sustenta (aula 11).
- **Dependências**: todo pacote que um modelo sugeriu procurado antes de ser instalado (aula 11).
- **Desligar**: um interruptor que funciona, usado pelo menos uma vez (aula 11).

## E depois

**Uma funcionalidade que usa um modelo muda sem deploy**: o provedor atualiza um modelo, preços
mudam, os e-mails que os clientes escrevem mudam. Mantenha a avaliação rodando num horário fixo,
leia o custo e a taxa de erro toda semana, e trate uma mudança brusca em qualquer um como incidente
até ela ser explicada.
