---
title: Uma mudança por commit
version: 1
---

O hábito mais difícil é o primeiro, porque o trabalho não chega uma mudança por vez. Você corrige uma
coisa, repara em outra, acrescenta uma linha para ver o que está acontecendo. Na hora do commit, a árvore
de trabalho tem três mudanças, e *git add .* faria delas um commit só.

Aqui está o loanbook no passo 12, com a correção para quem pega emprestado com um nome feito de espaços
escrita, o teste dela escrito, e uma linha de depuração ainda no código:

```
ana@laptop:~/loanbook$ git status --short
 M app.py
 M test_app.py
```

`git add -p` passa pelas mudanças um **trecho** (*hunk*) por vez e pergunta, para cada um, se deve
prepará-lo. O primeiro trecho é a correção; a resposta é `y`. O segundo é a linha de depuração; a resposta
é `n`:

```
ana@laptop:~/loanbook$ printf 'y\nn\n' | git add -p app.py
diff --git a/app.py b/app.py
index e6039b6..f5d8924 100644
--- a/app.py
+++ b/app.py
@@ -71,6 +71,7 @@ def item_named(db, item_id):
 
 
 def lend(db, item_id, borrower, today):
+    borrower = (borrower or "").strip()
     if not borrower:
         raise Refused(HTTPStatus.BAD_REQUEST, "Say who is borrowing it.")
     item = item_named(db, item_id)
(1/2) Stage this hunk [y,n,q,a,d,j,J,g,/,e,?]? @@ -115,6 +116,7 @@ class Handler(BaseHTTPRequestHandler):
         item_id, action = int(m[1]), m[2]
         try:
             body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
+            print("DEBUG body", body)
             with closing(connect()) as db:
                 if action == "loan":
                     result = lend(db, item_id, body.get("borrower"), date.today())
(2/2) Stage this hunk [y,n,q,a,d,K,g,/,e,?]? 
```

O que ficou sem preparar é exatamente o que não deve entrar no commit. `git diff` mostra a árvore de
trabalho contra a área de preparação, então lista a linha de depuração e o teste, que ainda não foi
adicionado. A linha de depuração é descartada com `git restore`, o teste é adicionado, e o commit leva a
correção e o teste dela e nada mais:

```
ana@laptop:~/loanbook$ git diff
diff --git a/app.py b/app.py
index e48521f..f5d8924 100644
--- a/app.py
+++ b/app.py
@@ -116,6 +116,7 @@ class Handler(BaseHTTPRequestHandler):
         item_id, action = int(m[1]), m[2]
         try:
             body = json.loads(self.rfile.read(int(self.headers.get("Content-Length") or 0)) or b"{}")
+            print("DEBUG body", body)
             with closing(connect()) as db:
                 if action == "loan":
                     result = lend(db, item_id, body.get("borrower"), date.today())
diff --git a/test_app.py b/test_app.py
index f5885a4..9e1fe69 100644
--- a/test_app.py
+++ b/test_app.py
@@ -35,6 +35,11 @@ class LoanRules(unittest.TestCase):
             app.give_back(self.db, 1, TODAY)
         self.assertEqual(refused.exception.status, 409)
 
+    def test_a_borrower_made_of_spaces_is_refused(self):
+        with self.assertRaises(app.Refused) as refused:
+            app.lend(self.db, 1, "   ", TODAY)
+        self.assertEqual(refused.exception.status, 400)
+
     def test_a_loan_is_overdue_the_day_after_it_is_due(self):
         app.lend(self.db, 1, "Bruno", TODAY)
         due = TODAY + timedelta(days=app.LOAN_DAYS)
ana@laptop:~/loanbook$ git restore app.py
ana@laptop:~/loanbook$ git add test_app.py
ana@laptop:~/loanbook$ git commit -q -m 'Refuse a borrower made of spaces' -m 'The test came first, and it failed: "   " was accepted as a name.'
```

Duas coisas fazem isso valer o minuto a mais. **A linha de depuração nunca chega ao histórico**, que é a
primeira verificação da aula 10 feita antes da aula 10. E **o commit pode ser lido, e revertido, como uma
ideia só**: se o strip se mostrar errado, um `git revert` remove ele e o teste dele, e nada sem relação vai
junto.
