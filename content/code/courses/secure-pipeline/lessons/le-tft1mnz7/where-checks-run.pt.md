---
title: Seis lugares, e o tempo que cada um pode gastar
version: 1
---

A pergunta "esta checagem deveria rodar mais cedo?" não tem resposta sozinha. A pergunta útil é
**"que lugar pode bancá-la?"**, e todo lugar da linha tem um orçamento: o tempo que uma pessoa espera
ali antes de parar de esperar e ir fazer outra coisa. Uma checagem que cabe no orçamento de um lugar
roda ali. Uma que não cabe vai mais para a direita, para um lugar que pode bancá-la, e não é
descartada.

### Os orçamentos

| lugar | quando roda | o orçamento | o que cabe ali |
|---|---|---|---|
| editor | enquanto você digita ou salva | menos de um segundo | um linter, uma regra do Semgrep num arquivo |
| hook de pre-commit | no `git commit` | alguns segundos | uma varredura de segredos nas linhas em stage (aula 6) |
| cada push | em cada push, em qualquer branch | **cerca de dez minutos** | testes, análise estática, auditoria de dependências, build, varredura da imagem |
| depois do merge na main | só na `main` | o mesmo que um push | publicar o que passou; no linkbox, a tag `main` da imagem (aula 8) |
| noturno | uma vez por dia, na `main` | uma hora ou mais | um rebuild sem cache, a varredura dinâmica (aula 4) |
| produção | o tempo todo | nenhum: nunca acaba | avisos novos contra o que está rodando, alertas em tempo de execução |

Os números são regras práticas, e a do push tem uma longa história. *Extreme Programming Explained*,
de Kent Beck, fez do **build de dez minutos** uma prática própria, e *Continuous Delivery*, de Jez
Humble e David Farley, pede o mesmo do primeiro estágio de um commit: menos de dez minutos, e melhor
ainda abaixo de cinco. O motivo é humano, não técnico. **Dez minutos é mais ou menos quanto alguém
espera por uma resposta antes de mudar de tarefa.** Depois que mudou, um build vermelho interrompe a
tarefa nova em vez de fechar a antiga.

### Checagens rápidas e lentas

Uma checagem é rápida ou lenta por um de três motivos, e qual deles é decide o que dá para fazer.

- **Ela lê pouco.** Um linter num arquivo, uma varredura de segredos nas linhas em stage. Rápida em
  qualquer lugar.
- **Ela lê muito, mas só o que mudou.** Os testes de um serviço, o Bandit no código dele. Rápida
  enquanto o serviço é pequeno: o Bandit da aula 3 lê as 69 linhas do código do linkbox, onde um
  monolito tem centenas de milhares.
- **Ela precisa construir ou rodar algo antes.** Uma varredura de imagem precisa de uma imagem; uma
  varredura dinâmica precisa de uma cópia do serviço rodando e depois percorre cada página que achar.
  Lenta por natureza, e candidata natural à lista noturna.

**O segundo tipo é onde os orçamentos se perdem em silêncio.** Cada checagem é rápida quando entra, e
o serviço cresce debaixo de todas ao mesmo tempo. É por isso que as duas próximas seções medem o
pipeline do linkbox em vez de chutar, e por isso que o pipeline imprime um tempo para cada estágio
que roda.

### Uma checagem, vários lugares

Uma checagem não fica presa a um lugar. A varredura de segredos da aula 6 roda no hook de
pre-commit, onde lê só as linhas em stage, e de novo como primeiro estágio de cada push, onde lê o
histórico inteiro. As duas são a mesma ferramenta com entradas diferentes, e **a segunda existe
porque a primeira pode ser pulada**: um hook vive no clone de uma pessoa, e `git commit --no-verify`
passa por cima dele. Uma checagem que importa nunca fica só no laptop.

O build é o outro exemplo. A imagem é construída a cada push a partir de camadas que builds
anteriores deixaram em cache, e é isso que mantém o estágio de build curto. A lista noturna a
constrói de novo sem cache nenhum, então **um build que só funciona por causa do que está em cache**
aparece numa noite qualquer, e não no dia em que uma correção urgente precisa de um build limpo.

### Duas listas para o linkbox

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"sp-l02-lists\" aria-label=\"Dois gatilhos, um executor. Um git push em qualquer branch faz o servidor de CI rodar ci/pipeline.sh com ci/stages, test e depois build, e o veredito volta no próprio push. Um agendamento à noite clona a main e roda ci/pipeline.sh duas vezes, primeiro com ci/stages e depois com ci/nightly, cujo único estágio é rebuild, e o veredito precisa ser enviado a alguém de manhã.\"><defs><marker id=\"sp-l02-lists-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l02-lists-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"30\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">git push</text><text x=\"80.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">qualquer branch</text><rect x=\"15\" y=\"140\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">agendamento</text><text x=\"80.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main, à noite</text><rect x=\"185\" y=\"30\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ci/stages</text><text x=\"260.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">test, build</text><rect x=\"185\" y=\"130\" width=\"150\" height=\"76\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ci/stages</text><text x=\"260\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">depois</text><text x=\"260\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ci/nightly</text><text x=\"260\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rebuild</text><rect x=\"375\" y=\"30\" width=\"150\" height=\"176\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ci/pipeline.sh</text><rect x=\"565\" y=\"30\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">no próprio push</text><text x=\"635.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">segundos depois</text><rect x=\"565\" y=\"140\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">enviado a alguém</text><text x=\"635.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">de manhã</text><path d=\"M145 58 L183 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l02-lists-ah-paper-dim)\"></path><path d=\"M145 168 L183 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l02-lists-ah-paper-dim)\"></path><path d=\"M335 58 L373 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l02-lists-ah-paper-dim)\"></path><path d=\"M335 168 L373 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l02-lists-ah-paper-dim)\"></path><path d=\"M525 58 L563 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l02-lists-ah-paper-dim)\"></path><path d=\"M525 168 L563 168\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l02-lists-ah-amber)\"></path></svg>", "caption": "As duas listas dividem o executor. O que a execução noturna acrescenta é uma lista, não um segundo pipeline."}
```

Então o pipeline do linkbox ganha duas listas. `ci/stages` é o que roda a cada push, e precisa ficar
dentro do orçamento do push à medida que o curso acrescenta estágios. `ci/nightly` é o que roda uma
vez por dia na `main`, depois de tudo em `ci/stages` ter passado. Esta aula começa a segunda lista
com um estágio, um rebuild da imagem sem cache, e a aula 4 acrescenta a varredura dinâmica. **O que
passa da primeira lista para a segunda continua rodando, todo dia, no código que está de fato na
`main`.**
