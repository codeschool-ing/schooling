---
title: Templates recebem variáveis, não texto
version: 1
---

A prévia do lembrete monta o template emendando o recado da recepcionista no próprio texto do
template:

```python
    page = render_template_string(
        "<p>Hello {{ patient }}, see you on {{ day }}.</p><p>" + note + "</p>",
```

Os lembretes do console usam `{{ name }}` para o nome do paciente, então as recepcionistas estão
acostumadas a digitar chaves. Uma escreve um recado com um par delas:

```
(.venv) ana@vm:~/sc/exams-convert$ pytest -q --tb=short -k note 2>&1 | grep -E '^E |^jinja2|passed|failed'
E   AssertionError: assert 'Hello lucia' in '<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The ser...nd was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
jinja2.exceptions.TemplateSyntaxError: expected token 'end of print statement', got 'referral'
1 failed, 5 deselected in 0.16s
```

O `grep` tira de um traceback longo a asserção e o erro do próprio motor de templates.
`expected token 'end of print statement', got 'referral'`. **O Jinja interpretou o recado como parte
do template**, achou `{{ the referral }}`, e tentou ler `the referral` como expressão. Aqui a expressão
não era válida e a página falhou com `500`. Um recado cujas chaves guardassem por acaso uma expressão
válida teria sido **avaliado**, no servidor, com tudo o que o motor de templates alcança. Isso é
**injeção de template no servidor**, e nos motores da maioria das linguagens esse alcance chega a rodar
código no servidor.

Há uma segunda perda escondida na mesma linha. Um valor escrito no texto do template também não é
escapado, porque deixou de ser valor: o autoescape da aula 4 vale para **variáveis**, e o recado tinha
deixado de ser uma.

### O canal separado: uma variável

O texto do template é fixo e o recado é passado como `note=note`, exatamente como `patient` e `day`
já eram:

```
(.venv) ana@vm:~/sc/exams-convert$ git diff
diff --git a/app.py b/app.py
index fecbd07..9a3bc57 100644
--- a/app.py
+++ b/app.py
@@ -50,8 +50,9 @@ def find_staff():
 def preview():
     note = request.form.get("note", "")
     page = render_template_string(
-        "<p>Hello {{ patient }}, see you on {{ day }}.</p><p>" + note + "</p>",
+        "<p>Hello {{ patient }}, see you on {{ day }}.</p><p>{{ note }}</p>",
         patient="lucia",
         day="Monday 16 November",
+        note=note,
     )
     return page
```

```
(.venv) ana@vm:~/sc/exams-convert$ pytest -q
......                                                                   [100%]
6 passed in 0.17s
```

Seis de seis. As chaves aparecem como foram escritas, e tudo o mais que o recado tiver é escapado como
qualquer outro valor. Faça o commit, e veja o histórico:

```
(.venv) ana@vm:~/sc/exams-convert$ git commit -qam "Pass the note to the template as a variable"
(.venv) ana@vm:~/sc/exams-convert$ git log --oneline
863e513 Pass the note to the template as a variable
5192718 Escape the name in the LDAP filter
9e253dd Run file with a list of arguments, without a shell
6196450 Exam types, staff lookup and reminder preview
```

### A regra para templates

**Um template é código, escrito por quem desenvolve e guardado no repositório; dados chegam a ele só
como variáveis.** O `render_template_string` não é errado em si, e esta aula o usa para cada programa
caber na página; fica errado no momento em que o primeiro argumento dele é montado a partir de
qualquer coisa que uma requisição trouxe. O mesmo vale para qualquer recurso que deixe usuários
escreverem os próprios templates, como os templates de lembrete do console: esses precisam de um motor
deliberadamente limitado, como o ambiente com sandbox do Jinja, e de uma revisão própria.
