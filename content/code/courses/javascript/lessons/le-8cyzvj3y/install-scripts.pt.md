---
title: Uma instalação roda código
version: 1
---

**Um pacote pode trazer um script que o gerenciador roda durante a instalação, com as permissões do
seu usuário.** O campo `scripts` que guardou o `start` na seção 02 também aceita
`preinstall`, `install` e `postinstall`, e esses rodam quando alguém instala o pacote.

Eles existem por bons motivos. Um pacote que embrulha uma biblioteca escrita em C a compila para a
sua máquina, e um pacote que precisa de um binário baixa o do seu sistema. Mas um script de
instalação é um programa da internet que roda antes de você ter lido uma linha dele. Nos ataques ao
ecossistema do npm que viraram notícia, um script de instalação costumava ser onde o código rodava.
O `secure-pipeline`, na aula 12, segue onde uma cadeia de suprimentos de software quebra.

## Vendo um rodar

O `shelf-banner` do laboratório tem um `postinstall` que faz algo inofensivo e visível: escreve um
arquivo no projeto que o instalou.

```
ana@dev:~/js/scripts$ npm install shelf-banner

added 1 package in 564ms
ana@dev:~/js/scripts$ ls
banner-was-here.txt
node_modules
package-lock.json
package.json
ana@dev:~/js/scripts$ cat banner-was-here.txt
written by shelf-banner's postinstall, running as ana
```

**O npm não imprimiu nada sobre isso.** Por padrão o npm esconde a saída dos scripts de instalação
das dependências, então o único sinal de que o script rodou é o arquivo que ele deixou. Num pacote
de verdade esse arquivo podia estar em qualquer lugar onde o usuário da ana pode escrever.

## Desligando

`--ignore-scripts` instala os arquivos e não roda script nenhum de pacote:

```
ana@dev:~/js/scripts$ rm -rf node_modules banner-was-here.txt
ana@dev:~/js/scripts$ npm ci --ignore-scripts

added 1 package in 277ms
ana@dev:~/js/scripts$ ls
node_modules
package-lock.json
package.json
```

Nenhum arquivo desta vez. A mesma chave pode morar no `.npmrc` como `ignore-scripts=true`, para que
toda instalação do projeto a receba. O custo é que um pacote que precisa mesmo compilar algo para de
funcionar. Quando isso acontece, rode o build dele de propósito, como um passo que alguém escolheu,
com `npm rebuild NOME`.

O pnpm 10 não roda os scripts de build de dependência nenhuma a menos que o projeto a nomeie, e diz
o que pulou:

```
ana@dev:~/js/pnpm$ pnpm add shelf-banner
Progress: resolved 0, reused 1, downloaded 0, added 0
Packages: +1
+
Progress: resolved 3, reused 2, downloaded 1, added 1, done

dependencies:
+ shelf-banner 1.0.0

╭ Warning ─────────────────────────────────────────────────────────────────────╮
│                                                                              │
│   Ignored build scripts: shelf-banner@1.0.0.                                 │
│   Run "pnpm approve-builds" to pick which dependencies should be allowed     │
│   to run scripts.                                                            │
│                                                                              │
╰──────────────────────────────────────────────────────────────────────────────╯
Done in 638ms using pnpm v10.28.0
ana@dev:~/js/pnpm$ ls
node_modules
package.json
phantom.js
pnpm-lock.yaml
shelf.js
```

`pnpm approve-builds` pergunta quais pacotes podem rodar seus scripts e escreve a resposta no
`package.json`, para que a escolha seja revisada como qualquer outra mudança. Ele é interativo,
então não foi rodado aqui.

O Yarn 4 os roda por padrão, e `enableScripts: false` no `.yarnrc.yml` os impede:

```
ana@dev:~/js/yarn$ yarn add shelf-banner | cut -b5-
YN0000: · Yarn 4.10.3
YN0000: ┌ Resolution step
YN0085: │ + shelf-banner@npm:1.0.0
YN0000: └ Completed
YN0000: ┌ Fetch step
YN0013: │ A package was added to the project (+ 1.32 KiB).
YN0000: └ Completed
YN0000: ┌ Link step
YN0000: │ ESM support for PnP uses the experimental loader API and is therefore experimental
YN0007: │ shelf-banner@npm:1.0.0 must be built because it never has been before or the last one failed
YN0000: └ Completed
YN0000: · Done with warnings in 0s 326ms
ana@dev:~/js/yarn$ ls
banner-was-here.txt
package.json
phantom.js
shelf.js
yarn.lock
ana@dev:~/js/yarn$ rm banner-was-here.txt
ana@dev:~/js/yarn$ echo "enableScripts: false" >> .yarnrc.yml
ana@dev:~/js/yarn$ rm -rf .yarn/install-state.gz && yarn install | cut -b5- | grep YN0004
YN0004: │ shelf-banner@npm:1.0.0 lists build scripts, but all build scripts have been disabled.
ana@dev:~/js/yarn$ ls
package.json
phantom.js
shelf.js
yarn.lock
```

## O que mais protege você

- **o lockfile e o `npm ci`**: uma versão não muda debaixo de você entre a revisão e o deploy, e o
  hash de integridade pega um arquivo que mudou sob a mesma versão;
- **menos dependências**: cada uma é código e pessoas em quem você confia. Uma função de dez linhas
  costuma sair mais barata de escrever do que de depender;
- **`npm audit`**: ele manda as versões instaladas para o registro e lista vulnerabilidades
  conhecidas com a versão que corrige cada uma. O registro do laboratório não tem base de alertas,
  então não foi rodado aqui. O `secure-pipeline`, na aula 5, roda esse tipo de verificação num
  pipeline, e o `secure-code`, na aula 17, decide quando atualizar e quando fixar a versão.
