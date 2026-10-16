---
title: Quem é dono de qual pasta
version: 1
---

**A regra da aula 2 pede uma aprovação de qualquer pessoa que não seja o autor.** Esse é o piso. Com
uma organização por ambiente, um time costuma querer regras mais específicas: uma mudança na produção
aprovada por alguém responsável pela produção, uma mudança em `clusters/` por alguém que cuida da
plataforma.

Um arquivo `CODEOWNERS` diz quem é dono de quais caminhos. O Gitea o lê em `.gitea/CODEOWNERS` no
branch padrão e, quando um pull request toca um caminho com dono, pede uma revisão aos donos sozinho.
Salve isto como `.gitea/CODEOWNERS` no `fleet`:

```
apps/bulletin/production/.* @bruno
clusters/.* @bruno
```

Cada linha é um padrão e as pessoas donas dos caminhos que ele casa. **O Gitea lê o padrão como uma
expressão regular casada contra o caminho inteiro**, então `apps/bulletin/production/.*` é todo arquivo
dentro daquela pasta; o GitHub e o GitLab leem o mesmo arquivo com os padrões do `.gitignore`, em que
`apps/bulletin/production/` sozinho bastaria. Aqui o Bruno é dono da produção e da
configuração do cluster; o staging não é de ninguém em particular, então qualquer revisor serve.

```
ana@laptop:~/fleet$ git switch --quiet -c owners
ana@laptop:~/fleet$ git add .gitea/CODEOWNERS
ana@laptop:~/fleet$ git commit --quiet -m "fleet: owners of production and of the cluster"
ana@laptop:~/fleet$ git switch --quiet -c production-replicas
ana@laptop:~/fleet$ git commit --quiet -am "production: three replicas"
ana@laptop:~/fleet$ git push --quiet -u origin production-replicas 2>/dev/null
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"head": "production-replicas", "base": "main", "title": "production: three replicas"}' http://localhost:3000/api/v1/repos/ana/fleet/pulls | jq .number
11
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" http://localhost:3000/api/v1/repos/ana/fleet/pulls/11 | jq '[.requested_reviewers[].login]'
[
  "bruno"
]
```

O pull request tocou `apps/bulletin/production/`, e o Gitea pôs o Bruno como revisor sem ninguém
escolhê-lo. **Um pedido não é uma exigência**: sozinho, o `CODEOWNERS` encaminha revisões, e a regra de
proteção continua contando qualquer aprovação. A proteção do Gitea tem uma opção,
`block_on_official_review_requests`, que recusa um merge enquanto um dono pedido não tiver aprovado, e
o GitHub e o GitLab têm um equivalente. Ligá-la é o passo de "a pessoa certa fica sabendo" para "a
pessoa certa decide".

**A posse por pasta é mais um motivo para a organização importar.** Se o staging e a produção vivessem
num arquivo só, ninguém seria dono de um sem ser dono do outro.
