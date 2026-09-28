---
title: O que um teclado encontra
version: 1
---

A segunda verificação é a que qualquer avaliador faz sem instalar nada: **guarde o mouse e aperte Tab**. Cada
toque move o foco para a próxima coisa em que se pode agir, e um leitor de tela anuncia o nome dela. Este
script aperta Tab pela página e imprime como cada parada se chama, como uma aproximação desse anúncio. Antes:

```
$ node tab-walk.mjs
1. input: Borrower
2. button: Lend
3. button: Return
```

Três paradas: um campo chamado *Borrower*, um botão *Lend*, um botão *Return*. Agora imagine quarenta itens.
Quem usa leitor de tela ouve *Borrower, Lend, Borrower, Lend, Return, Borrower…* e não tem como saber de qual
projetor se trata cada um. **Todo nome está certo e nenhum é útil.** Depois do passo 11:

```
$ node tab-walk.mjs
1. input: Lend Projector 1 to
2. button: Lend
3. button: Return Projector 2
```

*Lend Projector 1 to*, e *Return Projector 2*. As mesmas três paradas, e agora cada uma diz sobre o que age.
Aqui está a marcação da página como aquele commit a mudou:

```
ana@laptop:~/loanbook$ git diff v0.2.0 HEAD~1 -- static/index.html
diff --git a/static/index.html b/static/index.html
index 5b24d98..375de42 100644
--- a/static/index.html
+++ b/static/index.html
@@ -7,13 +7,16 @@
   <link rel="stylesheet" href="/style.css">
 </head>
 <body>
-  <h1>Equipment on loan</h1>
-  <table>
-    <thead><tr><th>Item</th><th>Status</th><th>Action</th></tr></thead>
-    <tbody id="items"></tbody>
-  </table>
-  <p id="empty" hidden>No equipment yet. Whoever runs this server adds it with
-    <code>python3 app.py add "Projector 1"</code>.</p>
+  <main>
+    <h1>Equipment on loan</h1>
+    <p id="message" role="status"></p>
+    <table>
+      <thead><tr><th scope="col">Item</th><th scope="col">Status</th><th scope="col">Action</th></tr></thead>
+      <tbody id="items"></tbody>
+    </table>
+    <p id="empty" hidden>No equipment yet. Whoever runs this server adds it with
+      <code>python3 app.py add "Projector 1"</code>.</p>
+  </main>
   <script src="/app.js"></script>
 </body>
 </html>
```

O conteúdo da tabela foi para dentro de `main`, o marco para onde um leitor de tela salta. Um parágrafo com
`role="status"` substituiu o `alert()` nos resultados, porque uma região de status é lida sem tirar o foco
do lugar, e uma caixa de alerta interrompe. Os cabeçalhos das colunas ganharam `scope="col"`, então cada
célula é anunciada com o nome da sua coluna. Os rótulos em si são montados no `app.js`, um por linha,
com o nome do item.

Nada disso apareceu no relatório do axe, antes ou depois. **Uma ferramenta é onde a verificação começa, não
onde termina**, e os poucos minutos com o teclado são o que encontra os problemas que mais importam para
quem os tem.
