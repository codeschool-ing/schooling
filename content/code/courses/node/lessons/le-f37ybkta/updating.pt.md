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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Uma linha de versões do Express de 5.0.0 a 6.0.0 e além. A faixa ^5.1.0 cobre de 5.1.0 até 6.0.0, sem incluir o 6.0.0. O Current é 5.1.0, o que o node_modules tem; Wanted e Latest são os dois 5.3.0, o mais novo que a faixa aceita. Um 6.0.0, se fosse publicado, seria o Latest e ficaria fora da faixa, e o npm update não iria até ele.\"><line x1=\"30\" y1=\"110\" x2=\"700\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"700.0,110.0 692.6,113.1 692.6,106.9\" fill=\"var(--wire)\"></polygon><line x1=\"60\" y1=\"104\" x2=\"60\" y2=\"116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"60\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5.0.0</text><line x1=\"170\" y1=\"104\" x2=\"170\" y2=\"116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"170\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5.1.0</text><line x1=\"280\" y1=\"104\" x2=\"280\" y2=\"116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"280\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5.2.0</text><line x1=\"390\" y1=\"104\" x2=\"390\" y2=\"116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"390\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5.3.0</text><line x1=\"560\" y1=\"104\" x2=\"560\" y2=\"116\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"560\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">6.0.0</text><rect x=\"170\" y=\"78\" width=\"385\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"362\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">^5.1.0</text><text x=\"170\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Current</text><line x1=\"170\" y1=\"66\" x2=\"170\" y2=\"76\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></line><text x=\"390\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Wanted = Latest</text><line x1=\"390\" y1=\"66\" x2=\"390\" y2=\"76\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"560\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um major novo: fora da faixa</text><text x=\"560\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o npm update não mexe</text><text x=\"280\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o npm update vem até aqui</text></svg>", "caption": "Uma faixa com circunflexo aceita toda versão minor e patch do seu major, e nada além dele."}
```

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
