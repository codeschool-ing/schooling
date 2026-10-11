---
title: Sessões ou tokens
version: 1
---

Lado a lado, os dois são menos diferentes do que as discussões sobre eles sugerem, e as diferenças
que sobram apontam numa direção clara. A tabela é a aula num lugar só, e o padrão logo abaixo dela
é por onde começar.

| | cookie de sessão | JWT |
|---|---|---|
| encerrar um login | apagar a linha, vale na hora | esperar o `exp`, ou manter uma lista de bloqueio conferida em toda requisição |
| o que o servidor guarda | uma linha por login | a chave; mais refresh tokens e uma lista de bloqueio quando a revogação importa |
| vários servidores | todos leem um armazenamento de sessões | qualquer servidor com a chave verifica sozinho |
| tamanho em toda requisição | 43 caracteres aqui | 240 caracteres aqui, e crescendo a cada claim |
| ler o conteúdo | nada a ler: o id é aleatório | qualquer um que tenha o token lê o payload |
| outros domínios e serviços | um cookie fica com o host dele | um cabeçalho vai aonde o cliente o mandar |
| clientes que não são navegadores | possível, mas cookie é hábito de navegador | natural: um cabeçalho |
| CSRF | exposto, então `SameSite` e um token CSRF | não exposto, enquanto viaja num cabeçalho |
| XSS | o `HttpOnly` deixa o id fora de alcance | exposto onde quer que um script consiga lê-lo |
| vazamento do armazenamento do servidor | ids em hash são inúteis | uma chave vazada assina tokens para qualquer um |

Os dois tamanhos são dos tokens desta própria aula, o id de sessão de ana e o token de acesso dela:

```
ana@api:~/shelf$ awk '$6 == "sid" {printf "%s", $7}' kept.txt | wc -c
43
ana@api:~/shelf$ jq -j .access_token login.json | wc -c
240
```

Cada claim acrescentada ao token, um nome, um papel, uma lista de permissões, deixa toda requisição
mais longa. E um token que carrega permissões leva uma cópia delas, que continua dizendo a coisa
antiga até o `exp` depois que as verdadeiras mudam.

## O padrão

**Para uma aplicação de navegador falando com a própria API, use um cookie de sessão.** Ele é
revogado apagando uma linha, não deixa nada legível no navegador, e a consulta que custa é uma
leitura por índice, barata perto de todo o resto que uma requisição faz. Toda linguagem da trilha de
back-end tem uma biblioteca bem testada para isso.

**Recorra a tokens assinados quando a requisição cruza uma fronteira**: entre os seus próprios
serviços, onde um serviço consegue verificar um token sem chamar de volta quem o emitiu; entre
domínios, onde um cookie não acompanha; e para clientes que não são navegadores. Mantenha a vida
curta, fixe o algoritmo, exija as claims e acrescente refresh com rotação quando os usuários
precisarem continuar logados.

E quando o usuário entra em outro lugar, com uma conta do Google ou da Microsoft, ou quando um app
age em nome do usuário com o consentimento dele, os tokens são emitidos por outro sistema e as regras
para eles têm nome. **A aula 9 é OAuth 2.0 e OpenID Connect**, onde o JWT volta como ID token e
toda verificação desta aula vale para ele.
