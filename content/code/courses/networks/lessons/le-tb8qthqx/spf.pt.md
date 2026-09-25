---
title: SPF: que servidores podem mandar
version: 1
---

O **SPF**, Sender Policy Framework, é um registro `TXT` em que um domínio lista os servidores que podem
mandar e-mail por ele:

```
ana@laptop:~$ dig +short TXT example.com
"v=spf1 mx -all"
ana@laptop:~$ dig +short TXT example.net
"v=spf1 mx -all"
```

`v=spf1 mx -all` se lê da esquerda para a direita: `mx`, os servidores dos registros MX do domínio podem
mandar; `-all`, todo o resto falha. Outros termos listam endereços (`ip4:198.51.100.0/24`) ou puxam a
lista de um provedor (`include:`), e `~all` pede uma falha "leve" (*softfail*), que quem recebe trata
como suspeita e não como recusa.

O servidor que recebe confere o endereço de onde veio a conexão com o registro SPF **do domínio do
remetente do envelope**, o `MAIL FROM`. É a linha `spf=pass smtp.mailfrom=example.com` da seção 05. Dois
limites, os dois importantes. O SPF confere o envelope, não o `From:` que uma pessoa lê. E uma mensagem
encaminhada por outro servidor chega do endereço desse servidor e falha no SPF, embora não haja nada de
errado com ela.
