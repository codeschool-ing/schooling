---
title: Filtros LDAP, escapados pela biblioteca
version: 1
---

**LDAP** é o protocolo que fala a maioria dos diretórios de pessoal das organizações, o Active
Directory da Microsoft entre eles. Uma busca manda um **filtro** escrito numa linguagem pequena
própria: `(cn=carla)` quer dizer "entradas cujo nome comum é carla", `*` quer dizer "qualquer coisa",
e parênteses agrupam condições. O console monta o filtro com uma f-string:

```python
        "ou=staff,dc=vereda,dc=example", f"(cn={request.args['name']})", attributes=["cn", "title"]
```

Uma recepcionista que não lembra um nome e digita `*`, como muitas caixas de busca permitem, recebe
toda a equipe:

```
(.venv) ana@vm:~/sc/exams-convert$ pytest -q --tb=short -k star
F                                                                        [100%]
=================================== FAILURES ===================================
___________________ test_a_star_is_a_character_not_everyone ____________________
/home/ana/sc/exams-convert/test_app.py:29: in test_a_star_is_a_character_not_everyone
    assert client.get("/staff?name=*").json == []
E   AssertionError: assert [{'name': 'an...e': 'physio'}] == []
E     
E     Left contains 3 more items, first extra item: {'name': 'ana', 'role': 'admin'}
E     Use -v to get more diff
=========================== short test summary info ============================
FAILED test_app.py::test_a_star_is_a_character_not_everyone - AssertionError:...
1 failed, 5 deselected in 0.15s
```

**A estrela foi lida como o curinga do filtro**, não como um caractere de um nome. Neste diretório,
"todo mundo" são três pessoas e seus papéis; num de verdade, é toda conta da organização, com os
atributos que a busca pedir. Um nome com parênteses, como alguns diretórios guardam o departamento ao
lado do nome, quebra o filtro de vez, e o console responde `500`:

```
(.venv) ana@vm:~/sc/exams-convert$ pytest -q --tb=short -k parentheses 2>&1 | grep -E '^E |^ldap3|passed|failed'
E   AssertionError: assert None == []
E    +  where None = <WrapperTestResponse streamed [500 INTERNAL SERVER ERROR]>.json
E    +    where <WrapperTestResponse streamed [500 INTERNAL SERVER ERROR]> = get('/staff', query_string={'name': 'Silva (Pinheiros)'})
E    +      where get = <FlaskClient <Flask 'app'>>.get
ldap3.core.exceptions.LDAPInvalidFilterError: malformed filter
1 failed, 5 deselected in 0.17s
```

### O escape da biblioteca

Filtros LDAP não têm marcadores, então este é o caso em que o **escape** é o canal separado. A RFC
4515, que define a sintaxe dos filtros, diz como: cada caractere especial é escrito como uma barra
invertida e seus dois dígitos hexadecimais, então `*` vira `\2a` e quer dizer uma estrela. O `ldap3`
traz a função:

```
(.venv) ana@vm:~/sc/exams-convert$ git diff
diff --git a/app.py b/app.py
index 4dc7da8..fecbd07 100644
--- a/app.py
+++ b/app.py
@@ -4,6 +4,7 @@ from pathlib import Path
 
 from flask import Flask, jsonify, render_template_string, request
 from ldap3 import MOCK_SYNC, Connection, Server
+from ldap3.utils.conv import escape_filter_chars
 
 app = Flask(__name__)
 EXAMS = Path("exams")
@@ -40,7 +41,7 @@ def exam_type(name):
 def find_staff():
     connection = directory()
     connection.search(
-        "ou=staff,dc=vereda,dc=example", f"(cn={request.args['name']})", attributes=["cn", "title"]
+        "ou=staff,dc=vereda,dc=example", f"(cn={escape_filter_chars(request.args['name'])})", attributes=["cn", "title"]
     )
     return jsonify([{"name": str(e.cn), "role": str(e.title)} for e in connection.entries])
 
```

```
(.venv) ana@vm:~/sc/exams-convert$ pytest -q --tb=no
.....F                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_note_is_shown_as_written - AssertionError: assert ...
1 failed, 5 passed in 0.19s
```

**A estrela agora não acha ninguém, porque ninguém se chama `*`, e os parênteses são buscados como
estão escritos.** Faça o commit:

```
(.venv) ana@vm:~/sc/exams-convert$ git commit -qam "Escape the name in the LDAP filter"
```

Mais dois hábitos valem para buscas em diretório. **Conecte a aplicação com uma conta que só lê o que
o recurso precisa**, para que um filtro que der errado exponha os atributos de que o console precisa
e não os dados de toda conta. E **peça atributos nomeados**, `["cn", "title"]` como aqui, em vez de
todos.
