---
title: "Termina: sair no servidor"
version: 1
---

O logout da primeira versão:

```python
@app.post("/sign-out")
def sign_out():
    response = jsonify(signed_out=True)
    response.delete_cookie("sid")
    return response
```

Parece completo. O navegador recebe um `Set-Cookie` que expira o cookie, esquece o id, e a próxima
página pede para o paciente entrar de novo. **Mas a tabela de sessões continua com o id, e o
servidor continua a atendê-lo.** Qualquer cópia feita antes do logout, no log de um proxy, num
perfil de navegador que outra pessoa abriu, na memória de um script, continua funcionando até o
limite de inatividade acabar, ou para sempre se não houver um. A paciente apertou o botão para
encerrar a sessão, e nada no servidor terminou.

A regra: **sair apaga a sessão onde ela é conferida.** Apagar o cookie é uma cortesia com o
navegador; apagar a linha é a segurança.

```
(.venv) ana@vm:~/sc/sessions$ git diff
diff --git a/app.py b/app.py
index 653aece..05c5ebc 100644
--- a/app.py
+++ b/app.py
@@ -69,6 +69,7 @@ def bookings():
 
 @app.post("/sign-out")
 def sign_out():
+    SESSIONS.pop(request.cookies.get("sid"), None)
     response = jsonify(signed_out=True)
     response.delete_cookie("sid")
     return response
```

```
(.venv) ana@vm:~/sc/sessions$ pytest -q
.......                                                                  [100%]
7 passed in 0.13s
```

**Sete de sete.** Faça o commit da última correção, e veja o histórico:

```
(.venv) ana@vm:~/sc/sessions$ git commit -qam "End the session on the server at sign-out"
(.venv) ana@vm:~/sc/sessions$ git log --oneline
119d187 End the session on the server at sign-out
23b59a8 Issue a new id at sign-in, and expire idle and old sessions
7aab90c Draw session ids from secrets, and mark the cookie
2d69645 Sign patients in with a server-side session
```

O log é a aula em quatro linhas: um commit com as falhas e os testes que as nomeiam, e um commit
por momento, cada um deixando verdes alguns desses testes.

### Quando mais uma sessão termina

Sair é o momento que o paciente escolhe. Outros três cabem à aplicação escolher, e cada um é apagar
uma ou mais linhas como a de cima:

- **Quando a senha muda, toda outra sessão daquela conta termina.** Senão a paciente que a trocou
  por desconfiar de alguém acredita que trancou essa pessoa do lado de fora, e não trancou. A aula
  11 escreve esse teste.
- **Quando uma conta é desativada ou um papel é retirado**, as sessões terminam na hora. Retirar um
  acesso que continua valendo até o limite de inatividade é só agendar a retirada.
- **Quando algo parece errado**, a equipe pode encerrar uma sessão, ou todas, sem pedir a ninguém
  que saia. Com sessões no servidor isso é apagar; com cookies assinados, é trocar a `secret_key` e
  deslogar todo mundo.

Nada disso é possível com uma sessão que o servidor não guarda. É por isso que o portal desta aula as
guarda, e é a pergunta a fazer à sessão de qualquer framework antes de confiar nela: **consigo
encerrar uma a partir do servidor?**
