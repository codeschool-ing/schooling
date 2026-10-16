---
title: Três cópias, dois tipos, uma em outro lugar
version: 1
---

Todo backup deste curso até aqui ficou na mesma máquina que o banco que ele protege. A lição 3 disse
isso do snapshot da máquina virtual, e vale igualmente para o repositório da lição 5 em
`/var/lib/pgbackrest`: um disco que falha, uma máquina que é apagada, um data center que alaga, ou uma
pessoa com a senha do servidor leva o banco e todas as cópias dele de uma vez só. **Um backup na
mesma máquina é uma conveniência para erros pequenos, não um backup.**

A regra que se usa há décadas cabe numa linha:

| | |
|---|---|
| **3** | três cópias dos dados: a que está em produção e dois backups |
| **2** | em dois tipos diferentes de armazenamento, para que um tipo de falha não leve os dois |
| **1** | uma delas em outro lugar: outro prédio, outra região, outro provedor |

O ransomware acrescentou dois dígitos a ela, e é disso que trata a lição 10: **1** cópia que não pode
ser alterada nem apagada por um período definido, sejam quais forem as credenciais de quem tenta, e
**0** erros quando essa cópia é restaurada, que é o ensaio da lição 7 apontado para ela.

## O que "outro lugar" tem que significar

Outro lugar se mede pelo que pode falhar junto, não pela distância:

- **Outro disco no mesmo servidor** sobrevive a uma falha de disco e a mais nada.
- **Outro servidor no mesmo rack** sobrevive a uma falha de servidor, e não a um incêndio, a uma
  enchente ou ao switch de rede acima dos dois.
- **Outra região da mesma conta de nuvem** sobrevive à queda de uma região, e não à conta ser
  encerrada, comprometida ou bloqueada por uma fatura não paga.
- **Outro provedor, ou o mesmo provedor numa outra conta com outras credenciais**, sobrevive a tudo
  isso.

A pergunta a fazer sobre cada cópia é qual evento único a destruiria **junto com** o banco em
produção, e a cópia cuja resposta é "nenhum em que eu consiga pensar" é a que conta como offsite.

No fim desta lição as cópias do shop vão estar assim:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Duas caixas. O servidor do banco guarda o banco em produção e o repo1, o repositório local para restaurações rápidas; uma nota diz que um evento leva os dois. Em outro lugar fica o repo2, criptografado, guardado por mais tempo e imutável até uma data; todo segmento e backup chega aos dois repositórios, e o repo2 sobrevive ao evento que leva o servidor.\"><defs><marker id=\"l9p-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o servidor do banco</text><rect x=\"40\" y=\"56\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">banco em produção</text><rect x=\"200\" y=\"56\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"265\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">repo1</text><text x=\"265\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">restaurações rápidas</text><path d=\"M170 81 L198 81\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9p-pa)\"></path><text x=\"185\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um evento leva os dois</text><rect x=\"420\" y=\"20\" width=\"280\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"560\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">em outro lugar</text><rect x=\"450\" y=\"56\" width=\"220\" height=\"74\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">repo2</text><text x=\"560\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">criptografado, guardado por mais tempo,</text><text x=\"560\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">imutável até uma data</text><text x=\"560\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">sobrevive a esse evento</text><path d=\"M350 81 L448 81\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9p-pa)\"></path><text x=\"385\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">segmentos,</text><text x=\"385\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">backups</text></svg>", "caption": "Onde ficam as cópias do shop depois desta lição. O repositório local é para velocidade; só o que fica em outro lugar, legível com a senha e que ninguém apaga antes da data, conta contra os eventos que levam um servidor inteiro.", "same": ["backups"]}
```

As próximas seções dão ao shop um segundo repositório, criptografam esse repositório, perdem o
primeiro de propósito e restauram a partir do segundo, e depois fazem a pergunta mais difícil: quem
consegue apagar a cópia que deveria sobreviver a tudo.
