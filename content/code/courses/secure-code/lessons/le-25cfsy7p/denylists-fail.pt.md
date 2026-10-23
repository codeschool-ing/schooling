---
title: Por que uma lista de valores ruins falha
version: 1
---

O primeiro instinto quando um campo preocupa alguém é escrever o que não pode estar nele: nada de
sinais de menor e maior, nada de ponto e vírgula, nada de hífen duplo. Essa lista é uma **lista de
bloqueio** (*denylist*), e ela falha por um motivo que não tem nada a ver com o cuidado de quem a
escreveu. **Ela precisa conhecer de antemão todo valor ruim, e a entrada que ela encontra foi
escrita por gente que não a leu.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l02-sets\" aria-label=\"Duas maneiras de decidir o que um campo aceita, desenhadas como regiões de toda entrada possível. À esquerda, uma lista de bloqueio: tudo é aceito menos alguns valores ruins listados, então o que ninguém previu passa, inclusive uma data impossível e uma clínica que não existe. À direita, uma lista de permissão: nada é aceito além de uma pequena região descrita, as quatro clínicas, datas reais, horário de funcionamento, então o que ninguém previu é recusado.\"><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">lista de bloqueio</text><rect x=\"20\" y=\"40\" width=\"320\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"180\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">toda entrada possível</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">lista de permissão</text><rect x=\"380\" y=\"40\" width=\"320\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"540\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">toda entrada possível</text><rect x=\"40\" y=\"80\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">os valores que alguém listou</text><text x=\"180\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">aceito: todo o resto,</text><text x=\"180\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">inclusive o imprevisto</text><rect x=\"460\" y=\"90\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"112.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o que está descrito:</text><text x=\"540.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">quatro clínicas, datas reais,</text><text x=\"540.0\" y=\"137.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">horário de funcionamento</text><text x=\"540\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">recusado: todo o resto</text></svg>", "caption": "Uma lista de bloqueio precisa conhecer de antemão todo valor ruim. Uma lista de permissão só precisa conhecer os bons, e eles são bem menos."}
```

O formulário de agendamento da Vereda tem quatro campos: a clínica, a data, o horário e o telefone
do paciente. Uma lista de bloqueio nos quatro, a que a ana herdou, recusa `<`, `>`, `;` e `--`. Eis o
que ela deixa passar, cada item um problema real e nenhum com caractere proibido:

| campo | aceito pela lista de bloqueio | por que está errado |
|---|---|---|
| clínica | `Moema`, `paulista` | as clínicas são escritas em minúsculas, e não existe clínica na Paulista |
| data | `2026-11-31` | novembro tem 30 dias |
| horário | `23:00` | as clínicas fecham às oito da noite |
| telefone | `1198765`, ou nenhum telefone | um telefone em São Paulo tem 10 ou 11 dígitos, e o lembrete precisa de um |

Nada disso é ataque. É o que as pessoas digitam, e o que outros programas enviam, numa terça-feira
qualquer. **Um campo que aceita isso guarda dados que o resto do sistema não consegue usar**: um
lembrete mandado para sete dígitos, um agendamento num dia que não existe, uma tela de agenda que
quebra numa clínica para a qual não tem cor. Algumas falhas mais adiante neste curso começam
exatamente aí, com código mais à frente que supôs que o valor tinha sido verificado.

### A lista trata da coisa errada

Uma lista de bloqueio também responde a uma pergunta que ninguém deveria fazer na entrada. `<` é
perigoso dentro de HTML e inofensivo num campo de telefone que nunca é exibido como HTML; `--`
importa em SQL e não numa data. **Se um caractere é perigoso depende de para onde o valor vai em
seguida**, e a entrada não sabe disso. A aula 4 cuida do lado da saída, onde o contexto é conhecido,
e a aula 5 do lado do banco. Na entrada, a pergunta útil é outra: isto é uma clínica válida, uma
data real, um horário de funcionamento, um número de telefone?

### Quando uma lista de bloqueio ainda está certa

Uma lista de bloqueio curta tem lugar **por cima** de uma verificação que já descreve o que é bom.
Um campo de senha aceita quase tudo por definição, então a verificação útil ali é uma lista de
senhas que já vazaram, que a aula 11 monta. É a lista de bloqueio fazendo o único trabalho que ela
sabe fazer: recusar valores conhecidos dentro de um espaço que, fora isso, é aberto. Como única
verificação de um campo que tem forma, é a ferramenta errada.
