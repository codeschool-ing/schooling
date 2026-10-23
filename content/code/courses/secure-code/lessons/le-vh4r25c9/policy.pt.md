---
title: Uma política que as pessoas conseguem seguir
version: 1
---

A política da primeira versão é a que quase todo mundo já viu: pelo menos oito caracteres, uma letra
maiúscula, um dígito, um símbolo. Ela recusou `lilac river morning tea` por não ter maiúscula, e
aceitou `Vereda2026!`. **As duas respostas estão erradas, e a segunda é a perigosa.**

Regras de composição não produzem senhas aleatórias. Produzem os mesmos poucos padrões, de novo e de
novo: uma palavra com a primeira letra maiúscula, um ano, uma exclamação no fim. Toda ferramenta de
adivinhação tenta esses padrões primeiro. Enquanto isso, uma senha de quatro palavras sem relação é
longa, fácil de lembrar e de digitar, e recusada por não ter símbolo.

### O que o NIST pede hoje

O National Institute of Standards and Technology dos Estados Unidos publica a diretriz contra a qual a
maioria das políticas é escrita hoje, a SP 800-63B, revisada em 2025. Para senhas, ela pede isto:

- **O comprimento é a exigência.** Pelo menos 15 caracteres quando a senha é o único fator, como
  neste portal; pelo menos 8 quando é usada com um segundo fator. Aceite pelo menos 64.
- **Nada de regras de composição.** Nenhuma mistura obrigatória de maiúsculas, dígitos e símbolos.
- **Conferir contra uma lista de bloqueio**: senhas conhecidas de vazamentos anteriores, palavras de
  dicionário, caracteres repetidos ou em sequência, e palavras específicas do serviço, como o nome dele.
- **Nada de troca periódica forçada.** Troque a senha quando houver indício de que foi comprometida,
  não a cada 90 dias; trocas agendadas produzem `Vereda2026!` seguida de `Vereda2027!`.
- **Permitir colar** e gerenciadores de senha, e dizer por que uma senha foi recusada.

### A correção

```
(.venv) ana@vm:~/sc/passwords$ git diff
diff --git a/app.py b/app.py
index b8ce3c5..ed8634a 100644
--- a/app.py
+++ b/app.py
@@ -8,6 +8,7 @@ from flask import Flask, abort, jsonify, request
 app = Flask(__name__)
 USERS = {}
 SESSIONS = {}
+COMMON = {"passwordpassword", "123456789012345", "qwertyuiopasdfgh"}
 HASHER = PasswordHasher()
 DECOY = HASHER.hash("a password nobody has")
 
@@ -29,14 +30,10 @@ def password_is_right(name, password):
 
 
 def policy_problem(password):
-    if len(password) < 8:
-        return "use at least 8 characters"
-    if not any(c.isupper() for c in password):
-        return "add an uppercase letter"
-    if not any(c.isdigit() for c in password):
-        return "add a digit"
-    if password.isalnum():
-        return "add a symbol"
+    if len(password) < 15:
+        return "use at least 15 characters: a few unrelated words are enough"
+    if password.lower() in COMMON or "vereda" in password.lower():
+        return "that password is too easy to guess: choose another"
     return None
 
 
```

A lista de bloqueio aqui tem três entradas, para a página continuar legível, mais uma conferência do
nome da empresa em qualquer forma. **Em produção a lista é longa**: dezenas ou centenas de milhares de
senhas de vazamentos reais. Alguns serviços oferecem a conferência como uma API que só vê os
primeiros caracteres de um hash da senha, então a senha em si nunca sai do servidor.

```
(.venv) ana@vm:~/sc/passwords$ pytest -q --tb=no
........F                                                                [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_changing_the_password_ends_the_other_sessions - Asse...
1 failed, 8 passed in 1.48s
(.venv) ana@vm:~/sc/passwords$ git commit -qam "Ask for length, and refuse guessable passwords"
```

A recusa diz o que fazer, não só o que estava errado: *a few unrelated words are enough*, algumas
palavras sem relação bastam. Uma política que as pessoas conseguem seguir é uma que diz a elas como.
