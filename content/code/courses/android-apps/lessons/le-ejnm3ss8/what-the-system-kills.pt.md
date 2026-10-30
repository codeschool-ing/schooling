---
title: O que o sistema ainda decide
version: 1
---

**O WorkManager garante que o trabalho roda; o Android decide quando, e num celular de verdade isso
pode ser bem mais tarde do que um teste sugere.** Tudo nas seções 03 a 06 rodou num teste em que o
test driver dizia "agora". Num celular quem diz é o sistema, e ele pesa o seu planner contra a
bateria, todos os outros apps e o que o estudante está fazendo. Esta seção descreve como isso fica.

**Não executado.** Nada do que segue foi observado para este curso: precisa de um celular ou de um
emulador, e a seção 02 da aula 1 diz por que a máquina de gravação não tinha nenhum dos dois. Vem da
documentação do Google para o WorkManager e para o gerenciamento de energia do Android, lida em 30 de
outubro de 2026.

## Atrasos que você não controla

- **Doze.** Um celular parado, fora da tomada e com a tela apagada entra em Doze depois de um tempo,
  e o trabalho de fundo espera por janelas curtas de manutenção, cada vez mais espaçadas quanto mais
  tempo ele fica parado. A sua sincronização de seis horas pode rodar horas atrasada durante a noite.
  Esse é o objetivo do Doze, e o motivo de o WorkManager existir é que ele espera do jeito certo, em
  vez de não rodar.
- **Grupos de espera de apps** (*app standby buckets*). O Android ordena os apps por quão recente e
  frequentemente o estudante os usa, de *ativo* a *raramente usado*, e dá a cada grupo uma cota
  diferente de trabalho de fundo. Um app que o estudante abre todo dia roda os jobs perto do horário;
  um que ele não abre há semanas pode esperar um dia.
- **A economia de bateria**, quando o estudante a liga, restringe ainda mais o trabalho de fundo, e o
  `setRequiresBatteryNotLow` soma a contenção do próprio planner por cima.

## Mortes a que o WorkManager sobrevive, e a única a que não

| o que acontece | o que o WorkManager faz |
|---|---|
| o sistema encerra o processo para liberar memória | o pedido está no banco; o sistema reinicia o trabalho quando ele fica apto |
| o estudante arrasta o app para fora dos recentes | o mesmo: o processo acaba, o pedido fica |
| o celular reinicia | o receiver de boot, o `RECEIVE_BOOT_COMPLETED` da seção 06, reagenda tudo |
| **o estudante aperta Forçar parada nas configurações do app** | **todo job é cancelado e nada roda até o estudante abrir o app de novo** |

Forçar parada é o estudante dizendo "este app não pode fazer nada até eu abri-lo", e o Android
respeita isso por completo. É também o que os gerenciadores de bateria de alguns fabricantes fazem com
os apps por iniciativa própria, e é por isso que uma sincronização pode parar num celular de uma marca
e funcionar no de outra. Não há nada no código que passe por cima disso, e nem deveria haver.

## Vendo num aparelho

Num celular com as opções de desenvolvedor, a documentação do Google mostra como ver o que o WorkManager pediu ao sistema. `adb shell dumpsys jobscheduler` lista os jobs do app com as suas restrições, e o **Background Task Inspector** do Android Studio mostra cada pedido, o estado e a
cadeia. Para provocar o Doze sem esperar, `adb shell dumpsys deviceidle force-idle` põe um celular
conectado nele na hora. **Não executado**, como o resto desta seção.

## O que levar disto

Escreva os workers como se eles fossem rodar atrasados, mais de uma vez, e às vezes depois de o
estudante mudar os dados. É a mesma disciplina que `mobile-offline`, o curso depois deste, transforma
num desenho inteiro: a aula 8 dele põe as operações numa caixa de saída e a aula 10 torna inofensivo
enviar uma duas vezes. Um worker que envia "tudo o que ainda não foi enviado", e não "a sessão
acrescentada às 09:14", já está quase lá.
