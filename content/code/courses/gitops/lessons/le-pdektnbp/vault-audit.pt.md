---
title: Quem leu qual segredo
version: 1
---

**O Vault responde a pergunta que nenhum outro registro daqui responde: quem leu um segredo, e
quando.** Um audit device grava cada pedido e cada resposta, antes de o Vault agir, num arquivo, num
socket ou no log do sistema. Fica desligado até alguém ligá-lo, e a primeira coisa a saber dele é a
propriedade que o torna confiável: **se o Vault não consegue gravar em nenhum audit device, ele
recusa o pedido.** Uma leitura sem registro não é possível.

O Vault roda num contêiner, então o arquivo fica dentro dele, no diretório que a imagem prepara para
logs:

```
ana@laptop:~/setup$ vault audit enable file file_path=/vault/logs/audit.log
Success! Enabled the file audit device at: file/
ana@laptop:~/setup$ vault audit list
Path     Type    Description
----     ----    -----------
file/    file    n/a
```

Agora uma leitura, a que o operador da aula 10 faz a cada minuto para o token de produção, e a
entrada que ela deixou:

```
ana@laptop:~/setup$ docker exec vault cat /vault/logs/audit.log | jq -c 'select(.type == "response" and .request.path == "secret/data/bulletin/production") | {time, op: .request.operation, path: .request.path, role: .auth.metadata.role, account: .auth.metadata.service_account_name, namespace: .auth.metadata.service_account_namespace, token: .response.data.data.token}' | tail -n 1
{"time":"2026-10-16T04:54:43.748291356Z","op":"read","path":"secret/data/bulletin/production","role":"bulletin-production","account":"bulletin","namespace":"production","token":"hmac-sha256:4450a34b53860338c73f2618c5b0176d61311e6ab6ccd78cf0d8c4216716257a"}
ana@laptop:~/setup$ vault write -field=hash sys/audit-hash/file input="$(vault kv get -field=token secret/bulletin/production)"; echo
hmac-sha256:4450a34b53860338c73f2618c5b0176d61311e6ab6ccd78cf0d8c4216716257a
```

Uma leitura de `secret/data/bulletin/production`, pelo role do Kubernetes `bulletin-production`,
como a ServiceAccount `bulletin` em `production`. Onde estaria o valor do token há uma string
`hmac-sha256:`, e o Vault calcula a mesma string para o valor que guarda, então a entrada fala
daquele valor sem contê-lo.

**Os valores não estão no log.** Toda string que poderia ser um segredo, o token que o Vault
entregou e os dados que devolveu, é trocada por um HMAC: um hash com chave que o Vault consegue
recalcular. Assim o log pode ir para um serviço de logs e ser lido por um auditor sem virar uma
cópia de todo segredo. Quando alguém pergunta "este token em particular chegou a ser lido?", `vault
write sys/audit-hash/file input=...` calcula o mesmo HMAC para um valor que você tem, e você procura
por ele no log.

O que a entrada nomeia, em claro, é o caminho, a operação, o horário e a identidade: o role do auth
do Kubernetes, a ServiceAccount e o namespace dela. Esse é o elo do Vault de volta ao cluster, e de
lá, pelo ExternalSecret, de volta ao Git.
