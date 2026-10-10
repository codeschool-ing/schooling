---
title: A pessoa cujo trabalho é anotar
version: 1
---

Dos quatro papéis de incidente da aula 13, o escriba é o que os times pulam, porque parece o menos importante: todos os outros estão fazendo alguma coisa. É o papel cuja ausência é notada mais tarde e mais lamentada, na semana seguinte, quando o postmortem tenta reconstruir o que aconteceu a partir da memória e do histórico do chat e erra a ordem.

## O que o escriba escreve

**Uma linha por evento, com o horário**, no canal do incidente ou num documento compartilhado, enquanto acontece:

- **observações**: "17:44 Rafa encontra mais 11 cobranças duplicadas";
- **decisões**, com quem as tomou: "18:02 Bia decide fazer rollback do D047";
- **ações**, quando começam e terminam: "18:04 rollback iniciado", "18:15 rollback concluído";
- **mudanças de estado**: severidade elevada, papéis trocados, página de status atualizada.

Fatos, não interpretações. "18:02 a lógica de nova tentativa está quebrada" é um chute escrito como se fosse sabido; "18:02 Rafa suspeita do BIL-218, a mudança da nova tentativa" é um fato sobre o que alguém pensou, e continua verdadeiro mesmo que o chute se revele errado.

## Pequenas regras que salvam um postmortem

- **Um relógio só.** Todo horário no mesmo fuso, escrito do mesmo jeito. Uma linha do tempo que mistura UTC dos logs com horário local do chat é uma linha do tempo em que dois eventos trocam de lugar.
- **Escreva na hora, não depois.** Uma linha escrita dez minutos depois fica com o horário errado, ou sem horário, e um postmortem construído sobre ela vai discutir a ordem.
- **Marque o tipo de evento.** Uma palavra curta no começo, *detect*, *declare*, *decide*, *restore*, *resolve*, deixa um programa, ou uma pessoa cansada, achar os momentos que importam. A próxima seção usa exatamente isso.
- **Registre o que foi tentado e não funcionou.** Uma correção que falhou é tão importante para o postmortem quanto a que funcionou, e é a primeira coisa que todo mundo esquece.

## Por que é um papel e não um hábito

Todo mundo concorda que alguém deveria anotar, e no meio de um incidente todo mundo supõe que outra pessoa está anotando. Nomear um escriba faz disso o trabalho de uma pessoa, e o trabalho é real: um incidente com uma boa linha do tempo ganha um postmortem em uma hora, e um sem ela ganha um postmortem que gasta essa hora discutindo o que aconteceu quando. É também **um excelente primeiro papel para quem é novo em incidentes**: a pessoa vê a resposta inteira, aprende como as decisões são tomadas e contribui com algo para o qual ninguém mais tem tempo.
