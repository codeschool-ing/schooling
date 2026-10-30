---
title: O watchdog, e a morte que não deixa relatório
version: 1
---

**O iOS não tem diálogo de "não está respondendo": ele encerra o app.** O sistema roda um
**watchdog** que vigia o tempo de abertura e quão responsivo um app está, e termina um que prende a
thread principal por tempo demais. *Lido na documentação da Apple sobre encerramentos pelo watchdog e
sobre relatórios de eventos jetsam, outubro de 2026; não rodado.*

## A assinatura do watchdog

O relatório de crash da Apple para esse encerramento leva o código **`0x8badf00d`**, lido, nas
palavras da própria Apple, *ate bad food*, no motivo do encerramento. A descrição diz o que o app
estava fazendo quando o tempo acabou: **`scene-create`** quer dizer que ele não desenhou o primeiro
quadro no tempo permitido, o que é uma abertura que demorou demais; `scene-update` quer dizer que um
app em uso parou de atualizar a interface.

A pilha do relatório mostra o que a thread principal fazia no momento do encerramento, e a
documentação da Apple avisa que isso pode enganar: um app com 5 segundos permitidos que gastou 4
numa tarefa e o último segundo em outra mostra a segunda tarefa na pilha. **A pilha nomeia a gota
d'água, e não o balde.**

## Jetsam: morto por memória

Quando falta memória num celular, o sistema primeiro pede aos apps que liberem um pouco, depois
encerra apps para recuperá-la. Isso é um **evento jetsam**. Ele deixa um **relatório de evento
jetsam**, que difere de um relatório de crash em três pontos que a Apple lista: descreve a memória de
**todos** os apps e processos do aparelho, é JSON, e **não tem as pilhas das threads do seu app**.

O Android tem o equivalente: o **low-memory killer** encerra apps em segundo plano, e às vezes o de
primeiro plano, sem exceção nenhuma lançada no seu código.

## Por que nenhum coletor de crashes o vê

Um coletor de crashes pega uma exceção ou um sinal e grava um relatório, lição 12. Uma morte pelo
watchdog e uma morte por memória mandam **`SIGKILL`**, o único sinal que nenhum processo consegue
pegar. Não existe momento em que o coletor consiga gravar alguma coisa. Então a evidência é indireta:

- **Os relatórios do próprio sistema**, o relatório de crash do watchdog e o de evento jetsam, que
  chegam ao App Store Connect e ao Organizer do Xcode vindos de quem compartilha diagnósticos.
- **O MetricKit** no iOS, que entrega ao app os diagnósticos do sistema na abertura seguinte,
  inclusive travamentos e encerramentos.
- **O `ApplicationExitInfo`** no Android, disponível desde o Android 11, que diz ao app na abertura
  seguinte por que o processo anterior terminou: um crash, um ANR, o low-memory killer, a pessoa
  arrastando o app para fora.
- **Um detector de travamento dentro do app**, que percebe uma thread principal congelada **antes**
  de o sistema matá-la, a partir de outra thread que ainda está rodando. A próxima seção monta um.
