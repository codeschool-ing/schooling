---
title: O pydantic-settings no FastAPI
version: 1
---

O agenda-api lê a configuração por uma classe. Acrescente a biblioteca, e declare o que a API precisa
em `app/config.py`:

```
ana@vm:~/agenda-api$ uv add pydantic-settings
Resolved 42 packages in 283ms
Prepared 2 packages in 53ms
Installed 2 packages in 3ms
 + pydantic-settings==2.16.1
 + python-dotenv==1.2.4
```

```schooling-example
{"language": "python", "file": "app/config.py", "parts": [{"code": "# app/config.py\nfrom pydantic import SecretStr\nfrom pydantic_settings import BaseSettings, SettingsConfigDict\n\n\n", "note": "O **pydantic-settings** é o Pydantic para configuração: uma classe cujos campos são preenchidos pelo ambiente, e validados como um corpo de requisição."}, {"code": "class Settings(BaseSettings):\n    model_config = SettingsConfigDict(env_file=\".env\", env_prefix=\"AGENDA_API_\")\n\n", "note": "O `env_prefix` liga `secret_key` a `AGENDA_API_SECRET_KEY`; o `env_file` também lê um `.env` no diretório atual, abaixo do ambiente de verdade na prioridade."}, {"code": "    database_url: SecretStr\n    secret_key: SecretStr\n", "note": "**O `SecretStr`** mantém um valor fora de todo `print`, linha de log e traceback; o `.get_secret_value()` é o único jeito de lê-lo. A URL é secreta porque leva a senha."}, {"code": "    token_minutes: int = 30\n\n\n", "note": "Um padrão torna o campo opcional, e o tipo o converte: `AGENDA_API_TOKEN_MINUTES=15` chega como o inteiro 15."}, {"code": "settings = Settings()\n", "note": "Montado uma vez, na importação. Um campo faltando para a aplicação aqui, antes de ela responder a qualquer pessoa."}]}
```

Sem um `.env` e sem as variáveis:

```
ana@vm:~/agenda-api$ uv run python -c 'from app.config import settings' 2>&1 | tail -6
database_url
  Field required [type=missing, input_value={}, input_type=dict]
    For further information visit https://errors.pydantic.dev/2.14/v/missing
secret_key
  Field required [type=missing, input_value={}, input_type=dict]
    For further information visit https://errors.pydantic.dev/2.14/v/missing
```

**Os dois campos faltando, pelo nome**, num erro só, antes de qualquer outra coisa rodar. Escreva o
arquivo, com uma chave gerada e uma senha gerada dentro da URL, e dê ao agenda-api um papel próprio
como o agenda tem:

```
ana@vm:~/agenda-api$ printf 'AGENDA_API_SECRET_KEY=%s\nAGENDA_API_DATABASE_URL=postgresql+psycopg://agenda_api_app:%s@localhost/agenda_api\n' "$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')" "$(python3 -c 'import secrets; print(secrets.token_urlsafe(24))')" > .env
ana@vm:~/agenda-api$ echo "create role agenda_api_app login password :'pw'" | sudo -u postgres psql -v pw="$(sed -n 's|^AGENDA_API_DATABASE_URL=.*agenda_api_app:\(.*\)@.*|\1|p' .env)"
CREATE ROLE
ana@vm:~/agenda-api$ sudo -u postgres psql agenda_api -c "reassign owned by ana to agenda_api_app" -c "alter database agenda_api owner to agenda_api_app"
REASSIGN OWNED
ALTER DATABASE
```

E as configurações, impressas:

```
ana@vm:~/agenda-api$ uv run python -c 'from app.config import settings; print(settings)'
database_url=SecretStr('**********') secret_key=SecretStr('**********') token_minutes=30
```

**`'**********'`**: a URL e a chave não conseguem vazar por um print nem por um traceback.

## Lendo

O `app/db.py` monta a engine a partir da configuração:

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

No `app/security.py`, a chave e a vida do token vêm das configurações, com o import ao lado dos outros:

```python
from .config import settings
from .db import SessionDep
from .models import User

SECRET_KEY = settings.secret_key.get_secret_value()
ALGORITHM = "HS256"
TOKEN_MINUTES = settings.token_minutes
```

O `migrations/env.py` do Alembic lê a mesma URL, então ela é escrita uma vez, no `.env`; a linha
`sqlalchemy.url` sai do `alembic.ini`, que a aula 10 precisava manter em dia com o `app/db.py`:

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

O Alembic chegou ao banco como o papel novo, e os testes continuam passando. Mais um efeito, com a API
rodando:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/me -H "Authorization: Bearer $(cat token.txt)"; echo
{"detail":"Could not validate the token"}
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/token -d username=bruno -d password=m4-orchard-copper-17 | python3 -c "import json, sys; print(json.load(sys.stdin)['access_token'])" > token.txt
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/me -H "Authorization: Bearer $(cat token.txt)"; echo
{"username":"bruno"}
```

**O token guardado na aula 12 é recusado**: ele foi assinado com a chave antiga, e é assim que se troca
a chave de um JWT. Todo token emitido com ela parou de funcionar na hora, que é o que fazer depois de um
vazamento, e o custo de fazê-lo fora disso: todo mundo entra de novo.
