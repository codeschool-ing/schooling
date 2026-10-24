---
title: Rodando sem tela
version: 1
---

**Toda transcrição desta aula começou com `xvfb-run -a`**, porque o computador onde ela foi gravada não tem
tela. O **Xvfb** é um servidor X, o programa que desenha janelas no Linux, que guarda a tela na memória em
vez de num monitor. Uma janela aberta nele é desenhada, recebe cliques do Playwright, e nunca é vista. O
`xvfb-run` inicia um, roda o comando com a variável `DISPLAY` apontando para ele, e o para depois; o `-a`
escolhe um número de tela livre.

```sh
sudo apt install xvfb xauth
xvfb-run -a node desk.mjs
```

Num desktop você não precisa dele: `node desk.mjs` e `npm start` usam a tela para a qual você está
olhando. **Em integração contínua você precisa**, e esse é o motivo de esta seção existir: um runner do
GitHub Actions ou qualquer servidor de build também não tem tela, e um teste de um app Electron ali roda
exatamente como estas transcrições rodaram. Runners de Windows e macOS têm tela própria e não precisam de
nada.

Duas coisas sobre ele valem saber antes da primeira falha:

- **Sem tela, o Electron para na hora**, com um erro dizendo que não conseguiu abrir uma. Essa mensagem é
  o sinal para envolver o comando no `xvfb-run`.
- **Um Linux de desktop tem um barramento de sessão**, o D-Bus, com que o Electron e o Chromium conversam
  para notificações, energia e acessibilidade, e um servidor puro não tem. O Chromium imprime erros sobre
  isso e segue; a máquina deste curso roda um, como um desktop rodaria, então as transcrições não os têm.

O que o `xvfb-run` não consegue dar é a cara da coisa de verdade: a barra de título do gerenciador de
janelas, as fontes do sistema e a escala dele. **Um app desktop é conferido num desktop**, de cada sistema
para o qual ele é entregue, antes de um lançamento; o Xvfb é para as conferências que uma máquina consegue
repetir.
