---
title: Ninguém faz push na main
version: 1
---

**Quem escreve na `main` muda a produção**, porque o agente aplica o que a `main` disser. Proteger o
branch é proteger o cluster, e a proteção tem duas partes: uma segunda pessoa, e uma regra de que
nada chega à `main` sem ela.

## Uma segunda pessoa

Uma revisão precisa de quem revise. No seu laboratório você faz as duas pessoas, então crie a
segunda conta e um token para ela:

```
ana@laptop:~/fleet$ docker exec gitea gitea admin user create --username bruno --password 'change-me-too' --email bruno@example.org --must-change-password=false
New user 'bruno' has been successfully created!
ana@laptop:~/fleet$ docker exec gitea gitea admin user generate-access-token --username bruno --token-name terminal --scopes write:repository --raw > ~/bruno.token
ana@laptop:~/fleet$ chmod 600 ~/bruno.token
ana@laptop:~/fleet$ curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "$AS_ANA" -H "$JSON" -d '{"permission": "write"}' $API/collaborators/bruno
204
```

O Bruno agora é um **colaborador** com permissão `write`: ele pode enviar branches e aprovar pull
requests no `fleet`. Mais uma variável, para o token dele:

```sh
AS_BRUNO="Authorization: token $(cat ~/bruno.token)"
```

## A regra

Uma regra de proteção de branch na `main` diz três coisas aqui. **Nenhum push direto**, de ninguém,
administradores inclusive. **Uma aprovação** antes que um pull request possa entrar. E **uma
aprovação é descartada quando chegam commits novos**, para que quem revisa aprove exatamente o que
entra, e não uma versão anterior.

```
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"rule_name": "main", "enable_push": false, "required_approvals": 1, "dismiss_stale_approvals": true}' $API/branch_protections | jq '{rule_name, enable_push, required_approvals, dismiss_stale_approvals}'
{
  "rule_name": "main",
  "enable_push": false,
  "required_approvals": 1,
  "dismiss_stale_approvals": true
}
```

Agora tente do jeito antigo. Mude a mensagem no `staging/bulletin.yaml` para `Staging is ready for
review.` e envie direto para a `main`:

```
ana@laptop:~/fleet$ git commit --quiet -am "staging: ready for review"
ana@laptop:~/fleet$ git push
remote: 
remote: error:        
remote: error: Not allowed to push to protected branch main        
remote: error:        
To http://localhost:3000/ana/fleet.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to 'http://localhost:3000/ana/fleet.git'
```

`Not allowed to push to protected branch main`. O commit existe na sua máquina e em nenhum outro
lugar. Ele não se perdeu: ponha-o num branch próprio e volte a `main` para onde o servidor a tem,

```
ana@laptop:~/fleet$ git switch -c banner-v2
Switched to a new branch 'banner-v2'
ana@laptop:~/fleet$ git switch main
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)
ana@laptop:~/fleet$ git reset --hard origin/main
HEAD is now at 7cb8caf Revert "staging: no service"
```

e a `main` volta a combinar com o servidor, enquanto a mudança espera no `banner-v2` pelo pull
request da próxima seção.
