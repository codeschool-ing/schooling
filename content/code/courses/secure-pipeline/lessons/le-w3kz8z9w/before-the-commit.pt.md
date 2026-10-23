---
title: Antes do commit, um hook; antes do push, a plataforma
version: 1
---

Tudo até aqui foi a resposta a um segredo que entrou. O segredo mais barato de tratar é o que nunca
chegou a um commit, porque um commit é a primeira cópia. **Um hook de pre-commit varre o que você
está prestes a commitar, no seu próprio laptop, e recusa o commit se encontrar alguma coisa.** Nada
foi copiado para lugar nenhum ainda, então não há nada a revogar.

### O hook

O Git roda `.git/hooks/pre-commit` antes de gravar um commit, e um hook que sai com qualquer coisa
diferente de 0 interrompe o commit. `gitleaks git --pre-commit --staged` varre só o que está no
stage, que são poucas linhas e leva uma fração de segundo, rápido o bastante para ninguém ter
vontade de desligá-lo. `--verbose` faz a recusa dizer onde está o segredo, e `--redact` mantém o
valor fora do terminal, que pode estar sendo compartilhado numa chamada ou gravado. Salve como
`~/linkbox/.git/hooks/pre-commit`:

```sh
#!/bin/sh
# Refuse a commit that adds a secret. Only what is staged is scanned, so it
# takes a fraction of a second; the pipeline still reads the whole history.
exec gitleaks git --pre-commit --staged --no-banner --no-color --redact --verbose
```

Como o hook do servidor de CI na aula 1, ele só roda se for executável:

```
ana@vm:~/linkbox$ chmod +x .git/hooks/pre-commit
```

### O hook, recusando

Alguém está escrevendo uma exportação para um serviço de relatórios e cola a chave do serviço no
código para experimentar. A chave aqui é inventada e não abre nada; o hook não tem como saber, e nem
deveria tentar:

```
ana@vm:~/linkbox$ printf "EXPORT_KEY = \"kq83JdZ0p1Vx7LmN4tR6sW9yB2cF5hG8\"\n" > export.py
ana@vm:~/linkbox$ git add export.py
ana@vm:~/linkbox$ git commit -m "export the links to the reporting service"
Finding:     EXPORT_KEY = "REDACTED"
Secret:      REDACTED
RuleID:      generic-api-key
Entropy:     4.937500
File:        export.py
Line:        1
Fingerprint: export.py:generic-api-key:1

2:00AM INF 0 commits scanned.
2:00AM INF scanned ~48 bytes (48 bytes) in 202ms
2:00AM WRN leaks found: 1
ana@vm:~/linkbox$ git log --oneline -1
cecdf72 the rotated token, recorded as a dead finding
ana@vm:~/linkbox$ git restore --staged export.py && rm export.py
```

**O commit não foi feito.** `git log` ainda mostra o último commit antes dele, e o arquivo continua no
stage, intacto, esperando o autor decidir. A saída é a que o resto desta aula defende: a chave vai
para o ambiente, lida do jeito que `settings.py` agora lê `LINKBOX_TOKEN`, e o arquivo vai para o
stage de novo sem ela. Se a chave tivesse mesmo sido colada do console do serviço, ela ainda não saiu
do laptop, e nada nela precisa ser revogado.

### O que o hook não faz

**Um hook é uma conveniência para quem faz o commit, e não é um controle.** Três motivos, cada um um
fato sobre o Git e não sobre o gitleaks:

- Os hooks moram em `.git/hooks`, que não faz parte do repositório. Um clone não recebe nenhum deles,
  então cada desenvolvedor tem de instalá-lo em cada clone, e um colega novo começa sem ele.
- `git commit --no-verify` o pula, e também qualquer ferramenta que faça commits em nome de alguém.
- Ele lê só o que está no stage deste commit, neste laptop. Um segredo que chegou de outro jeito,
  num merge ou num branch de alguém sem o hook, nunca passa por ele.

Existem ferramentas que instalam e atualizam hooks para um time inteiro a partir de um arquivo no
repositório; o framework pre-commit é a mais comum em projetos Python. Elas resolvem o primeiro
motivo e nenhum dos outros dois. **O que é imposto roda no servidor**, onde ninguém consegue pular: o
estágio do pipeline da próxima seção, que lê o histórico inteiro a cada push. O hook só faz esse
estágio falhar menos vezes.

### Proteção de push em plataformas hospedadas

As plataformas hospedadas acrescentam uma camada entre as duas. A documentação do GitHub descreve a
proteção de push (push protection): num repositório onde ela está ligada, um push que contém um
segredo no formato de token de algum provedor que o GitHub conhece é recusado antes de entrar, e
quem faz o push vê qual segredo e onde. É possível passar por cima escolhendo um motivo, como valor
de teste ou falso positivo, e essa escolha fica registrada onde os administradores do repositório
podem vê-la. O GitLab documenta um recurso parecido com o nome de secret push protection.

Ela fica no servidor, então não é pulada por falta de hook, e recusa antes de o segredo chegar ao
repositório, o que o estágio do pipeline não consegue: quando um pipeline roda, o commit já foi
enviado. O limite dela é o formato do que reconhece. Ela procura os formatos de provedores
conhecidos, então um token inventado por você, como o token `lbx_` do linkbox, passa por ela a menos
que você acrescente um padrão próprio. **Nada disso foi executado neste curso**: precisa de um
repositório hospedado, e o laboratório é a sua própria máquina. As camadas que ela descreve estão
desenhadas abaixo, com o que cada uma enxerga.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"sp-l06-layers\" aria-label=\"Três lugares onde um segredo pode ser barrado, na ordem em que uma mudança passa por eles. O hook de pre-commit, no seu laptop, lê o que está no stage e é pulado por --no-verify ou por um clone sem ele. A proteção de push, numa plataforma hospedada, lê os commits enviados procurando formatos de token de provedores conhecidos; não foi executada neste curso. O estágio do pipeline, no servidor de CI, lê o histórico inteiro a cada push e não pode ser pulado.\"><defs><marker id=\"sp-l06-layers-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"200\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">hook de pre-commit</text><text x=\"120\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no seu laptop</text><text x=\"120\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">lê o que está no stage</text><text x=\"120\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pulado por --no-verify</text><rect x=\"260\" y=\"50\" width=\"200\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">proteção de push</text><text x=\"360\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">numa plataforma hospedada</text><text x=\"360\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">formatos de provedores</text><text x=\"360\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">não executada neste curso</text><rect x=\"500\" y=\"50\" width=\"200\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">estágio do pipeline</text><text x=\"600\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no servidor de CI</text><text x=\"600\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">lê o histórico inteiro</text><text x=\"600\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ninguém consegue pular</text><path d=\"M220 115 L258 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l06-layers-ah-paper-dim)\"></path><path d=\"M460 115 L498 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l06-layers-ah-paper-dim)\"></path><text x=\"120\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ao fazer commit</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ao fazer push</text><text x=\"600\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois do push</text></svg>", "caption": "Três lugares onde um segredo pode ser barrado. O último lê tudo e não pode ser pulado; os dois primeiros fazem com que ele falhe menos vezes."}
```
