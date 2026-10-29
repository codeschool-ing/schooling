---
title: O que faz de um site um app
version: 1
---

**Um Progressive Web App é um site que um navegador consegue instalar.** Instalado, ele ganha um ícone na tela
inicial ou na lista de aplicativos, abre numa janela própria sem barra de endereço, e continua funcionando
offline se o service worker dele disser como. Nada nele é compilado para uma plataforma: é o mesmo HTML, CSS e
JavaScript, do mesmo servidor, com o mesmo endereço.

Três coisas tornam um site instalável, e o planner já tem duas:

| o quê | por quê | o planner |
|---|---|---|
| **HTTPS**, ou `localhost` | um app instalado recebe a confiança de uma janela e de um ícone próprios | `localhost`, desde a aula 1 |
| **um service worker** | para o app abrir quando a rede não abre | desde a aula 10 |
| **um manifesto de web app** | o nome do app, os ícones, a janela que ele quer e a página onde começa | a próxima seção |

**As versões recentes do Chromium não exigem mais o service worker** para instalar; um manifesto com um nome e um
ícone basta. Um app instalado que mostra o erro offline do navegador é um app ruim, porém, e por isso a aula 10
veio antes.

## Que navegadores instalam

O **Chrome** e o **Edge**, no desktop e no Android, instalam pela barra de endereço ou pelo menu, e disparam um
evento que uma página pode usar para oferecer a instalação ela mesma. O **Safari** no iOS e no iPadOS instala pelo
menu de compartilhar, *Adicionar à Tela de Início*, e no macOS por *Adicionar ao Dock*; ele não dispara esse evento,
então uma página só pode explicar como. O **Firefox** no Android adiciona um site à tela inicial; no desktop o
suporte já veio e já foi, então confira a versão que você tem em mãos. Um site que funciona como app funciona em
todos eles como site, e esse é o *progressivo* do nome.

**O que instalar não faz** é pôr o app numa loja, dar a ele mais acesso ao aparelho do que o site tinha, ou deixá-lo
mais rápido. A velocidade é das dez aulas anteriores; instalar é como uma pessoa o mantém à mão.
