---
title: Lendo o diff como um desconhecido
version: 1
---

Uma autorrevisão começa olhando a mudança do jeito que outra pessoa vai olhar: **como um diff**, e não
como os arquivos no seu editor. O editor mostra o que o código é; o diff mostra o que você mudou, que é o
que quem revisa lê primeiro.

Aqui está a mudança de estado vazio do loanbook, feita num branch próprio:

```
ana@laptop:~/loanbook$ git switch -c empty-state
Switched to a new branch 'empty-state'
ana@laptop:~/loanbook$ git add -A
ana@laptop:~/loanbook$ git commit -q -m 'Say what to do when there is nothing to lend'
```

Comece pelo tamanho. `--stat` dá os arquivos e quanto de cada um mudou:

```
ana@laptop:~/loanbook$ git diff --stat main...empty-state
 static/app.js     | 2 ++
 static/index.html | 3 +++
 2 files changed, 5 insertions(+)
```

Cinco linhas em dois arquivos, que é o tamanho certo para uma ideia. **Um diff que você não consegue ler de
uma vez é um diff que ninguém vai ler com cuidado**, inclusive você, e o primeiro comentário de revisão
num diff grande costuma ser *dá para dividir isto?*

Depois o diff inteiro. Os três pontos em `main...empty-state` querem dizer *o que este branch mudou desde
que saiu do main*, que é exatamente o que um pull request mostra:

```
ana@laptop:~/loanbook$ git diff main...empty-state
diff --git a/static/app.js b/static/app.js
index 40feb12..59a99d4 100644
--- a/static/app.js
+++ b/static/app.js
@@ -24,7 +24,9 @@ function row(item) {
 async function load() {
   const res = await fetch("/api/items");
   const items = await res.json();
+  console.log("items", items);
   list.innerHTML = items.map(row).join("");
+  document.getElementById("empty").hidden = items.length > 0;
   for (const form of list.querySelectorAll("form")) {
     form.onsubmit = (e) => {
       e.preventDefault();
diff --git a/static/index.html b/static/index.html
index d3c0805..dfadd4b 100644
--- a/static/index.html
+++ b/static/index.html
@@ -12,6 +12,9 @@
     <thead><tr><th>Item</th><th>Status</th><th>Action</th></tr></thead>
     <tbody id="items"></tbody>
   </table>
+  <p id="empty" hidden>No equipment yet. Whoever runs this server adds it with
+    <code>python3 app.py add "Projector 1"</code>.</p>
+  <!-- TODO: nicer empty state -->
   <script src="/app.js"></script>
 </body>
 </html>
```

Leia de cima a baixo, devagar, como se outra pessoa tivesse escrito. Duas linhas não deveriam estar ali:
um `console.log` que sobrou de conferir o que o servidor devolvia, e um `TODO` que é um lembrete para você
num arquivo que todo visitante baixa. Nenhuma quebra nada, e cada uma diz a quem revisa que a mudança foi
enviada sem ser lida.
