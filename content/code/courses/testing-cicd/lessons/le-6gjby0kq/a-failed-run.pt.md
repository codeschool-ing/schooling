---
title: Uma execução que falhou, e o que parou
version: 1
---

Execuções verdes são fáceis de ler. A que vale ler é a vermelha. Em 18 de setembro de 2026, um pull
request que acrescentava aulas a outro curso deste catálogo rodou o mesmo workflow, e o registro
mostra o que aconteceu:

```
ana@laptop:~$ curl -s $A/runs/35315497063/jobs | jq -r ".jobs[] | [.name, .conclusion] | @tsv"
Changes	success
Go	failure
Browser	success
Infra	skipped
ana@laptop:~$ curl -s $A/runs/35315497063/jobs | jq -r ".jobs[] | select(.name == \"Go\") | .steps[] | select(.number >= 10 and .number <= 16) | [.number, .name, .conclusion] | @tsv"
10	The restore drill's question still runs	success
11	The catalogue is coherent	success
12	A student who read nothing cannot pass	failure
13	The interface speaks every language it claims to	skipped
14	Our stylesheets parse, and do not lay out their elements	skipped
15	Nothing the browser fetches leaves the origin	skipped
16	The tests, with a database behind them	skipped
```

**O job `Go` falhou e o job `Browser` deu certo.** Jobs são independentes: um falhar não para os
outros, a não ser que um tenha `needs` do que falhou. `Infra` foi pulado pelo job `Changes`, porque o
pull request não tocava infraestrutura.

Dentro do `Go`, os passos contam o resto. Os passos 10 e 11 passaram. **O passo 12, *A student who
read nothing cannot pass* (um aluno que não leu nada não passa), falhou**, e todo passo depois dele
foi pulado: a verificação da interface, a das folhas de estilo, a suíte de testes contra o banco. É a
regra da aula 5 seção 05, um passo que falha para o job, vista do lado do serviço.

## O que isso quer dizer para quem lê

O passo 12 é a verificação do repositório de que as respostas dos exercícios não podem ser
adivinhadas sem ler o material, o mesmo `check-exercises` pelo qual as questões deste curso tiveram
de passar. Então a execução vermelha diz algo preciso: as questões daquele pull request entregavam as
respostas. Não diz nada sobre o código Go, porque **os testes Go não rodaram**. Um job vermelho é uma
afirmação sobre o primeiro passo que falhou e uma ausência de informação sobre tudo depois dele.

Dois hábitos vêm daí:

- **Leia o primeiro passo que falhou, não o resumo do job.** "Go falhou" soa como um problema de Go;
  o passo diz que era um problema de conteúdo.
- **Ordene os passos do mais barato e mais provável de falhar ao mais caro.** Uma verificação de três
  segundos antes de uma suíte de dois minutos faz um erro de conteúdo custar três segundos de runner,
  não o job inteiro. Este repositório põe as verificações rápidas primeiro exatamente por isso.

## Quando a ordem não serve para você

Às vezes uma equipe quer que toda verificação rode mesmo depois de uma falhar, para ver todos os
problemas numa rodada. O GitHub Actions permite isso por passo com `if: always()` ou
`continue-on-error: true`, ao custo de uma execução mais longa que continua depois de já saber que a
resposta é não. Como o `fail-fast` das matrizes, é uma troca entre tempo de runner e informação, e a
escolha certa pode ser diferente para pull requests e para a `main`.
