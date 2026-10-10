---
title: Sessões que terminam
version: 1
---

Um token de sessão é uma senha com prazo de validade: quem o tem é, até onde o serviço consegue
saber, o cliente que fez login. **Então as perguntas que um testador faz sobre um token são as
perguntas sobre uma senha, mais uma: quando ele para de funcionar?** Um token que funciona para
sempre é uma senha que nunca pode ser trocada, e um que vazou num log no ano passado ainda abre a
conta hoje.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l17-session\" aria-label=\"Uma sessão desenhada como uma barra ao longo do tempo. Ela começa no login, quando um token aleatório é emitido, e toda requisição no meio é aceita. Termina de um de dois jeitos: no logout, quando a linha é apagada, ou na expiração, 1800 segundos depois do login. Depois do fim, o mesmo token recebe 401. Abaixo da barra, a linha do banco guarda o SHA-256 do token, e não o token, então uma cópia do banco não abre nada.\"><defs><marker id=\"l17-session-nf-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">um token é uma senha com fim</text><path d=\"M40.0 120.0 L690.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l17-session-nf-ah-wire)\"></path><rect x=\"80.0\" y=\"98.0\" width=\"480.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><path d=\"M130.0 104.0 L130.0 136.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M190.0 104.0 L190.0 136.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M250.0 104.0 L250.0 136.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M310.0 104.0 L310.0 136.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M370.0 104.0 L370.0 136.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"250.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">toda requisição aceita</text><text x=\"80.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">login</text><path d=\"M430.0 92.0 L430.0 148.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"430.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">logout</text><text x=\"430.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linha apagada</text><path d=\"M560.0 92.0 L560.0 148.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"560.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">expiração</text><text x=\"560.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1800 s após o login</text><text x=\"626.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">401</text><rect x=\"80.0\" y=\"192.0\" width=\"330.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"245.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o banco guarda sha256(token), e não o token</text></svg>", "caption": "O que vier primeiro encerra a sessão: logout ou expiração. Nos dois casos o token para de abrir qualquer coisa.", "same": ["logout"]}
```

O `account.py` encerra uma sessão de três jeitos. O **logout** apaga a linha dela. A **expiração** é
um horário gravado na linha quando a sessão começa, `SESSION_SECONDS` depois do login, 1800 segundos
a não ser que o ambiente diga outra coisa, e `who` ignora qualquer linha vencida. E uma **cópia do
banco** não abre nada, porque a linha guarda o SHA-256 do token e não o token, como "Senhas e login"
mostra.

## Logout, e um token no endereço

`ana` ainda tem o token da seção anterior. Ponha-o no endereço em vez do cabeçalho, do jeito que
alguns serviços aceitam; depois faça logout e tente o cabeçalho de novo:

```
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' "localhost:8001/bookings/1?token=$(cat ~/ana.token)"
{"error": "sign in first"}
401
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/logout -H "Authorization: Bearer $(cat ~/ana.token)"
{"ok": true}
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/bookings/1 -H "Authorization: Bearer $(cat ~/ana.token)"
{"error": "sign in first"}
401
```

O token no endereço é ignorado, então a requisição é anônima e recebe `401`. Esse é o comportamento a
exigir, não um recurso que falta. **Um endereço fica anotado em mais lugares do que alguém consegue
listar**: o histórico do navegador, o log de acesso do servidor, cada proxy no caminho, o cabeçalho
`Referer` mandado ao próximo site, o print colado num chamado. Um token num cabeçalho ou num cookie
vai só para o servidor a que se destina.

Depois do logout, o mesmo cabeçalho que funcionava um minuto antes recebe `401`. **Esse é o teste que
a aula 16 já roda**, `test_logout_ends_the_session`, e ele vale a pena porque o jeito fácil de fazer
logout é esquecer o token no navegador e deixá-lo válido no servidor, o que parece idêntico para quem
clica no botão.

## Expiração, com um relógio curto

Trinta minutos é tempo demais para esperar, então a validade é uma variável de ambiente. Pare o
serviço com `Ctrl+C` no terminal dele e inicie-o de novo com sessões de dois segundos:

```sh
env ACCOUNT_SESSION_SECONDS=2 python3 account.py
```

Depois, no outro terminal, faça o login de `bia` de novo, use o token na hora, espere três segundos e
use-o outra vez:

```
ana@nft:~/boxoffice$ curl -s -X POST localhost:8001/login -d '{"name": "bia", "password": "correct horse battery"}' | jq -r .token > ~/bia.token
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/bookings/1 -H "Authorization: Bearer $(cat ~/bia.token)"
{"error": "no such booking"}
404
ana@nft:~/boxoffice$ sleep 3
ana@nft:~/boxoffice$ curl -s -w '%{http_code}\n' localhost:8001/bookings/1 -H "Authorization: Bearer $(cat ~/bia.token)"
{"error": "sign in first"}
401
```

A primeira resposta é a verificação de dono, recusando a ela a reserva de `ana`, o que prova que a
sessão estava viva. Três segundos depois a mesma requisição é anônima. Pare o serviço de novo e
inicie-o com o `python3 account.py` simples antes de continuar: sessões de dois segundos são um ajuste
de teste, não uma configuração que alguém deva colocar em produção.

## As três marcas do cookie

A página HTML do `account.py` é alcançada com um cookie em vez de um cabeçalho, porque o navegador
manda o cookie sozinho. Faça login e veja o que o serviço pede ao navegador para guardar:

```
ana@nft:~/boxoffice$ curl -si -X POST localhost:8001/login -d '{"name": "bia", "password": "correct horse battery"}' | grep -i -e '^HTTP' -e '^set-cookie'
HTTP/1.1 200 OK
Set-Cookie: session=0X8_t7CJ5D8WAd1DjRxrsgJtdUOTEz1v2u03XvsvkCw; HttpOnly; SameSite=Lax; Path=/; Max-Age=1800
```

- **`HttpOnly`** mantém o cookie longe do JavaScript da página. Se algum texto vindo de fora chegasse
  a rodar como script, ele ainda não conseguiria ler a sessão e mandá-la para outro lugar.
- **`SameSite=Lax`** diz ao navegador para não mandar o cookie junto com um formulário enviado por
  outro site. A aula 20 testa a segunda camada atrás dela, o token CSRF.
- **`Max-Age=1800`** deixa o navegador esquecer o cookie quando o servidor esquece a sessão.

A marca ausente é **`Secure`**, que diz ao navegador para mandar o cookie só por HTTPS. Ela está
ausente porque este serviço fala HTTP simples com `127.0.0.1`, e um navegador se recusaria a mandar
um cookie `Secure` ali. Numa implantação real, atrás de HTTPS, ela vai em todo cookie de sessão, e um
plano de teste diz isso numa linha própria.
