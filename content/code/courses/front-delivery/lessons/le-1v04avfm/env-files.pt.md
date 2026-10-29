---
title: Os arquivos que o Vite lê, e qual deles ganha
version: 1
---

**O Vite lê variáveis de arquivos `.env` na raiz do projeto, escolhe quais pelo modo do build, e deixa
uma variável que já está definida no shell ganhar de todos.** Digitar `VITE_TITLE=…` antes de cada build
funciona, e ninguém faz isso por muito tempo. Os arquivos são como um projeto guarda uma configuração por
ambiente sem ninguém precisar lembrar.

## Quatro nomes

| arquivo | lido quando | vai para o commit |
|---|---|---|
| `.env` | sempre | sim |
| `.env.local` | sempre | **não**: o `.gitignore` do template tem `*.local` |
| `.env.<mode>` | só quando o build roda naquele modo | sim |
| `.env.<mode>.local` | só naquele modo | **não** |

**O modo é uma palavra com que o build roda.** `npm run dev` roda em `development`, `npm run build` em
`production`, e `--mode staging` no nome que você der. Quando dois arquivos definem a mesma variável, o
do modo ganha do geral, e um arquivo `.local` ganha do que não é. Uma variável que já está no ambiente
quando o Vite começa ganha de todos os arquivos.

## Um modo de staging

Dê ao planner um build de staging com um título que diga isso:

```
ana@dev:~/planner$ echo 'VITE_TITLE=Study planner (staging)' > .env.staging
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner
ana@dev:~/planner$ npm run build -- --mode staging > /dev/null
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner (staging)
```

O build comum não leu `.env.staging`, então o título é o padrão. O build de staging leu. Um valor com
espaços não precisa de aspas no arquivo: o Vite pega tudo o que vem depois do `=` até o fim da linha.

## Qual ganha

Um arquivo `.local` é de uma máquina só: um valor que você quer enquanto desenvolve, ou um que não deve
ir para o commit. Ponha um ao lado do arquivo de staging, e depois defina a mesma variável no shell
também:

```
ana@dev:~/planner$ echo 'VITE_TITLE=Study planner (Ana)' > .env.staging.local
ana@dev:~/planner$ npm run build -- --mode staging > /dev/null
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner (Ana)
ana@dev:~/planner$ VITE_TITLE='Study planner (shell)' npm run build -- --mode staging > /dev/null
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner (shell)
```

O `.env.staging.local` ganhou do `.env.staging`, e o shell ganhou dos dois. **Essa última regra é aquela
em que um host se apoia**: os valores digitados no painel dele chegam ao build como variáveis de ambiente
comuns, então ganham de qualquer coisa commitada.

O `git status` mostra a outra metade da tabela:

```
ana@dev:~/planner$ git status --short
?? .env.staging
```

O `.env.staging` está esperando para ir para o commit, e o `.env.staging.local` nem aparece: o `*.local`
do `.gitignore` o esconde. Faça o commit do primeiro e apague o segundo, que era só para esta
demonstração:

```
ana@dev:~/planner$ rm .env.staging.local
ana@dev:~/planner$ git add .env.staging
ana@dev:~/planner$ git commit -qm "A staging mode"
```

## E no desenvolvimento

`npm run dev` roda no modo `development`, então lê `.env`, `.env.local`, `.env.development` e
`.env.development.local`, e nunca `.env.staging`. Ele os lê quando o servidor começa, e fica de olho
neles. Com o servidor rodando num terminal, grave um arquivo para desenvolvimento a partir de um segundo:

```
ana@dev:~/planner$ echo 'VITE_TITLE=Study planner (dev)' > .env.development.local
```

O primeiro terminal mostra o Vite percebendo, e se reiniciando para pegar a mudança:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 275 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
7:40:38 PM [vite] .env.development.local changed, restarting server...
7:40:38 PM [vite] server restarted.
```

**Esse reinício é só do dev server.** Um build lê os arquivos uma vez, e um site publicado fica com o
valor com que foi construído até o próximo build, digam o que disserem os arquivos depois.

Apague o `.env.development.local` depois de ver o reinício; nenhuma aula seguinte o usa.
