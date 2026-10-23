---
title: "Refletido: HTML montado fora do template"
version: 1
---

A busca devolve a caixa de entrada quando algo é encontrado. Quando nada é, responde com uma frase
montada por uma f-string:

```python
        return f"<p>No messages match {term}.</p>"
```

O resto da aplicação usa templates, que escapam. Esta linha não usa nenhum, então o termo chega à
página exatamente como chegou (o `-w '\n'` só imprime uma quebra de linha depois da resposta):

```
(.venv) ana@vm:~/sc/messages$ curl -s -w '\n' -G --data-urlencode 'q=<i>knee</i>' http://127.0.0.1:5000/search
<p>No messages match <i>knee</i>.</p>
```

`<i>knee</i>` voltou como `<i>knee</i>`, e um navegador mostraria **knee** em itálico. Aqui o termo só
chega a quem o digitou, então o risco é um link que outra pessoa escreveu, já com o termo dentro, e
que a recepcionista abre. É por isso que XSS refletido aparece tanto em páginas de erro e em mensagens
de "nenhum resultado": são escritas com pressa, muitas vezes à mão, e citam a requisição.

A correção põe a frase num template, onde `term` é uma variável e é escapado como qualquer outra:

```
(.venv) ana@vm:~/sc/messages$ git diff
diff --git a/app.py b/app.py
index de8e65b..6ed83f1 100644
--- a/app.py
+++ b/app.py
@@ -35,5 +35,5 @@ def search():
     term = request.args.get("q", "")
     found = [m for m in MESSAGES if term.lower() in m["text"].lower()]
     if not found:
-        return f"<p>No messages match {term}.</p>"
+        return render_template_string("<p>No messages match {{ term }}.</p>", term=term)
     return render_template_string(INBOX, messages=found)
```

```
(.venv) ana@vm:~/sc/messages$ pytest -q --tb=no
....F                                                                    [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_the_script_writes_text_not_markup - assert 'innerHTM...
1 failed, 4 passed in 0.12s
```

**Resta uma falha**, e é a que nenhum teste do lado do servidor consegue ver na página. Faça o commit:

```
(.venv) ana@vm:~/sc/messages$ git commit -qam "Write the no-match sentence through the template"
```

A regra aplicada é a da aula 4: **HTML é produzido pelo motor de templates, nunca juntando strings**.
Uma rota que devolve uma string com uma tag dentro, montada a partir de qualquer coisa que a requisição
trouxe, é o que procurar numa revisão. JSON é o padrão mais seguro para uma resposta que não é página,
e o `jsonify` do Flask o manda com um tipo de conteúdo que navegadores não desenham como HTML.
