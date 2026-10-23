---
title: pydantic-settings for FastAPI
version: 1
---

agenda-api reads its configuration through a class. Add the library, and declare what the API needs
in `app/config.py`:

```
ana@vm:~/agenda-api$ uv add pydantic-settings
Resolved 42 packages in 283ms
Prepared 2 packages in 53ms
Installed 2 packages in 3ms
 + pydantic-settings==2.16.1
 + python-dotenv==1.2.4
```

```schooling-example
{"language": "python", "file": "app/config.py", "parts": [{"code": "# app/config.py\nfrom pydantic import SecretStr\nfrom pydantic_settings import BaseSettings, SettingsConfigDict\n\n\n", "note": "**pydantic-settings** is Pydantic for configuration: a class whose fields are filled from the environment, and validated like a request body."}, {"code": "class Settings(BaseSettings):\n    model_config = SettingsConfigDict(env_file=\".env\", env_prefix=\"AGENDA_API_\")\n\n", "note": "`env_prefix` maps `secret_key` to `AGENDA_API_SECRET_KEY`; `env_file` also reads a `.env` in the current directory, below the real environment in priority."}, {"code": "    database_url: SecretStr\n    secret_key: SecretStr\n", "note": "**`SecretStr`** keeps a value out of every `print`, log line and traceback; `.get_secret_value()` is the one way to read it. The URL is secret because it carries the password."}, {"code": "    token_minutes: int = 30\n\n\n", "note": "A default makes a field optional, and the type converts it: `AGENDA_API_TOKEN_MINUTES=15` arrives as the integer 15."}, {"code": "settings = Settings()\n", "note": "Built once, at import. A missing field stops the application here, before it answers anybody."}]}
```

Without a `.env` and without the variables:

```
ana@vm:~/agenda-api$ uv run python -c 'from app.config import settings' 2>&1 | tail -6
database_url
  Field required [type=missing, input_value={}, input_type=dict]
    For further information visit https://errors.pydantic.dev/2.14/v/missing
secret_key
  Field required [type=missing, input_value={}, input_type=dict]
    For further information visit https://errors.pydantic.dev/2.14/v/missing
```

**Both missing fields, by name**, in one error, before anything else runs. Write the file, with a
generated key and a generated password inside the URL, and give agenda-api a role of its own as
agenda has:

```
ana@vm:~/agenda-api$ printf 'AGENDA_API_SECRET_KEY=%s\nAGENDA_API_DATABASE_URL=postgresql+psycopg://agenda_api_app:%s@localhost/agenda_api\n' "$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')" "$(python3 -c 'import secrets; print(secrets.token_urlsafe(24))')" > .env
ana@vm:~/agenda-api$ echo "create role agenda_api_app login password :'pw'" | sudo -u postgres psql -v pw="$(sed -n 's|^AGENDA_API_DATABASE_URL=.*agenda_api_app:\(.*\)@.*|\1|p' .env)"
CREATE ROLE
ana@vm:~/agenda-api$ sudo -u postgres psql agenda_api -c "reassign owned by ana to agenda_api_app" -c "alter database agenda_api owner to agenda_api_app"
REASSIGN OWNED
ALTER DATABASE
```

And the settings, printed:

```
ana@vm:~/agenda-api$ uv run python -c 'from app.config import settings; print(settings)'
database_url=SecretStr('**********') secret_key=SecretStr('**********') token_minutes=30
```

**`'**********'`**: the URL and the key cannot leak through a print or a traceback.

## Reading them

`app/db.py` builds its engine from the setting:

```python
# app/db.py
from typing import Annotated

from fastapi import Depends
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from .config import settings

engine = create_engine(settings.database_url.get_secret_value())


def get_session():
    with Session(engine) as session:
        yield session


SessionDep = Annotated[Session, Depends(get_session)]
```

In `app/security.py`, the key and the token's life come from the settings, with the import beside
the others:

```python
from .config import settings
from .db import SessionDep
from .models import User

SECRET_KEY = settings.secret_key.get_secret_value()
ALGORITHM = "HS256"
TOKEN_MINUTES = settings.token_minutes
```

Alembic's `migrations/env.py` reads the same URL, so it is written once, in `.env`; the line
`sqlalchemy.url` comes out of `alembic.ini`, which lesson 10 had to keep in step with `app/db.py`:

```python
from app.config import settings
from app.models import Base

config.set_main_option("sqlalchemy.url", settings.database_url.get_secret_value())
target_metadata = Base.metadata
```

```
ana@vm:~/agenda-api$ grep -n 'settings' app/security.py migrations/env.py
app/security.py:11:from .config import settings
app/security.py:15:SECRET_KEY = settings.secret_key.get_secret_value()
app/security.py:17:TOKEN_MINUTES = settings.token_minutes
migrations/env.py:21:from app.config import settings
migrations/env.py:24:config.set_main_option("sqlalchemy.url", settings.database_url.get_secret_value())
ana@vm:~/agenda-api$ grep -c "sqlalchemy.url" alembic.ini
0
ana@vm:~/agenda-api$ uv run alembic current 2>&1 | tail -1
0003 (head)
ana@vm:~/agenda-api$ uv run pytest -q
..........                                                                                   [100%]
10 passed in 1.59s
```

Alembic reached the database as the new role, and the tests still pass. One more effect, with the API
running:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/me -H "Authorization: Bearer $(cat token.txt)"; echo
{"detail":"Could not validate the token"}
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/token -d username=bruno -d password=m4-orchard-copper-17 | python3 -c "import json, sys; print(json.load(sys.stdin)['access_token'])" > token.txt
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/me -H "Authorization: Bearer $(cat token.txt)"; echo
{"username":"bruno"}
```

**The token saved in lesson 12 is refused**: it was signed with the old key, and this is how a JWT key
is rotated. Every token issued with it stopped working at once, which is what to do after a leak, and
the cost of doing it otherwise: everybody logs in again.
