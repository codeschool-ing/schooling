---
title: O código que você não escreveu
version: 1
---

**Todo pacote em `node_modules` que chega ao navegador roda com os direitos da página, e todo que roda no
build ou nos testes roda com os seus.** O código do próprio planner são algumas centenas de linhas; o
código que ele instalou é muito mais:

```
ana@dev:~/planner$ npm ls --all --parseable | wc -l
114
```

**114 pacotes, para um app que publica um script de 3 kB.** Quase todos são ferramentas que nunca chegam
ao navegador, o Vite, o Vitest, o Playwright e aquilo de que eles dependem, e eles rodam no seu computador
toda vez que você digita `npm test`. Uma Software Supply Chain Failure, a A03 da lista de 2025, é qualquer
um deles ser vulnerável ou trocado pelo código de outra pessoa.

Três coisas que o planner já faz a respeito, e um comando:

- **Versões exatas e um lockfile.** O `package.json` cita versões exatas e o `package-lock.json` cita
  todo pacote abaixo delas, com um hash de cada. O `npm ci` instala exatamente isso, então uma versão
  publicada amanhã não chega ao seu projeto sem ser pedida.
- **Hashes de integridade.** Cada entrada do lockfile tem o hash do arquivo que o npm baixou; uma cópia
  que difere num byte é recusada na instalação.
- **Assinaturas.** O registro do npm assina o que serve, e o npm consegue conferir cada pacote instalado
  contra essas assinaturas com um comando:

```sh
npm audit signatures
```

*Esse comando não foi rodado onde este curso foi gravado.* Ele busca as chaves contra as quais confere nos
servidores do Sigstore, e a máquina de gravação foi recusada ali; na sua máquina ele mostra quantos
pacotes tiveram assinaturas verificadas, e cita os que não tiveram.

E as **vulnerabilidades conhecidas**: o `npm audit` compara cada versão instalada com os avisos publicados
para ela.

```
ana@dev:~/planner$ npm audit
found 0 vulnerabilities
```

**Nada conhecido, hoje.** Essa frase tem data: um pacote limpo agora pode ter um aviso no mês que vem, e é
por isso que o `npm audit` pertence às checagens que um projeto roda em todo pull request, e não à
transcrição de um curso.

## Para um script carregado de outro lugar

Uma página que carrega um script de uma CDN em vez do próprio build consegue fazer o navegador conferi-lo,
com o **Subresource Integrity**: um atributo `integrity="sha384-…"` na tag `<script>`, o hash do arquivo
que a página espera. Se a CDN algum dia servir outra coisa, o navegador a recusa. O planner não carrega
nada de outro lugar, o que o `script-src 'self'` da aula 8 recusaria de qualquer jeito, e essa é a versão
mais forte da mesma ideia.
