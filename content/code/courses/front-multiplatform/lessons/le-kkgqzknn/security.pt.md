---
title: Segurança, que é quase só não desfazer os padrões
version: 1
---

**Um app Electron roda com as permissões da pessoa no computador dela, e as páginas dele desenham
conteúdo.** Se algo que não é o seu código chegar a rodar num renderizador, por um script injetado, uma
biblioteca comprometida ou uma página carregada da rede, o que isso alcança é decidido pelas configurações
no `main.mjs`. É por isso que o guia de segurança do próprio Electron é uma lista de conferência, e a maior
parte dela é manter o que o Electron já faz.

Pergunte à janela do planner o que um script nela alcança:

```
ana@dev:~/planner$ xvfb-run -a node desk.mjs --eval 'typeof require' --eval 'typeof process' --eval 'Object.keys(window.desktop)' --eval 'window.desktop.exportPlan(123)' | head -n 4
typeof require = undefined
typeof process = undefined
Object.keys(window.desktop) = exportPlan
window.desktop.exportPlan(123) = page.evaluate: Error: Error invoking remote method 'export-plan': Error: not a plan
```

- **`require` e `process` são indefinidos**: não há Node.js na página. Isso é `nodeIntegration: false` e
  `sandbox: true` juntos; o sandbox também limita o que o processo renderizador pode fazer no sistema
  operacional, como o Chromium limita uma aba de navegador.
- **`window.desktop` tem uma função**, e a página não tem mais nada do Electron. Isso é
  `contextIsolation: true`: as variáveis do próprio preload, e o `ipcRenderer` do Electron, moram num mundo
  que a página não vê, então uma página não consegue chamar `ipcRenderer.invoke` com um nome de canal
  escolhido por ela.
- **O processo principal conferiu o que recebeu.** O `exportPlan(123)` foi recusado com o erro do próprio
  processo principal, `not a plan`. Todo `ipcMain.handle` é uma porta de entrada para um programa com as
  permissões da pessoa, e ele valida os argumentos como um servidor web valida um pedido.

## O resto da lista

Do guia de segurança do Electron, os itens que importam para um app como o planner:

| faça | porque |
|---|---|
| carregue só os seus arquivos, de um esquema próprio | uma página remota numa janela com preload é o código de outra pessoa ao lado da sua porta |
| mantenha o `nodeIntegration` desligado, o `contextIsolation` e o `sandbox` ligados | são as paredes acima; desligar uma por conveniência a tira também para um atacante |
| exponha do preload funções pequenas e específicas, nunca o próprio `ipcRenderer` | o `exportPlan(text)` dá para conferir; um `send(channel, data)` genérico não |
| defina uma Content Security Policy no `index.html` | ela impede um `<script>` injetado ou um handler inline de rodar |
| abra links externos no navegador do sistema, com `shell.openExternal`, depois de conferir o endereço | um link que abre dentro do app ganha a janela do app |
| mantenha o próprio Electron atualizado | cada versão traz as correções de segurança do Chromium; um Electron velho é um navegador velho |

**A última linha é a que apps Electron mais deixam de cumprir**, porque nada quebra quando ela é pulada. Um
navegador se atualiza sozinho; um app Electron só se atualiza quando você o entrega, que é o assunto da
aula 15.

Uma Content Security Policy para o `index.html` do planner é uma linha `<meta>` no `<head>` dele,
permitindo scripts e conexões só da própria origem e dos endereços `blob:` que a implementação web da
câmera usa: `<meta http-equiv="Content-Security-Policy" content="default-src 'self'; img-src 'self' blob:;
connect-src 'self' blob:">`. *Ela não foi acrescentada ao planner neste curso, que mantém o `index.html`
como a aula 1 o escreveu; uma política tem que ser testada contra todo recurso do app antes de ser
entregue, e o servidor de desenvolvimento do Vite e os plugins do planner precisariam ser conferidos um a
um.*
