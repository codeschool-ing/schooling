---
title: Jobs pulados e verificações obrigatórias
version: 1
---

Um pull request de 19 de setembro de 2026 mudou conteúdo de curso e mais nada, e a execução dele fica
assim:

```
ana@laptop:~$ curl -s $A/runs/35432460022 | jq -r "[.event, .head_branch, .conclusion] | @tsv"
pull_request	claude/wonderful-cray-nrgjb2	success
ana@laptop:~$ curl -s $A/runs/35432460022/jobs | jq -r ".jobs[] | [.name, .conclusion] | @tsv"
Changes	success
Browser	success
Go	success
Infra	skipped
```

`Infra` foi **pulado**, e a execução como um todo é um **sucesso**. Essa combinação é proposital, e é o
que torna seguro exigir as verificações.

## Exigindo uma verificação

Um repositório pode marcar verificações como **obrigatórias**: um pull request não entra enquanto cada
verificação nomeada não relatar sucesso. No GitHub isso é uma regra de proteção de branch ou um
ruleset na `main`, definido nas configurações do repositório; no GitLab é a configuração de merge
request que exige pipelines bem-sucedidos. É o que transforma o hábito da aula 5 seção 11, conferir
antes do merge, em algo que a plataforma impõe.

Verificações obrigatórias têm uma armadilha, e o workflow deste repositório a explica num comentário
acima do job `Changes`. Uma verificação é satisfeita por um relato de sucesso, **ou de skipped**. Mas
um workflow inteiro que nunca começa não manda relato nenhum, e uma verificação obrigatória sem relato
deixa o pull request esperando para sempre. Então:

| como um job é evitado | o que a verificação relata | com a verificação obrigatória |
|---|---|---|
| `if:` no job, decidido na execução | skipped | o pull request pode entrar |
| `paths:` no gatilho do workflow | nada, o workflow nunca rodou | o pull request espera para sempre |

Por isso este repositório roda o workflow em todo pull request e deixa um primeiro job decidir o que
pular. Um filtro de caminhos no gatilho seria menos YAML e um botão de merge que nunca fica verde no
dia em que alguém muda só documentação.

## Pulado não é aprovado

Uma verificação pulada satisfaz uma exigência, e isso é uma decisão que alguém tomou sobre **quais
verificações uma mudança pode afetar**. Se a decisão estiver errada, uma mudança passa sem teste e a
execução fica verde. O job `Changes` deste repositório erra para o lado de rodar: um push na `main`,
um release e qualquer diff que ele não consiga calcular rodam tudo. É o mesmo princípio do teste de
contrato pulado da aula 2: **pulado é uma afirmação sobre o que não aconteceu**, e alguém deveria
conseguir dizer por que era certo que não acontecesse.
