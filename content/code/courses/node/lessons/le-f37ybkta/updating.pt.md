---
title: Mantendo as dependências em dia
version: 1
---

**Uma dependência que nunca é atualizada vira uma dependência com um buraco conhecido**, e quanto mais
ela espera, maior o salto quando alguém finalmente precisa dá-lo. Atualizar é trabalho de rotina,
feito em passos pequenos, e o npm tem um comando para ver onde você está e um para andar.

Para ter algo a atualizar, faça um projeto de rascunho ao lado do `links` que fixe o Express numa
versão mais antiga, a 5.1.0, e tenha uma faixa que permita as mais novas:

```
ana@dev:~/server/older$ echo '{ "name": "older", "private": true }' > package.json
ana@dev:~/server/older$ npm install express@5.1.0

added 68 packages, and audited 69 packages in 939ms

28 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/server/older$ npm outdated; echo "exit code $?"
Package  Current  Wanted  Latest  Location              Depended by
express    5.1.0   5.3.0   5.3.0  node_modules/express  older
exit code 1
```

## outdated

O `npm outdated` compara três versões de cada dependência direta:

| coluna | significado |
|---|---|
| Current | o que está em `node_modules` agora |
| Wanted | a mais nova que a faixa do `package.json` aceita |
| Latest | a mais nova publicada, seja qual for a faixa |

Current 5.1.0, Wanted e Latest 5.3.0: a faixa `^5.1.0` já permite a mais nova, então a atualização é
uma minor, que o versionamento semântico promete que não vai quebrar você. **O npm sai com código 1
quando há algo desatualizado**, e é por isso que um script consegue usá-lo como verificação.

## update

O `npm update` leva cada dependência à versão Wanted, reescreve o lockfile, e deixa as faixas do
`package.json` como estão:

```
ana@dev:~/server/older$ npm update

removed 3 packages, changed 3 packages, and audited 66 packages in 585ms

28 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/server/older$ npm ls
older@ /home/ana/server/older
└── express@5.3.0
```

## Uma versão major é uma decisão

Quando a Latest é uma major nova — Express 4 para 5, digamos — o `npm update` não faz nada, porque a
faixa não permite, e isso está certo. **Uma versão major é o autor avisando que algo vai quebrar.** O
Express publica um guia de migração do 4 para o 5, e as aulas 6 e 7 apontam as mudanças que importam
num servidor: a sintaxe dos caminhos de rota, os erros de handlers `async`, o `req.body` quando nada
foi enviado. O caminho é o mesmo para qualquer pacote: ler o que a major nova mudou, instalá-la com
`npm install express@5`, rodar os testes, e corrigir o que eles encontrarem.

Pouco e sempre é o hábito. Um projeto que anda uma minor por mês nunca enfrenta a tarde de andar
quatro majors de uma vez, que é a tarde que a auditoria da próxima seção costuma forçar.
