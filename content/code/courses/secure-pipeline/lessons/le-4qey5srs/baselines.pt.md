---
title: Achados antigos, achados novos e exceções que vencem
version: 1
---

O linkbox é pequeno, e o pipeline dele encontrou os achados um de cada vez. Um serviço real que adota
um scanner encontra todos de uma vez: trezentos achados na primeira execução, em código escrito ao
longo de cinco anos por pessoas que já saíram. Quebrar o build por todos eles para o time no primeiro
dia, e o gate é desligado no terceiro. Alertar por todos eles enterra o próximo achado real debaixo de
trezentos antigos. **A saída é separar achados novos de achados existentes**, e tratar os dois de
jeitos diferentes.

### Baselines

Uma baseline é um registro dos achados que existiam quando o scanner chegou. O gate então quebra só
por achados que não estão nela, que é a metade "agora, na mudança" da regra virando mecanismo: quem faz
o push responde pelo que acrescentou, não pelo histórico. Os scanners deste curso têm, cada um, uma
forma disso:

```
ana@vm:~/linkbox$ gitleaks git --help | grep baseline
  -b, --baseline-path string          path to baseline with issues that can be ignored
ana@vm:~/linkbox$ semgrep scan --help 2>/dev/null | grep -A2 "baseline-commit=VAL"
       --baseline-commit=VAL (absent SEMGREP_BASELINE_COMMIT env)
           Only show results that are not found in this commit hash. Aborts
           run if not currently in a git directory, there are unstaged
ana@vm:~/linkbox$ pip-audit --help | grep -A2 -- "--ignore-vuln ID  "
  --ignore-vuln ID      ignore a specific vulnerability by its vulnerability
                        ID; this option can be used multiple times (default:
                        [])
```

O gitleaks lê um relatório anterior e deixa de fora os achados que estão nele. O Semgrep compara com
um commit e aponta só o que é novo desde então. O pip-audit não tem baseline nenhuma, só
`--ignore-vuln`, um aviso por vez e para sempre, e é por isso que esta aula escreveu um gate.

**Uma baseline não tem datas nem nomes.** Cada linha dela é um achado que alguém decidiu não corrigir
hoje, registrado num arquivo pelo qual ninguém responde, sem um dia em que a decisão seja revista.
Deixada sozinha, ela nunca encolhe, e um achado antigo nela é tão explorável quanto um novo. Então uma
baseline é um ponto de partida com um plano junto: um número de achados, um dono para o número e um
orçamento para reduzi-lo, medido do jeito que a aula 20 mede a dívida de segurança.

### Exceções, que uma baseline não é

O arquivo de exceções desta aula é a outra ferramenta, para o achado único com que um time decidiu
conviver por um tempo. As linhas dele carregam o que falta a uma baseline: **uma data, um motivo e um
dono**. O dono não é um campo do arquivo. É quem fez o commit da linha, e o Git já registra isso:

```
ana@vm:~/linkbox$ git blame -s ci/exceptions.txt | tail -n 3
9c388009 4) PYSEC-2026-1475 2026-11-20 templates need rework for 3.1.5; Ana, see issue 41
9c388009 5) PYSEC-2026-1472 2026-11-20 templates need rework for 3.1.5; Ana, see issue 41
9c388009 6) PYSEC-2026-1471 2026-11-20 templates need rework for 3.1.6; Ana, see issue 41
ana@vm:~/linkbox$ git log -1 --format="%an, %ad" --date=short -- ci/exceptions.txt
Ana Lima, 2026-10-23
```

O `git blame` aponta o commit por trás de cada linha, e o commit aponta o autor e o dia. O nome no
motivo é uma cortesia para quem lê; o commit é o registro que ninguém pode esquecer de preencher.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"sp-l07-expiry\" aria-label=\"A vida de uma exceção, escrita em 23 de outubro para valer até 20 de novembro. De 23 de outubro a 13 de novembro o achado passa; de 14 a 20 de novembro, a última semana, o gate alerta; a partir de 21 de novembro a exceção é ignorada e o achado volta a quebrar o build. Renová-la é um commit novo, com data e motivo novos.\"><defs><marker id=\"sp-l07-expiry-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l07-expiry-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"70\" width=\"420\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">passa, em exceção</text><rect x=\"460\" y=\"70\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"530\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">alerta</text><rect x=\"600\" y=\"70\" width=\"105\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"652\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">quebra de novo</text><path d=\"M30 130 L710 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l07-expiry-ah-paper-dim)\"></path><line x1=\"40\" y1=\"122\" x2=\"40\" y2=\"138\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"36\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">23 out</text><text x=\"36\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a linha entra num commit</text><line x1=\"460\" y1=\"122\" x2=\"460\" y2=\"138\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"460\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">14 nov</text><text x=\"460\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">começa a última semana</text><line x1=\"597\" y1=\"122\" x2=\"597\" y2=\"138\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"597\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">20 nov</text><text x=\"597\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o último dia</text><text x=\"652\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">21 nov: a data passou</text><path d=\"M652 70 L652 40 L60 40 L60 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l07-expiry-ah-phosphor)\"></path><text x=\"356\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">renovar: um commit novo, uma data nova, um motivo novo</text></svg>", "caption": "A exceção anuncia o próprio fim uma semana antes, e depois dele o achado volta como se nunca tivesse tido exceção."}
```

Quatro regras impedem que as exceções virem uma baseline com outro nome:

1. A data é curta, semanas e não um ano, porque uma decisão envelhece tão rápido quanto o código em
   volta dela. A da seção anterior durou quatro semanas.
2. O gate alerta na última semana, para que quem a escreveu veja a data chegando no curso normal dos
   seus pushes.
3. Uma exceção vencida é ignorada, e o achado quebra o build exatamente como antes. Renovar uma é um
   commit novo, com uma data nova e um motivo que diz o que mudou, lido por quem revisa.
4. Uma linha sem motivo é recusada: o gate não consegue dividi-la em três campos, o Python levanta um
   erro e o build quebra.

### Onde isso deixa o pipeline

Todo estágio agora responde com três códigos, a última linha conta os alertas, e um estágio que não
rodou quebra o build. O gate de composição sabe a diferença entre uma correção que ninguém aplicou, um
aviso que ninguém consegue corrigir e uma decisão com data marcada. O que a aula não consegue escrever
num script é a leitura: **um alerta só vale o lugar que ocupa se alguém o lê**, e o número de alertas
que um time de fato lê é menor que o número que um scanner consegue produzir. A aula 8 põe um scanner
de imagens diante da mesma pergunta, com achados numa imagem base que não têm versão corrigida
nenhuma.
