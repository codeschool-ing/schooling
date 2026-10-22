---
title: O que é um JWT
version: 1
---

Este é o token que a ana recebeu, cortado nos pontos e decodificado:

```
ana@vm:~/agenda-api$ tr '.' '\n' < token.txt
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
eyJzdWIiOiJhbmEiLCJleHAiOjE3OTI3MTM5MzV9
q9DrKbWnRSehD40b0wJQ1ZMkKes5LpDArCmiqO0RGpM
ana@vm:~/agenda-api$ cut -d. -f1 token.txt | base64 -d; echo
{"alg":"HS256","typ":"JWT"}
ana@vm:~/agenda-api$ cut -d. -f2 token.txt | base64 -d; echo
{"sub":"ana","exp":1792713935}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 228\" role=\"img\" aria-label=\"O token do token.txt em suas três partes. O header decodifica para alg HS256, typ JWT. O payload decodifica para sub ana e um instante exp. A assinatura é um HMAC-SHA256 das duas primeiras partes, feito com a SECRET_KEY.\"> <text x=\"20\" y=\"42\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">header</text> <rect x=\"110\" y=\"20\" width=\"330\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"275\" y=\"41\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9</text> <text x=\"460\" y=\"41\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{\"alg\":\"HS256\",\"typ\":\"JWT\"}</text> <text x=\"20\" y=\"104\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">payload</text> <rect x=\"110\" y=\"82\" width=\"330\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"275\" y=\"103\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">eyJzdWIiOiJhbmEiLCJleHAiOjE3OTI3MTM5MzV9</text> <text x=\"460\" y=\"103\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{\"sub\":\"ana\",\"exp\":1792713935}</text> <text x=\"20\" y=\"166\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">assinatura</text> <rect x=\"110\" y=\"144\" width=\"330\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"275\" y=\"165\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">q9DrKbWnRSehD40b0wJQ1ZMkKes5LpDArCmiqO0RGpM</text> <text x=\"460\" y=\"165\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HMAC-SHA256(header.payload, SECRET_KEY)</text> <text x=\"360\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">As duas primeiras são base64, que qualquer um lê. Só a terceira precisa da chave.</text> </svg>", "caption": "O token que a ana recebeu, cortado nos pontos. Trocar uma letra do payload deixa a assinatura errada, que foi o que o token forjado encontrou.", "same": ["header", "payload"]}
```

**Um JWT são três strings base64 unidas por pontos.** O header diz como ele é assinado. O payload são
as **claims**: `sub`, o sujeito, aqui um nome de usuário, e `exp`, o momento em que ele deixa de valer,
em segundos desde 1970. O `base64 -d` leu os dois sem chave nenhuma: **um JWT é assinado, não
criptografado**, então nada secreto vai no payload.

A terceira parte é a **assinatura**: um HMAC das duas primeiras, calculado com uma chave que só o
servidor conhece. Mude um caractere do header ou do payload, e a assinatura deixa de conferir; calcule
uma assinatura nova, e você precisa da chave. Então o servidor pode confiar no `sub` sem perguntar ao
banco se aquele token foi mesmo emitido.

## Tokens que devem falhar

O `bad_tokens.py` faz dois: o token da ana com `ana` trocado por `bruno` no payload, a assinatura
intocada, e um token assinado com a chave certa que expirou há um minuto.

```python
# bad_tokens.py
import base64
import json
import time

import jwt

from app.security import ALGORITHM, SECRET_KEY

header, payload, signature = open("token.txt").read().strip().split(".")
claims = json.loads(base64.urlsafe_b64decode(payload + "=="))
claims["sub"] = "bruno"
forged = base64.urlsafe_b64encode(json.dumps(claims).encode()).decode().rstrip("=")
open("forged.txt", "w").write(f"{header}.{forged}.{signature}")

expired = jwt.encode({"sub": "ana", "exp": int(time.time()) - 60}, SECRET_KEY, algorithm=ALGORITHM)
open("expired.txt", "w").write(expired)
```

```
ana@vm:~/agenda-api$ uv run python bad_tokens.py
ana@vm:~/agenda-api$ uv run python -c "import jwt; print(jwt.decode(open('forged.txt').read(), options={'verify_signature': False}))"
{'sub': 'bruno', 'exp': 1792713935}
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/me -H "Authorization: Bearer $(cat forged.txt)"; echo
{"detail":"Could not validate the token"}
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/me -H "Authorization: Bearer $(cat expired.txt)"; echo
{"detail":"Could not validate the token"}
```

O PyJWT lê o payload forjado quando mandado não conferir, e **a API recusa os dois**, com uma mensagem
que não diz qual conferência falhou.

## O que ele custa

Esse também é o limite dele. **Nada é guardado, então não há o que apagar**: um JWT continua valendo
até o `exp`, mesmo depois de um logout, de uma troca de senha ou de uma demissão. As respostas comuns
são uma vida curta, minutos em vez de dias, com um segundo token, de vida mais longa e guardado no
servidor, para pegar novos; ou uma lista de tokens revogados, que é de novo uma tabela conferida a
cada requisição. E a chave de assinatura agora é o único segredo que, vazado, deixa qualquer um ser
qualquer um: a aula 15 a tira do código.
