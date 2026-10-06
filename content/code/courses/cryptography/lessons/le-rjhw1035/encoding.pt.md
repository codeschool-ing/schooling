---
title: Codificação é formato, não cadeado
version: 1
---

**Codificar transforma bytes em outra representação por uma regra pública, para que eles possam
viajar por onde só se aceita texto. Qualquer um consegue reverter, porque a regra é tudo o que
existe.** Base64, hexadecimal, codificação de URL e PEM são codificações. Nenhuma delas tem chave, e
nenhuma esconde nada de ninguém.

## Base64 em três comandos

O cabeçalho `Authorization` da autenticação HTTP Basic leva o nome de usuário e a senha unidos por
dois-pontos e codificados em Base64. As credenciais da Ana, codificadas:

```
ana@lab:~/lab$ printf 'ana.lima:Vereda@2026' | base64
YW5hLmxpbWE6VmVyZWRhQDIwMjY=
```

E decodificadas, por qualquer um que veja o cabeçalho, sem chave nenhuma:

```
ana@lab:~/lab$ echo 'YW5hLmxpbWE6VmVyZWRhQDIwMjY=' | base64 -d; echo
ana.lima:Vereda@2026
```

É por isso que a autenticação Basic só é aceitável dentro do TLS: o cabeçalho é a senha. O Base64
está ali porque cabeçalhos HTTP levam texto, e uma senha pode conter bytes que quebrariam o
cabeçalho. Ele nunca teve a intenção de proteger nada.

## Como os três ficam lado a lado

As mesmas seis letras, em hexadecimal, em Base64, e cifradas com AES sob a chave do laboratório e
depois codificadas em Base64 para exibir:

```
ana@lab:~/lab$ printf 'Vereda' | xxd -p; printf 'Vereda' | base64; printf 'Vereda' | openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) | base64
566572656461
VmVyZWRh
KUUmel4MOXcihqnxJ8ogPg==
```

O hexadecimal gasta dois caracteres por byte, o Base64 quatro caracteres a cada três bytes. A
terceira linha **também** parece Base64, porque é: texto cifrado são bytes, e bytes que precisam
viajar como texto também são codificados. O que a separa da segunda linha não é a aparência, mas o
que a reverte. A segunda precisa de `base64 -d`. A terceira precisa de `base64 -d` **e da chave**.

## O caso mais comum: um Secret do Kubernetes

O Kubernetes guarda os valores de um Secret em Base64, e muita gente lê a palavra *Secret* e o valor
ilegível e supõe cifragem. O portal da Vereda tem um:

```
ana@lab:~/lab$ cat data/portal-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: portal-db
type: Opaque
data:
  username: cG9ydGFs
  password: Vi1kYi1zM2NyZXQtMjAyNg==
```

E quem consegue ler o manifesto, ou rodar `kubectl get secret -o yaml` com permissão de leitura sobre
ele, tem a senha:

```
ana@lab:~/lab$ grep password: data/portal-secret.yaml | awk '{print $2}' | base64 -d; echo
V-db-s3cret-2026
```

O Kubernetes usa Base64 para que um Secret possa guardar dados binários, como um keystore, num
arquivo YAML. A proteção de um Secret vem de outro lugar: quem tem permissão de lê-lo (RBAC), se o
cluster cifra seu armazenamento em repouso (com um provedor de chaves) e se o manifesto alguma vez é
commitado num repositório. Um manifesto de Secret no Git, com Base64 e tudo, é uma senha no Git.
