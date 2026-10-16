---
title: O Newman, instalado no projeto
version: 1
---

**O Newman é um programa Node que roda uma coleção do Postman pela linha de comando**, com os mesmos
scripts e as mesmas regras de variáveis do aplicativo. A lição 5 já o usou, buscado pelo `npx` para
um cache em cada máquina. Isso serve para experimentar e é errado para um projeto: a versão vivia só
num comando que alguém digitou, e um colega, ou um pipeline, teria de digitar o mesmo. **Um projeto
nomeia as suas ferramentas num arquivo**, para que quem o baixar receba as mesmas.

Para um programa Node, esse arquivo é o `package.json`. O boxoffice nunca precisou de um, porque não
usa nada além dos módulos do próprio Node. O Newman é o primeiro pacote de que o projeto depende,
então crie o arquivo agora, em `~/boxoffice`, com os padrões do npm:

```
ana@laptop:~/boxoffice$ npm init -y
Wrote to /home/ana/boxoffice/package.json:

{
  "name": "boxoffice",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
```

`-y` responde cada pergunta que o npm faria com o padrão, e o nome vem do diretório. Depois instale o
Newman:

```
ana@laptop:~/boxoffice$ npm install --save-dev --save-exact newman@6.2.3
npm warn deprecated har-validator@5.1.5: this library is no longer supported
npm warn deprecated uuid@3.4.0: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated uuid@8.3.2: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).
npm warn deprecated @faker-js/faker@5.5.3: Please update to a newer version.

added 148 packages, and audited 149 packages in 3s

21 packages are looking for funding
  run `npm fund` for details

19 vulnerabilities (8 moderate, 10 high, 1 critical)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

Três coisas aconteceram, e a transcrição mostra todas:

- `node_modules/` agora guarda o Newman e os pacotes de que ele precisa, 148 deles.
- o `package.json` ganhou uma entrada `devDependencies` para `newman`. *Dev* quer dizer uma
  ferramenta para trabalhar no projeto, não uma parte do que ele entrega; o boxoffice continua sem
  depender de nada. `--save-exact` escreve `6.2.3` em vez de `^6.2.3`, que deixaria uma instalação
  futura pegar qualquer 6.x.
- apareceu o `package-lock.json`. Ele registra a versão exata de cada um desses pacotes, para que um
  `npm ci` depois reproduza esta árvore byte a byte em vez de resolvê-la de novo.

## Os avisos, lidos em vez de pulados

As linhas `npm warn deprecated` são as mesmas quatro que a lição 5 viu. As últimas linhas são novas:
**o npm auditou a árvore e encontrou 19 vulnerabilidades, uma delas crítica.** Isso merece uma
olhada antes de ser descartado, e o remédio óbvio merece uma olhada ainda mais atenta:

```
ana@laptop:~/boxoffice$ npm audit | grep -m1 'Will install'
Will install newman@4.6.1, which is a breaking change
```

`npm audit fix --force` trocaria o Newman 6.2.3 pelo 4.6.1, duas versões principais atrás. As
vulnerabilidades estão em bibliotecas de que o Newman 6.2.3 depende, e o único remédio que o npm
consegue calcular é um Newman mais antigo cuja árvore ele não aponta. Aceitar seria trocar a
ferramenta com que o curso inteiro foi gravado por uma antiga, para calar um relatório sobre código
que só roda nas suas próprias máquinas.

O que quem testa faz no lugar disso é pesar onde o código roda. O Newman aqui é uma dependência de
desenvolvimento: roda na sua máquina e no seu pipeline, contra um servidor que você iniciou, lendo
uma coleção que você escreveu. Ele nunca chega a um usuário. **Então o achado fica registrado, a
versão continua fixada, e a próxima versão do Newman é conferida em busca de correção**, o que é uma
decisão, e não um hábito de ignorar texto vermelho. Uma dependência que fosse junto dentro do
boxoffice, atendendo requisições de estranhos, receberia outra resposta.

## Um nome para a execução

O `npm init` escreveu um script `test` que só imprime um erro. Abra o `package.json`, troque a
entrada `scripts` por uma chamada `test:api` e salve como `package.json`:

```json
{
  "name": "boxoffice",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test:api": "newman run postman/boxoffice.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "devDependencies": {
    "newman": "6.2.3"
  }
}
```

O script é o comando que a lição 5 digitou, sem o `npx`: dentro de um script do npm, os programas em
`node_modules/.bin` estão no caminho, então `newman` é o que este projeto instalou. Pergunte qual é:

```
ana@laptop:~/boxoffice$ npx newman --version
6.2.3
```

`npx newman` também encontra o local, agora que existe um. Daqui em diante a execução tem nome,
`npm run test:api`, e significa a mesma coisa em toda máquina que tenha este `package.json` e este
`package-lock.json`.

## O que o git não deve guardar

A lição 3 transformou `~/boxoffice` num repositório git e deu a ele um `.gitignore` para o `.env`. O
`node_modules/` também pertence ali: 148 pacotes que o `npm ci` reconstrói exatamente a partir do
lock. Assim como os arquivos que uma execução deixa para trás, criados pela seção 05 e pela seção 06.
Substitua o arquivo e salve como `.gitignore`:

```
# Secrets live in .env, on this machine only.
.env
# Installed by npm from package-lock.json, never committed.
node_modules/
# What a run leaves behind.
results/
boxoffice.log
```

O `package.json` e o `package-lock.json` vão para o commit; o `node_modules/` nunca vai. A seção 06
depende das duas metades disso.
