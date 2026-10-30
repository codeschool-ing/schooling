---
title: Escolhendo uma porta
version: 1
---

**Cada porta é melhor num tipo de trabalho, e uma empresa que usa cada uma para o seu tipo tem menos surpresas.** A
API por baixo delas é a mesma; o que difere é o que cada uma deixa para trás.

| porta | melhor para | o que deixa para trás |
|---|---|---|
| **o console** | olhar: explorar um serviço, ler um recurso, achar a configuração de que ninguém se lembra | nada além do log de auditoria |
| **o gcloud** | fazer uma coisa agora: um passo de runbook, uma consulta, um script que roda uma vez | uma linha no histórico do shell, e o log de auditoria |
| **o Terraform** | tudo o que deve continuar existindo amanhã | arquivos num repositório, revisados, e um estado que sabe o que fez |
| **uma biblioteca cliente** | um programa que age sozinho, lição 24 | o próprio código do programa |

A regra do planner sai da última coluna: **um recurso que importa é declarado**, para poder ser revisado antes de
existir, recriado depois de perdido, e comparado com o que existe, lições 25 e 26. O gcloud e o console continuam
sendo as ferramentas para ler, para incidentes e para experimentos no sandbox, e um experimento que acaba
importando é escrito no Terraform antes de alguém depender dele.

## Este curso, porta por porta

O curso usou as quatro, e a ordem em que as usou é a ordem em que elas se aprendem:

- o **gcloud** desde a lição 1, contra o emulador e contra as recusas do Google, para tudo o que podia ser rodado;
- o **Terraform** desde a lição 2, planejado contra as APIs do Google sem perguntar nada a elas, e aplicado de
  verdade só contra o emulador, nas lições 25 e 26;
- **a própria API**, com `curl`, nas lições 24 e 26, e o documento de discovery dela, na lição 25;
- **o console**, nunca na tela, porque as telas mudam e os pedidos por baixo delas não; toda lição que teria
  mostrado um mostra o pedido no lugar.

**O que o curso não pôde fazer é o passo que exige uma conta**, e a seção sobre uma conta real da lição 1 é onde ele
começa: autenticação de dois fatores primeiro, um orçamento antes do primeiro recurso, a árvore do planner, e todo
arquivo que este curso planejou, aplicado de verdade, uma lição de cada vez.
