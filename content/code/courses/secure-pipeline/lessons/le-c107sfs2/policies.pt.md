---
title: Uma policy que lê um caminho, e um token que morre
version: 1
---

Dois dos três estreitamentos são ferramentas do dia a dia do Vault. **Uma policy diz o que um token
pode fazer, e o tempo de vida do token diz por quanto tempo.** Os dois aparecem aqui com um token
feito à mão; as duas próximas seções trocam a mão pela identidade do próprio pipeline.

### A policy

O Vault recusa tudo o que uma policy não concede, então uma policy é uma lista do que é permitido e
de mais nada. O pipeline em `main` precisa ler um valor, a senha de assinatura, e a policy diz
exatamente isso. Ela pertence a quem opera o Vault, não ao projeto, então mora ao lado dos outros
arquivos do servidor de CI. Salve-a como `~/ci/vault/linkbox-sign.hcl`:

```hcl
# What a run of linkbox's pipeline on main may do in Vault: read the
# password of the signing key. Not list the secrets beside it, not write
# this one, not read any other path.
path "secret/data/linkbox/signing" {
  capabilities = ["read"]
}
```

O caminho é o da API, da seção anterior, com `data/` no meio. **Capabilities são verbos**: `read`,
`create`, `update`, `delete` e `list` são os que um armazenamento chave/valor usa, e `sudo` e `deny`
são os dois que mudam como os outros valem. Uma policy que concedesse `list` em
`secret/metadata/linkbox/` deixaria o pipeline ver o nome de todo segredo ao lado deste, o que já é
mais do que ele precisa. Um caminho pode terminar em `*` para casar com tudo abaixo dele, e é desse
asterisco que vem a maioria das policies largas demais: `secret/data/linkbox/*` parece "os segredos
do linkbox" e concede todo segredo que qualquer time acrescente depois com esse nome.

Carregue-a no Vault e crie um token que a leva e vive trinta segundos:

```
ana@vm:~/linkbox$ vault policy write linkbox-sign - <~/ci/vault/linkbox-sign.hcl
Success! Uploaded policy: linkbox-sign
ana@vm:~/linkbox$ t=$(vault token create -policy=linkbox-sign -ttl=30s -field=token)
ana@vm:~/linkbox$ vault token lookup "$t" | grep -E "^(policies|ttl) "
policies            [default linkbox-sign]
ttl                 30s
```

`vault token create` imprime uma tabela por padrão; `-field=token` imprime só o token, que vai para a
variável de shell `t` e nunca para a tela. A consulta confirma duas coisas. O token leva
`linkbox-sign` e também `default`, uma policy que todo token recebe, que deixa um token consultar a
si mesmo e se renovar ou se revogar. E o `ttl` dele são os trinta segundos com que foi criado, contando a partir do
momento da criação.

### Usando como um pipeline usaria

Daqui em diante os comandos são o lado do pipeline, então usam `curl` contra a API HTTP do Vault em
vez da função `vault`, que roda como root. `VAULT_ADDR` no seu shell é o endereço que o pipeline
receberia. Leia os nomes das chaves da senha, depois tente um caminho que a policy não nomeia, depois
tente escrever:

```
ana@vm:~/linkbox$ export VAULT_ADDR=http://127.0.0.1:8200
ana@vm:~/linkbox$ curl -s -H "X-Vault-Token: $t" $VAULT_ADDR/v1/secret/data/linkbox/signing | jq -c ".data.data | keys"
["password"]
ana@vm:~/linkbox$ curl -s -H "X-Vault-Token: $t" $VAULT_ADDR/v1/secret/data/linkbox/registry | jq -c
{"errors":["1 error occurred:\n\t* permission denied\n\n"]}
ana@vm:~/linkbox$ curl -s -H "X-Vault-Token: $t" --data "{\"data\": {\"password\": \"x\"}}" $VAULT_ADDR/v1/secret/data/linkbox/signing | jq -c
{"errors":["1 error occurred:\n\t* permission denied\n\n"]}
```

A leitura responde `["password"]`, os nomes dos campos naquele caminho, e nada sobre os valores:
pedir as chaves ao `jq` é como conferir que uma leitura funcionou sem imprimir um segredo. O outro
caminho e a escrita respondem **permission denied**. O Vault não diz se
`secret/data/linkbox/registry` existe, e isso é de propósito: um token capaz de distinguir um segredo
inexistente de um proibido conseguiria mapear o que não tem permissão de ler.

### Vendo o token morrer

O token foi criado com trinta segundos de vida. Espere esse tempo e repita a leitura que funcionou:

```
ana@vm:~/linkbox$ sleep 30
ana@vm:~/linkbox$ curl -s -H "X-Vault-Token: $t" $VAULT_ADDR/v1/secret/data/linkbox/signing | jq -c
{"errors":["2 errors occurred:\n\t* permission denied\n\t* invalid token\n\n"]}
```

O mesmo pedido, o mesmo caminho, recusado, e agora com um segundo motivo: **invalid token**. O Vault
esquece um token expirado, então para o servidor ele não existe mais. Ninguém revogou nada e nenhum
job precisou se lembrar de limpar. Um token vazado num log no segundo 10 não vale nada no segundo 31.

A vida de um token tem dois limites no Vault. O **TTL** é quanto ele vive se não for renovado, e o
**TTL máximo** é o teto que as renovações não passam. Um token que um job renova a cada poucos
minutos pode durar mais que o job se nada o impedir, então um token de CI pede um máximo próximo da
duração de uma execução. A role, daqui a duas seções, põe os dois em cinco minutos.

### O que isso resolveu, e o que não resolveu

Duas das três perguntas agora têm respostas estreitas. **O quê**: um caminho, só leitura. **Por
quanto tempo**: trinta segundos aqui, cinco minutos para o pipeline. A terceira, **quem**, está
intocada, e é a cara. Para usar esse token, uma execução precisa recebê-lo, o que significa alguém ou
alguma coisa com o root token, ou com um token de vida longa que pode criar tokens, sentado no
servidor de CI fabricando-os. Esse token de vida longa é a senha da primeira seção com outro nome.

**Uma credencial de vida curta vale o que vale o jeito de obtê-la.** Se obtê-la exige um segredo de
vida longa, a vida curta é enfeite. A próxima seção remove esse segredo mudando o que o pipeline
apresenta: não algo que ele guarda, mas uma afirmação sobre o que ele é, assinada pelo servidor de CI.
