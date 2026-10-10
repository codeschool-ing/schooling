---
title: Quando a montagem falha
version: 1
---

Montar o ambiente é onde a maioria das pessoas desiste de um curso como este, geralmente diante de
uma tela de saída que parece uma catástrofe e acaba sendo uma coisinha. Estas são as falhas que
aparecem ao seguir as duas últimas seções, cada uma com o que imprime e o que a resolve. Todas foram
produzidas de propósito, na máquina de onde vêm as transcrições.

**Leia um erro a partir da linha que nomeia o problema, não do topo.** O Node e o npm imprimem
muito contexto em volta da única frase que importa, e em cada caso abaixo essa frase é citada para
você encontrá-la.

## `address already in use`

A loja já está rodando em outro terminal, ou uma execução de teste deixou uma para trás, e um
segundo `npm start` tenta usar a mesma porta:

```
ana@laptop:~/quitanda$ npm start

> start
> node app/server.js

node:events:497
      throw er; // Unhandled 'error' event
      ^

Error: listen EADDRINUSE: address already in use 0.0.0.0:3000
    at Server.setupListenHandle [as _listen2] (node:net:1940:16)
    at listenInCluster (node:net:1997:12)
    at Server.listen (node:net:2102:7)
    at file:///home/ana/quitanda/app/server.js:69:4
Emitted 'error' event on Server instance at:
    at emitErrorNT (node:net:1976:8)
    at process.processTicksAndRejections (node:internal/process/task_queues:90:21) {
  code: 'EADDRINUSE',
  errno: -98,
  syscall: 'listen',
  address: '0.0.0.0',
  port: 3000
}

Node.js v22.22.0
```

`EADDRINUSE` quer dizer que **outro programa já ocupa a porta 3000**; as linhas em volta são o Node
dizendo em que ponto do próprio código percebeu. Ache o terminal em que a loja está rodando e pare-a
com Ctrl+C. Se não achar nenhum, uma execução de teste é a culpada de sempre: o `webServer` do
Playwright para o servidor que iniciou, mas uma execução interrompida no meio talvez não tenha
parado.

## `Executable doesn't exist`

O Playwright está instalado e os navegadores dele não:

```
ana@laptop:~/quitanda$ npx playwright test

Running 1 test using 1 worker

  ✘  1 tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (4ms)


  1) tests/smoke.spec.js:3:1 › the shop opens and lists its fruit ──────────────────────────────────

    Error: browserType.launch: Executable doesn't exist at /home/ana/.cache/ms-playwright/chromium_headless_shell-1194/chrome-linux/headless_shell
    ╔═════════════════════════════════════════════════════════════════════════╗
    ║ Looks like Playwright Test or Playwright was just installed or updated. ║
    ║ Please run the following command to download new browsers:              ║
    ║                                                                         ║
    ║     npx playwright install                                              ║
    ║                                                                         ║
    ║ <3 Playwright Team                                                      ║
    ╚═════════════════════════════════════════════════════════════════════════╝

  1 failed
    tests/smoke.spec.js:3:1 › the shop opens and lists its fruit ───────────────────────────────────
```

A caixa diz o que fazer, e está certa: `npx playwright install chromium` baixa a versão que esta
versão espera. Vale ler o caminho acima dela também, porque ele diz **qual versão de navegador** o
Playwright procurou. Quando você atualiza o Playwright, o número nesse caminho muda, e os navegadores
baixados para a versão antiga deixam de contar.

## `Could not read package.json`

O `npm start` rodado na pasta errada:

```
ana@laptop:~$ npm start
npm error code ENOENT
npm error syscall open
npm error path /home/ana/package.json
npm error errno -2
npm error enoent Could not read package.json: Error: ENOENT: no such file or directory, open '/home/ana/package.json'
npm error enoent This is related to npm not being able to find a file.
npm error enoent
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-10T07_07_06_918Z-debug-0.log
```

O npm procura o `package.json` na pasta em que você está, e o caminho que ele cita, `/home/ana`, é a
pasta pessoal e não o projeto. Faça `cd ~/quitanda` e rode de novo. O `debug-0.log` que ele menciona
não tem nada mais útil que as linhas acima.

## `Invalid package.json`

O `package.json` do projeto com uma vírgula a mais depois da linha `"test"`, o que acontece quando
se apaga à mão uma linha de uma lista:

```
ana@laptop:~/quitanda$ npm start
npm error code EJSONPARSE
npm error JSON.parse Invalid package.json: JSONParseError: Expected double-quoted property name in JSON at position 146 (line 8 column 3) while parsing near "...playwright test\",\n  },\n  \"devDependencie..."
npm error JSON.parse Failed to parse JSON data.
npm error JSON.parse Note: package.json must be actual JSON, not just JavaScript.
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-10T07_07_07_057Z-debug-0.log
```

O JSON não permite vírgula depois do último item de um objeto, embora o JavaScript permita, e é
isso que a última linha do erro insinua. **A posição diz onde olhar**: linha 8, coluna 3, onde o
analisador encontrou um `}` quando esperava outro nome. O erro em si está na linha anterior.

## Um aviso sobre o tipo de módulo

Nem toda mensagem impede a loja. Aqui o `"type": "module"` ficou fora do `package.json`, e o
servidor inicia mesmo assim:

```
ana@laptop:~/quitanda$ npm start

> start
> node app/server.js

(node:4221) [MODULE_TYPELESS_PACKAGE_JSON] Warning: Module type of file:///home/ana/quitanda/app/server.js is not specified and it doesn't parse as CommonJS.
Reparsing as ES module because module syntax was detected. This incurs a performance overhead.
To eliminate this warning, add "type": "module" to /home/ana/quitanda/package.json.
(Use `node --trace-warnings ...` to show where the warning was created)
quitanda is listening on http://localhost:3000
```

O Node 22 adivinha, percebe que o arquivo usa `import` e o lê de novo como módulo. Funciona, e o
aviso diz como acabar com a adivinhação: recoloque a linha. Sem ela, a adivinhação acontece a cada
início, para cada arquivo, e uma ferramenta posterior que não adivinha vai falhar onde o Node não
falhou.

## Uma versão do Node velha demais

Se `node --version` imprimir algo abaixo de `v22`, as ferramentas deste curso podem falhar de jeitos
que parecem não ter relação com a versão. No Windows, `where node` lista cada `node` do seu caminho,
na ordem em que são encontrados; no macOS e no Linux, `which -a node` faz o mesmo. O primeiro da
lista é o que responde. Desinstale o antigo, ou reinstale o Node de nodejs.org para o novo vir
primeiro. Essa falha não foi reproduzida para as transcrições, porque a máquina de onde elas vêm só
tem um Node.

## Quando não é nenhuma destas

Duas coisas estreitam quase todo o resto. Rode `npm start` sozinho e abra `http://localhost:3000`:
se a loja não abrir no seu navegador, o problema está na aplicação ou nos arquivos dela, e os testes
não têm nada com isso. Se ela abrir e o teste continuar falhando, compare os seus arquivos com os
blocos das duas últimas seções. Copiar com o botão de cada bloco evita a maioria desses problemas; um
arquivo salvo na pasta errada causa quase todo o resto.
