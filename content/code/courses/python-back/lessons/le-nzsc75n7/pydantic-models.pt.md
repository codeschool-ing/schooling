---
title: Modelos Pydantic: uma classe cujas anotações são as regras
version: 1
---

A aula 6 descreveu o formato de um evento com um serializer. O equivalente no FastAPI é um **modelo
Pydantic**: uma classe cujas anotações de tipo dizem o que cada campo é, conferidas sempre que uma
instância é montada. Salve os formatos da API como `app/schemas.py`:

```schooling-example
{"language": "python", "file": "app/schemas.py", "parts": [{"code": "# app/schemas.py\nfrom datetime import datetime\n\nfrom pydantic import BaseModel, EmailStr, Field\n\n\n", "note": "**Um modelo Pydantic é uma classe cujas anotações são as regras.** O `Field` acrescenta o que um tipo não diz: um padrão, um tamanho, uma faixa."}, {"code": "class EventIn(BaseModel):\n    slug: str = Field(pattern=r\"^[a-z0-9-]+$\", max_length=50)\n    title: str = Field(min_length=1, max_length=200)\n    starts_at: datetime\n    venue: str = Field(min_length=1, max_length=200)\n    capacity: int = Field(ge=1, le=1000)\n    description: str = \"\"\n\n\n", "note": "O `EventIn` é o que um cliente manda para criar um evento. O padrão do slug é o mesmo conjunto de caracteres que o `SlugField` do Django aceita, só em minúsculas."}, {"code": "class EventOut(EventIn):\n    taken: int\n\n\n", "note": "**O `EventOut` herda todos os campos e acrescenta `taken`**, que o servidor calcula e um cliente nunca manda."}, {"code": "class RegistrationIn(BaseModel):\n    name: str = Field(min_length=1, max_length=100)\n    email: EmailStr\n\n\n", "note": "O `EmailStr` valida um endereço direito, e é por isso que o projeto instalou `pydantic[email]`."}, {"code": "class RegistrationOut(RegistrationIn):\n    created_at: datetime\n\n\n", "note": "O que quem se inscreveu recebe de volta: os próprios dados, e a hora."}, {"code": "class RegistrationPublic(BaseModel):\n    name: str\n    created_at: datetime\n", "note": "**O que todo o resto pode ver: um nome e uma hora, sem endereço.** As próximas seções o usam."}]}
```

## Montar um a partir de dados não confiáveis

Este script, salvo como `validate.py` em `~/agenda-api`, monta um evento a partir de textos como o
JSON os entregaria, e uma inscrição que está errada duas vezes:

```python
# validate.py
from pydantic import ValidationError

from app.schemas import EventIn, RegistrationIn

event = EventIn(
    slug="pycon-watch",
    title="PyCon talks, watched together",
    starts_at="2026-12-03T19:00:00-03:00",
    venue="Public Library, lab 2",
    capacity="15",
)
print(repr(event.starts_at), repr(event.capacity))

try:
    RegistrationIn(name="", email="not-an-address")
except ValidationError as error:
    print(error.error_count(), "errors")
    for e in error.errors():
        print(e["loc"], e["type"], "-", e["msg"])
```

```
ana@vm:~/agenda-api$ uv run python validate.py
datetime.datetime(2026, 12, 3, 19, 0, tzinfo=TzInfo(-10800)) 15
2 errors
('name',) string_too_short - String should have at least 1 character
('email',) value_error - value is not a valid email address: An email address must have an @-sign.
```

**`"15"` virou o inteiro 15**, e o texto da data virou um `datetime` com o deslocamento. O Pydantic
**converte** um valor quando a conversão não tem ambiguidade, o que se chama modo *lax* e é o padrão
dele; um modelo declarado com `strict=True` recusa o texto. A inscrição falhou nos **dois** campos, e os
dois erros estão num `ValidationError` só, cada um com o nome do campo, um código de tipo que um
programa pode testar e uma mensagem que uma pessoa pode ler.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Quatro valores JSON à esquerda passam cada um pela regra que o campo declara: um slug comparado com um padrão, uma data interpretada, o texto 15 convertido no inteiro 15, e um endereço de e-mail sem arroba, que falha. Quando todo campo passa, o resultado é um modelo com valores tipados; quando algum falha, todo erro é listado e o FastAPI responde 422.\"> <defs><marker id=\"pd-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <defs><marker id=\"pd-b\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <text x=\"110\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o que chegou</text> <rect x=\"20\" y=\"34\" width=\"180\" height=\"132\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"30\" y=\"58\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"slug\": \"pycon-watch\"</text> <text x=\"30\" y=\"88\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"starts_at\": \"2026-12-…\"</text> <text x=\"30\" y=\"118\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"capacity\": \"15\"</text> <text x=\"30\" y=\"148\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"email\": \"not-an-address\"</text> <text x=\"360\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o tipo e as regras do campo</text> <rect x=\"240\" y=\"42\" width=\"240\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"58\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">str, pattern ^[a-z0-9-]+$</text> <path d=\"M200 54 L234 54\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pd-a)\"></path> <rect x=\"240\" y=\"72\" width=\"240\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">datetime: interpretado</text> <path d=\"M200 84 L234 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pd-a)\"></path> <rect x=\"240\" y=\"102\" width=\"240\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"118\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">int, ge=1: \"15\" vira 15</text> <path d=\"M200 114 L234 114\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pd-a)\"></path> <rect x=\"240\" y=\"132\" width=\"240\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.15\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"148\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">EmailStr: sem arroba</text> <path d=\"M200 144 L234 144\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pd-b)\"></path> <rect x=\"520\" y=\"34\" width=\"180\" height=\"54\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"610\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tudo passa: um modelo,</text> <text x=\"610\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">com valores tipados</text> <rect x=\"520\" y=\"112\" width=\"180\" height=\"54\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.15\" stroke=\"var(--amber)\"></rect> <text x=\"610\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">algo falha: todo erro</text> <text x=\"610\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">listado, depois 422</text> <path d=\"M480 61 L514 61\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pd-a)\"></path> <path d=\"M480 139 L514 139\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#pd-b)\"></path> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">A função nunca roda com dados que falharam; os argumentos já chegam no tipo certo.</text> </svg>", "caption": "A validação é por campo e completa: uma requisição com dois erros recebe os dois de uma vez."}
```

Quando uma conversão tem ambiguidade, ela falha, e o texto da própria exceção diz como:

```
ana@vm:~/agenda-api$ uv run python -c "from app.schemas import EventIn; EventIn(slug=\"x\", title=\"x\", starts_at=\"tomorrow\", venue=\"x\", capacity=\"fifteen\")" 2>&1 | tail -7
pydantic_core._pydantic_core.ValidationError: 2 validation errors for EventIn
starts_at
  Input should be a valid datetime or date, input is too short [type=datetime_from_date_parsing, input_value='tomorrow', input_type=str]
    For further information visit https://errors.pydantic.dev/2.14/v/datetime_from_date_parsing
capacity
  Input should be a valid integer, unable to parse string as an integer [type=int_parsing, input_value='fifteen', input_type=str]
    For further information visit https://errors.pydantic.dev/2.14/v/int_parsing
```

## O mesmo trabalho de um serializer, dito de outro jeito

| | serializer do DRF | modelo Pydantic |
|---|---|---|
| declarado com | objetos de campo: `serializers.IntegerField(min_value=1)` | anotações de tipo: `capacity: int = Field(ge=1)` |
| conhece o banco | o `ModelSerializer` lê o modelo | nada; é Python puro |
| códigos de erro | uma mensagem por campo | uma mensagem e um `type` legível por máquina por campo |
| usado fora da web | possível, raramente feito | em todo lugar: configurações na aula 15, qualquer dado que cruza uma fronteira |

A última linha importa. O Pydantic não faz parte do FastAPI, é uma biblioteca que o FastAPI usa, e os
mesmos modelos validam um arquivo de configuração, uma mensagem de uma fila ou uma linha de um CSV.
