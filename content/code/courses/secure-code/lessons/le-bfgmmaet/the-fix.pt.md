---
title: Um template que sabe onde está escrevendo
version: 1
---

A correção não são seis chamadas de escape na f-string. É **um motor de templates que escapa por
padrão**, para que a coisa segura aconteça sem ninguém precisar lembrar, e os dois contextos que o
padrão não cobre (dentro de `<script>` e dentro de uma URL) escritos com a ferramenta feita para cada
um.

O Flask renderiza templates Jinja2 com **escape automático ligado** para HTML, e o
`render_template_string` conta como HTML. Todo `{{ … }}` é escapado para HTML, a não ser que algo
diga o contrário. Este é o `app.py` novo:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "from urllib.parse import urlsplit\n\nfrom flask import Flask, render_template_string\n\nfrom profiles import PROFILES\n\napp = Flask(__name__)\n", "note": "Os dados vão para `profiles.py`, sem mudança, para o diff mostrar só a página."}, {"code": "PAGE = \"\"\"<h1>{{ p.name }}</h1>\n<input name=\"nickname\" value=\"{{ p.nickname }}\">\n{% if website %}<a href=\"{{ website }}\">website</a>{% endif %}\n<a href=\"{{ url_for('search', q=p.name) }}\">bookings of {{ p.name }}</a>\n<script>const note = {{ p.note|tojson }};</script>\n\"\"\"\n", "note": "Um template, quatro contextos. O Jinja escapa `{{ … }}` para HTML no texto e no atributo **entre aspas**; `url_for` monta a query; `tojson` escreve um literal JavaScript seguro dentro de `<script>`."}, {"code": "\ndef web_link(url):\n    return url if urlsplit(url).scheme in (\"http\", \"https\") else None\n", "note": "O escape torna inofensivo o texto de um link e não diz nada sobre para onde ele vai. Só endereços web viram links."}, {"code": "\n@app.get(\"/patients/<user>\")\ndef profile(user):\n    p = PROFILES[user]\n    return render_template_string(PAGE, p=p, website=web_link(p[\"website\"]))\n\n\n@app.get(\"/search\")\ndef search():\n    return \"\"", "note": "`/search` existe para o `url_for` ter uma rota para nomear; o que ela faz é assunto da aula 5."}]}
```

Quatro detalhes desse template carregam a aula:

- **`{{ p.name }}` é escapado** no título e no texto do link, do jeito que a primeira linha da figura
  diz.
- **`value="{{ p.nickname }}"` está entre aspas.** O escape automático transforma `"` em `&#34;`, o
  que só basta porque o atributo tem aspas a proteger. Escreva `value={{ p.nickname }}` sem elas e um
  espaço no apelido terminaria o atributo, escapado ou não.
- **`url_for('search', q=p.name)` monta a query**, codificando o valor para URL, e o escape
  automático depois escapa a URL inteira para o atributo: as duas camadas da segunda figura, na ordem
  certa, sem código escrito para nenhuma.
- **`{{ p.note|tojson }}` não tem aspas em volta.** O `tojson` escreve as aspas ele mesmo, como parte
  do literal JavaScript. Aspas em volta produziriam `""…""`, que é outro erro.

### Verde

```
(.venv) ana@vm:~/sc/profile$ pytest -q
......                                                                   [100%]
6 passed in 0.11s
```

```
(.venv) ana@vm:~/sc/profile$ git commit -am "Render the profile with an autoescaping template, tojson and url_for"
[main 40e37e0] Render the profile with an autoescaping template, tojson and url_for
 1 file changed, 15 insertions(+), 8 deletions(-)
```

### A página, como é escrita agora

```
(.venv) ana@vm:~/sc/profile$ curl -s http://127.0.0.1:5000/patients/lucia
<h1>Lucia &amp; Bia &lt;3</h1>
<input name="nickname" value="Lu &#34;the fast&#34;">
<a href="https://lucia.example/blog?a=1&amp;b=2">website</a>
<a href="/search?q=Lucia+%26+Bia+%3C3">bookings of Lucia &amp; Bia &lt;3</a>
<script>const note = "back pain \u003c/script\u003e again";</script>
```

Cada valor está onde o contexto espera, na codificação que o leitor dele espera. Num navegador, a
página mostra exatamente o que o paciente digitou: `Lucia & Bia <3` no título, `Lu "the fast"` na
caixa, `back pain </script> again` na nota. **O escape correto é invisível para quem lê a página**, e
é também por isso que a falta dele quase nunca é relatada.
