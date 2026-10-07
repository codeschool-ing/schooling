---
title: O motor transit
version: 1
---

O OpenBao faz vários trabalhos, cada um num motor montado num caminho. O que o transforma num
serviço de gestão de chaves é o **transit**: ele guarda chaves e oferece cifrar, decifrar e mais
algumas operações sobre dados que passam por ele e nunca são guardados. O nome diz isso: o dado
está em trânsito pelo serviço, não em repouso nele.

```
ana@lab:~/gov$ bao secrets enable transit
Success! Enabled the transit secrets engine at: transit/
ana@lab:~/gov$ bao write -f transit/keys/ipe-cpf
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          false
derived                   false
exportable                false
imported_key              false
keys                      map[1:1791343891]
latest_version            1
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
```

`ipe-cpf` é uma chave para um propósito, o CPF. A saída é a configuração dela, e quatro linhas
são decisões:

- **`type aes256-gcm96`** — AES com chave de 256 bits em modo GCM, que cifra e autentica: um texto
  cifrado alterado no caminho falha ao decifrar em vez de virar lixo;
- **`exportable false`** — a chave nunca pode ser lida para fora do OpenBao, por ninguém, nem o
  root;
- **`deletion_allowed false`** — a chave não pode ser apagada até alguém mudar isso antes, o que a
  seção 13 faz de propósito com outra chave;
- **`latest_version 1`** e **`min_decryption_version 1`** — a chave tem versões, e a seção 10
  acrescenta uma.

Uma chave por propósito é o hábito que vale formar aqui. Uma chave para o CPF, outra para backups,
outra por cliente quando o propósito exige (seção 13): as permissões, a rotação e a destruição de
cada uma podem então seguir o propósito dela.

## Cifrando e decifrando

O transit recebe o texto claro em base64, porque ele pode ser quaisquer bytes e não só texto:

```
ana@lab:~/gov$ printf '372.874.168-09' | base64
MzcyLjg3NC4xNjgtMDk=
ana@lab:~/gov$ bao write -field=ciphertext transit/encrypt/ipe-cpf plaintext=MzcyLjg3NC4xNjgtMDk= > cpf.ct
ana@lab:~/gov$ cat cpf.ct; echo
vault:v1:t+QDwmezRheG3+m55XNJSVWHooTcFCNurwlvKNddUqWUAGnvTK1DTk7Z
ana@lab:~/gov$ bao write -field=plaintext transit/decrypt/ipe-cpf ciphertext=$(cat cpf.ct) | base64 -d; echo
372.874.168-09
```

O texto cifrado é um texto com três partes: **`vault`**, um prefixo fixo; **`v1`**, a versão da
chave que o fez; e os bytes cifrados, que incluem um nonce aleatório, então cifrar o mesmo CPF duas
vezes dá dois textos diferentes. A Ana o guardou num arquivo e o devolveu, e o CPF saiu. Em momento
nenhum a chave apareceu na tela dela, no shell ou no disco.

Essa é a interface inteira, e ela basta para construir todo o resto desta aula. O que a torna
segura não é a interface, e sim quem pode chamar qual metade dela.
