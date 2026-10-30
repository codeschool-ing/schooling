---
title: O seu computador, preparado para este curso
version: 1
---

**Tudo neste curso roda no seu próprio computador, e esta seção o prepara.** Você precisa de duas
coisas: o **Node.js 22**, que roda o TypeScript do planner, e uma pasta, `~/planner`, onde mora
cada programa do curso. Uma terceira, o shell `sqlite3`, entra na aula 3, onde é usada pela
primeira vez.

## Três jeitos de ter um

| caminho | o que você ganha | o que custa ao seu computador | as transcrições |
|---|---|---|---|
| **instalado** (recomendado) | o Node.js e a `~/planner` no computador que você já usa | uns 240 MB de disco: 205 MB do Node.js e 27 MB da biblioteca de banco | iguais às impressas no Linux; próximas no Windows e no macOS |
| uma máquina virtual | Ubuntu Server 24.04, separado do seu sistema | alguns gigabytes de disco, e 2 GB de memória enquanto roda | iguais às impressas |
| online | uma máquina Linux numa aba do navegador | nada no seu computador; horas de uma franquia mensal | próximas, não exatas |

**Instale no computador que você usa.** Nada aqui mexe no resto do seu sistema: o Node vai para uma
pasta dentro do seu diretório pessoal e a biblioteca para a `~/planner`. No **Linux**, os comandos
abaixo funcionam como impressos. No **Windows**, todo comando é digitado no WSL, o Linux que vem
com o Windows: `wsl --install -d Ubuntu-24.04` num PowerShell aberto como administrador, uma
reinicialização, e depois o Ubuntu pelo menu Iniciar. Num **Mac**, pegue o Node.js 22 em nodejs.org
e digite o resto no app Terminal. Os caminhos do Windows e do Mac não foram rodados para este curso,
então um caminho numa transcrição pode ser diferente do seu.

**Uma máquina virtual** é o mesmo passo a passo do Linux dentro de uma máquina só dela: VirtualBox
no Windows ou no Linux, UTM num Mac com chip Apple, e o Ubuntu Server 24.04 LTS como convidado. Nada
neste curso abre janela, então um servidor sem área de trabalho basta.

**Online**, o GitHub Codespaces oferece uma máquina Linux com terminal numa aba do navegador. O
GitHub dá às contas pessoais uma franquia mensal de horas e cobra o que passar dela, em termos que
ele define e pode mudar. Ele não foi rodado para este curso.

## Node.js

O curso `javascript` instala o Node.js na aula 1, e este curso usa exatamente essa instalação: a
versão 22.22.0, de nodejs.org, em `~/.local/node`. Confira que ele responde:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
```

Se `node --version` não imprimir nada, ou imprimir uma versão abaixo de `v22`, volte à aula 1 de
`javascript`, seção "O seu computador, preparado para este curso", e faça lá uma vez. **Não instale
um segundo Node** pelos pacotes do sistema: com duas cópias, a versão que uma transcrição mostra
depende de qual o terminal encontra primeiro.

O Node 22 roda um arquivo `.ts` diretamente. Ele remove as anotações de tipo e roda o que sobra,
então `node show.ts` não precisa de etapa de build. **Ele não confere os tipos**, e o curso se
mantém na parte do TypeScript que dá para remover desse jeito: tipos e interfaces, sem `enum` e sem
`namespace`.

## A pasta do planner

Crie a pasta e dê a ela um `package.json`. Duas linhas dele importam: `private`, para o npm nunca
oferecer publicá-la, e `"type": "module"`, para o `import` funcionar em todo arquivo. Salve isto
como `package.json`:

```json
{
  "name": "planner",
  "private": true,
  "type": "module"
}
```

Depois instale a única biblioteca de que o curso precisa desde o começo. O `better-sqlite3` é o
SQLite para Node, o mesmo motor de banco que o Android e o iOS trazem, e o `-E` grava no
`package.json` a versão exata em vez de uma faixa:

```
ana@dev:~/planner$ npm install -E better-sqlite3@13.0.3

added 2 packages in 865ms
ana@dev:~/planner$ cat package.json
{
  "name": "planner",
  "private": true,
  "type": "module",
  "dependencies": {
    "better-sqlite3": "13.0.3"
  }
}
```

Por último, um programa que pede a cada ferramenta que responda. Salve como `check.ts` na
`~/planner`:

```typescript
// check.ts: does every tool this course uses answer?
import Database from "better-sqlite3";

const db = new Database(":memory:");
const row = db.prepare("select sqlite_version() as version").get() as { version: string };
console.log("node  ", process.version);
console.log("sqlite", row.version);
```

```
ana@dev:~/planner$ node check.ts
node   v22.22.0
sqlite 3.53.4
```

A versão do SQLite é a que vem compilada dentro do `better-sqlite3`, não uma instalada no seu
sistema, e é por isso que todo leitor deste curso recebe a mesma.
