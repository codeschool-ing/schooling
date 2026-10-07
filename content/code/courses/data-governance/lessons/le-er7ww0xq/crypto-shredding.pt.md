---
title: Destruindo uma chave de propósito
version: 1
---

Alguns dados precisam ser apagados em lugares de onde ninguém consegue apagá-los: os backups do ano
passado, uma cópia em outra região, uma fita num cofre. A aula 7 traz o motivo jurídico — o direito
de um cliente de ter seus dados eliminados — e a aula 10 as regras de retenção. Esta seção traz a
técnica, que só um serviço de gestão de chaves torna possível: **se o dado foi cifrado com uma
chave que só pertence a ele, destruir a chave apaga todas as cópias de uma vez.** Isso se chama
**crypto-shredding**, destruição criptográfica.

Uma chave para um cliente, e algo cifrado com ela:

```
ana@lab:~/gov$ bao write -f transit/keys/ipe-customer-4711
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          false
derived                   false
exportable                false
imported_key              false
keys                      map[1:1791343895]
latest_version            1
min_available_version     0
min_decryption_version    1
min_encryption_version    0
name                      ipe-customer-4711
soft_deleted              false
supports_decryption       true
supports_derivation       true
supports_encryption       true
supports_signing          false
type                      aes256-gcm96
ana@lab:~/gov$ printf '%s\n' vault:v1:yyUANlXaryMx87hy+lIDWOk/ON96J4uh8NOXPUujRtbVwIatK6+yf4criKkZV9qrxc+rQPg=
vault:v1:yyUANlXaryMx87hy+lIDWOk/ON96J4uh8NOXPUujRtbVwIatK6+yf4criKkZV9qrxc+rQPg=
ana@lab:~/gov$ bao write transit/keys/ipe-customer-4711/config deletion_allowed=true
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          true
derived                   false
exportable                false
imported_key              false
keys                      map[1:1791343895]
latest_version            1
min_available_version     0
min_decryption_version    1
min_encryption_version    0
name                      ipe-customer-4711
soft_deleted              false
supports_decryption       true
supports_derivation       true
supports_encryption       true
supports_signing          false
type                      aes256-gcm96
ana@lab:~/gov$ bao delete transit/keys/ipe-customer-4711
Success! Data deleted (if it existed) at: transit/keys/ipe-customer-4711
ana@lab:~/gov$ bao write transit/decrypt/ipe-customer-4711 ciphertext=vault:v1:yyUANlXaryMx87hy+lIDWOk/ON96J4uh8NOXPUujRtbVwIatK6+yf4criKkZV9qrxc+rQPg=
Error writing data to transit/decrypt/ipe-customer-4711: Error making API request.

URL: PUT https://bao.ipe.example:8200/v1/transit/decrypt/ipe-customer-4711
Code: 400. Errors:

* encryption key not found
```

O transit se recusa a apagar uma chave até a configuração dela dizer `deletion_allowed true`, um
segundo passo, deliberado, que torna impossível apagar por acidente. Aí a chave vai embora, e o
texto cifrado — onde quer que estejam as cópias dele, backups incluídos — responde `encryption key
not found`. Não "acesso negado", que outro token talvez superasse: não sobrou chave em lugar nenhum
para decifrar.

## O preço de poder fazer isso

**Uma chave por cliente são muitas chaves.** A Ipê tem 6.012 clientes, então 6.012 chaves, cada uma
para criar, proteger, guardar em backup e auditar. Os serviços aguentam essa escala, mas alguém
precisa projetar para ela, e ela só faz sentido para dado que realmente precisa ser apagável por
pessoa enquanto cópias dele vivem onde um `DELETE` não alcança.

**É irreversível, e esse é o objetivo e o perigo.** Uma chave apagada por engano destrói dado que
ninguém queria perder, em todo backup. É por isso que `deletion_allowed` existe, por que o passo
deve ser uma operação revisada e não o efeito colateral de um script, e por que os backups do
próprio OpenBao — que guardam as chaves — precisam de uma política de retenção que combine com a
promessa: um backup do serviço de chaves guardado por um ano quer dizer que uma chave destruída é
recuperável por um ano.

**Ele apaga só o que foi cifrado só com aquela chave.** As anotações de um cliente cifradas com a
chave dele somem; as mesmas anotações copiadas em claro num chamado de suporte, não. A destruição
só é tão completa quanto a disciplina sobre onde o texto claro pôde ir, que é de novo o inventário
de cópias da aula 3.
