---
title: "Baseado no DOM: o próprio script da página"
version: 1
---

O título "Replying to lucia" é escrito pelo `static/inbox.js`, no navegador, a partir da parte do
endereço depois do `#`. O fragmento **nunca é mandado ao servidor**: nenhum template o viu, nenhum log o
registrou, e nenhum teste do lado do servidor acharia a falha lendo respostas. É isso que "baseado no
DOM" quer dizer.

O script escreve com `innerHTML`, que **interpreta o valor como HTML** e constrói os elementos que ele
descrever. Foi isso que pôs o segundo elemento em negrito na página. A correção é a versão do próprio
DOM para o escape: **o `textContent` define texto e não interpreta nada**.

```
(.venv) ana@vm:~/sc/messages$ git diff
diff --git a/static/inbox.js b/static/inbox.js
index ff1b83c..8703ae8 100644
--- a/static/inbox.js
+++ b/static/inbox.js
@@ -1,5 +1,5 @@
 // static/inbox.js
 const replyTo = new URLSearchParams(location.hash.slice(1)).get("reply");
 if (replyTo) {
-  document.getElementById("reply").innerHTML = "Replying to " + replyTo;
+  document.getElementById("reply").textContent = "Replying to " + replyTo;
 }
```

```
(.venv) ana@vm:~/sc/messages$ pytest -q
.....                                                                    [100%]
5 passed in 0.11s
```

Cinco de cinco. Reinicie o portal e rode o `look.py` de novo:

```
(.venv) ana@vm:~/sc/messages$ python3 look.py
heading: Replying to lucia <b>D'Ávila</b>
first message: lucia: Knee <b>much</b> better since Monday.
See you Thursday.
bold elements: 0
```

**Nenhum elemento em negrito.** O título e a mensagem mostram as tags como caracteres, que é exatamente
o que a lucia e o endereço continham. Faça o commit, e veja o histórico:

```
(.venv) ana@vm:~/sc/messages$ git commit -qam "Write the reply heading with textContent"
(.venv) ana@vm:~/sc/messages$ git log --oneline
ffaaa7e Write the reply heading with textContent
0e487e9 Write the no-match sentence through the template
dbf9b46 Show messages as text, with line breaks kept by CSS
6d36ae8 Staff inbox, search and reply heading
```

### As funções perigosas do DOM

O XSS baseado no DOM mora numa lista curta de funções do navegador que transformam uma string em
marcação ou código. Procurá-las num código de front-end é a revisão:

| escreve marcação ou roda código | a contrapartida segura |
|---|---|
| `element.innerHTML = …`, `outerHTML`, `insertAdjacentHTML` | `textContent`, ou construir elementos com `createElement` |
| `document.write(…)` | construir elementos; nunca escrever o documento |
| `eval(…)`, `new Function(…)`, `setTimeout("…")` com uma string | chamar uma função; ler dados com `JSON.parse` |
| `location = …`, `a.href = …` com um valor que pode ser `javascript:` | conferir o esquema numa lista de permissão, como a aula 4 fez com links |

Mais duas defesas ficam atrás dessas. **A Content Security Policy da aula 8** impede que um script
injetado rode mesmo quando um erro como este passa. E os navegadores hoje oferecem **Trusted Types**,
uma política que faz o `innerHTML` e seus parentes recusarem strings comuns de vez, para que toda essa
classe de erro falhe alto no desenvolvimento em vez de falhar quieta em produção.
