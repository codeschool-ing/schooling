---
title: Logging in to the FastAPI API
version: 1
---

Both ways so far check every request against a row. agenda-api uses the third: a **JSON Web Token**,
which carries what the server needs inside itself, signed, so the server checks a signature instead
of reading a table. This section builds it and the next takes one apart. Add PyJWT, pwdlib with
Argon2, and `python-multipart`, which FastAPI needs to read the form a login sends:

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

A user needs a table. Add the class to the end of `app/models.py`:

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

A script creates users, asking for the password with `getpass` so it is neither echoed nor kept in
the shell's history. Save it as `create_user.py`, and `app/security.py` below it, which it imports:

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
{"language": "python", "file": "app/security.py", "parts": [{"code": "# app/security.py\nfrom datetime import datetime, timedelta, timezone\nfrom typing import Annotated\n\nimport jwt\nfrom fastapi import Depends, HTTPException, status\nfrom fastapi.security import OAuth2PasswordBearer\nfrom pwdlib import PasswordHash\nfrom sqlalchemy import select\n\nfrom .db import SessionDep\nfrom .models import User\n\n", "note": "PyJWT for the tokens, pwdlib for the passwords, and FastAPI's helper that reads a bearer token from the `Authorization` header."}, {"code": "SECRET_KEY = \"NYUmN5t9_2TwciV1gQFRytzmLGSpGbZlcDKDRTVqyj8\"  # lesson 15 moves it out\nALGORITHM = \"HS256\"\nTOKEN_MINUTES = 30\n\n", "note": "**The key that signs every token.** Anybody holding it can mint a token for any user, so lesson 15 takes it out of the code and into the environment."}, {"code": "passwords = PasswordHash.recommended()\nDECOY = passwords.hash(\"nobody has this password\")\nbearer = OAuth2PasswordBearer(tokenUrl=\"token\")\n\n\n", "note": "`PasswordHash.recommended()` is Argon2. `DECOY` is a hash nobody's password matches, for the case where the name does not exist."}, {"code": "def authenticate(session: SessionDep, username: str, password: str) -> User | None:\n    user = session.scalar(select(User).where(User.username == username))\n    stored = user.password_hash if user else DECOY\n    if not passwords.verify(password, stored) or user is None:\n        return None\n    return user\n\n\n", "note": "**Both branches compute one hash**: the user's, or the decoy's. The last section shows what the shortcut would cost."}, {"code": "def make_token(user: User) -> str:\n    expires = datetime.now(timezone.utc) + timedelta(minutes=TOKEN_MINUTES)\n    return jwt.encode({\"sub\": user.username, \"exp\": expires}, SECRET_KEY, algorithm=ALGORITHM)\n\n\n", "note": "The token says who (`sub`) and until when (`exp`), and nothing else."}, {"code": "def current_user(token: Annotated[str, Depends(bearer)], session: SessionDep) -> User:\n    refused = HTTPException(\n        status.HTTP_401_UNAUTHORIZED,\n        \"Could not validate the token\",\n        headers={\"WWW-Authenticate\": \"Bearer\"},\n    )\n    try:\n        claims = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])\n    except jwt.InvalidTokenError:\n        raise refused\n    user = session.scalar(select(User).where(User.username == claims[\"sub\"]))\n    if user is None:\n        raise refused\n    return user\n\n\n", "note": "**The dependency every protected route asks for.** A missing header is answered by `bearer` with 401; a token with a bad signature, an expired one or one for a deleted user, by this function."}, {"code": "CurrentUser = Annotated[User, Depends(current_user)]\n"}]}
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

**`$argon2id$`**, with its memory cost (`m=65536`, in KiB), time cost and parallelism in the
string, then the salt and the hash: the same layout as Django's, for a different algorithm.

The login route and a route that says who you are go in a router of their own, `app/auth.py`:

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

`OAuth2PasswordRequestForm` reads the `username` and `password` fields of a form post, the shape
OAuth2's password flow defines, which is also what makes the **Authorize** button of `/docs` work.
In `app/main.py`, import the router and include it after the forecast one, import `CurrentUser`, and
add `user: CurrentUser` to the parameters of `create_event`:

```
ana@vm:~/agenda-api$ grep -n 'auth_router\|CurrentUser' app/main.py
7:from .auth import router as auth_router
12:from .security import CurrentUser
21:app.include_router(auth_router)
45:def create_event(event: EventIn, session: SessionDep, user: CurrentUser):
```

## Using it

Run the API, `uv run uvicorn app.main:app --port 8001`, and try to create an event without a token,
then log in:

```
ana@vm:~/agenda-api$ curl -si http://127.0.0.1:8001/events -H 'Content-Type: application/json' -d '{"slug": "auth-clinic", "title": "Auth clinic", "starts_at": "2026-12-03T19:00:00-03:00", "venue": "Community Centre, room 3", "capacity": 15}' | grep -iE '^(HTTP|www-authenticate)|detail'
HTTP/1.1 401 Unauthorized
www-authenticate: Bearer
{"detail":"Not authenticated"}
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/token -d username=ana -d password=x9-river-lantern-42; echo
{"access_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhbmEiLCJleHAiOjE3OTI3MTM5MzV9.q9DrKbWnRSehD40b0wJQ1ZMkKes5LpDArCmiqO0RGpM","token_type":"bearer"}
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/token -d username=ana -d password=x9-river-lantern-42 | python3 -c "import json, sys; print(json.load(sys.stdin)['access_token'])" > token.txt
```

The first answer is FastAPI's own: `bearer` found no header. The second is the token, which
`token.txt` keeps for the next commands. With it:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/me -H "Authorization: Bearer $(cat token.txt)"; echo
{"username":"ana"}
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/events -H "Authorization: Bearer $(cat token.txt)" -H 'Content-Type: application/json' -d '{"slug": "auth-clinic", "title": "Auth clinic", "starts_at": "2026-12-03T19:00:00-03:00", "venue": "Community Centre, room 3", "capacity": 15}'; echo
{"slug":"auth-clinic","title":"Auth clinic","starts_at":"2026-12-03T19:00:00-03:00","venue":"Community Centre, room 3","capacity":15,"description":"","taken":0}
```

**201**, and `/me` says who the token belongs to. A wrong password and an unknown name get one
message, which does not say which of the two was wrong:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/token -d username=ana -d password=wrong; echo
{"detail":"Wrong username or password"}
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/token -d username=nobody -d password=wrong; echo
{"detail":"Wrong username or password"}
```

## The decoy

One message is not enough if the two answers take different times. A first version of
`authenticate` would naturally stop early:

```python
def authenticate(session: SessionDep, username: str, password: str) -> User | None:
    user = session.scalar(select(User).where(User.username == username))
    if user is None:
        return None
    if not passwords.verify(password, user.password_hash):
        return None
    return user
```

Both versions, timed by curl, four wrong passwords each:

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
{"svg": "<svg viewBox=\"0 0 720 196\" role=\"img\" aria-label=\"Four bars of response time for a wrong password. With the decoy hash: ana 0.073 seconds, nobody 0.060. Without it: ana 0.051 seconds, nobody 0.004, because no hash was computed.\"> <text x=\"218\" y=\"36\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ana, with the decoy</text> <rect x=\"230\" y=\"20\" width=\"439.698\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"677.698\" y=\"36\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">0.073 s</text> <text x=\"218\" y=\"72\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nobody, with the decoy</text> <rect x=\"230\" y=\"56\" width=\"360.228\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"598.2280000000001\" y=\"72\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">0.060 s</text> <text x=\"218\" y=\"108\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ana, without it</text> <rect x=\"230\" y=\"92\" width=\"305.442\" height=\"22\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"543.442\" y=\"108\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">0.051 s</text> <text x=\"218\" y=\"144\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nobody, without it</text> <rect x=\"230\" y=\"128\" width=\"24.642000000000003\" height=\"22\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\"></rect> <text x=\"262.642\" y=\"144\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">0.004 s</text> <text x=\"360\" y=\"182\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">A wrong password, timed by curl: the second ana-and-nobody pair of each run.</text> </svg>", "caption": "Without the decoy, an unknown name answers more than ten times faster, and the difference says who has an account."}
```

**With the decoy, ana and nobody cost about the same**: each request computes one Argon2 hash.
Without it, a name that does not exist answers in four milliseconds and one that does in fifty:
anyone can ask the login form whether a person has an account, which on an events site is a question
about that person. The first request of a run also pays for the process warming up, which is why the
figure uses the second pair. Django's own `authenticate` does the same thing as the decoy, running
the hasher once for an unknown user.
