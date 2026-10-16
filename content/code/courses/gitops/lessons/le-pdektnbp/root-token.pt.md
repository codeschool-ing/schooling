---
title: A última credencial
version: 1
---

**O token root do Vault pode tudo no Vault, e a aula 9 o deixou num arquivo desde então.** Ele foi
preciso para configurar o Vault: as políticas, o método de auth do Kubernetes, os secrets engines, o
audit device de uma seção atrás. Um Vault em uso não precisa dele, e um token root que existe é a
única credencial com que se contorna todo outro controle deste curso.

Revogá-lo é um comando, e perguntar ao token sobre si mesmo depois mostra que ele acabou:

```
ana@laptop:~/fleet$ vault token revoke $VAULT_TOKEN
Success! Revoked token (if it existed)
ana@laptop:~/fleet$ vault token lookup
Error looking up token: Error making API request.

URL: GET http://127.0.0.1:8200/v1/auth/token/lookup-self
Code: 403. Errors:

* 2 errors occurred:
	* permission denied
	* invalid token
```

`Success!`, e o mesmo token, perguntado sobre si mesmo, é recusado: `permission denied` e `invalid
token`. Todo comando `vault` neste terminal agora precisa de um login.

**No dia em que um token root for necessário de novo, o Vault faz um novo**, e para isso precisa das
chaves de unseal. `vault operator generate-root` começa um processo em que um quórum de portadores
de chaves envia cada um a sua, e o token que sai dali é para ser usado e revogado dentro da hora. É
um ato deliberado, registrado, que pede mais de uma pessoa, que é a propriedade que o token num
arquivo não tinha.

Para o resto do trabalho, um administrador entra com uma identidade própria e uma política que diz o
que ele pode mudar, e o log de auditoria das seções anteriores o registra pelo nome.

## Onde o curso termina

Doze aulas atrás, o estado do cluster era algo que uma pessoa digitava. Agora é um repositório em
que toda mudança tem um autor, um revisor, uma checagem e um registro de quando chegou a cada
ambiente. Os artefatos são assinados, e recusados quando não estão. Os segredos vivem fora do Git,
são lidos por uma identidade que tem nome e ficam registrados quando lidos. As credenciais expiram
sozinhas ou são rotacionadas numa ordem que não quebra nada. E quatro sistemas guardam registros que
respondem quem mudou o quê, quando e por quê, sem pedir a ninguém que se lembre.

Nada disso depende deste laboratório. O cluster pode ser EKS, o servidor Git o GitHub, o registry o
Harbor, o cofre o AWS Secrets Manager: os objetos mantêm os nomes, e as perguntas mantêm as
respostas.
