---
title: Um conjunto de regras, lido pelos dois lados
version: 1
---

A correção tem duas metades. **O servidor verifica cada campo por conta própria**, que é a metade de
segurança, e **o formulário é gerado a partir das regras do servidor**, o que mantém a verificação
do navegador honesta em vez de apenas presente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l03-one\" aria-label=\"Um conjunto de regras, FIELDS, escrito uma vez no servidor. Uma seta vai dele para o formulário HTML, onde vira os atributos maxlength, type e max. Outra seta vai para a função validate, onde vira as verificações. Como os dois saem do mesmo lugar, o formulário e o servidor não têm como discordar sobre um limite.\"><defs><marker id=\"l03-one-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"70\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">FIELDS (um lugar)</text><rect x=\"330\" y=\"20\" width=\"250\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"455.0\" y=\"40.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os atributos do formulário</text><text x=\"455.0\" y=\"53.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">maxlength, type, max</text><rect x=\"330\" y=\"120\" width=\"250\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"455.0\" y=\"140.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">validate()</text><text x=\"455.0\" y=\"153.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os mesmos limites, aplicados</text><path d=\"M210 85 L270 85 L270 47 L330 47\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-one-ah-paper-dim)\"></path><path d=\"M210 105 L270 105 L270 147 L330 147\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l03-one-ah-paper-dim)\"></path></svg>", "caption": "Escreva cada limite uma vez, no servidor, e gere o formulário a partir dele.", "same": ["maxlength, type, max", "validate()"]}
```

Aqui está o `app.py` novo inteiro:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "import re\nfrom datetime import date\n\nfrom flask import Flask, render_template_string, request\n\napp = Flask(__name__)\nPATIENTS = []\nTODAY = date(2026, 11, 1)\nEMAIL = re.compile(r\"[^@\\s]+@[^@\\s]+\\.[^@\\s]+\")\n", "note": "`TODAY` é fixo para as transcrições se repetirem; um portal de verdade usa `date.today()`. O padrão de e-mail verifica a forma e mais nada."}, {"code": "FIELDS = {\n    \"name\": {\"label\": \"Name\", \"type\": \"text\", \"maxlength\": 60},\n    \"email\": {\"label\": \"E-mail\", \"type\": \"email\", \"maxlength\": 120},\n    \"birth\": {\"label\": \"Birth date\", \"type\": \"date\", \"max\": TODAY.isoformat()},\n}\n", "note": "Todo limite, escrito uma vez. O formulário e a verificação leem os dois este dicionário, então não têm como discordar."}, {"code": "PAGE = \"\"\"<form method=\"post\" action=\"/signup\">\n{%- for name, f in fields.items() %}\n  <label>{{ f.label }} <input name=\"{{ name }}\" type=\"{{ f.type }}\" required\n    {%- if f.maxlength %} maxlength=\"{{ f.maxlength }}\"{% endif %}\n    {%- if f.max %} max=\"{{ f.max }}\"{% endif %}></label>\n  {%- if name in errors %} <strong>{{ errors[name] }}</strong>{% endif %}\n{%- endfor %}\n  <button>Sign up</button>\n</form>\"\"\"\n\n", "note": "O formulário é gerado a partir de `FIELDS`. Um erro aparece ao lado do campo a que se refere, o que ajuda a pessoa; a recusa em si é do servidor."}, {"code": "def validate(form):\n    errors, patient = {}, {}\n    for name, f in FIELDS.items():\n        value = form.get(name, \"\").strip()\n        if not value:\n            errors[name] = \"required\"\n        elif len(value) > f.get(\"maxlength\", 10):\n            errors[name] = \"too long\"\n        elif f[\"type\"] == \"email\" and not EMAIL.fullmatch(value):\n            errors[name] = \"not an e-mail address\"\n        elif f[\"type\"] == \"date\":\n            try:\n                if not date(1900, 1, 1) <= date.fromisoformat(value) <= TODAY:\n                    errors[name] = \"out of range\"\n            except ValueError:\n                errors[name] = \"not a date\"\n        patient[name] = value\n    return errors, patient\n\n", "note": "Os mesmos limites, aplicados. `patient` é montado com os nomes de `FIELDS` e mais nada, então um campo que o formulário nunca teve nunca é guardado. Uma data não tem `maxlength`, então 10 caracteres, o tamanho de `AAAA-MM-DD`, fazem as vezes."}, {"code": "@app.get(\"/signup\")\ndef form():\n    return render_template_string(PAGE, fields=FIELDS, errors={})\n\n\n@app.post(\"/signup\")\ndef signup():\n    errors, patient = validate(request.form)\n    if errors:\n        return render_template_string(PAGE, fields=FIELDS, errors=errors), 400\n    PATIENTS.append(patient)\n    return \"Welcome\", 201", "note": "Uma recusa é a mesma página com os erros e status 400, então o navegador a mostra e um script consegue saber que falhou."}]}
```

O formulário mantém todos os atributos que tinha. Um paciente no navegador vê o mesmo retorno
imediato de antes, agora com a mensagem do próprio servidor ao lado do campo quando algo passa pelo
navegador. O que mudou foi onde os números moram.

### Verde

```
(.venv) ana@vm:~/sc/signup$ pytest
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.7.0
rootdir: /home/ana/sc/signup
collected 8 items

test_app.py ........                                                     [100%]

============================== 8 passed in 0.15s ===============================
```

```
(.venv) ana@vm:~/sc/signup$ git commit -am "Check every field on the server, and draw the form from the same rules"
[main d3e87bc] Check every field on the server, and draw the form from the same rules
 1 file changed, 42 insertions(+), 5 deletions(-)
```

### O formulário, como o servidor o escreve agora

O `curl` sem `-d` envia um `GET`, e imprime a página que o navegador receberia. Cada `maxlength` e o
`max` da data vêm de `FIELDS`:

```
(.venv) ana@vm:~/sc/signup$ curl -s -w '\n' http://127.0.0.1:5000/signup
<form method="post" action="/signup">
  <label>Name <input name="name" type="text" required maxlength="60"></label>
  <label>E-mail <input name="email" type="email" required maxlength="120"></label>
  <label>Birth date <input name="birth" type="date" required max="2026-11-01"></label>
  <button>Sign up</button>
</form>
```

E a requisição da seção anterior, enviada de novo ao servidor novo, é recusada com 400 e o motivo ao
lado de cada campo:

```
(.venv) ana@vm:~/sc/signup$ curl -s -w '\n%{http_code}\n' -d 'name=&email=lucia&birth=2031-01-01' http://127.0.0.1:5000/signup
<form method="post" action="/signup">
  <label>Name <input name="name" type="text" required maxlength="60"></label> <strong>required</strong>
  <label>E-mail <input name="email" type="email" required maxlength="120"></label> <strong>not an e-mail address</strong>
  <label>Birth date <input name="birth" type="date" required max="2026-11-01"></label> <strong>out of range</strong>
  <button>Sign up</button>
</form>
400
```

### O que isto não resolve

O padrão de e-mail verifica que há alguma coisa, um `@`, alguma coisa, um ponto e alguma coisa.
Endereços variam muito mais do que qualquer padrão, e **a única verificação real de um endereço de
e-mail é mandar uma mensagem para ele** com um link de confirmação. Um padrão que tentasse ser
completo recusaria endereços reais e ainda aceitaria alguns que não existem. Mantenha a verificação
de sintaxe frouxa, e deixe o link de confirmação decidir.
