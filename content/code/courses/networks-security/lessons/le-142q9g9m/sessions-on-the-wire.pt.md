---
title: Um cookie de sessão é uma senha que expira
version: 1
---

O cookie da primeira captura desta aula, `session=7f3a9c2e`, é como a aplicação da loja reconhece um
cliente autenticado em cada requisição depois da primeira. **Quem o apresenta é aquele cliente**, até
onde a aplicação consegue dizer. Copiar um do fio e apresentá-lo é **sequestro de sessão** (session
hijacking): nenhuma senha foi necessária, porque a senha foi usada uma vez, no login, e o cookie a
substituiu.

Isso faz de um cookie de sessão um segredo com o mesmo peso de uma senha, e as defesas decorrem de
tratá-lo como tal. A maioria é definida pela aplicação no cabeçalho `Set-Cookie`, e quem defende ao
revisar uma aplicação confere cada uma:

| configuração | o que impede |
|---|---|
| `Secure` | o navegador nunca envia o cookie por HTTP puro, então a primeira captura desta aula não poderia acontecer |
| `HttpOnly` | scripts da página não conseguem lê-lo, então um script injetado não consegue copiá-lo |
| `SameSite=Lax` ou `Strict` | outros sites não conseguem fazer o navegador enviá-lo com as requisições deles |
| uma vida curta, renovada no login | um cookie copiado para de funcionar logo, e uma sessão nova começa com um valor novo |
| invalidação no logout | o valor morre com a sessão em vez de ficar sobrando no servidor |

**A primeira linha só funciona com o resto do site em HTTPS**, e a aula 13 mostra o que um atacante
no caminho faz com um site que responde primeiro em HTTP puro e redireciona depois: o próprio
redirecionamento viaja em claro. É por isso que o `Secure` anda junto com o HSTS, que diz ao
navegador para nunca tentar HTTP puro naquele site.

## O que a rede pode acrescentar

A contribuição da rede é o resto desta aula: segmentos onde um estranho não consegue escutar,
switches que recusam ARP forjado e um sensor que percebe quando algo muda. Nada disso protege um
cookie enviado em claro pelo Wi-Fi de um café. **Só a aplicação, ao nunca deixar o cookie viajar sem
criptografia, o protege em todo lugar.**
