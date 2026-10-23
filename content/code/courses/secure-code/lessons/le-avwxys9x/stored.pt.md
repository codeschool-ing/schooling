---
title: "Armazenado: o valor marcado como seguro"
version: 1
---

O template da caixa de entrada escreve cada mensagem assim:

```
{{ m.text|replace("\n", "<br>")|safe }}
```

A intenção era razoável. Mensagens têm quebras de linha, o HTML ignora quebras de linha, então o
template transforma cada `\n` em `<br>`, e depois marca o resultado como `safe` para o Jinja não
escapar as tags `<br>` que acabou de acrescentar. **O `safe` não vale só para as tags `<br>`; vale para
o valor inteiro**, então tudo o mais que a lucia digitou também passa como HTML confiável. A revisão
da aula 18 achou a mesma linha num diff e a marcou como achado 3.

A correção mantém as quebras de linha sem HTML nenhum. O texto é escrito como um valor escapado comum,
e uma linha de CSS diz ao navegador que mostre as quebras de linha: `white-space: pre-line`.

```
(.venv) ana@vm:~/sc/messages$ git diff
diff --git a/app.py b/app.py
index 5936458..de8e65b 100644
--- a/app.py
+++ b/app.py
@@ -9,12 +9,15 @@ MESSAGES = [
 
 INBOX = """<!doctype html>
 <html lang="en">
-<head><meta charset="utf-8"><title>Inbox</title></head>
+<head>
+<meta charset="utf-8"><title>Inbox</title>
+<style>.message { white-space: pre-line; }</style>
+</head>
 <body>
 <h1 id="reply">Inbox</h1>
 <form action="/search"><input name="q"><button>Search</button></form>
 {% for m in messages %}
-<p class="message"><strong>{{ m.patient }}</strong>: {{ m.text|replace("\\n", "<br>")|safe }}</p>
+<p class="message"><strong>{{ m.patient }}</strong>: {{ m.text }}</p>
 {% endfor %}
 <script src="/static/inbox.js"></script>
 </body>
```

```
(.venv) ana@vm:~/sc/messages$ pytest -q --tb=no
...FF                                                                    [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_search_term_is_shown_as_text - AssertionError: ass...
FAILED test_app.py::test_the_script_writes_text_not_markup - assert 'innerHTM...
2 failed, 3 passed in 0.11s
```

**Duas falhas a menos.** O `<b>` da lucia agora são os seis caracteres que ela mandou, mostrados como
foram escritos.

### Onde o `safe` se esconde

Todo motor de templates tem um jeito de desligar o escape para um valor, e cada um é um lugar a olhar
numa revisão: `|safe` e `Markup(...)` no Jinja, `{% autoescape false %}`, `mark_safe` e `|safe` no
Django, `dangerouslySetInnerHTML` no React (com esse nome, de propósito, para fazer um revisor parar),
`v-html` no Vue, `{{{ }}}` no Handlebars. A pergunta é sempre a mesma: **alguma parte deste valor pode
ter vindo de uma pessoa?** Se a resposta é sim, o valor não é seguro, seja qual for o motivo de
marcá-lo.

Quando alguma formatação é mesmo necessária, num editor de mensagens com negrito e listas por exemplo,
a resposta é um **sanitizador**: uma biblioteca que interpreta o HTML e mantém só uma lista de
permissão de tags e atributos, como o `nh3` em Python ou o DOMPurify no navegador. É a ideia de lista
de permissão da aula 2, aplicada à marcação, e pertence ao recurso que precisa dela, não a toda
mensagem.

Faça o commit:

```
(.venv) ana@vm:~/sc/messages$ git commit -qam "Show messages as text, with line breaks kept by CSS"
```
