---
title: Rotacionando uma chave sem perder o dado
version: 1
---

Chaves são rotacionadas por dois motivos. **Num calendário**, porque quanto mais tempo uma chave é
usada, mais texto cifrado depende dela e maior o estrago se ela vazar um dia; normas como o PCI DSS
pedem que toda chave tenha um tempo de vida definido. **Por suspeita**, porque uma chave que pode
ter sido exposta precisa parar de ser usada hoje, sem esperar alguém provar que foi.

A rotação ingênua — chave nova, decifrar tudo com a velha, cifrar com a nova, apagar a velha —
exige reescrever todo texto cifrado no momento da rotação, e um erro no meio perde dado. O transit
evita isso dando **versões** a uma chave:

```
ana@lab:~/gov$ bao write -f transit/keys/ipe-cpf/rotate
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          false
derived                   false
exportable                false
imported_key              false
keys                      map[1:1791350397 2:1791350399]
latest_version            2
min_available_version     0
min_decryption_version    1
min_encryption_version    0
name                      ipe-cpf
soft_deleted              false
supports_decryption       true
supports_derivation       true
supports_encryption       true
supports_signing          false
type                      aes256-gcm96
ana@lab:~/gov$ bao read -field=latest_version transit/keys/ipe-cpf; echo
2
ana@lab:~/gov$ bao write -field=ciphertext transit/encrypt/ipe-cpf plaintext=MzcyLjg3NC4xNjgtMDk=; echo
vault:v2:3GJFEtaMfyiaQftLrGC5X+ARuxp4PlBVdVdERYfb/0OaiIfDNGv2eFIj
ana@lab:~/gov$ bao write -field=plaintext transit/decrypt/ipe-cpf ciphertext=$(cat cpf.ct) | base64 -d; echo
372.874.168-09
```

`latest_version` agora é 2. **Cifrações novas usam a versão 2**, e o texto cifrado diz isso: começa
com `vault:v2:`. **Texto cifrado antigo continua decifrando**: o CPF `v1` em `cpf.ct`, feito antes
da rotação, voltou intacto. Nada precisou ser reescrito para a rotação valer.

## Aposentando a versão antiga

Uma rotação por suspeita não termina enquanto a versão 1 ainda decifra, e o texto cifrado antigo
pode passar para a versão nova **sem que o OpenBao jamais o mostre em claro a ninguém**:

```
ana@lab:~/gov$ bao write -field=ciphertext transit/rewrap/ipe-cpf ciphertext=$(cat cpf.ct); echo
vault:v2:LyvGZ/YOHYorJdLGpMnImUvV2gm85HPJ+y+tEJhRtGPBebgxJ6eV8gY1
ana@lab:~/gov$ bao write transit/keys/ipe-cpf/config min_decryption_version=2
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          false
derived                   false
exportable                false
imported_key              false
keys                      map[2:1791350399]
latest_version            2
min_available_version     0
min_decryption_version    2
min_encryption_version    0
name                      ipe-cpf
soft_deleted              false
supports_decryption       true
supports_derivation       true
supports_encryption       true
supports_signing          false
type                      aes256-gcm96
ana@lab:~/gov$ bao write transit/decrypt/ipe-cpf ciphertext=$(cat cpf.ct)
Error writing data to transit/decrypt/ipe-cpf: Error making API request.

URL: PUT https://bao.ipe.example:8200/v1/transit/decrypt/ipe-cpf
Code: 400. Errors:

* ciphertext or signature version is disallowed by policy (too old)
```

**`rewrap`** recebe um texto cifrado `v1` e devolve o mesmo texto claro cifrado como `v2`; o texto
claro só existe dentro do OpenBao durante a chamada. Um job que faz rewrap de todo texto cifrado de
uma tabela leva o dado para a versão nova sem que o job, ou quem o opera, consiga lê-lo — que é
exatamente a propriedade de que uma rotação depois de suspeita de vazamento precisa.

Depois, **`min_decryption_version=2`** aposenta a versão 1: a lista da chave agora tem só a versão
2, e o texto cifrado `v1` original é recusado como `too old`. Tudo o que ainda estiver cifrado com a
versão 1 depois disso fica ilegível, então a ordem é fixa: **rewrap primeiro, subir o mínimo
depois**, e contar os textos `v1:` que sobraram antes de subir.

## Num calendário

O transit consegue rotacionar uma chave sozinho (`auto_rotate_period` na configuração da chave), e
os serviços de nuvem oferecem o mesmo. A rotação automática cria a versão nova; ela não faz rewrap,
e não aposenta versões antigas. Esses dois passos continuam sendo trabalho de alguém, e o registro
honesto de uma política de rotação não é "as chaves rotacionam todo ano", e sim "as chaves
rotacionam todo ano, as versões antigas passam por rewrap em um mês e são aposentadas depois".
