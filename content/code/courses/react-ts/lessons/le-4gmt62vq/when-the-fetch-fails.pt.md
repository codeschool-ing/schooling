---
title: Quando a busca falha, e quando só parece que deu certo
version: 1
---

**Uma requisição que falhou pode chegar com status 200.** Esta seção escreve errado o nome do arquivo
para ver o que o planejador faz com uma requisição que dá errado, e a resposta ensina mais do que o
esperado.

```
ana@dev:~/planner$ sed -i "s|fetch('/courses.json')|fetch('/course.json')|" src/App.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network | grep -v 'GET /[@sn]'
net  GET /  200
net  GET /course.json  200
net  GET /course.json  200
[error] could not load the planner: Unexpected token '<', "<!doctype "... is not valid JSON
- alert: The planner could not be loaded.
ana@dev:~/planner$ curl -s -i http://localhost:5173/course.json | head -n 4
HTTP/1.1 200 OK
Vary: Origin
Content-Type: text/html
Cache-Control: no-cache
ana@dev:~/planner$ sed -i "s|fetch('/course.json')|fetch('/courses.json')|" src/App.tsx
```

O planejador fez a coisa certa no fim: o console tem o erro, e a tela diz que o planejador não pôde
ser carregado, como um `alert`, que um leitor de tela anuncia assim que aparece. Mas veja como ele
chegou lá. **O `/course.json` respondeu 200**, duas vezes, o strict mode de novo. O `curl` mostra por
quê: o servidor de desenvolvimento responde qualquer endereço que não reconhece com o `index.html` do
app, para que um app com endereços próprios, assunto da aula 17, possa ser aberto em qualquer um
deles. O status estava ok, o `response.ok` era true, e a falha veio um passo depois, quando o
`response.json()` encontrou `<!doctype` em vez de JSON.

Então o planejador pegou o erro, mas por sorte: pegou um erro de leitura, não um arquivo ausente.
Três coisas transformam essa sorte em projeto:

- **Confira o status, e depois a forma.** O `response.ok` pega um servidor que diz não. Só a leitura,
  e a validação por schema da aula 10, pegam um servidor que diz sim e manda a coisa errada.
- **Diga o que aconteceu no console, e algo útil na tela.** A linha do console tem o motivo real; a
  tela tem uma frase com que um usuário consegue fazer algo. A aula 12 dá à tela um jeito de oferecer
  uma nova tentativa.
- **Toda requisição tem três resultados**, e cada um precisa de uma tela: ainda esperando, chegou,
  falhou. O `status` do planejador são esses três. Um componente que só desenha o segundo mostra uma
  lista vazia enquanto espera, o que parece exatamente um planejador sem cursos.

Quando o servidor de desenvolvimento nem está rodando, a própria página não carrega, e você vê o
`ERR_CONNECTION_REFUSED` da aula 1. No build que você publica, um arquivo ausente é um 404 de
verdade, e é o `response.ok` que o pega.
