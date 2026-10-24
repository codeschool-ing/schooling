---
title: A WebView que o sistema já tem
version: 1
---

**O Tauri faz o mesmo tipo de app que o Electron, uma janela de desktop com o seu app web dentro, a partir
de duas peças diferentes.** Onde o Electron leva o próprio Chromium, o Tauri usa a WebView que o sistema
operacional já tem. Onde o processo principal do Electron é Node.js, o núcleo do Tauri é um programa escrito
em Rust, compilado para cada sistema.

| | Electron | Tauri |
|---|---|---|
| o motor que desenha a página | o próprio Chromium, em todo app | o do sistema: WebView2 no Windows, WebKit no macOS, WebKitGTK no Linux |
| a parte que pode mexer no computador | o processo principal, em Node.js | o núcleo, em Rust |
| a porta entre os dois | o preload e o IPC | comandos, chamados com `invoke` |
| o que a pessoa baixa | o app mais um navegador e um runtime | o app, e um programa nativo pequeno |

**O que a WebView do sistema compra é tamanho e memória**: não há navegador no download, e o sistema
operacional mantém a WebView atualizada, correções de segurança incluídas, que era a última linha do
checklist da aula 11. **O que ela custa é a uniformidade.** O WebView2 é Chromium, o WebKit do Mac é o
motor do Safari, e o WebKitGTK é outro build do WebKit, então o planner roda em três motores, de três
idades, como um site roda. Um recurso de CSS ou uma API web que funciona em um pode não funcionar em outro,
e o app precisa ser testado em cada sistema para o qual é distribuído.

O outro custo é o Rust. **O código do planner continua TypeScript**, e a maioria dos apps Tauri só precisa
de algumas linhas de Rust, para os comandos que a página chama. Mas essas linhas são Rust, compiladas pelas
ferramentas do Rust, que a próxima seção instala, e um erro nelas é um erro do compilador do Rust. O Tauri 2
também gera apps para Android e iOS, com o mesmo núcleo; este curso o usa só no desktop, porque as aulas 2 a
6 já levaram o planner ao celular com o Capacitor.
