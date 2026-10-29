---
title: Um registry seu
version: 1
---

**Um registry de pacotes é um servidor que guarda versões publicadas e responde ao `npm install`, e um
privado pode rodar no seu computador.** Empresas rodam um para os pacotes internos não serem públicos,
usando o GitHub Packages, o registry do GitLab, um serviço hospedado ou um servidor próprio. O
**Verdaccio** é um registry de código aberto que fala o mesmo protocolo do npm, então os mesmos comandos do
`npm` funcionam contra ele; esta seção o roda localmente, onde não custa nada e não precisa de conta.

Ele ganha uma pasta própria e um arquivo de configuração:

```yaml
# ~/registry/config.yaml
storage: ./storage
auth:
  htpasswd:
    file: ./htpasswd
uplinks:
  npmjs:
    url: https://registry.npmjs.org/
packages:
  "@planner/*":
    access: $authenticated
    publish: $authenticated
  "**":
    access: $all
    proxy: npmjs
listen: 127.0.0.1:4873
log: { type: stdout, format: pretty, level: warn }
```

Leia de baixo para cima: ele escuta só neste computador, na porta 4873. **Pacotes do escopo `@planner` só
podem ser lidos e publicados por um usuário que fez login**, que é o ponto de um registry privado. Todo o
resto pode ser lido por qualquer um e é buscado no registry público, o `uplink` dele, quando alguém pede,
então o mesmo registry consegue servir todas as dependências de um projeto. Usuários e senhas vão num
arquivo chamado `htpasswd` ao lado da configuração.

## Rodando

O `npx` roda um pacote sem instalá-lo num projeto; a versão é fixada como a de toda outra ferramenta:

```
ana@dev:~/registry$ npx -y verdaccio@6.10.7 --config ./config.yaml
warn --- you are using Node.js v22.22.0, Verdaccio recommends Node.js v24 or higher, please consider upgrading your Node.js distribution
warn --- http address - http://127.0.0.1:4873/ - verdaccio/6.10.7
```

O **Verdaccio 6.10.7** roda, e avisa que recomenda o Node 24. Ele funciona no Node 22 do curso, e o aviso
é o projeto dizendo para onde está indo. Deixe-o rodando num terminal próprio.

## Fazendo login

Publicar precisa de um usuário. O `npm adduser` cria um num registry que permite, como o Verdaccio permite
por padrão, e faz o login:

```
ana@dev:~/planner-ui$ npm adduser --registry http://127.0.0.1:4873/ --auth-type=legacy
npm notice Log in on http://127.0.0.1:4873/
Username: ana
Password: 
Email: (this IS public) 
ana@example.org

Logged in on http://127.0.0.1:4873/.
```

A senha foi digitada e não aparece, como em qualquer pedido de senha. **O npm guardou um token desse
registry em `~/.npmrc`**, na sua pasta pessoal, que é de onde todo comando seguinte o lê. Esse arquivo agora
é um segredo, do tipo de que a aula 2 tratou: nunca o copie para um projeto, e nunca o commite. O `.npmrc`
do próprio projeto, na próxima seção, guarda um endereço e mais nada.

`--auth-type=legacy` pede o usuário e a senha no terminal. O npm público usa por padrão o login pelo
navegador, que um registry no seu computador não oferece.
