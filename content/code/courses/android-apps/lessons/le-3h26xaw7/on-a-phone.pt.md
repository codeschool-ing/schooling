---
title: O que só um celular mostra
version: 1
---

**Tudo o que o estudante de fato vê de uma notificação é desenhado pelo sistema**, e este curso não
conseguiu mostrar: a máquina de gravação não tinha aparelho nem emulador, pelos motivos da seção 02
da aula 1. Esta seção diz o que procurar quando você rodar o planner no seu. **Não executado**: vem
da documentação do Google sobre notificações e sobre a permissão do Android 13, lida em 30 de outubro
de 2026.

## A caixa de diálogo da permissão

No Android 13 e posteriores, assim que a aula 20 pedir, o sistema mostra uma caixa com o nome do app e
dois botões, *Permitir* e *Não permitir*. O app não pode estilizá-la, reescrevê-la nem acrescentar um
botão. Se o estudante a dispensa tocando fora, nada é decidido e o app pode pedir de novo; a aula 20
trata do que acontece depois de duas recusas.

## A gaveta e a barra de status

Um lembrete postado aparece na gaveta de notificações com o nome do planner, o ícone pequeno, o título
e o texto. O ícone pequeno também aparece na barra de status no alto da tela, que é onde um ícone
colorido apareceria como um quadrado branco. Com `IMPORTANCE_DEFAULT` o celular toca o som de
notificação, a menos que o estudante o tenha no silencioso; ele não aparece por cima do app que o
estudante está usando.

## As configurações do canal

Pressionar e segurar a notificação, ou abrir as configurações de notificação do app, mostra o canal
com o nome e a descrição que a seção 03 lhe deu: *Study reminders*, *A nudge on days with a session
planned*. Dali o estudante pode silenciá-lo, desligá-lo ou deixá-lo aparecer por cima da tela.
**Esta é a tela onde conferir os nomes dos seus canais**, porque é o único lugar onde a maioria dos
estudantes chega a lê-los.

## Experimentando pelo terminal

Com um celular ou um emulador conectado, a documentação do Google lista comandos para inspecionar o
que o app postou e como estão os canais dele:

```sh
adb shell dumpsys notification --noredact
adb shell cmd notification list
```

E para conceder ou revogar a permissão sem a caixa de diálogo, que é como testes instrumentados e
conferências manuais chegam a cada um dos quatro celulares da seção 05:

```sh
adb shell pm grant com.example.planner android.permission.POST_NOTIFICATIONS
adb shell pm revoke com.example.planner android.permission.POST_NOTIFICATIONS
```

Nenhum dos quatro comandos foi executado para este curso, e por isso não há saída.

## Não Perturbe, e o estudante ocupado

Um celular em Não Perturbe guarda a notificação na gaveta e não faz som, seja qual for a importância
do canal, a menos que o estudante tenha liberado o app. **Esse é o comportamento certo para um
lembrete de estudo**, e nada no planner tenta contorná-lo: um lembrete que interrompe uma prova para
dizer que é hora de estudar entendeu errado o próprio trabalho.
