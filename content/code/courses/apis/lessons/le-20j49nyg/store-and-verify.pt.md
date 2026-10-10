---
title: Contas para a shelf
version: 1
---

**A shelf ganha uma tabela `users` com uma coluna para o hash e nenhuma para a senha, e dois
comandos: um para cadastrar, outro para entrar.** O login também faz o que a seção anterior pediu:
quando os parâmetros no código mudaram desde que um hash foi feito, ele troca esse hash enquanto tem a
senha correta à mão.

Salve como `~/shelf/passwords.py`:

```schooling-example
{
  "language": "python",
  "file": "shelf/passwords.py",
  "parts": [
    {
      "code": "# shelf/passwords.py\n\"\"\"The bookshop's accounts: a password is stored as an Argon2id hash and checked at login.\n\n    python3 passwords.py register NAME    asks for a password and stores its hash\n    python3 passwords.py login NAME       asks for a password and checks it\n\"\"\"\nimport getpass\nimport secrets\nimport sqlite3\nimport sys\n\nfrom argon2 import PasswordHasher\nfrom argon2.exceptions import VerifyMismatchError\n\nimport db",
      "note": "A biblioteca padrão, o `argon2` do `python3-argon2` e o `db.py` da lição 1, então as contas moram no mesmo `shelf.db` que os livros."
    },
    {
      "code": "\nHASHER = PasswordHasher(memory_cost=19456, time_cost=2, parallelism=1)\nDECOY = HASHER.hash(secrets.token_urlsafe(16))\nSHORTEST = 15",
      "note": "O `HASHER` guarda os parâmetros, o mínimo da OWASP para o Argon2id, no único lugar onde uma edição os muda. O `DECOY` é o hash de um texto aleatório que ninguém conhece, feito uma vez quando o programa começa. `SHORTEST` é o comprimento mínimo do NIST para uma senha que é o único fator."
    },
    {
      "code": "\n\ndef accounts():\n    conn = db.connect()\n    conn.execute(\"CREATE TABLE IF NOT EXISTS users (\"\n                 \" id INTEGER PRIMARY KEY,\"\n                 \" name TEXT NOT NULL UNIQUE,\"\n                 \" password_hash TEXT NOT NULL)\")\n    return conn",
      "note": "A tabela tem uma coluna para o hash e nenhuma para a senha. O `CREATE TABLE IF NOT EXISTS` a cria no `shelf.db` na primeira vez e deixa o `db.py` como estava."
    },
    {
      "code": "\n\ndef register(name, password):\n    if len(password) < SHORTEST:\n        raise ValueError(f\"a password needs at least {SHORTEST} characters\")\n    with accounts() as conn:\n        conn.execute(\"INSERT INTO users (name, password_hash) VALUES (?, ?)\",\n                     (name, HASHER.hash(password)))",
      "note": "O `HASHER.hash` sorteia um salt novo de 16 bytes e devolve um texto só com o algoritmo, os parâmetros, o salt e o hash. Esse texto é tudo o que a linha guarda."
    },
    {
      "code": "\n\ndef login(name, password):\n    \"\"\"True if the password is right, with the same work whether or not the name exists.\"\"\"\n    with accounts() as conn:\n        row = conn.execute(\"SELECT id, password_hash FROM users WHERE name = ?\",\n                           (name,)).fetchone()\n        stored = row[\"password_hash\"] if row else DECOY\n        try:\n            HASHER.verify(stored, password)\n        except VerifyMismatchError:\n            return False\n        if row is None:\n            return False\n        if HASHER.check_needs_rehash(stored):\n            conn.execute(\"UPDATE users SET password_hash = ? WHERE id = ?\",\n                         (HASHER.hash(password), row[\"id\"]))\n        return True",
      "note": "Um nome que não existe é conferido contra o `DECOY`, então custa o mesmo hash que uma senha errada. O `verify` lê os parâmetros do texto guardado, e não do `HASHER`, e é por isso que um hash antigo ainda confere depois que eles mudam. O `check_needs_rehash` compara os dois, e um hash feito com parâmetros antigos é trocado enquanto a senha está à mão."
    },
    {
      "code": "\n\ndef ask():\n    \"\"\"Typed without echo at a terminal; one line when it comes through a pipe.\"\"\"\n    if sys.stdin.isatty():\n        return getpass.getpass(\"password: \")\n    return sys.stdin.readline().rstrip(\"\\n\")",
      "note": "Num terminal, a senha é digitada sem eco. Por um pipe, como nas transcrições abaixo, é uma linha da entrada padrão. Ela nunca é um argumento, porque os argumentos de um comando em execução ficam visíveis para todo usuário da máquina."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    if len(sys.argv) != 3 or sys.argv[1] not in (\"register\", \"login\"):\n        sys.exit(__doc__)\n    command, name = sys.argv[1:]\n    password = ask()\n    if command == \"register\":\n        try:\n            register(name, password)\n        except (ValueError, sqlite3.IntegrityError) as e:\n            sys.exit(f\"not registered: {e}\")\n        print(f\"registered {name}\")\n    elif login(name, password):\n        print(f\"welcome, {name}\")\n    else:\n        sys.exit(\"wrong name or password\")",
      "note": "Dois comandos. Um nome errado e uma senha errada recebem a mesma frase, pelo motivo que a última seção desta lição dá."
    }
  ]
}
```

Cada comando pede a senha. Num terminal você a digita e nada aparece. Nas transcrições abaixo ela
chega por um pipe vindo do `echo`, para você ver o que foi enviado. Fazer o mesmo deixa a senha no
histórico do seu shell, o que serve para uma senha inventada para esta lição e para mais nada.

O diretório tem os dois arquivos da lição 1 e os dois desta, e também o `shelf.db` se você já rodou o
`rest.py`:

```
ana@api:~/shelf$ ls
db.py
hashrate.py
passwords.py
rest.py
```

Uma senha curta demais é recusada antes de qualquer hash. Depois a Ana se cadastra, e um segundo
cadastro com o mesmo nome é recusado pelo `UNIQUE` da tabela:

```
ana@api:~/shelf$ echo 'sunshine' | python3 passwords.py register ana
not registered: a password needs at least 15 characters
ana@api:~/shelf$ echo 'correct horse battery staple' | python3 passwords.py register ana
registered ana
ana@api:~/shelf$ echo 'correct horse battery staple' | python3 passwords.py register ana
not registered: UNIQUE constraint failed: users.name
```

Entrando com a senha certa, e com uma que difere na última letra:

```
ana@api:~/shelf$ echo 'correct horse battery staple' | python3 passwords.py login ana
welcome, ana
ana@api:~/shelf$ echo 'correct horse battery stapler' | python3 passwords.py login ana
wrong name or password
```

E a própria linha. Isto é tudo o que um vazamento do `shelf.db` mostraria sobre a senha da Ana:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT * FROM users'
1|ana|$argon2id$v=19$m=19456,t=2,p=1$rZXEcBow2YskINKytiXaLg$uqN7XiHe8l1STpFKzRYDTg
```

## Mudando os parâmetros

Digamos que a medição da seção anterior convenceu você a dar 46 MiB a cada login em vez de 19. A
mudança é um número no `HASHER`:

```
ana@api:~/shelf$ sed -i 's/memory_cost=19456/memory_cost=47104/' passwords.py && grep -n 'HASHER =' passwords.py
17:HASHER = PasswordHasher(memory_cost=47104, time_cost=2, parallelism=1)
```

Nada mais muda, e ninguém fica trancado do lado de fora. A Ana entra como antes, e a linha fica
diferente depois:

```
ana@api:~/shelf$ echo 'correct horse battery staple' | python3 passwords.py login ana
welcome, ana
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT * FROM users'
1|ana|$argon2id$v=19$m=47104,t=2,p=1$HqHQJDbw//7YwobzMSn2sg$wpRteeWTjxZbETvb019qAA
```

O `verify` conferiu a senha dela contra o texto antigo, usando os parâmetros escritos nele, `m=19456`.
Conferiu, então o `check_needs_rehash` comparou esses com os do `HASHER`, achou `m=47104` lá, e o
`login` guardou um hash novo, com um salt novo, enquanto ainda tinha a senha. A linha de mais ninguém
mudou, e não vai mudar até a pessoa entrar.

**Essa é a fraqueza de atualizar no login: uma conta que ninguém usa fica com o hash antigo para
sempre.** A folha da OWASP diz o remédio para quando isso importa, como depois de abandonar um esquema
fraco: passado um tempo, apagar os hashes antigos e pedir a esses usuários que definam uma senha nova.

Daqui em diante, o resto desta lição usa o `passwords.py` editado, com `m=47104`.
