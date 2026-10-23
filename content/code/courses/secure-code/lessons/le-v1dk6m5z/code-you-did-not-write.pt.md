---
title: Código que você não escreveu
version: 1
---

A aula 1 instalou dois pacotes e o pip instalou doze. Essa proporção é normal, e é o motivo desta
aula existir: **a maior parte do código dentro de uma aplicação Python foi escrita por gente de fora
da equipe**, e roda com exatamente os mesmos direitos do código que a equipe escreveu. Uma falha numa
biblioteca que o portal importa é uma falha no portal.

A pasta desta aula não tem aplicação, só a lista do que uma aplicação usa. Crie como antes:

```
(.venv) ana@vm:~/sc$ mkdir deps
(.venv) ana@vm:~/sc$ cd deps
(.venv) ana@vm:~/sc/deps$ git init -b main
Initialized empty Git repository in /home/ana/sc/deps/.git/
```

O `pip show` diz o que um pacote traz junto. A linha `Requires` é a lista do próprio Flask:

```
(.venv) ana@vm:~/sc/deps$ pip show flask
Name: Flask
Version: 3.1.3
Summary: A simple framework for building complex web applications.
Home-page: 
Author: 
Author-email: 
License-Expression: BSD-3-Clause
Location: /home/ana/sc/.venv/lib/python3.13/site-packages
Requires: blinker, click, itsdangerous, jinja2, markupsafe, werkzeug
Required-by: 
```

Seis pacotes, cada um com seus mantenedores, seu calendário de lançamentos e seu histórico de
alertas. O Jinja2, o motor de templates em que a aula 4 confiou para o escape, exige por sua vez o
MarkupSafe. Essas são as **dependências transitivas**: ninguém na Vereda as escolheu pelo nome, e
cada uma é código que roda quando um paciente abre uma página.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l17-tree\" aria-label=\"O que uma linha num arquivo de requisitos traz junto. A linha flask==3.1.3 instala o Flask, e o Flask exige mais seis pacotes: blinker, click, itsdangerous, Jinja2, MarkupSafe e Werkzeug. O Jinja2 por sua vez exige o MarkupSafe. O pip-audit, instalado para verificar os outros, trouxe 24 pacotes próprios. Cada caixa é código que roda dentro da aplicação.\"><defs><marker id=\"l17-tree-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o que você escreveu</text><rect x=\"30\" y=\"120\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">flask==3.1.3</text><text x=\"110\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">uma linha</text><text x=\"470\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o que veio junto</text><rect x=\"250\" y=\"120\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"305.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Flask</text><rect x=\"430\" y=\"40\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">blinker</text><path d=\"M360 142 L395 142 L395 55 L430 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><rect x=\"430\" y=\"78\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">click</text><path d=\"M360 142 L395 142 L395 93 L430 93\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><rect x=\"430\" y=\"116\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">itsdangerous</text><path d=\"M360 142 L395 142 L395 131 L430 131\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><rect x=\"430\" y=\"154\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Jinja2</text><path d=\"M360 142 L395 142 L395 169 L430 169\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><rect x=\"430\" y=\"192\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">MarkupSafe</text><path d=\"M360 142 L395 142 L395 207 L430 207\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><rect x=\"430\" y=\"230\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Werkzeug</text><path d=\"M360 142 L395 142 L395 245 L430 245\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><path d=\"M570 169 L620 169 L620 207 L570 207\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><path d=\"M190 142 L250 142\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l17-tree-ah-paper-dim)\"></path><text x=\"470\" y=\"285\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">o próprio pip-audit trouxe mais 24</text></svg>", "caption": "Uma linha escrita, sete pacotes instalados. As dependências de uma dependência rodam com os mesmos direitos do seu próprio código."}
```

### Três perguntas sobre cada uma

Uma dependência é uma decisão, mesmo quando chega sem ninguém decidir. As três perguntas que valem a
pena são curtas:

| pergunta | por que importa |
|---|---|
| **há uma falha conhecida publicada para a versão que usamos?** | o problema mais comum e mais barato de achar, e a próxima seção trata dele |
| **ela ainda é mantida?** | uma biblioteca que ninguém mantém não recebe correções, então um alerta contra ela não tem versão corrigida para onde ir |
| **precisamos dela?** | a dependência mais segura é a que a aplicação não tem; uma função de dez linhas copiada de um pacote costuma ser melhor mantida em casa do que importada |

A primeira pergunta tem uma ferramenta. As outras duas são julgamento, feitas quando uma dependência
entra e de novo quando ela dá problema, e cabem na revisão de código que a aula 18 descreve.
