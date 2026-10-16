---
title: O Vault na sua máquina
version: 1
---

**O HashiCorp Vault é um servidor cujo trabalho inteiro é guardar segredos e decidir quem pode
lê-los.** Ele os guarda cifrados, entrega cada um só a quem provou quem é e tem uma política que
permita, e registra cada pedido. Ele também inventa segredos sob demanda, uma senha de banco que
existe por uma hora, o que a aula 11 usa. Aqui ele roda num contêiner ao lado do cluster, como o
registry e o Gitea.

O cliente de linha de comando é um zip do site de releases da HashiCorp, com um arquivo de checksums
ao lado:

```
ana@laptop:~/setup$ curl -fsSLO https://releases.hashicorp.com/vault/2.1.2/vault_2.1.2_linux_$ARCH.zip
ana@laptop:~/setup$ curl -fsSL https://releases.hashicorp.com/vault/2.1.2/vault_2.1.2_SHA256SUMS | grep " vault_2.1.2_linux_$ARCH.zip$" | sha256sum --check
vault_2.1.2_linux_amd64.zip: OK
ana@laptop:~/setup$ unzip -q vault_2.1.2_linux_$ARCH.zip vault && sudo install -m 0755 vault /usr/local/bin/ && rm vault vault_2.1.2_linux_$ARCH.zip
ana@laptop:~/setup$ vault version
Vault v2.1.2 (76fdd6587523c4c6cb079635075e019714d23470), built 2026-10-06T15:17:37Z
```

## Não o servidor de desenvolvimento

O Vault tem um **modo dev**, `vault server -dev`, e a maioria dos tutoriais começa por ele: um
comando, já destrancado, um token root impresso na tela, tudo guardado na memória. É um bom jeito de
experimentar um comando e um jeito ruim de aprender o Vault, porque pula as duas coisas que fazem o
Vault ser o que é: armazenamento que sobrevive a um reinício e um **selo**. Este laboratório roda o
servidor de verdade com uma configuração pequena. Salve isto como `~/vault/vault.hcl`:

```hcl
storage "raft" {
  path    = "/vault/file"
  node_id = "vault-1"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

api_addr      = "http://127.0.0.1:8200"
cluster_addr  = "http://127.0.0.1:8201"
disable_mlock = true
```

`raft` é o armazenamento próprio do Vault, guardado num volume para sobreviver ao contêiner. O
`tls_disable` é só para este laptop, onde o listener responde em `127.0.0.1` e na rede Docker do
cluster; em qualquer coisa compartilhada, o Vault fala TLS e mais nada. O `disable_mlock` é o que a
HashiCorp recomenda com o armazenamento `raft`, cujos arquivos mapeados em memória não combinam bem
com travar memória.

O contêiner entra na rede `kind`, para que o cluster o alcance como `vault`, do jeito que alcança o
`registry` e o `gitea`:

```
ana@laptop:~$ docker run -d --name vault --network kind -p 127.0.0.1:8200:8200 -v ~/vault:/vault/config:ro -v vault-data:/vault/file hashicorp/vault:2.1.2 server
2214e313b639bb282002c8ca632fc7031d6d968a1c5c010708d20ee383ebd70f
ana@laptop:~$ export VAULT_ADDR=http://127.0.0.1:8200
ana@laptop:~$ vault status
Key                     Value
---                     -----
Seal Type               shamir
Initialized             false
Sealed                  true
Total Shares            0
Threshold               0
Unseal Progress         0/0
Unseal Nonce            n/a
Version                 2.1.2
Build Date              2026-10-06T15:17:37Z
Storage Type            raft
Removed From Cluster    false
HA Enabled              true
```

`Initialized false`, `Sealed true`: um servidor que nunca foi configurado e não consegue ler o
próprio armazenamento. O código de saída do `vault status` diz o mesmo, `2` para selado, o que um
script consegue testar.

## Inicializado, depois destrancado

**O Vault cifra tudo o que guarda com uma chave que ele não mantém em disco.** Inicializar cria essa
chave e divide a chave que a protege em **chaves de destrancamento**; iniciar o servidor o deixa
**selado**, sem conseguir ler o próprio armazenamento, até que chaves suficientes sejam
apresentadas. Em produção são cinco chaves nas mãos de cinco pessoas e quaisquer três o abrem, ou um
serviço de chaves da nuvem o destranca sozinho. Aqui uma chave basta, e ela vai num arquivo que só
você lê, junto com o **token root**, que pode tudo:

```
ana@laptop:~$ vault operator init -key-shares=1 -key-threshold=1 -format=json > ~/vault-init.json && chmod 600 ~/vault-init.json
ana@laptop:~$ jq -c keys ~/vault-init.json
["recovery_keys_b64","recovery_keys_hex","recovery_keys_shares","recovery_keys_threshold","root_token","unseal_keys_b64","unseal_keys_hex","unseal_shares","unseal_threshold"]
ana@laptop:~$ vault operator unseal $(jq -r '.unseal_keys_b64[0]' ~/vault-init.json) | grep -E '^(Initialized|Sealed)'
Initialized             true
Sealed                  false
```

O arquivo guarda as chaves de destrancamento, o token root e as equivalentes de recuperação, e o `jq
-c keys` mostra a forma dele sem imprimir nenhuma delas. Uma chave o destrancou: `Sealed false`.

## Um segredo, e um reinício

O motor chave-valor do Vault guarda segredos versionados sob caminhos. Ele é habilitado uma vez, em
`secret/`:

```
ana@laptop:~$ export VAULT_TOKEN=$(jq -r .root_token ~/vault-init.json)
ana@laptop:~$ vault secrets enable -path=secret kv-v2
Success! Enabled the kv-v2 secrets engine at: secret/
ana@laptop:~$ vault kv put secret/bulletin/staging token=$(openssl rand -hex 16) >/dev/null
ana@laptop:~$ vault kv put secret/bulletin/production token=$(openssl rand -hex 16)
========= Secret Path =========
secret/data/bulletin/production

======= Metadata =======
Key                Value
---                -----
created_time       2026-10-16T00:49:25.786557741Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
ana@laptop:~$ vault kv get -field=token secret/bulletin/production | sha256sum | cut -c1-12
94054ba47262
```

Versão 1 de `bulletin/production`, escrita na hora que o Vault mostra; cada escrita seguinte é uma
versão nova, e as antigas continuam legíveis até alguém destruí-las. A impressão digital é a que os
pods da produção vão mostrar quando a aula 10 a ler daqui.

Agora a propriedade que o modo dev esconde. Reinicie o contêiner, como um reinício do laptop faria:

```
ana@laptop:~$ docker restart vault
vault
ana@laptop:~$ vault status | grep -E '^(Initialized|Sealed)'
Initialized             true
Sealed                  true
ana@laptop:~$ vault kv get secret/bulletin/production
Error making API request.

URL: GET http://127.0.0.1:8200/v1/sys/internal/ui/mounts/secret/bulletin/production
Code: 503. Errors:

* Vault is sealed
ana@laptop:~$ vault operator unseal $(jq -r '.unseal_keys_b64[0]' ~/vault-init.json) | grep '^Sealed'
Sealed                  false
```

**Depois de todo reinício o Vault está selado, e nada consegue ler um segredo até alguém
destrancá-lo.** É o preço de um cofre que não guarda a própria chave ao lado dos dados, e o motivo
de as instalações reais usarem destrancamento automático com um serviço de chaves da nuvem: um Vault
selado às três da manhã é uma queda para tudo o que depende dele. O token root serve para configurar
o Vault; depois disso, pessoas e programas recebem tokens próprios, com políticas que permitem o que
precisam. A próxima seção dá um ao cluster.
