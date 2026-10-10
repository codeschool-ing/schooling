---
title: Refresh tokens e rotação
version: 1
---

**Um access token é conferido pela API com uma chave pública e nenhuma conversa**, e é isso que o
torna rápido; é também por isso que ninguém consegue chamá-lo de volta: uma API que nunca pergunta
ao servidor de autorização não fica sabendo que um token foi retirado. O estrago que um access
token roubado pode fazer é limitado por uma coisa só, a validade dele, e por isso ela é curta. Os do
`idp.py` duram 300 segundos.

Uma pessoa não deveria entrar de novo a cada cinco minutos, e o **refresh token** é a resposta. Ele
dura muito, vai só para o servidor de autorização e nunca para uma API, e compra um access token
novo sem a pessoa:

```
ana@api:~/shelf$ echo $RT
IMn9szUzfVNK0MgY32rQLBFvNzf179TwXPC2i73FdAQ
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=refresh_token -d refresh_token=$RT | tee tokens2.json | jq 'del(.access_token)'
{
  "token_type": "Bearer",
  "expires_in": 300,
  "scope": "books:read openid profile",
  "refresh_token": "QxCmj-nVw11uQP41CGKzG3wedisK3gsVFBN6RN_y9Ds"
}
```

A resposta traz um access token novo, e **um refresh token novo, diferente do que foi enviado.**
Isso é a **rotação**: todo refresh token funciona uma vez, e usá-lo o substitui. Guarde o novo:

```
ana@api:~/shelf$ RT2=$(jq -r .refresh_token tokens2.json)
```

## Por que a rotação pega um roubo

Suponha que uma cópia de um refresh token vaze. Sem rotação, o ladrão e o app usam o mesmo token
lado a lado por semanas e nenhum dos dois percebe. Com rotação, o primeiro dos dois a usá-lo recebe
um novo, e quando o outro apresenta o antigo, **o servidor de autorização vê voltar um refresh token
que já foi gasto.** Ele não sabe qual dos dois portadores é o app de verdade, então encerra o grant
inteiro e os dois perdem:

```
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=refresh_token -d refresh_token=$RT
{"error": "invalid_grant", "error_description": "refresh token used twice; grant revoked"}
```

Inclusive o substituto, que foi emitido corretamente um instante atrás:

```
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=refresh_token -d refresh_token=$RT2
{"error": "invalid_grant", "error_description": "unknown or revoked refresh token"}
```

O próximo refresh do app de verdade falha, a pessoa entra de novo, e a cópia do ladrão morre. Um
servidor de autorização de verdade também registra o evento onde alguém vai olhar, porque um
refresh token reusado é evidência de roubo, e o `idp.py` só recusa.

**O que a rotação não faz é alcançar o access token já emitido.** O grant está revogado e o primeiro
access token ainda abre a lista de estoque, porque a API conferiu uma assinatura e um horário e não
perguntou a ninguém:

```
ana@api:~/shelf$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8000/books/stock -H "Authorization: Bearer $AT"
200
```

Esse é o motivo da validade curta, dito com um número: quem tem esse token tem no máximo o que
sobra dos 300 segundos dele. Se já passaram mais de cinco minutos desde que você o gerou, a sua
resposta é `401`, que é o mesmo argumento chegando pelo outro lado.

## Onde um refresh token fica guardado

Ele é a coisa mais valiosa que um cliente guarda, então onde ele mora importa mais do que onde mora
o access token:

| cliente | onde o refresh token mora |
|---|---|
| um app web com servidor | no servidor, na sessão do usuário; o navegador só tem um cookie de sessão |
| um app de celular | o armazenamento protegido do sistema: Keychain no iOS, Keystore no Android |
| um app de página única | de preferência em lugar nenhum do navegador: um pequeno servidor do próprio app (um "backend for frontend") guarda os tokens e o navegador recebe um cookie. Se o navegador precisar guardá-lo, a rotação é obrigatória, e o servidor de autorização limita a vida dele |
