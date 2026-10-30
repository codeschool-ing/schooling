---
title: Standard ou Autopilot
version: 1
---

A orientação do próprio Google é começar no Autopilot a menos que algo o descarte, e é um padrão
razoável. **A versão útil da pergunta não é qual é melhor, mas quais das suas cargas o Autopilot
recusaria ou cobraria caro demais.** Se nenhuma, o Autopilot remove uma categoria inteira de
trabalho; se algumas, a resposta pode ser um cluster de cada.

## As perguntas, em ordem

1. **Algo precisa do que a seção 04 recusa?** Um agente privilegiado, um caminho do host, um módulo
   de kernel próprio, SSH para depurar. Se sim, essa carga precisa do Standard, seja qual for o
   preço.
2. **Quão cheios ficariam os nós do Standard?** Rode o `autopilot.py` com os formatos reais dos
   pods. Se os nós ficariam bem cheios o dia inteiro, o Standard sai mais barato pela margem que a
   seção 03 mostrou.
3. **A carga é irregular?** Um cluster ocupado de dia e quase vazio à noite paga por nós vazios no
   Standard, a menos que o autoscaling seja bem ajustado, e não paga nada no Autopilot.
4. **Quem cuidaria dos nós?** Estratégias de atualização, tamanhos de pool, tipos de máquina e
   segurança dos nós são um trabalho recorrente. Uma equipe de duas pessoas que prefere não tê-lo
   tem um motivo para o Autopilot que nenhuma comparação de preço mostra.

## A resposta da loja

| carga | o que decide | onde |
|---|---|---|
| `web`, `orders` | pequenas, irregulares, nada privilegiado | Autopilot |
| redimensionamento de `photos` | lote interrompível | Autopilot, pods Spot |
| um agente de logs que precisa de caminhos do host | recusado pelo Autopilot | Standard, ou o registro de logs da própria plataforma |

Para a loja, a última linha se resolve sozinha: o GKE já manda os logs para o Cloud Logging, que o
`gcp-operations` cobre, então o agente que precisava de caminhos do host nem é necessário. Um
cluster Autopilot carrega tudo, por uma taxa de cluster.

## Mudando de ideia

O modo de um cluster é fixado quando ele é criado: não dá para converter um cluster Standard em
Autopilot nem o contrário. Mudar quer dizer criar o outro tipo e publicar de novo nele, que é o
mesmo trabalho de qualquer migração de cluster e o motivo de responder às quatro perguntas antes
de a primeira carga de produção chegar, e não depois. Os objetos do Kubernetes em si quase sempre
passam sem mudança, exceto o que a seção 04 recusa, então o custo da mudança é a migração, não uma
reescrita.
