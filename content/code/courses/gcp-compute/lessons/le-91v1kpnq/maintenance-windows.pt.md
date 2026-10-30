---
title: Janelas de manutenção e exclusões
version: 1
---

Um canal de lançamento decide **quais** versões chegam. Uma política de manutenção decide
**quando** o GKE pode aplicá-las. Sem ela, a manutenção automática pode começar a qualquer hora, e
a noite mais movimentada da loja serve tanto quanto qualquer outra. **Uma janela diz quando a
manutenção pode acontecer; uma exclusão diz quando ela não pode.**

## A janela recorrente

O cluster da loja na seção 02 já tem uma:

```
ana@laptop:~/gcp/gke$ terraform plan -no-color | grep -E 'start_time|end_time|recurrence|exclusion_name|\+ scope'
              + end_time       = "2026-12-02T00:00:00Z"
              + exclusion_name = "black-friday"
              + start_time     = "2026-11-25T00:00:00Z"
                  + scope             = "NO_UPGRADES"
              + end_time   = "2026-11-07T11:00:00Z"
              + recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
              + start_time = "2026-11-07T05:00:00Z"
```

As três strings seguem padrões, não um formato do Google. `start_time` e `end_time` são
timestamps em UTC, e numa janela recorrente só importam a hora do dia e a duração: aqui, seis
horas a partir das 05:00. `recurrence` é uma RRULE do padrão iCalendar, a mesma sintaxe de um
convite de calendário: semanal, aos sábados e domingos.

**Os horários são UTC, e a loja não é.** Pergunte ao seu próprio computador quanto são 05:00 UTC
do primeiro sábado em São Paulo:

```
ana@laptop:~/gcp/gke$ TZ=America/Sao_Paulo date -d 2026-11-07T05:00:00Z
Sat Nov  7 02:00:00 -03 2026
ana@laptop:~/gcp/gke$ TZ=America/Sao_Paulo date -d 2026-11-07T11:00:00Z
Sat Nov  7 08:00:00 -03 2026
```

Das duas às oito da manhã, hora local, e é essa a ideia: a janela foi escolhida para quando os
clientes da loja estão dormindo, e escrevê-la em UTC sem converter é o jeito mais comum de pôr
manutenção no meio da noite de alguém.

O Google exige que uma janela deixe espaço para a manutenção: a documentação pede pelo menos 48
horas de disponibilidade em qualquer período de 32 dias, em trechos de pelo menos quatro horas.
**Quaisquer 32 dias contêm pelo menos oito dias de fim de semana, e oito dias de seis horas dão
exatamente 48.** Janelas de quatro horas nos mesmos dias dariam 32 horas e seriam recusadas. Essa
regra é verificada quando o cluster é criado ou atualizado, não pelo plan; o laboratório não
consegue dizer que uma janela é curta demais.

## Exclusões

Uma exclusão é um período com nome, início e fim, durante o qual um tipo declarado de atualização
não acontece, mesmo dentro da janela. A loja tem uma para a semana da Black Friday. O `scope` diz
quanto fica retido:

| scope | o que fica retido |
|---|---|
| `NO_UPGRADES` | toda atualização, plano de controle e nós; o Google limita quanto tempo essa exclusão pode durar |
| `NO_MINOR_UPGRADES` | a passagem para uma versão menor nova; as correções continuam chegando |
| `NO_MINOR_OR_NODE_UPGRADES` | versões menores em qualquer parte, e qualquer mudança nos nós |

Os escopos mais estreitos podem durar muito mais que o `NO_UPGRADES`, até o fim do suporte da
versão, o que os torna a ferramenta para "nada muda nos nós durante a migração", e não para uma
semana movimentada.

## O que uma janela não segura

Duas coisas passam de qualquer jeito, e a documentação do Google as lista: **correções de segurança
que ele considera urgentes**, e **o fim do suporte de uma versão**. Um cluster ainda numa versão
cujo suporte acabou é atualizado esteja ou não aberta uma janela ou exclusão. Uma exclusão é um
jeito de escolher o momento, não de ficar parado, e um cluster cujas exclusões vivem sendo renovadas
é um cluster acumulando uma atualização grande para depois.
