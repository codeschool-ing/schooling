---
title: Segredos
version: 1
---

**Um segredo é um valor cujo vazamento deixaria alguém fazer o que não devia**: a chave de
administração, a senha de um banco, um token de API. Três regras guardam um segredo, e cada uma é um
hábito e não uma ferramenta.

## Longo e aleatório

Uma chave que uma pessoa escolheu é uma chave que uma pessoa adivinha. **Gere a chave**, a partir da
fonte aleatória que a aula 4 usou para os códigos:

```
ana@dev:~/server/links$ node -p 'require("node:crypto").randomBytes(24).toString("base64url")'
5Hum7Nw7Qc1lNv_k5f-LNxT7q3S_awPo
ana@dev:~/server/links$ echo "ADMIN_KEY=$(node -p 'require("node:crypto").randomBytes(24).toString("base64url")')" > .env
```

Vinte e quatro bytes aleatórios, escritos como 32 caracteres de base64url, que não dá problema num
cabeçalho nem num arquivo. A segunda linha gera uma nova e a grava no `.env` sem que ela seja digitada
em momento algum. É por isso que o `config.js` recusa qualquer coisa com menos de 24 caracteres: os
valores de exemplo e o velho `change-me-in-lesson-9` são recusados.

## Nunca no git

O projeto vira um repositório agora, se ainda não for, e o arquivo do segredo é ignorado antes de
existir:

```
ana@dev:~/server/links$ git init -q && printf '.env\ntest/tmp/\n' >> .gitignore && cat .gitignore
node_modules/
data/
.env
test/tmp/
ana@dev:~/server/links$ git check-ignore -v .env data/links.json
.gitignore:3:.env	.env
.gitignore:2:data/	data/links.json
ana@dev:~/server/links$ git status --short
?? .env.example
?? .gitignore
?? .npmrc
?? count.js
?? demo/
?? jar.txt
?? package-lock.json
?? package.json
?? public/
?? server.js
?? src/
?? test.env
?? test/
```

O `git check-ignore -v` diz qual regra ignora um arquivo, que é o jeito de ter certeza antes do
primeiro commit e não depois. **Um segredo que foi para um commit uma vez fica no histórico para
sempre**: apagá-lo no commit seguinte o deixa em todo clone, e a única solução é torná-lo inútil,
gerando um novo e aposentando o antigo. Serviços que varrem repositórios atrás de chaves vazadas, o
próprio GitHub entre eles, as encontram minutos depois de um push num repositório público.

## Nunca num log

O serviço imprime a configuração na inicialização, e **o `summary()` troca a chave por uma frase sobre
ela**. Um segredo num log é um segredo em todo sistema para onde os logs são mandados, e legível por
todo mundo que pode lê-los:

```
ana@dev:~/server/links$ node --env-file=.env server.js
links on http://127.0.0.1:3000 {
  production: false,
  host: '127.0.0.1',
  port: 3000,
  dataFile: '/home/ana/server/links/data/links.json',
  adminKey: '(set, 32 characters)'
}
```

Os pedidos de administração agora precisam da chave nova, e a antiga é recusada como qualquer outra
chave errada:

```
ana@dev:~/server/links$ curl -s -H 'x-admin-key: change-me-in-lesson-9' http://127.0.0.1:3000/links
{"error":"this needs the admin key"}
ana@dev:~/server/links$ curl -s -H "x-admin-key: $(sed -n 's/^ADMIN_KEY=//p' .env)" http://127.0.0.1:3000/links
[]
```

O `$(sed -n 's/^ADMIN_KEY=//p' .env)` no segundo comando lê a chave de dentro do arquivo, então ela
nunca é digitada nem colada.

Num servidor a mesma variável vem de onde a plataforma guarda segredos: um arquivo protegido que o
gerenciador de serviço lê, que a aula 10 mostra, ou um cofre de segredos. O código é o mesmo em cada
caso, porque ele só lê o `process.env`.
