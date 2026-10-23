---
title: Comandos sem shell
version: 1
---

O recurso de tipo de exame monta uma linha de comando e a entrega ao shell:

```python
    result = subprocess.run(
        f"file --brief --mime-type exams/{name}", shell=True, capture_output=True, text=True
    )
```

Peça a ele um exame cujo nome tem um espaço, e leia o que o `file` respondeu:

```
(.venv) ana@vm:~/sc/exams-convert$ pytest -q --tb=short -k spaces
F                                                                        [100%]
=================================== FAILURES ===================================
_____________________ test_a_name_with_spaces_is_one_file ______________________
/home/ana/sc/exams-convert/test_app.py:21: in test_a_name_with_spaces_is_one_file
    assert client.get("/exams/knee scan.pdf/type").json["type"] == "application/pdf"
E   AssertionError: assert 'cannot open ...or directory)' == 'application/pdf'
E     
E     - application/pdf
E     + cannot open `exams/knee' (No such file or directory)
E     + cannot open `scan.pdf' (No such file or directory)
=========================== short test summary info ============================
FAILED test_app.py::test_a_name_with_spaces_is_one_file - AssertionError: ass...
1 failed, 5 deselected in 0.22s
```

``cannot open `exams/knee'`` e ``cannot open `scan.pdf'``. **O shell dividiu o nome no espaço**,
porque dividir em espaços é o que um shell faz com uma linha de comando, e rodou o `file` em dois
arquivos que não existem. O nome devia ser um argumento; o shell o leu como parte do programa. Todo
outro caractere a que o shell dá significado, `;`, `|`, `$( )`, aspas, está na mesma posição desse
espaço, e a mesma linha agiria sobre cada um deles.

### O canal separado: nenhum shell

O `subprocess.run` não precisa de shell. Recebendo uma **lista**, ele inicia o programa diretamente e
entrega cada elemento como um argumento, exatamente como está escrito. Nenhum shell interpreta nada,
então nenhum caractere de `name` tem significado:

```
(.venv) ana@vm:~/sc/exams-convert$ git diff
diff --git a/app.py b/app.py
index 2060366..4dc7da8 100644
--- a/app.py
+++ b/app.py
@@ -29,7 +29,9 @@ def directory():
 @app.get("/exams/<path:name>/type")
 def exam_type(name):
     result = subprocess.run(
-        f"file --brief --mime-type exams/{name}", shell=True, capture_output=True, text=True
+        ["file", "--brief", "--mime-type", "--", str(EXAMS / name)],
+        capture_output=True,
+        text=True,
     )
     return jsonify(name=name, type=result.stdout.strip())
 
```

Dois detalhes da chamada nova importam. O **`--`** diz ao `file` que tudo depois dele é nome de
arquivo, mesmo um que comece com `-`; sem ele, um exame chamado `-z.pdf` seria lido como opção, pelo
próprio `file` e não pelo shell. E `EXAMS / name` monta o caminho com `pathlib` em vez de juntar
strings. Quais nomes podem chegar a essa pasta é a pergunta da aula de upload, a aula 14.

```
(.venv) ana@vm:~/sc/exams-convert$ pytest -q --tb=no
...FFF                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_star_is_a_character_not_everyone - AssertionError:...
FAILED test_app.py::test_parentheses_in_a_name_are_searched_for - AssertionEr...
FAILED test_app.py::test_a_note_is_shown_as_written - AssertionError: assert ...
3 failed, 3 passed in 0.19s
```

**Uma falha a menos.** Faça o commit:

```
(.venv) ana@vm:~/sc/exams-convert$ git commit -qam "Run file with a list of arguments, without a shell"
```

### Melhor ainda: nenhum comando

A linha de comando mais segura é a que o programa não precisa. O Python faz boa parte do que pequenas
ferramentas de linha de comando fazem: `pathlib` e `shutil` copiam e movem arquivos, `zipfile` faz
arquivos compactados, bibliotecas como a `python-magic` leem tipos de arquivo pela `libmagic` sem
processo nenhum. Quando um programa realmente precisa rodar outro, as regras são as de cima: **uma
lista, nada de `shell=True`, `--` antes de qualquer nome, e nunca `os.system`**, que sempre usa um
shell.
