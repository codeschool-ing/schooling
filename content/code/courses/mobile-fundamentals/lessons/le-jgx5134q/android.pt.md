---
title: Android: seis callbacks, e o processo por trás deles
version: 1
---

**No Android o ciclo de vida pertence a uma Activity, um pedaço do app do tamanho de uma tela, e o
sistema chama seis métodos nela conforme ela muda de estado.** A referência de Activity lista todos,
e cada um é o sistema avisando ao app que algo já aconteceu ou está para acontecer:

| callback | o que quer dizer | o estado neste curso |
|---|---|---|
| `onCreate` | a Activity está sendo construída; ela recebe o estado salvo antes, se houver | não rodando → começando |
| `onStart` | ela está ficando visível | começando |
| `onResume` | ela está na frente e recebe os toques do usuário | **ativo** |
| `onPause` | ela perdeu o primeiro plano; ainda visível, talvez em parte | **inativo** |
| `onStop` | ela não está mais visível | **em segundo plano** |
| `onDestroy` | a Activity está para ser destruída | terminando, ou sendo reconstruída |

Voltar do segundo plano acrescenta um sétimo, `onRestart`, antes de `onStart` e `onResume`.

## A coluna que mais importa

**A referência de Activity marca três desses métodos como "killable": depois que `onPause`, `onStop`
ou `onDestroy` retorna, o processo pode ser morto a qualquer momento sem que mais nenhuma linha do
código dele seja executada.** Essa frase é o lado Android inteiro desta aula. Uma Activity parada é
avisada de que parou, e depois pode simplesmente deixar de existir. A referência diz de `onStop` que
em seguida o app vai receber `onRestart`, `onDestroy` "ou nada", e diz de `onDestroy` que há situações
em que o sistema mata o processo hospedeiro sem chamá-lo, nem a nenhum outro.

**`onDestroy`, portanto, não é uma despedida.** Ele roda quando o usuário encerra a Activity, por
exemplo voltando dela, e quando o sistema a reconstrói por uma mudança de configuração, como girar o
celular. Ele não roda quando o processo é morto para liberar memória, que é o caso que perde o
trabalho do usuário.

## Processo, não Activity

**O sistema mata processos, não telas.** O guia do ciclo de vida da Activity diz isso com todas as
letras: o sistema nunca mata uma Activity diretamente para liberar memória; ele mata o processo em
que ela roda, destruindo não só a Activity mas tudo o mais que roda naquele processo. Tudo o que está
na memória vai junto: as variáveis, o texto meio digitado, a lista que veio da rede.

A probabilidade disso depende do estado do processo, e o mesmo guia dá a ordem:

| estado do processo | a Activity nele | probabilidade de ser morto |
|---|---|---|
| primeiro plano | resumed | a menor |
| visível, sem foco | started ou paused | baixa |
| segundo plano, invisível | stopped | maior |
| vazio | destroyed | a maior |

**O app parado em segundo plano é a vítima comum.** O guia de processos do Android chama de processo
em cache um processo que não é necessário no momento, diz que o sistema fica livre para matá-lo
quando recursos como memória são necessários em outro lugar, e que um sistema funcionando bem mata
regularmente os apps em cache. Este curso chama esse estado de suspenso: na memória, sem fazer nada,
e o próximo da fila.

## O que o guia diz sobre salvar

**`onPause` é curto demais para salvar, e `onStop` é onde vai o trabalho pesado.** O guia do ciclo de
vida diz que a execução de `onPause` é muito breve e não oferece necessariamente tempo suficiente
para operações de salvamento, e manda não usá-lo para salvar dados do usuário, fazer chamadas de rede
ou rodar transações de banco; ele aponta `onStop` para operações de encerramento que usam
relativamente mais CPU. Então, no Android, o último momento confiável é `onStop`, e a etapa depois da
próxima transforma isso numa regra.

O curso de Kotlin depois da bifurcação, `android-apps`, coloca esses callbacks num app de verdade na
aula 2, se você seguir esse caminho. Aqui eles continuam sendo nomes, e o programa desta aula os
imprime.
