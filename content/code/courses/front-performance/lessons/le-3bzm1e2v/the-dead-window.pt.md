---
title: A janela em que os cliques se perdem
version: 1
---

**Entre o momento em que uma página renderizada no servidor aparece e o momento em que o seu script a
assume, todo botão dela é a foto de um botão.** Um clique nessa janela chega a um elemento sem
listener, não faz nada, e é esquecido. Num notebook rápido a janela tem alguns milissegundos e
ninguém a encontra. Num celular lento ela tem segundos.

O `tools/hydrate.ts` consegue fazê-la ter segundos de propósito: `--script-delay 2000` segura todo
script por dois segundos, e `--click-at 300` clica em *Mark done* 300 milissegundos depois de a página
chegar, quando ela já está pintada e o script ainda está a caminho:

```
@@
```

**O clique aconteceu, e a sessão continua não feita.** A página tinha pintado muito antes, e o script
a assumiu uns dois segundos depois, então o clique caiu no meio. Nada na página dizia que ela não
estava pronta, e nada depois disse que um clique tinha se perdido.

```schooling-figure
@fig
```

## Três jeitos de fechá-la

**Encurtar a janela.** Menos JavaScript antes da hidratação, e um servidor perto da pessoa. Isso é o
assunto das aulas 7 e 8, e é a única correção que também ajuda todo o resto.

**Fazer a página dizer que não está pronta.** Um botão renderizado como `disabled` pelo servidor e
habilitado pelo script não pode ser apertado na janela, e só parece apertável quando é. Custa uma
piscada de controles acinzentados e diz a verdade.

**Gravar os cliques e repeti-los.** O Angular faz isso com o `withEventReplay()` do `app.config.ts` da
aula 2: um pequeno script embutido na página, antes de tudo, grava os eventos do documento inteiro, e a
hidratação os repete para os componentes que agora existem. A página que o Angular mandou na aula 2
traz esse script, `ng-event-dispatch-contract`. O React, a partir da versão 18, repete alguns eventos
que caem numa parte da página que ainda está hidratando. **Um formulário com um `action` de verdade é a
versão mais antiga da ideia**: um envio antes da hidratação ainda vai ao servidor, e funciona.

O planner tem um formulário, e o seu *Add session* mandaria um envio ao servidor se fosse apertado na
janela; o `server.ts` não tem tratador para isso, e a aula 1 disse. Os botões *Mark done* não têm
alternativa nenhuma.
