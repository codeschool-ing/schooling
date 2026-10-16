---
title: O que o Git e o servidor lembram
version: 1
---

**O Git responde *o quê* e *quando*; o servidor Git responde *quem concordou*.** Um commit carrega
um autor, um committer, duas datas e uma mensagem, e o hash dele os amarra a exatamente uma árvore
de arquivos. O pull request em volta carrega o que o commit não consegue: quem o abriu, quem
aprovou, o que a checagem disse e quem fez o merge.

Os commits que chegaram à `main` de `fleet`, do mais novo para o mais antigo:

```
ana@laptop:~/fleet$ git log --first-parent --format='%h %ad %s' --date=format:'%m-%d %H:%M' main | head -n 8
dbee7f1 10-16 04:53 Merge pull request 'staging: no debugging account' (#23) from revert-staging-debug into main
4378df8 10-16 04:48 Merge pull request 'staging: a debugging account' (#22) from staging-debug into main
79a931a 10-16 04:48 Merge pull request 'staging-applier: its namespace and its sealed secrets' (#21) from staging-applier-extra into main
db03e43 10-16 04:43 Merge pull request 'staging: applied as staging-applier' (#20) from staging-applier into main
2ae2f39 10-16 04:42 Merge pull request 'production: the token comes from Vault' (#19) from production-vault into main
378dd13 10-16 04:41 Merge pull request 'external-secrets: the operator, 1.3.2' (#18) from external-secrets into main
c4ba102 10-16 04:40 Merge pull request 'vault: an identity to check tokens with, and one for production' (#17) from vault-auth into main
839828e 10-16 04:40 Merge pull request 'production: a token encrypted with SOPS' (#16) from production-token into main
```

`--first-parent` segue a `main` e nada mais, então cada linha é um pull request, do mais novo para o
mais antigo: o revert que fechou a aula 11 em cima, pull request 23, e as mudanças das aulas 9 a 11
abaixo dele. As datas são do servidor, gravadas quando cada merge aconteceu.

Cada linha `Merge pull request` é do servidor: registra o número do pull request e o branch, e o
segundo pai dela é o commit que alguém escreveu. **O autor desse commit é texto**, como disse a aula
8; o que o servidor acrescenta é a conta que fez o push e as contas que revisaram, e ele registra
isso diga o commit o que disser. A API do Gitea os dá para qualquer pull request, com o `$AS_ANA` e
o `$API` da aula 2:

```
ana@laptop:~/fleet$ N=$(curl -s -H "$AS_ANA" "$API/pulls?state=closed&limit=1" | jq '.[0].number'); echo $N
23
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" $API/pulls/$N | jq '{title, opened_by: .user.login, merged_by: .merged_by.login, merged_at, merge_commit_sha}'
{
  "title": "staging: no debugging account",
  "opened_by": "ana",
  "merged_by": "ana",
  "merged_at": "2026-10-16T04:53:32Z",
  "merge_commit_sha": "dbee7f14f470f86002116cfceee7fad4278fa244"
}
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" $API/pulls/$N/reviews | jq -c '.[] | {by: .user.login, state, submitted_at}'
{"by":"bruno","state":"APPROVED","submitted_at":"2026-10-16T04:53:32Z"}
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" $API/commits/$(git rev-parse HEAD^2)/statuses | jq -c '.[] | {context, status, by: .creator.login}'
{"context":"validate","status":"success","by":"ci"}
```

Pull request 23: aberto por `ana`, aprovado por `bruno`, com merge feito por `ana`, num horário e
num commit que o servidor registrou. O commit dele tem um status, `validate`, publicado pela conta
`ci`. Nada aqui depende do que o commit diz de si mesmo.

O commit assinado da aula 8 é o único lugar em que o histórico diz mais que o servidor: o Git
confere a assinatura contra os signatários permitidos, aqui, na sua própria máquina, sem confiar em
nada além da lista de chaves:

```
ana@laptop:~/fleet$ git log --show-signature -1 --format='%h %an %s' $(git log --no-merges --format=%h --grep='back to the signed chart' -1)
Good "git" signature for ana@example.org with ED25519 key SHA256:JTvPwQC6FsWa2odLTarjFyxrssN4MZrlG4wj3RfMRUo
74e4555 Ana Lima preview: back to the signed chart
```

**Três perguntas, três lugares para perguntar.** O que mudou: o diff do commit. Quem concordou: as
revisões do pull request. Quem escreveu: a assinatura, onde houver, e a conta que fez o push, onde
não houver.
