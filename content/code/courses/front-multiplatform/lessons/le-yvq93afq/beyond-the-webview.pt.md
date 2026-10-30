---
title: O que nenhuma WebView alcança
version: 1
---

**Alguns limites não são de acabamento: são coisas que a WebView não consegue fazer de jeito nenhum**,
porque acontecem fora da tela do app, onde não há página. Os plugins levam a maioria delas para o lado
nativo, e algumas ficam fora do alcance de um app embrulhado sem trabalho nativo sério.

| o quê | onde acontece | num app Capacitor |
|---|---|---|
| um widget na tela inicial | um programa pequeno à parte que o sistema roda | código nativo, uma extensão do app, escrita em Swift ou Kotlin |
| um app de relógio, uma tela de carro | outro aparelho, outra interface | nativo, do zero |
| trabalho com o app fechado | o agendador de segundo plano do sistema | plugins para tarefas específicas, sob os limites rígidos do sistema |
| notificações push | os serviços de push da Apple e do Google | um plugin, mais contas e chaves nos dois |
| uma extensão de compartilhamento, um teclado | dentro de outro app | extensão nativa |
| Bluetooth, NFC, um aparelho USB | as interfaces de dispositivo do sistema | plugins da comunidade, de qualidade variada |
| listas muito compridas, animação pesada | a tela, sessenta vezes por segundo | possível na web, e mais difícil que no nativo |

**Leia a primeira coluna como perguntas sobre o seu app**, não sobre o Capacitor. Um planner de estudos
quer um lembrete, que a aula 4 deu a ele, e talvez queira um widget mostrando as sessões de hoje, que
ele não tem como ter sem escrever um em Swift e um em Kotlin. Qualquer um dos dois pode ser acrescentado
depois, como código nativo dentro dos projetos que a aula 3 abriu, e o resto do app continua web. **Esse
caminho do meio é real**: muitos apps são telas web numa casca nativa com algumas partes nativas, e a
decisão é por recurso, não para o app inteiro.

## O trabalho em segundo plano é o mais rígido

O navegador no seu bolso roda uma página enquanto você olha para ela. Um app de celular não pode rodar
quando ninguém olha: os dois sistemas suspendem um app em segundo plano em pouco tempo, e dão a ele só
jeitos específicos e limitados de trabalhar ali, uma tarefa agendada, uma atualização de localização,
um download que o sistema termina por ele. É por isso que o lembrete da aula 4 foi agendado com o sistema
e não com um temporizador na página. **Um desenho que precisa do app rodando, como um cronômetro que conta
uma sessão de estudo com a tela apagada, não sobrevive em nenhum dos dois sistemas**, a menos que seja
refeito em torno desses limites: o sistema guarda a notificação, e o app só calcula o tempo quando é
aberto de novo.
