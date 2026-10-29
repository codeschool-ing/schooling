---
title: O que o servidor manda hoje
version: 1
---

**Até aqui o HTML do planner veio vazio, e o navegador construiu cada palavra dele.** O dev server
manda o `index.html` com um `<app-root>` sem nada dentro, e dois scripts. A página só aparece depois
que esses scripts chegaram, rodaram, pediram os dados a `/api/planner` e desenharam o resultado. Um
navegador com o JavaScript desligado mostra o que o servidor mandou, e isso é nada:

```
ana@dev:~/planner$ look http://localhost:4200/ --no-js --text body
```

O `curl` mostra o mesmo em texto, porque busca a página e não roda script nenhum:

```
ana@dev:~/planner$ curl -s http://localhost:4200/ | sed -n '/<body>/,/<\/body>/p'
<body>
  <app-root></app-root>
<script src="polyfills.js" type="module"></script><script src="main.js" type="module"></script></body>
```

Para quem tem uma boa conexão a espera é curta, e ninguém percebe. Outros percebem:

- **Um celular lento** espera o script inteiro antes de mostrar uma palavra. O script deste planner
  é pequeno; o de uma aplicação grande não é, e até ele rodar a tela fica em branco.
- **Um buscador, ou um app de conversa montando a prévia de um link,** pode não rodar script
  nenhum, ou rodar mais tarde e com menos frequência. O que ele lê de um `<app-root>` vazio é um
  título e mais nada.
- **Uma pessoa com o JavaScript bloqueado** recebe uma página vazia, que não diz nada sobre o porquê.

**Renderizar no servidor é rodar a mesma aplicação no servidor, uma vez por requisição, e mandar o
HTML que ela produziu.** O navegador mostra esse HTML na hora. Depois os scripts chegam, e o Angular
no navegador assume a página em vez de desenhá-la de novo; esse passo se chama hidratação, e é o
assunto da quinta seção desta aula.

Tem um custo, e o custo é o motivo de ser uma escolha e não um padrão:

| | renderizado no navegador | renderizado no servidor |
| --- | --- | --- |
| o que serve a página | qualquer servidor web, a partir de arquivos | um programa Node.js que roda o Angular |
| o primeiro HTML | um `<app-root>` vazio | a página, com o texto |
| onde o código roda | no navegador | primeiro no servidor, depois no navegador |
| o que o código pode supor | um navegador: `window`, `localStorage`, foco | nada que o servidor não tenha |

A última linha é a cara. Código que roda em dois lugares precisa estar certo nos dois, e o planner já
tem código que só faz sentido num navegador. Esta aula o encontra.
