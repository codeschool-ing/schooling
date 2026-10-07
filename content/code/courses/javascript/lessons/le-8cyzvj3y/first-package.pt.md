---
title: Um pacote e o package.json
version: 1
---

**Um pacote é uma pasta de código com um `package.json` que lhe dá um nome e uma versão.** Um
**registro** é um servidor que guarda pacotes publicados e os entrega pelo nome. O público é o
`registry.npmjs.org`; nesta aula o laboratório roda o seu próprio, na mesma máquina, com alguns
pacotes escritos para a aula. Um **gerenciador de pacotes** é o programa que conversa com o
registro, baixa o que você pede e põe onde o Node consegue achar.

## Apontando para um registro

Cada projeto desta aula mora numa pasta própria dentro de `~/js`, e cada um tem um `.npmrc`, o
arquivo de configuração que o npm lê antes de qualquer coisa:

```ini
registry=http://127.0.0.1:4873/
audit=false
```

`registry` diz de onde vêm os pacotes. `audit=false` impede o npm de pedir ao registro alertas de
segurança a cada instalação. O registro do laboratório não tem nenhum para dar, então a pergunta só
terminaria num aviso. Sem esse arquivo o npm iria ao registro público, que é o que ele faz na sua
máquina.

## Uma primeira instalação

Um projeto começa como um `package.json` com nome e versão. `"type": "module"` faz dos seus
arquivos `.js` ES modules, como a aula 9 explicou, e `"private": true` quer dizer que o npm se
recusa a publicá-lo por acidente:

```json
{
  "name": "shelf",
  "version": "1.0.0",
  "type": "module",
  "private": true
}
```

```
ana@dev:~/js/first$ npm install shelf-slug@1

added 1 package in 534ms
ana@dev:~/js/first$ cat package.json
{
  "name": "shelf",
  "version": "1.0.0",
  "type": "module",
  "private": true,
  "dependencies": {
    "shelf-slug": "^1.2.0"
  }
}
ana@dev:~/js/first$ ls node_modules
shelf-slug
```

O `npm install` fez três coisas. Perguntou ao registro quais versões de `shelf-slug` existem e
escolheu uma. Baixou essa versão para **`node_modules`**, a pasta em que o Node procura quando um
import nomeia um pacote. E escreveu a dependência no `package.json`.

`@1` pede o `1.x` mais novo. Sem isso o npm pega o mais novo de todos, que aqui é `2.0.0`, e o
código abaixo foi escrito para `1.x`. A próxima seção mostra o que acontece quando essa linha é
cruzada.

O que o npm escreveu não é `1.2.0` e sim **`^1.2.0`**, uma faixa. O circunflexo quer dizer "esta
versão ou qualquer uma posterior que prometa não quebrá-la". A próxima seção é sobre exatamente
essa promessa.

## Usando

Um import que nomeia um pacote em vez de um caminho, sem `./` na frente, é procurado em
`node_modules`:

```javascript
import { slug } from "shelf-slug";

console.log(slug("Grande Sertão: Veredas"));
```

```
ana@dev:~/js/first$ node slug.js
grande-sertao:-veredas
```

O acento sumiu, que é o que esta versão do pacote faz. Os dois-pontos ficam, porque nada nele
remove pontuação. Um pacote faz o que o código dele faz, não o que o nome sugere.

## Scripts

O campo `scripts` do `package.json` nomeia comandos do projeto, e `npm run NOME` roda um. `start` e
`test` são tão comuns que `npm start` e `npm test` funcionam sem o `run`:

```
ana@dev:~/js/first$ npm pkg set scripts.start="node slug.js"
ana@dev:~/js/first$ npm start

> shelf@1.0.0 start
> node slug.js

grande-sertao:-veredas
```

O npm imprimiu o script antes de rodá-lo. Dentro de um script, os programas instalados pelas suas
dependências estão no `PATH`, então um script chama uma ferramenta pelo nome, sem `npx` nem
caminho. É assim que a maioria dos projetos guarda os comandos de build e de teste: no
`package.json`, onde quem chega encontra.

## Dois tipos de dependência

`dependencies` é o que o código precisa para rodar. **`devDependencies`** é o que você precisa só
enquanto trabalha nele: um executor de testes, um linter, um bundler. `npm install --save-dev NOME`
põe um pacote na segunda lista. Quando alguém instala o seu pacote publicado, o npm busca as
`dependencies` dele e pula as `devDependencies`. O registro do laboratório não tem executor de
testes para mostrar isso, então não foi rodado aqui. O curso `node`, na aula 4, leva o
`package.json` e os scripts adiante, do lado do servidor.
