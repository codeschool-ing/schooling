---
title: O enunciado: o seu app, em mais uma plataforma
version: 1
---

**O projeto é um app web seu, transformado num app para uma plataforma, lançado, e mostrado no seu
portfólio.** Não o planner: o planner era do curso, e cada passo dele já está nestas aulas. O seu é um app web que
você escreveu, em qualquer framework ou em nenhum, de um curso anterior ou do seu próprio trabalho. Se você não tem
nenhum que mostraria, o planner vale como ponto de partida, desde que o app que você lançar faça algo que o do curso
não fazia.

## O que você entrega

| parte | o que é |
|---|---|
| **uma nota de decisão** | uma página: que caminho você seguiu, e por quê, nos termos da aula 10 |
| **o app**, numa plataforma | um pacote Android, um pacote de desktop, ou os dois, gerados de um commit com tag |
| **um recurso do aparelho** | pelo menos uma coisa que um site não consegue fazer: um arquivo, uma notificação, a câmera, o menu da janela |
| **um release** | os pacotes, o `SHA256SUMS`, a assinatura dele e a sua chave pública, e notas de release |
| **uma versão que muda** | pelo menos dois releases, para o segundo mostrar que os números e o caminho de atualização funcionam |
| **o repositório** | o código, sem nenhuma chave nele e com um README que diz como gerar e como instalar |

**O caminho é escolha sua**, e a nota de decisão é onde você escolhe. A aula 10 terminou nisso: os motivos importam
mais que a escolha. Uma boa nota cabe numa página e responde a quatro perguntas:

```
# Decision: how my app reaches <the platform>

## What the app is
One paragraph: what it does, who it is for, and what it runs on today.

## What the platform has to add
The device features or the desktop features the app needs that a browser does not give it.

## The route
Capacitor, React Native, Electron or Tauri, and the one or two you did not take.

## Why
What the route reuses of the code you have, what it costs, and who will maintain it.
What you would need to see to change your mind.
```

**O que "lançado" quer dizer depende do caminho, e nada disso precisa de loja.** Um APK Android assinado com a sua
própria chave, oferecido como download, é um release; um AppImage e um `.deb` no seu site também. As lojas são
opcionais, custam dinheiro, e a aula 14 disse o que cada uma pede. Se você publicar numa, diga isso no README com um
link; se não, diga como uma pessoa instala o arquivo.

**O que o seu computador não consegue rodar é dito, não escondido.** Um build iOS sem Mac, um instalador Windows sem
Windows: a nota diz em que plataformas você gerou e testou, e em quais não, exatamente como este curso marcou cada
passo que não conseguiu executar.
