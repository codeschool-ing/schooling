---
title: Levar os scripts do próprio portal para um arquivo
version: 1
---

Os dois relatórios nomeiam código que o portal escreveu. A correção não é afrouxar a política em volta
deles; é levá-los para onde a política permite que scripts venham, **um arquivo na origem do próprio
portal**.

O Flask serve qualquer coisa numa pasta chamada `static` ao lado do `app.py`, em `/static/…`. Crie a
pasta e o arquivo:

```
(.venv) ana@vm:~/sc/csp$ mkdir static
```

```javascript
// static/portal.js
document.title = "Vereda: " + document.getElementById("when").textContent;
document.getElementById("larger").addEventListener("click", () => {
  document.getElementById("when").classList.toggle("large");
});
```

A primeira linha é o script inline, sem mudança. O resto substitui o atributo `onclick`: o botão ganha
um `id`, e o arquivo **liga o tratador** com `addEventListener`, que é código num arquivo e não código
num atributo. A página agora carrega o arquivo com `<script src>`:

```
(.venv) ana@vm:~/sc/csp$ git diff
diff --git a/app.py b/app.py
index 278aa93..59e3fbf 100644
--- a/app.py
+++ b/app.py
@@ -12,10 +12,8 @@ PAGE = """<!doctype html>
 <body>
 <h1>Your next session</h1>
 <p id="when">Monday 16 November, 09:00, with carla</p>
-<button onclick="document.getElementById('when').classList.toggle('large')">Larger text</button>
-<script>
-  document.title = "Vereda: " + document.getElementById("when").textContent;
-</script>
+<button id="larger">Larger text</button>
+<script src="/static/portal.js"></script>
 </body>
 </html>
 """
```

```
(.venv) ana@vm:~/sc/csp$ pytest -q --tb=no
.FF...                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_every_page_sends_an_enforced_policy - assert 'Conten...
FAILED test_app.py::test_scripts_come_only_from_the_portal - assert None == "...
2 failed, 4 passed in 0.13s
```

**O teste do código inline passa, e o do arquivo de script também.** Reinicie e olhe:

```
(.venv) ana@vm:~/sc/csp$ python3 look.py
title: Vereda: Monday 16 November, 09:00, with carla
larger text: True
```

Nenhuma mensagem. Tudo o que a página faz agora vem de um arquivo que a política permite, então a
política só de relatório não tem mais nada a relatar. Faça o commit da mudança:

```
(.venv) ana@vm:~/sc/csp$ git add static/portal.js
(.venv) ana@vm:~/sc/csp$ git commit -qam "Move the page's scripts into a file"
```

### Quando um script inline não pode mudar de lugar

Às vezes uma página precisa de um valor que só o servidor conhece na hora de desenhar, e o hábito é um
`<script>` inline que o escreve numa variável. Dois jeitos tiram isso do caminho da política:

- **Ponha o valor no HTML como dado**, `<main data-patient-id="…">`, e deixe o arquivo de script lê-lo
  com `dataset`. Dado não é código, e o escape da aula 4 cobre atributos.
- **Um nonce**: o servidor sorteia um valor para cada resposta, o põe na política,
  `script-src 'self' 'nonce-…'`, e no único `<script nonce="…">` em que confia. Um script injetado na
  página não tem como conhecer o valor. O nonce precisa ser novo em toda resposta, ou é só uma senha
  escrita na página.

Nunca `'unsafe-inline'`: ele permite os scripts inline do portal e os de todo mundo, o que equivale a
desligar a linha que importa.
