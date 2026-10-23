---
title: O LIKE tem curingas próprios
version: 1
---

Um teste ainda falha, e é outro tipo de problema. O marcador garantiu que o valor é dado. Mas o valor
é um **padrão de `LIKE`**, e dentro de um padrão dois caracteres têm significado próprio: `%`
corresponde a qualquer sequência de caracteres e `_` a um caractere qualquer. Busque por `%`, e o
padrão `%%%` corresponde a todo paciente do portal:

```
(.venv) ana@vm:~/sc/search$ curl -s -G --data-urlencode 'surname=%' http://127.0.0.1:5000/patients
[{"clinic":"Pinheiros","first_name":"Marta","surname":"Avelar"},{"clinic":"Pinheiros","first_name":"Lucia","surname":"D'\u00c1vila"},{"clinic":"Santana","first_name":"Bruno","surname":"O'Neill"},{"clinic":"Moema","first_name":"Rafael","surname":"Souza"}]
```

Nenhum SQL foi injetado; a consulta fez o que um `LIKE` com esse padrão faz. Mesmo assim, a
recepcionista digitou um caractere e recebeu a lista inteira de pacientes, e uma busca por `S_uza`
acha `Souza` sem que ninguém tenha digitado um `o`. Numa tabela grande, um padrão cheio de curingas
também é lento. **O que um valor quer dizer dentro do programa que o lê é o código que decide, não
quem digita.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l05-like\" aria-label=\"O mesmo termo de busca lido por dois interpretadores em sequência. Em cima, o termo % vai como placeholder, então o SQL o lê como valor e não como código; depois o LIKE lê o mesmo valor como padrão, em que % quer dizer qualquer sequência de caracteres, e todo sobrenome casa. Embaixo, o like_pattern transforma o termo numa barra invertida e um sinal de porcentagem; o SQL continua lendo um valor, e o LIKE, avisado de que a barra escapa, lê um sinal de porcentagem literal, que nenhum sobrenome contém.\"><defs><marker id=\"l05-like-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"80\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">digitado</text><text x=\"330\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">lido pelo SQL</text><text x=\"580\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">lido pelo LIKE</text><rect x=\"20\" y=\"50\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">%</text><path d=\"M140 75 L240 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-like-ah-paper-dim)\"></path><rect x=\"240\" y=\"50\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um valor, não código</text><path d=\"M420 75 L480 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-like-ah-paper-dim)\"></path><rect x=\"480\" y=\"50\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"68.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">qualquer sequência de caracteres</text><text x=\"590.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">todo paciente casa</text><rect x=\"20\" y=\"124\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">\\%</text><path d=\"M140 149 L240 149\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-like-ah-paper-dim)\"></path><rect x=\"240\" y=\"124\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um valor, não código</text><path d=\"M420 149 L480 149\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-like-ah-paper-dim)\"></path><rect x=\"480\" y=\"124\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"142.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um % literal</text><text x=\"590.0\" y=\"155.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nenhum paciente casa</text><text x=\"190\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">like_pattern()</text></svg>", "caption": "O placeholder resolve o primeiro leitor e nada mais. O padrão precisa do próprio escape, porque o LIKE é um segundo leitor."}
```

A correção escapa os dois curingas, e o próprio caractere de escape, e diz ao SQLite qual caractere
escapa com `ESCAPE '\'`:

```
(.venv) ana@vm:~/sc/search$ git diff
diff --git a/app.py b/app.py
index d768bf2..6b6c640 100644
--- a/app.py
+++ b/app.py
@@ -47,6 +47,11 @@ def init_db():
         db().commit()
 
 
+def like_pattern(term):
+    escaped = term.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
+    return f"%{escaped}%"
+
+
 @app.get("/patients")
 def search():
     term = request.args.get("surname", "")
@@ -55,8 +60,8 @@ def search():
         abort(400)
     rows = db().execute(
         "SELECT first_name, surname, clinic FROM patients "
-        f"WHERE surname LIKE ? ORDER BY {order}",
-        (f"%{term}%",),
+        f"WHERE surname LIKE ? ESCAPE '\\' ORDER BY {order}",
+        (like_pattern(term),),
     )
     return jsonify([dict(row) for row in rows])
 
```

```
(.venv) ana@vm:~/sc/search$ pytest -q
.....                                                                    [100%]
5 passed in 0.13s
```

**Cinco de cinco.** Faça o commit, e veja o histórico:

```
(.venv) ana@vm:~/sc/search$ git commit -qam "Search for % and _ literally"
(.venv) ana@vm:~/sc/search$ git log --oneline
e44568f Search for % and _ literally
61f929c Pass the surname as a parameter, and allowlist the sort
ef40cab Search patients by surname, sorted
```

### Onde mais um valor é um pequeno programa

O `LIKE` é o caso desta aula; o hábito é mais amplo. Um valor posto numa expressão regular precisa de
`re.escape`; um valor posto num comando de shell é a aula 6; um valor posto numa página é a aula 4.
Toda vez, pergunte o que lê o valor em seguida e o que esse leitor trata como especial.
