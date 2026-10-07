---
title: A resposta é entrada não confiável
version: 2
---

A resposta de um modelo vai para algum lugar: uma página, uma query, um comando de shell, um
arquivo. **Trate-a como qualquer outra coisa que veio de fora**, porque muitas vezes veio: o modelo
copia texto do que leu, e o que ele leu foi escrito por outra pessoa.

## Numa página

Uma avaliação de produto chega com uma tag de script dentro, o `review.html`:

```html
<p>Love the lamp, the light is warm.</p><script>alert("hi")</script>
```

e o modelo é pedido a reescrevê-la como HTML para a página do produto. O `render.py` guarda o bloco de
código da resposta, numa linha só, e o põe na página duas vezes:

```python
"""Put a model's rewrite of a review into a page, twice: as it came, and escaped."""
import html
import re
import subprocess
import sys

reply = subprocess.run([sys.executable, "ask.py", "Rewrite this product review as HTML for the product page, "
                        "keeping its markup: " + open("review.html").read()], capture_output=True, text=True).stdout
block = re.search(r"```\w*\n(.*?)\n```", reply, re.S)
fragment = " ".join((block.group(1) if block else reply).split())
print("as it came: <div class=\"review\">" + fragment + "</div>")
print("escaped:    <div class=\"review\">" + html.escape(fragment) + "</div>")
```

```
ana@dev:~/shop$ python render.py
as it came: <div class="review"><p>Love the lamp, the light is warm.</p> <script>alert("hi")</script></div>
escaped:    <div class="review">&lt;p&gt;Love the lamp, the light is warm.&lt;/p&gt; &lt;script&gt;alert(&quot;hi&quot;)&lt;/script&gt;</div>
```

**O modelo manteve a tag**, como lhe pediram manter a marcação. Posta na página como veio, ela é um
script que roda no navegador de todo visitante. Escapada, é texto que mostra o que diz. Um pedido que
soava inofensivo, manter a formatação da avaliação, foi tudo o que bastou; pedido um resumo de uma
frase, o mesmo modelo descartou a tag enquanto esta aula era preparada, e o escape é para o dia em que
não descartar. Ele é uma chamada, e o lugar dele é o ponto em que texto vira HTML, como para qualquer
outro conteúdo de usuário. Sistemas de template que escapam por padrão fazem isso por você; desligar
isso para a saída "confiável" do modelo é o erro.

## Numa query

```python
"""Use a model's answer in a query, twice: pasted into the SQL, and as a parameter."""
import sqlite3
import subprocess
import sys

EMAIL = "The lamp from my last order flickers when I turn it on. Can you help?\n\nDara O'Brien"
name = subprocess.run([sys.executable, "ask.py", "Which customer wrote this email? Reply with the name only.\n\n" + EMAIL],
                      capture_output=True, text=True).stdout.strip()
db = sqlite3.connect(":memory:")
db.execute("create table customers (name text, email text)")
db.execute("insert into customers values (?, ?)", ("Dara O'Brien", "dara@example.com"))
try:
    print("pasted:   ", db.execute(f"select email from customers where name = '{name}'").fetchall())
except sqlite3.Error as e:
    print("pasted:    sqlite3 error:", e)
print("parameter:", db.execute("select email from customers where name = ?", (name,)).fetchall())
```

```
ana@dev:~/shop$ python lookup.py
pasted:    sqlite3 error: near "Brien": syntax error
parameter: [('dara@example.com',)]
```

O modelo leu o nome na assinatura do e-mail, como pedido: `Dara O'Brien`. **Um apóstrofo num nome
real quebra a query colada.** Aqui ela falha alto. Uma resposta com outro
formato mudaria o que a query faz em vez de quebrá-la. Um parâmetro nunca faz parte do SQL, então a
mesma resposta acha o e-mail da Dara.

## A regra, toda vez

- **HTML**: escape, ou use um template que escapa por padrão.
- **SQL**: parâmetros, nunca formatação de string.
- **Shell**: uma lista de argumentos, nunca um comando em string; melhor ainda, nenhum shell.
- **Markdown renderizado como HTML**: sanitize o resultado, porque Markdown deixa HTML cru passar.
- **Caminhos de arquivo**: resolva e confira que ficam dentro da pasta, como a ferramenta do manual
  da aula 7 fazia.

Nada disso é novo. **O novo é que o texto não confiável chega parecendo a saída do seu próprio
programa**, de uma função que você escreveu, e é aí que as pessoas esquecem.
