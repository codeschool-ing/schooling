---
title: Quando a preparação falha
version: 1
---

**A maioria das preparações que falham aqui falha de um de quatro jeitos, e cada um diz qual na
primeira linha.** Leia a primeira linha do erro antes de qualquer coisa; a pilha embaixo dela é o
Node dizendo em que ponto do código dele percebeu, e raramente é ali que está o problema.

## `node: command not found`, ou uma versão abaixo da 22

O terminal não encontra o Node, ou encontra um mais antigo primeiro. Feche o terminal e abra outro,
porque a `~/.local/bin` só entra no seu `PATH` no login, e rode `node --version` de novo. Se ainda
faltar, a aula 1 de `javascript` o instala; se for antigo, `which node` mostra a cópia que o
terminal achou, e é essa que se remove.

## Um aviso sobre o tipo de módulo

Se o `package.json` perdeu a linha `"type": "module"`, o Node ainda roda o programa, e acrescenta
um aviso dizendo que teve de adivinhar:

```
ana@dev:~/planner$ node check.ts
node   v22.22.0
sqlite 3.53.4
(node:3095) [MODULE_TYPELESS_PACKAGE_JSON] Warning: Module type of file:///home/ana/planner/check.ts is not specified and it doesn't parse as CommonJS.
Reparsing as ES module because module syntax was detected. This incurs a performance overhead.
To eliminate this warning, add "type": "module" to /home/ana/planner/package.json.
(Use `node --trace-warnings ...` to show where the warning was created)
```

O programa imprimiu as duas linhas dele, então nada quebrou. Ponha a linha de volta mesmo assim: o
aviso sai em toda execução, e a adivinhação custa ao Node uma segunda leitura do arquivo. O número
depois de `node:` é o ID do processo, e o seu vai ser outro.

## `Cannot find package 'better-sqlite3'`

O Node procura um pacote na pasta `node_modules` ao lado do programa, depois em cada pasta acima
dela. Um programa salvo fora da `~/planner` não encontra nenhuma:

```
ana@dev:~/elsewhere$ node check.ts 2>&1 | head -n 5
node:internal/modules/package_json_reader:314
  throw new ERR_MODULE_NOT_FOUND(packageName, fileURLToPath(base), null);
        ^

Error [ERR_MODULE_NOT_FOUND]: Cannot find package 'better-sqlite3' imported from /home/ana/elsewhere/check.ts
```

O caminho na mensagem, `/home/ana/elsewhere/check.ts`, é onde o programa estava. Mova-o para a
`~/planner`, ou rode `npm install` na pasta em que ele está.

## O `npm install` para enquanto constrói o `better-sqlite3`

O pacote traz o motor de banco já compilado para os sistemas comuns: Linux, macOS e Windows, em
processadores Intel e ARM. Em qualquer outro, o npm o compila a partir do código-fonte, e isso exige
Python 3, `make` e um compilador C++. No Ubuntu e no WSL, `sudo apt install build-essential python3`
instala os três; num Mac, `xcode-select --install` instala as ferramentas de linha de comando da
Apple. *Esse caminho não foi rodado para este curso: a máquina de gravação é Linux em Intel, que o
pacote cobre.*

## No Windows: mantenha a pasta no Linux

No WSL, os discos do Windows aparecem em `/mnt/c`, e um projeto ali é lento, porque cada acesso a
arquivo atravessa do Linux para o Windows. Mantenha a `~/planner` no seu diretório pessoal do
Linux, onde as transcrições a têm, e abra pelo Windows como `\\wsl$\Ubuntu-24.04\home\<você>\planner`
quando quiser ver os arquivos.
