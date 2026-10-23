---
title: Entrando na API FastAPI
version: 1
---

Os dois jeitos até aqui conferem cada requisição contra uma linha. O agenda-api usa o terceiro: um
**JSON Web Token**, que leva dentro de si o que o servidor precisa, assinado, então o servidor confere
uma assinatura em vez de ler uma tabela. Esta seção o monta e a próxima desmonta um. Acrescente o
PyJWT, o pwdlib com Argon2, e o `python-multipart`, de que o FastAPI precisa para ler o formulário que
um login manda:

```
ana@vm:~/agenda-api$ uv add pyjwt "pwdlib[argon2]" python-multipart
Resolved 34 packages in 268ms
Prepared 7 packages in 24ms
Installed 7 packages in 2ms
 + argon2-cffi==25.1.0
 + argon2-cffi-bindings==26.1.0
 + cffi==2.1.1
 + pwdlib==0.3.1
 + pycparser==3.12
 + pyjwt==2.15.1
 + python-multipart==0.0.32
```

Um usuário precisa de uma tabela. Acrescente a classe ao fim de `app/models.py`:

```python
class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    username: Mapped[str] = mapped_column(String(150), unique=True)
    password_hash: Mapped[str] = mapped_column(String(255))
```

```
ana@vm:~/agenda-api$ uv run alembic revision --autogenerate --rev-id 0002 -m "users" 2>&1 | grep -E "Detected added|Generating"
INFO  [alembic.autogenerate.compare.tables] Detected added table 'users'
Generating /home/ana/agenda-api/migrations/versions/0002_users.py ...  done
ana@vm:~/agenda-api$ uv run alembic upgrade head 2>&1 | tail -1
INFO  [alembic.runtime.migration] Running upgrade 0001 -> 0002, users
```

Um script cria usuários, pedindo a senha com `getpass` para que ela não apareça na tela nem fique no
histórico do shell. Salve como `create_user.py`, e o `app/security.py` abaixo dele, que ele importa:

```python
# create_user.py
import sys
from getpass import getpass

from sqlalchemy.orm import Session

from app.db import engine
from app.models import User
from app.security import passwords

username = sys.argv[1]
password = getpass("Password: ")
with Session(engine) as session:
    session.add(User(username=username, password_hash=passwords.hash(password)))
    session.commit()
print("created", username)
```

```schooling-example
{"language": "python", "file": "app/security.py", "parts": [{"code": "# app/security.py\nfrom datetime import datetime, timedelta, timezone\nfrom typing import Annotated\n\nimport jwt\nfrom fastapi import Depends, HTTPException, status\nfrom fastapi.security import OAuth2PasswordBearer\nfrom pwdlib import PasswordHash\nfrom sqlalchemy import select\n\nfrom .db import SessionDep\nfrom .models import User\n\n", "note": "O PyJWT para os tokens, o pwdlib para as senhas, e o auxiliar do FastAPI que lê um token bearer do cabeçalho `Authorization`."}, {"code": "SECRET_KEY = \"NYUmN5t9_2TwciV1gQFRytzmLGSpGbZlcDKDRTVqyj8\"  # lesson 15 moves it out\nALGORITHM = \"HS256\"\nTOKEN_MINUTES = 30\n\n", "note": "**A chave que assina todo token.** Quem a tiver pode emitir um token para qualquer usuário, então a aula 15 a tira do código e a leva para o ambiente."}, {"code": "passwords = PasswordHash.recommended()\nDECOY = passwords.hash(\"nobody has this password\")\nbearer = OAuth2PasswordBearer(tokenUrl=\"token\")\n\n\n", "note": "`PasswordHash.recommended()` é o Argon2. `DECOY` é um hash com que a senha de ninguém confere, para o caso de o nome não existir."}, {"code": "def authenticate(session: SessionDep, username: str, password: str) -> User | None:\n    user = session.scalar(select(User).where(User.username == username))\n    stored = user.password_hash if user else DECOY\n    if not passwords.verify(password, stored) or user is None:\n        return None\n    return user\n\n\n", "note": "**Os dois caminhos calculam um hash**: o do usuário, ou o do chamariz. A última seção mostra quanto o atalho custaria."}, {"code": "def make_token(user: User) -> str:\n    expires = datetime.now(timezone.utc) + timedelta(minutes=TOKEN_MINUTES)\n    return jwt.encode({\"sub\": user.username, \"exp\": expires}, SECRET_KEY, algorithm=ALGORITHM)\n\n\n", "note": "O token diz quem (`sub`) e até quando (`exp`), e nada mais."}, {"code": "def current_user(token: Annotated[str, Depends(bearer)], session: SessionDep) -> User:\n    refused = HTTPException(\n        status.HTTP_401_UNAUTHORIZED,\n        \"Could not validate the token\",\n        headers={\"WWW-Authenticate\": \"Bearer\"},\n    )\n    try:\n        claims = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])\n    except jwt.InvalidTokenError:\n        raise refused\n    user = session.scalar(select(User).where(User.username == claims[\"sub\"]))\n    if user is None:\n        raise refused\n    return user\n\n\n", "note": "**A dependência que toda rota protegida pede.** Um cabeçalho ausente é respondido pelo `bearer` com 401; um token com assinatura errada, um expirado ou um de usuário apagado, por esta função."}, {"code": "CurrentUser = Annotated[User, Depends(current_user)]\n"}]}
```

```
ana@vm:~/agenda-api$ uv run python create_user.py ana
Password: 
created ana
ana@vm:~/agenda-api$ psql agenda_api -c "select username, password_hash from users"
 username |                                           password_hash                                           
----------+---------------------------------------------------------------------------------------------------
 ana      | $argon2id$v=19$m=65536,t=3,p=4$khGY7flzgPS15PZdj+Kvgw$elB0FFKGeHXW7q80YOVenOYRsmGv+D9wjFx759RiaZc
(1 row)
```

**`$argon2id$`**, com o custo de memória (`m=65536`, em KiB), o custo de tempo e o paralelismo na
string, e depois o salt e o hash: o mesmo formato do Django, para outro algoritmo.

A rota de login e uma rota que diz quem você é vão num router próprio, `app/auth.py`:

```python
# app/auth.py
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm

from .db import SessionDep
from .security import CurrentUser, authenticate, make_token

router = APIRouter(tags=["auth"])


@router.post("/token")
def login(form: Annotated[OAuth2PasswordRequestForm, Depends()], session: SessionDep):
    user = authenticate(session, form.username, form.password)
    if user is None:
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "Wrong username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return {"access_token": make_token(user), "token_type": "bearer"}


@router.get("/me")
def me(user: CurrentUser):
    return {"username": user.username}
```

O `OAuth2PasswordRequestForm` lê os campos `username` e `password` de um formulário enviado, o
formato que o fluxo de senha do OAuth2 define, e que também faz o botão **Authorize** do `/docs`
funcionar. No `app/main.py`, importe o router e inclua-o depois do de previsão, importe o
`CurrentUser`, e acrescente `user: CurrentUser` aos parâmetros do `create_event`:

```
ana@vm:~/agenda-api$ grep -n 'auth_router\|CurrentUser' app/main.py
7:from .auth import router as auth_router
12:from .security import CurrentUser
21:app.include_router(auth_router)
45:def create_event(event: EventIn, session: SessionDep, user: CurrentUser):
```

## Usando

Rode a API, `uv run uvicorn app.main:app --port 8001`, e tente criar um evento sem token, depois
entre:

```
ana@vm:~/agenda-api$ curl -si http://127.0.0.1:8001/events -H 'Content-Type: application/json' -d '{"slug": "auth-clinic", "title": "Auth clinic", "starts_at": "2026-12-03T19:00:00-03:00", "venue": "Community Centre, room 3", "capacity": 15}' | grep -iE '^(HTTP|www-authenticate)|detail'
HTTP/1.1 401 Unauthorized
www-authenticate: Bearer
{"detail":"Not authenticated"}
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/token -d username=ana -d password=x9-river-lantern-42; echo
{"access_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhbmEiLCJleHAiOjE3OTI3MTM5MzV9.q9DrKbWnRSehD40b0wJQ1ZMkKes5LpDArCmiqO0RGpM","token_type":"bearer"}
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/token -d username=ana -d password=x9-river-lantern-42 | python3 -c "import json, sys; print(json.load(sys.stdin)['access_token'])" > token.txt
```

A primeira resposta é do próprio FastAPI: o `bearer` não achou cabeçalho. A segunda é o token, que o
`token.txt` guarda para os próximos comandos. Com ele:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/me -H "Authorization: Bearer $(cat token.txt)"; echo
{"username":"ana"}
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events -H "Authorization: Bearer $(cat token.txt)" -H 'Content-Type: application/json' -d '{"slug": "auth-clinic", "title": "Auth clinic", "starts_at": "2026-12-03T19:00:00-03:00", "venue": "Community Centre, room 3", "capacity": 15}'; echo
{"slug":"auth-clinic","title":"Auth clinic","starts_at":"2026-12-03T19:00:00-03:00","venue":"Community Centre, room 3","capacity":15,"description":"","taken":0}
```

**201**, e o `/me` diz de quem é o token. Uma senha errada e um nome desconhecido recebem uma mesma
mensagem, que não diz qual dos dois estava errado:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/token -d username=ana -d password=wrong; echo
{"detail":"Wrong username or password"}
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/token -d username=nobody -d password=wrong; echo
{"detail":"Wrong username or password"}
```

## O chamariz

Uma mensagem só não basta se as duas respostas levarem tempos diferentes. Uma primeira versão do
`authenticate` naturalmente pararia antes:

```python
def authenticate(session: SessionDep, username: str, password: str) -> User | None:
    user = session.scalar(select(User).where(User.username == username))
    if user is None:
        return None
    if not passwords.verify(password, user.password_hash):
        return None
    return user
```

As duas versões, cronometradas pelo curl, quatro senhas erradas cada:

```
ana@vm:~/agenda-api$ for who in ana nobody ana nobody; do curl -s -o /dev/null -w "$who %{http_code} %{time_total} s\n" http://127.0.0.1:8001/token -d username=$who -d password=wrong; done
ana 401 0.072142 s
nobody 401 0.059659 s
ana 401 0.073283 s
nobody 401 0.060038 s
ana@vm:~/agenda-api$ for who in ana nobody ana nobody; do curl -s -o /dev/null -w "$who %{http_code} %{time_total} s\n" http://127.0.0.1:8001/token -d username=$who -d password=wrong; done
ana 401 0.090864 s
nobody 401 0.004015 s
ana 401 0.050907 s
nobody 401 0.004107 s
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 196\" role=\"img\" aria-label=\"Quatro barras de tempo de resposta para uma senha errada. Com o hash chamariz: ana 0,073 segundo, nobody 0,060. Sem ele: ana 0,051 segundo, nobody 0,004, porque nenhum hash foi calculado.\"> <text x=\"218\" y=\"36\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ana, com o chamariz</text> <rect x=\"230\" y=\"20\" width=\"439.698\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"677.698\" y=\"36\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">0.073 s</text> <text x=\"218\" y=\"72\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nobody, com o chamariz</text> <rect x=\"230\" y=\"56\" width=\"360.228\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"598.2280000000001\" y=\"72\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">0.060 s</text> <text x=\"218\" y=\"108\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ana, sem ele</text> <rect x=\"230\" y=\"92\" width=\"305.442\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"543.442\" y=\"108\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">0.051 s</text> <text x=\"218\" y=\"144\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nobody, sem ele</text> <rect x=\"230\" y=\"128\" width=\"24.642000000000003\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></rect> <text x=\"262.642\" y=\"144\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">0.004 s</text> <text x=\"360\" y=\"182\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Uma senha errada, cronometrada pelo curl: o segundo par ana e nobody de cada rodada.</text> </svg>", "caption": "Sem o chamariz, um nome desconhecido responde mais de dez vezes mais rápido, e a diferença diz quem tem conta.", "same": ["0.073 s", "0.060 s", "0.051 s", "0.004 s"]}
```

**Com o chamariz, ana e nobody custam mais ou menos o mesmo**: cada requisição calcula um hash
Argon2. Sem ele, um nome que não existe responde em quatro milissegundos e um que existe em cinquenta:
qualquer pessoa pode perguntar ao formulário de login se alguém tem conta, o que num site de eventos é
uma pergunta sobre essa pessoa. A primeira requisição de uma rodada também paga o aquecimento do
processo, por isso a figura usa o segundo par. O `authenticate` do próprio Django faz o mesmo que o
chamariz, rodando o hasher uma vez para um usuário desconhecido.
