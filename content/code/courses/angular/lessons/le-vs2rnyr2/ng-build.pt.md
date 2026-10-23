---
title: Um build para a web
version: 1
---

**O `ng build` escreve a aplicação como arquivos que um servidor web pode enviar.** O servidor de
desenvolvimento faz o build em memória e continua rodando; o build escreve em disco e para. O que ele
escreve é o que vai para um servidor de verdade, e é construído de outro jeito: menor, sem as
conferências de desenvolvimento, e com nomes que mudam sempre que o conteúdo muda.

```
ana@dev:~/planner$ npx ng build
❯ Building...
✔ Building...
Initial chunk files | Names         |  Raw size | Estimated transfer size
main-J4WVDBNH.js    | main          | 187.14 kB |                50.84 kB
styles-5INURTSO.css | styles        |   0 bytes |                 0 bytes

                    | Initial total | 187.14 kB |                50.84 kB

Application bundle generation complete. [3.464 seconds] - 2026-10-23T23:33:30.254Z

Output location: /home/ana/planner/dist/planner
```

Duas colunas de tamanho. **Raw** é o arquivo em disco. **Estimated transfer** é o que atravessa a
rede depois que o servidor comprime, que é o que uma pessoa numa conexão lenta espera. São os números
que a aula 1 prometeu: uma aplicação cujo template inteiro é um título e um outlet vazio já pesa isso,
porque o framework que chama o seu código também está no arquivo.

O build de produção é o padrão, porque o `angular.json` diz isso. Os **budgets** dele são limites que
o build confere depois de cada execução:

```
ana@dev:~/planner$ node -e "console.log(require('./angular.json').projects.planner.architect.build.configurations.production.budgets)"
[
  { type: 'initial', maximumWarning: '500kB', maximumError: '1MB' },
  {
    type: 'anyComponentStyle',
    maximumWarning: '4kB',
    maximumError: '8kB'
  }
]
```

Passando do `maximumWarning`, o build avisa; passando do `maximumError`, ele falha. O segundo budget
limita a folha de estilo de cada componente. Eles existem para que uma dependência acrescentada numa
sexta-feira que dobra o download seja um build vermelho, e não um site lento descoberto um mês depois.

## O que ele escreveu

```
ana@dev:~/planner$ ls dist/planner/browser
courses.json
favicon.ico
index.html
main-J4WVDBNH.js
styles-5INURTSO.css
```

`main-` seguido de oito caracteres é o **hash do conteúdo**: o nome é calculado a partir dos bytes do
arquivo. Mude uma linha e o nome muda, então um navegador que guardou em cache o arquivo de ontem não
tem como confundi-lo com o de hoje, e um servidor pode dizer aos navegadores para guardar todo arquivo
com hash por um ano. O `index.html` mantém o nome e é o único arquivo que nunca deve ficar muito tempo
em cache, porque é ele que dá nome aos outros.

## Servindo como um host estático serviria

Não há Angular num servidor de produção. A pasta é um conjunto de arquivos, e qualquer servidor que
envie arquivos serve. O Python, que o Ubuntu instala com o sistema, tem um embutido; num segundo
terminal:

```
ana@dev:~/planner$ python3 -m http.server 8081 --directory dist/planner/browser
Serving HTTP on 0.0.0.0 port 8081 (http://0.0.0.0:8081/) ...
```

```
ana@dev:~/planner$ look http://127.0.0.1:8081/
Study planner
```

Nenhuma linha de console desta vez: nada de Vite, porque não há servidor de desenvolvimento, e nada da
mensagem de modo de desenvolvimento, porque este é o build de produção. Agora peça ao mesmo servidor
um endereço que o planner vai ter a partir da aula 17:

```
ana@dev:~/planner$ look http://127.0.0.1:8081/courses/git
[error] Failed to load resource: the server responded with a status of 404 (File not found)
Error response

Error code: 404

Message: File not found.

Error code explanation: 404 - Nothing matches the given URI.
```

O servidor do Python procurou um arquivo chamado `courses/git`, não achou, e mandou a própria página
de erro. A aplicação nunca carregou, então nunca teve a chance de ler o endereço e desenhar a tela
certa. **Um host de aplicação Angular precisa responder todo endereço para o qual não tem arquivo com
o `index.html`**, e deixar a aplicação decidir. O servidor de desenvolvimento já faz isso, como duas seções atrás mostraram para este
mesmo endereço. Todo serviço de hospedagem tem uma configuração para isso, e o curso `front-delivery`
é onde você define uma.

O terminal dele registrou as duas requisições, a segunda com o seu 404:

```
ana@dev:~/planner$ python3 -m http.server 8081 --directory dist/planner/browser
Serving HTTP on 0.0.0.0 port 8081 (http://0.0.0.0:8081/) ...
127.0.0.1 - - [23/Oct/2026 20:33:30] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [23/Oct/2026 20:33:31] "GET /styles-5INURTSO.css HTTP/1.1" 200 -
127.0.0.1 - - [23/Oct/2026 20:33:31] "GET /main-J4WVDBNH.js HTTP/1.1" 200 -
127.0.0.1 - - [23/Oct/2026 20:33:32] code 404, message File not found
127.0.0.1 - - [23/Oct/2026 20:33:32] "GET /courses/git HTTP/1.1" 404 -
```

Pare-o com Ctrl-C. A saída do build não é coisa para commitar: o `.gitignore` já deixa o `dist/` de
fora, porque ele sempre pode ser gerado de novo a partir do código.
