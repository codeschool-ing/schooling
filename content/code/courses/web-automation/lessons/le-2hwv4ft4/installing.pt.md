---
title: A instalação, e a metade que vem por fora
version: 1
---

**O Cypress se instala em duas metades, e só a primeira vem do npm.** O pacote `cypress` em
`node_modules` é um pequeno programa de linha de comando. A parte que faz o trabalho é o aplicativo
Cypress: uma versão do Electron, o navegador que o Cypress leva dentro de si, com o executor e o
servidor. O pacote o busca no servidor de downloads da própria Cypress depois que o npm termina, e o
guarda numa pasta de cache no seu diretório pessoal, fora do projeto, compartilhada por todo projeto
que use a mesma versão.

## O projeto, com as três ferramentas

O `package.json` ganha o Cypress ao lado do Playwright e do Selenium da aula 8, cada um fixado numa
versão exata, para que o que você instala seja o que estas aulas descrevem. Nada mais muda no
projeto. Salve-o como `package.json`:

```json
{
  "name": "quitanda",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node app/server.js",
    "test": "playwright test"
  },
  "devDependencies": {
    "@playwright/test": "1.56.0",
    "cypress": "16.1.1",
    "selenium-webdriver": "4.51.0"
  }
}
```

No seu computador, o comando é o de sempre, e o que importa é o download no fim dele:

```sh
npm install
```

As transcrições vêm de uma máquina que não alcança o servidor de downloads da Cypress, então foram
gravadas com o download desligado. `CYPRESS_INSTALL_BINARY=0` é a chave, e ela existe de verdade: um
servidor de build que só roda Playwright a usa para tirar o download de toda execução.

```
%%CAP npm-install%%
```

O pacote está lá. Pergunte o que está instalado e ele responde, metade por metade:

```
%%CAP cypress-version%%
```

**`not installed` na segunda linha é o estado que um download que falhou deixa para trás**, e é
fácil não ver, porque o próprio `npm install` terminou sem reclamar. O que você vê na sua máquina,
depois de um download que deu certo, é a versão do binário nessa linha; isso não foi executado
aqui, então não aparece.

## Conferindo, e o que um binário ausente diz

`npx cypress verify` inicia o binário uma vez, sem rodar teste nenhum, para provar que ele funciona.
É o jeito mais rápido de saber se o download deu certo, e sem o binário ele diz isto:

```
%%CAP cypress-verify%%
```

Leia a partir da linha que nomeia o problema: **nenhuma versão do Cypress está instalada** numa
pasta com o nome da versão, `16.1.1`. Essa pasta é o cache. Atualize o pacote e o caminho muda junto,
e o binário baixado para a versão antiga deixa de valer, a mesma armadilha que a aula 1 mostrou com
os navegadores do Playwright.

A correção que ele sugere, `npx cypress install`, baixa o binário de novo. Aqui está esse comando
numa máquina que não alcança o servidor de downloads de jeito nenhum. Num servidor de build, onde a
variável `CI` está definida, o Cypress imprime o progresso em linhas simples em vez de uma animação,
e é essa a forma mostrada:

```
%%CAP cypress-install-fails%%
```

`ENOTFOUND` quer dizer que o nome `download.cypress.io` não pôde ser resolvido: sem rede, ou numa
rede que não deixa esse nome passar. **Atrás de um proxy de empresa**, o pacote lê `HTTP_PROXY` do
ambiente antes de baixar. Onde o servidor está bloqueado de vez, `CYPRESS_DOWNLOAD_MIRROR` o aponta
para uma cópia que alguém mantém dentro da rede, e `CYPRESS_INSTALL_BINARY` pode nomear um arquivo
zip do binário obtido por outro caminho. Cada um desses nomes aparece no código do próprio pacote;
nenhum deles foi exercitado aqui.

## Dizendo ao Cypress onde estão as coisas

O Cypress lê `cypress.config.js` na raiz do projeto. Três configurações bastam para esta aula: o
endereço da loja, para que um teste possa escrever `cy.visit('/')`; onde ficam os arquivos de spec,
para que o Cypress nunca entre nos testes do Playwright em `tests/`; e que este projeto não tem
arquivo de suporte, o arquivo que o Cypress carregaria antes de cada spec com comandos
compartilhados. Como o `package.json` diz `"type": "module"`, o arquivo usa `import` e `export`,
como o resto do projeto. Salve-o como `cypress.config.js`:

```javascript
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000',
    specPattern: 'cypress/e2e/**/*.cy.js',
    // No support file: this course writes no custom commands.
    supportFile: false,
  },
});
```

**O Cypress não inicia a loja por você.** A configuração do Playwright tem um `webServer` que faz
isso; o Cypress espera a aplicação já rodando, em `baseUrl`. Então uma sessão do Cypress na sua
máquina pede dois terminais: `npm start` num, e o comando do Cypress no outro.
