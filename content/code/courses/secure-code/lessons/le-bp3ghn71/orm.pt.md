---
title: Usar um ORM do jeito certo
version: 1
---

Um **ORM**, um mapeador objeto-relacional, escreve o SQL por você a partir de objetos Python. Usado
como previsto, ele parametriza todo valor, e esse é um dos melhores motivos para usar um. Ele também
oferece um caminho de volta ao SQL cru, e é por esse caminho que a injeção volta em projetos que
achavam que o ORM a tinha eliminado.

Esta seção usa o SQLAlchemy, o ORM mais usado em Python, contra o mesmo `patients.db`. Instale:

```
(.venv) ana@vm:~/sc/search$ pip install --progress-bar off sqlalchemy==2.1.6
Collecting sqlalchemy==2.1.6
  Downloading sqlalchemy-2.1.6-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl.metadata (9.7 kB)
Requirement already satisfied: typing-extensions>=4.6.0 in /home/ana/sc/.venv/lib/python3.13/site-packages (from sqlalchemy==2.1.6) (4.16.0)
Downloading sqlalchemy-2.1.6-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl (4.7 MB)
Installing collected packages: sqlalchemy
Successfully installed sqlalchemy-2.1.6
```

O `orm.py` liga a tabela `patients` a uma classe e pede a lucia de três jeitos. Salve ao lado do
`app.py`:

```schooling-example
{"language": "python", "file": "orm.py", "parts": [{"code": "# orm.py\nfrom sqlalchemy import String, create_engine, select, text\nfrom sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column\n\n\nclass Base(DeclarativeBase):\n    pass\n\n\nclass Patient(Base):\n    __tablename__ = \"patients\"\n    id: Mapped[int] = mapped_column(primary_key=True)\n    first_name: Mapped[str] = mapped_column(String(50))\n    surname: Mapped[str] = mapped_column(String(50))\n    clinic: Mapped[str] = mapped_column(String(50))\n\n\nengine = create_engine(\"sqlite:///patients.db\")\nname = \"D'Ávila\"\n", "note": "Uma classe para a tabela `patients`, no estilo tipado do SQLAlchemy 2, e o mesmo arquivo de banco que o portal usa."}, {"code": "with Session(engine) as session:\n    query = select(Patient.surname).where(Patient.surname == name)\n    print(query)\n    print(session.scalars(query).all())\n", "note": "A consulta montada com objetos. `print(query)` mostra o SQL que o ORM vai mandar, antes de mandar."}, {"code": "    bound = text(\"SELECT surname FROM patients WHERE surname = :surname\")\n    print(session.scalars(bound, {\"surname\": name}).all())\n", "note": "SQL cru pelo `text()`, com um marcador nomeado e o valor num dicionário."}, {"code": "    built = text(f\"SELECT surname FROM patients WHERE surname = '{name}'\")\n    print(session.scalars(built).all())", "note": "SQL cru montado com f-string: o caminho de volta, usado do jeito errado."}]}
```

```
(.venv) ana@vm:~/sc/search$ python3 orm.py 2>&1 | grep -v '^ '
SELECT patients.surname 
FROM patients 
WHERE patients.surname = :surname_1
["D'Ávila"]
["D'Ávila"]
Traceback (most recent call last):
sqlite3.OperationalError: near "Ávila": syntax error

The above exception was the direct cause of the following exception:

Traceback (most recent call last):
sqlalchemy.exc.OperationalError: (sqlite3.OperationalError) near "Ávila": syntax error
[SQL: SELECT surname FROM patients WHERE surname = 'D'Ávila']
(Background on this error at: https://sqlalche.me/e/21/e3q8)
```

O `grep -v '^ '` esconde as linhas recuadas do traceback, então o que sobra é o que cada um dos três
jeitos imprimiu.

- **A consulta montada com objetos** imprimiu primeiro o SQL, e o valor é um **parâmetro vinculado**,
  `:surname_1`, não o nome. A segunda linha é o resultado: `D'Ávila`, encontrada.
- **O `text()` com `:surname`** é SQL cru, e continua seguro, porque o nome viaja como valor no
  dicionário ao lado. SQL cru não é o problema.
- **O `text()` com f-string** é a falha da primeira seção, escrita dentro do ORM. O SQLAlchemy passou a
  string ao SQLite, e o SQLite falhou no mesmo apóstrofo com a mesma mensagem. O ORM não protege um
  valor que já foi colado no texto.

### O que procurar numa revisão

Todo ORM tem a sua grafia do caminho de volta, e cada uma é segura com valores vinculados e insegura
com uma string montada a partir deles:

| ORM | o caminho de volta ao SQL |
|---|---|
| SQLAlchemy | `text(…)`, e `.where()` recebendo uma string em vez de uma expressão |
| Django | `.raw(…)`, `.extra(…)`, `RawSQL(…)`, e `cursor.execute(…)` |
| ActiveRecord | `where("surname = '#{name}'")`, `order(params[:sort])` |

Uma busca no código por esses nomes, seguida de uma olhada no que monta a string passada a cada um,
acha a maior parte das injeções que um projeto com ORM tem. O resto da revisão é o mesmo que sem ORM:
**colunas de ordenação, nomes de tabela e outros identificadores vêm de uma lista de permissão**,
porque nenhum ORM consegue vincular um nome de coluna como valor.
