---
title: Cada palavra depois do valor do cookie
version: 1
---

**Um cabeçalho `Set-Cookie` é um nome, um valor e uma lista de instruções ao navegador sobre quem pode
ler o cookie, para onde mandá-lo e por quanto tempo.** O servidor do planner escreveu
`sid=…; HttpOnly; SameSite=Lax; Path=/` na aula 5. Eis cada atributo que importa para uma sessão,
incluindo os três que ele deixou de fora.

| atributo | o que diz ao navegador | para um cookie de sessão |
|---|---|---|
| `HttpOnly` | nenhum script pode ler este cookie pelo `document.cookie` | sempre |
| `Secure` | mandá-lo só por HTTPS; o `localhost` conta como seguro, então o desenvolvimento funciona | sempre |
| `SameSite=Lax` | deixá-lo de fora de requisições que outro site começa, menos links simples que a pessoa segue | o padrão a escolher |
| `SameSite=Strict` | deixá-lo de fora de toda requisição que outro site começa, links inclusive | onde chegar logado por um link não importa |
| `SameSite=None` | mandá-lo para todo lugar; só permitido com `Secure` | só para um cookie feito para funcionar dentro de outros sites |
| `Path=/` | mandá-lo com todo endereço do site | sim |
| `Max-Age=28800` | esquecê-lo depois de tantos segundos, aqui oito horas | sim, tanto quanto o limite do próprio servidor |
| `Domain=…` | mandá-lo também aos subdomínios | deixe de fora, para o cookie ficar com o único host que o definiu |

## O prefixo `__Host-`

Um cookie cujo nome começa com `__Host-` é um que o navegador **se recusa a aceitar** a menos que seja
`Secure`, tenha `Path=/` e não tenha `Domain`. Isso parece uma restrição e é uma garantia: um cookie
chamado `__Host-sid` só pode ter sido definido por este host exato, numa conexão segura, então nem um
subdomínio descuidado nem uma página servida em HTTP simples conseguem plantar um cookie de sessão
próprio para o navegador mandar. Renomear o cookie não custa nada e transforma três regras numa que o
navegador aplica.

## O que nenhum deles faz

Cada atributo aqui é uma instrução ao navegador, e **o servidor precisa manter as próprias regras
também**. O `Max-Age` faz o navegador descartar o cookie; ele não impede uma cópia do valor de
funcionar, se o servidor ainda a aceitar. O logout limpa o cookie; se o login por trás dele acaba é
decisão do servidor. A próxima seção escreve os três testes que perguntam ao servidor, e não ao
navegador, e os três falham.
