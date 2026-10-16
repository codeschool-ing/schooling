---
title: Boxoffice, a aplicação em teste
version: 1
---

Toda aula deste curso testa uma aplicação: o **boxoffice**, a bilheteria do Vila, um teatro pequeno
de São Paulo. Ele vende ingressos para três espetáculos, manda um e-mail para confirmar uma conta
nova e leva cada pedido de reservado a pago a usado. É pequeno o bastante para ler de uma vez e
grande o bastante para estar errado de dez jeitos diferentes, e essa é a ideia: **ele tem defeitos
de propósito**, e as aulas os encontram uma técnica de cada vez. Esta seção dá as duas coisas de que
um testador parte, os requisitos e o programa, e o põe para rodar.

## Os requisitos

Um testador nunca testa um programa contra o que imagina que ele deveria fazer. Testa contra algo
escrito, e para o boxoffice é a lista abaixo, como o teatro a escreveu. Todo caso deste curso cita
um destes ids, e a aula 2 diz por que isso importa.

| id | requisito |
|---|---|
| R1 | A página inicial lista todo espetáculo com data e hora, preço e lugares restantes. Horários são de São Paulo. |
| R2 | Qualquer pessoa cria uma conta com um nome de 1 a 40 caracteres, um e-mail que nenhuma outra conta usa e uma senha de 8 a 64 caracteres. |
| R3 | Uma conta nova recebe um e-mail com um link que a confirma, válido por 24 horas. Pedir um link novo faz o antigo deixar de funcionar. |
| R4 | Quem tem conta reserva de 1 a 6 ingressos por pedido para um espetáculo, enquanto houver lugar. A reserva de um espetáculo fecha uma hora antes do início. |
| R5 | Um ingresso custa o preço do espetáculo. Estudantes pagam meia. Uma conta confirmada, um membro, tem 10% de desconto, e um pedido de 5 ingressos ou mais tem 15%. Descontos não se somam: vale o maior. |
| R6 | Um pedido novo fica reservado. Um pedido reservado pode ser pago ou cancelado; um pedido pago pode ser usado na porta, ou reembolsado antes de o espetáculo começar. Cancelar ou reembolsar devolve os lugares. |
| R7 | Entrada errada é respondida com uma frase dizendo o que está errado, nunca com uma página de erro. |
| R8 | Toda página funciona numa tela de celular de 360 pixels de largura e no desktop, nas versões atuais do Chrome, Firefox, Safari e Edge. |
| R9 | Toda página pode ser usada só com o teclado e com leitor de tela, no nível AA da WCAG 2.2. |

Uma página não está na lista porque o sistema real do teatro não a tem. **A caixa de saída**, em
`/outbox`, mostra todo e-mail que a aplicação enviou, do mais novo ao mais antigo. Em produção esses
e-mails sairiam para caixas de entrada de verdade; nesta versão de teste eles param ali, para você
ler. A aula 22 trata de por que ambientes de teste fazem isso e do que isso custa.

## O programa

Crie um diretório para ele, `boxoffice` no seu diretório pessoal, e abra-o no seu editor. Num
terminal:

```sh
mkdir ~/boxoffice
cd ~/boxoffice
```

No Windows sem WSL, crie a pasta pelo Explorador de Arquivos e abra um terminal nela. Depois crie um
arquivo novo nesse diretório, cole nele o programa abaixo usando o botão de copiar do bloco, e
salve. Salve com o nome `boxoffice.py`, exatamente esse:

```python
"""boxoffice: the Vila theatre's ticket office, the application this course tests.

Run it with:  python3 boxoffice.py      and open http://127.0.0.1:8000
Everything lives in memory, so stopping it and starting it again resets it.
"""
import html
import os
import random
import secrets
import traceback
from datetime import datetime, timedelta
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

VERSION = "1.0"
PORT = int(os.environ.get("BOXOFFICE_PORT", "8000"))
SEED = os.environ.get("BOXOFFICE_SEED")
TOKENS = random.Random(SEED) if SEED else None

ACCOUNTS = {
    "member@example.org": {"name": "Bia Souza", "password": "correct-horse-1", "confirmed": True},
}
LINKS = {}      # confirmation token -> {"email", "expires"}
OUTBOX = []     # every e-mail the application has sent, oldest first
ORDERS = {}     # order number -> order
NEXT = [1001]

# Which action moves an order from which state to which.
MOVES = {
    "pay": ({"reserved"}, "paid"),
    "cancel": ({"reserved"}, "cancelled"),
    "use": ({"paid"}, "used"),
    "refund": ({"paid", "used"}, "refunded"),
}


def now():
    """The current time on this machine's clock, or BOXOFFICE_NOW if it is set."""
    fixed = os.environ.get("BOXOFFICE_NOW")
    moment = datetime.fromisoformat(fixed) if fixed else datetime.now().astimezone()
    return moment.astimezone().replace(tzinfo=None)


# The calendar starts on the day the application starts. Show times are
# São Paulo time, written without a zone.
TODAY = now().date()
SHOWS = {
    "S1": {"title": "The Seagull", "at": f"{TODAY} 20:00", "price": 6000, "seats": 120},
    "S2": {"title": "Hamlet", "at": f"{TODAY + timedelta(7)} 20:00", "price": 8000, "seats": 80},
    "S3": {"title": "The Little Prince", "at": f"{TODAY + timedelta(8)} 16:00", "price": 3000,
           "seats": 200},
}


def money(cents):
    reais = f"{cents // 100:,}".replace(",", ".")
    return f"R$ {reais},{cents % 100:02d}"


def token():
    if TOKENS:
        return "".join(TOKENS.choices("abcdefghjkmnpqrstuvwxyz23456789", k=16))
    return secrets.token_urlsafe(12)


def send(to, subject, body):
    OUTBOX.append({"to": to, "subject": subject, "body": body, "at": now()})


def send_link(email):
    t = token()
    LINKS[t] = {"email": email, "expires": now() + timedelta(hours=24)}
    send(email, "Confirm your account",
         f"Hello {ACCOUNTS[email]['name']},\n\nConfirm your account within 24 hours:\n"
         f"http://127.0.0.1:{PORT}/confirm?token={t}\n")


def discount(student, member, tickets):
    """The percentage off an order. Discounts do not add up; the largest one applies."""
    if student:
        return 50
    off = 0
    if member:
        off += 10
    if tickets >= 5:
        off += 15
    return off


def page(title, body, status=200):
    return status, f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} · Vila theatre</title>
<style>body{{font-family:sans-serif;margin:1rem}} table.shows{{width:760px}}
td,th{{text-align:left;padding:.3rem}}</style></head>
<body><h1>{title}</h1>
{body}
<p><a href="/">Shows</a> · <a href="/signup">Sign up</a> · <a href="/outbox">Outbox</a></p>
<footer>boxoffice {VERSION}</footer></body></html>
"""


def home(q):
    rows = "".join(
        f"<tr><td>{s['title']}</td><td>{s['at']}</td><td>{money(s['price'])}</td>"
        f"<td>{s['seats']}</td><td><a href=\"/book?show={k}\">Book</a></td></tr>"
        for k, s in SHOWS.items())
    return page("Shows", "<table class=\"shows\"><tr><th>Show</th><th>When</th>"
                f"<th>Price</th><th>Seats left</th><th></th></tr>{rows}</table>")


def signup_form(q, msg=""):
    return page("Sign up", f"<p class=\"msg\">{msg}</p>" + """<form method="post" action="/signup">
<p><label for="name">Name</label> <input id="name" name="name"></p>
<p><label for="email">E-mail</label> <input id="email" name="email"></p>
<p><label for="password">Password</label> <input id="password" name="password" type="password"></p>
<p><button>Create account</button></p></form>""")


def signup(f):
    name, email, password = f.get("name", ""), f.get("email", "").lower(), f.get("password", "")
    if not 1 <= len(name) <= 40:
        return signup_form({}, "Name must be 1 to 40 characters.")
    if "@" not in email or "." not in email.split("@")[-1]:
        return signup_form({}, "That is not an e-mail address.")
    if email in ACCOUNTS:
        return signup_form({}, "There is already an account with that e-mail.")
    if not 8 <= len(password) <= 64:
        return signup_form({}, "Password must be 8 to 64 characters.")
    ACCOUNTS[email] = {"name": name, "password": password, "confirmed": False}
    send_link(email)
    sent = f"Account created. We sent a link to {html.escape(email)}."
    return page("Account created", f"<p class=\"msg\">{sent}</p>")


def confirm(q):
    link = LINKS.get(q.get("token", ""))
    if not link or now() > link["expires"]:
        return page("Confirm", "<p class=\"msg\">This link is not valid.</p>", 400)
    ACCOUNTS[link["email"]]["confirmed"] = True
    return page("Confirm", "<p class=\"msg\">Your account is confirmed.</p>")


def resend(f):
    email = f.get("email", "").lower()
    if email in ACCOUNTS and not ACCOUNTS[email]["confirmed"]:
        send_link(email)
    return page("Confirm", "<p class=\"msg\">If that account exists, we sent a new link.</p>")


def outbox(q):
    mails = "".join(
        f"<article><h2>{html.escape(m['subject'])}</h2><p>To: {html.escape(m['to'])} · "
        f"{m['at']:%Y-%m-%d %H:%M}</p><pre>{html.escape(m['body'])}</pre></article>"
        for m in reversed(OUTBOX))
    return page("Outbox", mails or "<p>No e-mail has been sent.</p>")


def book_form(q, msg=""):
    show = q.get("show", "S1")
    options = "".join(
        f"<option value=\"{k}\"{' selected' if k == show else ''}>{s['title']}</option>"
        for k, s in SHOWS.items())
    return page("Book", f"<p class=\"msg\">{msg}</p>" + f"""<form method="post" action="/book">
<p><label for="email">E-mail</label> <input id="email" name="email"></p>
<p><label for="show">Show</label> <select id="show" name="show">{options}</select></p>
<p><input name="quantity" placeholder="Tickets (1 to 6)"></p>
<p><label><input type="checkbox" name="student"> Student (half price)</label></p>
<p><button>Book</button></p></form>""")


def book(f):
    email, show = f.get("email", "").lower(), f.get("show", "")
    if email not in ACCOUNTS:
        return book_form(f, "Sign up before you book.")
    if show not in SHOWS:
        return book_form(f, "There is no such show.")
    quantity = int(f.get("quantity", ""))
    if not 1 <= quantity < 6:
        return book_form(f, "You can book 1 to 6 tickets.")
    s = SHOWS[show]
    if now() > datetime.fromisoformat(s["at"]) - timedelta(hours=1):
        return book_form(f, "Booking for this show has closed.")
    if quantity > s["seats"]:
        return book_form(f, f"Only {s['seats']} seats are left.")
    off = discount("student" in f, ACCOUNTS[email]["confirmed"], quantity)
    total = s["price"] * quantity * (100 - off) // 100
    s["seats"] -= quantity
    number = NEXT[0]
    NEXT[0] += 1
    ORDERS[number] = {"email": email, "show": show, "quantity": quantity,
                      "off": off, "total": total, "state": "reserved"}
    return order({"id": str(number)}, f"Order {number} reserved.")


def order(q, msg=""):
    o = ORDERS.get(int(q.get("id", "0") or 0))
    if not o:
        return page("Order", "<p class=\"msg\">There is no such order.</p>", 404)
    buttons = "".join(f"<button name=\"action\" value=\"{a}\">{a.title()}</button> "
                      for a in MOVES)
    return page(f"Order {q['id']}", f"""<p class="msg">{msg}</p>
<p>{SHOWS[o['show']]['title']}, {o['quantity']} ticket(s), {o['off']}% off:
<strong>{money(o['total'])}</strong></p>
<p>State: <strong>{o['state']}</strong></p>
<form method="post" action="/order">
<input type="hidden" name="id" value="{q['id']}">{buttons}</form>""")


def act(f):
    o = ORDERS.get(int(f.get("id", "0") or 0))
    if not o:
        return page("Order", "<p class=\"msg\">There is no such order.</p>", 404)
    allowed, target = MOVES.get(f.get("action", ""), (set(), ""))
    if o["state"] not in allowed:
        return order(f, f"An order that is {o['state']} cannot be {f.get('action', '')}ed.")
    o["state"] = target
    if target in ("cancelled", "refunded"):
        SHOWS[o["show"]]["seats"] += o["quantity"]
    return order(f, f"Order is now {target}.")


def health(q):
    return 200, f"ok boxoffice {VERSION}\n"


GET = {"/": home, "/signup": signup_form, "/confirm": confirm, "/outbox": outbox,
       "/book": book_form, "/order": order, "/health": health}
POST = {"/signup": signup, "/resend": resend, "/book": book, "/order": act}


class Handler(BaseHTTPRequestHandler):
    def answer(self, routes, fields):
        route = routes.get(urlparse(self.path).path)
        try:
            status, body = route(fields) if route else page("Not found", "", 404)
        except Exception:
            status, body = 500, "<pre>" + html.escape(traceback.format_exc()) + "</pre>"
        data = body.encode()
        self.send_response(status)
        kind = "text/plain" if body.startswith("ok") else "text/html"
        self.send_header("Content-Type", kind + "; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        q = {k: v[0] for k, v in parse_qs(urlparse(self.path).query).items()}
        self.answer(GET, q)

    def do_POST(self):
        size = int(self.headers.get("Content-Length", 0))
        f = {k: v[0] for k, v in parse_qs(self.rfile.read(size).decode()).items()}
        self.answer(POST, f)


if __name__ == "__main__":
    print(f"boxoffice {VERSION} on http://127.0.0.1:{PORT}  (Ctrl-C stops it)")
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
```

Você não precisa lê-lo para testá-lo, e a maioria dos testadores nunca vê o código do que testa. Ele
está aqui inteiro por dois motivos. O curso dá tudo o que usa, então nada depende de um download que
pode ter mudado de lugar. E a aula 13 lê uma função dele, `discount`, para mostrar o que é um teste
de unidade.

Três configurações são lidas do ambiente, e o curso usa cada uma uma vez. `BOXOFFICE_PORT` troca a
porta 8000 por outra. `BOXOFFICE_NOW` fixa o relógio da aplicação num momento que você escolhe, o
que a aula 13 chama de relógio falso e a aula 21 usa para mostrar um defeito que só existe em
algumas máquinas. `BOXOFFICE_SEED` faz os links de confirmação saírem iguais em toda execução.

## Iniciando

No terminal, em `~/boxoffice`:

```
ana@laptop:~/boxoffice$ python3 boxoffice.py
boxoffice 1.0 on http://127.0.0.1:8000  (Ctrl-C stops it)
```

O terminal agora pertence ao servidor, e cada requisição que ele responde acrescenta uma linha
abaixo dessa. **Deixe-o aberto** e abra o endereço que ele imprimiu, `http://127.0.0.1:8000`, no
navegador. Você deve ver uma página chamada Shows com uma tabela de três: The Seagull hoje às 20:00,
Hamlet daqui a uma semana e The Little Prince no dia seguinte, às 16:00. As datas vêm do dia em que
você inicia o programa, então as suas não são as das transcrições deste curso.

Quando uma aula pede para conferir algo pelo terminal, abra um **segundo** terminal e digite nele.
A primeira coisa a perguntar é se o servidor está no ar:

```
ana@laptop:~$ curl http://127.0.0.1:8000/health
ok boxoffice 1.0
```

O `curl` manda uma requisição e imprime a resposta, e essa linha é a resposta inteira do `/health`.
A aula 8 monta um teste de fumaça sobre ela.

**Para reiniciar a aplicação, pare-a e inicie de novo.** Ctrl-C no terminal dela a para;
`python3 boxoffice.py` a inicia com três espetáculos, lugares cheios, nenhum pedido e uma conta, a
do membro `member@example.org` com a senha `correct-horse-1`. Nada sobrevive a um reinício, e toda
aula que reserva ou cadastra supõe que você partiu daí.
