---
title: O seu próprio laboratório
version: 2
---

Tudo o que este curso roda, roda no seu computador: Python, um modelo de linguagem servido pelo **Ollama** e a pequena loja para a qual os agentes trabalham. Nada é alugado e nada pede conta. Esta seção monta essa máquina, e toda aula depois dela supõe que ela existe.

## Três jeitos de ter a máquina

| caminho | o que custa ao seu computador | |
|---|---|---|
| **instalado**, no computador à sua frente | uns 6 GB de disco e 4 GB de memória livre enquanto um modelo responde | **recomendado** |
| numa máquina virtual, Ubuntu Server 24.04 LTS | o mesmo, mais o que é do convidado: dê a ele 8 GB de memória, 4 processadores e 30 GB de disco | quando você prefere manter o seu sistema limpo |
| online, uma máquina Linux alugada com root | nada no seu computador; uma máquina com 8 GB de memória, cobrada por hora | quando o seu computador não roda modelo nenhum |

**Instalado é a recomendação porque um modelo é o único programa aqui que quer o computador inteiro.** O Ollama roda nativo no Linux, no macOS e no Windows, e nos dois que têm usa o chip gráfico. Uma máquina virtual não vê nada disso: o modelo dela roda nos processadores que ela recebeu, e mais devagar. Toda transcrição deste curso foi gravada no Ubuntu 24.04, então no Linux o seu terminal vai se parecer mais com o das aulas; no macOS e no Windows os comandos são os mesmos depois que o Python e o Ollama estão instalados.

Para uma máquina virtual, use o hipervisor que o seu sistema já tem: **Hyper-V** no Windows, **UTM** no macOS e **KVM com virt-manager** no Linux. Instale nele o Ubuntu Server 24.04 LTS e siga os passos de Linux abaixo. Para o caminho online, qualquer fornecedor que venda uma máquina Linux pequena por hora serve; um plano gratuito que exista hoje pode não existir quando você chegar à aula 18, então não conte com ele.

## O Ollama e os modelos

No Linux, o script do próprio Ollama o instala e o deixa rodando como serviço; no macOS e no Windows, o instalador de `ollama.com/download` faz o mesmo.

```sh
curl -fsSL https://ollama.com/install.sh | sh
```

Uma configuração importa antes de qualquer coisa rodar. O Ollama dá a cada conversa um **contexto de 4096 tokens** se ninguém disser outra coisa, e um agente com algumas ferramentas e alguns passos já feitos passa disso depressa. O que não cabe é cortado do começo da conversa, sem erro nenhum. Este curso usa 8192:

```sh
sudo mkdir -p /etc/systemd/system/ollama.service.d
printf '[Service]\nEnvironment="OLLAMA_CONTEXT_LENGTH=8192"\n' | sudo tee /etc/systemd/system/ollama.service.d/context.conf
sudo systemctl daemon-reload && sudo systemctl restart ollama
```

No macOS e no Windows, defina `OLLAMA_CONTEXT_LENGTH` como `8192` numa variável de ambiente da sua conta e reinicie o Ollama. Depois baixe os modelos:

```sh
ollama pull llama3.2:3b     # the model every lesson uses
ollama pull all-minilm      # the embedding model behind the help-centre search
ollama pull llama3.2:1b     # a smaller model: lesson 18 compares it, and a weaker computer can use it throughout
ollama pull qwen2.5:3b      # lesson 9 only, which says why
```

**O `llama3.2:3b` é o modelo do curso**, o mesmo que todo curso de IA desta plataforma recomenda; se você já o instalou para outro curso, já o tem. Ele é pequeno: três bilhões de parâmetros, onde os modelos por trás das APIs pagas têm centenas de vezes mais. Ele vai chamar a ferramenta errada de vez em quando, inventar um detalhe ou parar cedo. As aulas mostram essas execuções como aconteceram, porque um laço que só encontra modelo perfeito não ensina nada sobre o laço.

## O Python e as bibliotecas

As bibliotecas pedem Python 3.12 ou mais novo. O Ubuntu 24.04 vem com o 3.12; no Ubuntu, o módulo de ambientes virtuais é um pacote à parte.

```sh
sudo apt install python3-venv
mkdir ~/agents && cd ~/agents
python3 -m venv .venv
. .venv/bin/activate
pip install anthropic==1.11.0 openai==3.24.0 mcp==2.3.0 \
  openai-agents==0.23.1 claude-agent-sdk==0.2.163 google-adk==2.11.0 litellm==1.83.0 \
  jsonschema==4.26.0 pytest==9.1.1 uvicorn==0.54.0
```

Essas são as versões com que toda transcrição foi feita. Uma mais nova quase sempre funciona, e quando não funciona o erro diz qual biblioteca.

**As bibliotecas dos fornecedores conversam com o Ollama porque o Ollama fala a língua delas.** Ele responde à Messages API da Anthropic em `/v1/messages` e ao Chat Completions da OpenAI em `/v1/chat/completions`, chamadas de ferramenta incluídas, então os pacotes `anthropic` e `openai` só precisam saber onde ele está. Salve isto como `~/agents/ollama.env`:

```sh
# ollama.env: point the providers' SDKs at the Ollama on this machine.
export ANTHROPIC_BASE_URL=http://127.0.0.1:11434
export ANTHROPIC_API_KEY=ollama
export OPENAI_BASE_URL=http://127.0.0.1:11434/v1
export OPENAI_API_KEY=ollama
export OLLAMA_API_BASE=http://127.0.0.1:11434
```

e acrescente-o ao script de ativação do ambiente, para que `. .venv/bin/activate` defina as cinco variáveis daqui em diante:

```sh
cat ollama.env >> .venv/bin/activate
. .venv/bin/activate
```

As chaves são marcadores: o Ollama não confere nenhuma, e as bibliotecas se recusam a começar sem uma.

**Se você preferir a API de um fornecedor**, com uma chave sua e a conta que vem com ela, os programas são os mesmos. Deixe as URLs base de fora, ponha as suas chaves de verdade no lugar e troque `llama3.2:3b` em cada programa por um modelo que esse fornecedor venda. As respostas vão sair mais bem escritas que as das aulas, e os laços em volta delas não mudam.

## A loja

Os agentes deste curso trabalham para a **Marginalia**, uma livraria online que não existe: a mesma que o `embeddings-vectors` buscou por significado e da qual o `rag` respondeu. Os pedidos dela, os livros à venda e catorze artigos da central de ajuda cabem num programa. Salve-o como `~/agents/make_shop.py`:

```python
"""make_shop.py: writes Marginalia's data into ./data, from nothing.

Marginalia is an online bookshop that does not exist. Everything here was
written for the course: the people, the orders, the books on sale and the
help centre. Amounts are whole cents. Run it again to start over.
"""
import json
import sqlite3
from pathlib import Path

DATA = Path(__file__).resolve().parent / "data"

SCHEMA = """
CREATE TABLE customers (id TEXT PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL, city TEXT NOT NULL);
CREATE TABLE prices (book_id TEXT PRIMARY KEY, cents INTEGER NOT NULL, stock INTEGER NOT NULL);
CREATE TABLE orders (
  id TEXT PRIMARY KEY, customer_id TEXT NOT NULL REFERENCES customers(id), placed_on TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('received', 'packed', 'shipped', 'delivered', 'cancelled')),
  delivered_on TEXT, shipping INTEGER NOT NULL, tracking TEXT);
CREATE TABLE order_lines (order_id TEXT NOT NULL REFERENCES orders(id), book_id TEXT NOT NULL,
  quantity INTEGER NOT NULL, cents INTEGER NOT NULL);
CREATE TABLE refunds (id INTEGER PRIMARY KEY AUTOINCREMENT, order_id TEXT NOT NULL REFERENCES orders(id),
  cents INTEGER NOT NULL, reason TEXT NOT NULL, approved_by TEXT NOT NULL, at TEXT NOT NULL);
"""

CUSTOMERS = [
    ("c-101", "Bia Moreira", "bia@example.com", "Recife"),
    ("c-102", "Caio Fontes", "caio@example.com", "Curitiba"),
    ("c-103", "Davi Rocha", "davi@example.com", "Belém"),
    ("c-104", "Elisa Prado", "elisa@example.com", "Porto Alegre"),
    ("c-105", "Fábio Lins", "fabio@example.com", "Salvador"),
    ("c-106", "Gabi Teles", "gabi@example.com", "Campinas"),
]
# id, customer, placed on, status, delivered on, shipping in cents, tracking code
ORDERS = [
    ("M-1041", "c-101", "2026-09-02", "delivered", "2026-09-05", 0, "BR5512340001"),
    ("M-1042", "c-101", "2026-09-20", "delivered", "2026-09-24", 490, "BR5512340002"),
    ("M-1043", "c-102", "2026-09-28", "shipped", None, 0, "BR5512340003"),
    ("M-1044", "c-103", "2026-08-11", "delivered", "2026-08-14", 0, "BR5512340004"),
    ("M-1045", "c-104", "2026-10-01", "packed", None, 490, None),
    ("M-1046", "c-105", "2026-10-02", "received", None, 0, None),
    ("M-1047", "c-106", "2026-09-15", "delivered", "2026-09-18", 0, "BR5512340007"),
    ("M-1048", "c-102", "2026-09-30", "cancelled", None, 490, None),
]
LINES = [
    ("M-1041", "b01", 1, 3490), ("M-1041", "b06", 1, 2990), ("M-1042", "b39", 1, 2990),
    ("M-1043", "b13", 1, 2490), ("M-1043", "b14", 1, 2590), ("M-1043", "b26", 1, 5990),
    ("M-1044", "b36", 1, 4590), ("M-1045", "b41", 1, 2290), ("M-1046", "b31", 1, 4990),
    ("M-1046", "b33", 1, 5490), ("M-1047", "b19", 2, 3890), ("M-1048", "b40", 1, 3290),
]
# id, title, author, year, genre, price in cents, copies in stock
BOOKS = [
    ("b01", "Pride and Prejudice", "Jane Austen", 1813, "romance", 3490, 12),
    ("b03", "Jane Eyre", "Charlotte Brontë", 1847, "romance", 3990, 4),
    ("b06", "Persuasion", "Jane Austen", 1817, "romance", 2990, 7),
    ("b07", "The Hound of the Baskervilles", "Arthur Conan Doyle", 1902, "mystery", 2790, 0),
    ("b11", "The Mysterious Affair at Styles", "Agatha Christie", 1920, "mystery", 3190, 9),
    ("b13", "The Time Machine", "H. G. Wells", 1895, "science fiction", 2490, 15),
    ("b14", "The War of the Worlds", "H. G. Wells", 1898, "science fiction", 2590, 3),
    ("b19", "Dracula", "Bram Stoker", 1897, "horror", 3890, 6),
    ("b26", "The Count of Monte Cristo", "Alexandre Dumas", 1844, "adventure", 5990, 2),
    ("b31", "Moby-Dick", "Herman Melville", 1851, "adventure", 4990, 5),
    ("b33", "Middlemarch", "George Eliot", 1871, "literary", 5490, 1),
    ("b36", "Crime and Punishment", "Fyodor Dostoevsky", 1866, "literary", 4590, 8),
    ("b39", "Dom Casmurro", "Machado de Assis", 1899, "literary", 2990, 20),
    ("b40", "The Posthumous Memoirs of Brás Cubas", "Machado de Assis", 1881, "literary", 3290, 11),
    ("b41", "Alice's Adventures in Wonderland", "Lewis Carroll", 1865, "children", 2290, 14),
    ("b55", "The Adventures of Sherlock Holmes", "Arthur Conan Doyle", 1892, "mystery", 3590, 0),
    ("b59", "Sense and Sensibility", "Jane Austen", 1811, "romance", 2990, 6),
]
# id, title, body
HELP = [
    ("h01", "Changing an order after you have placed it",
     "You can change the delivery address or remove an item while the order still says Received. Once it says Packed, the parcel has left the shelf and the order can no longer be edited. Cancel it instead and place a new one."),
    ("h02", "Cancelling an order",
     "Open the order in your account and choose Cancel order. If the order has already shipped, the button is gone and you will need to send the parcel back when it arrives. A cancelled order is refunded to the card it was paid with."),
    ("h05", "Orders for schools and libraries",
     "Institutions buying twenty or more copies of one title receive 15% off the cover price and can pay by invoice within 30 days. Send the list of titles and quantities from an institutional email address to schools@marginalia.example."),
    ("h07", "Delivery times and costs",
     "Standard delivery takes three to five working days and is free on orders over 40. Below that it costs 4.90. Express delivery arrives the next working day if you order before 2 pm and costs 9.90."),
    ("h08", "Tracking a parcel",
     "When the parcel leaves our warehouse we email you a tracking link from the carrier. The link may show nothing for the first twelve hours, until the carrier scans the parcel at its depot. After that it updates at each step of the journey."),
    ("h09", "A parcel marked as delivered that never arrived",
     "Check with neighbours and around the building first, because carriers often leave parcels in a safe place. If it has not turned up after 48 hours, tell us and we will open a claim with the carrier and send a replacement or a refund, whichever you prefer."),
    ("h12", "Damaged books on arrival",
     "If a book arrives with a torn cover, bent corners or water damage, photograph it next to the packaging and send the pictures within 14 days. We replace damaged books at no cost and you do not need to send the damaged copy back."),
    ("h14", "How to return a book",
     "You have 30 days from delivery to return a printed book in the condition you received it. Start the return from the order in your account, print the prepaid label and drop the parcel at any post office. Returns are free."),
    ("h15", "When your refund arrives",
     "We refund within three working days of the return reaching our warehouse. The money goes back to the card or account you paid with, and your bank may take another five to ten days to show it. Gift cards are refunded as store credit."),
    ("h17", "Items that cannot be returned",
     "Personalised and signed copies, opened jigsaw puzzles and anything bought in the clearance section cannot be returned unless they arrive damaged. E-books follow their own rules, described in the e-books section."),
    ("h20", "Payment methods we accept",
     "We accept Visa, Mastercard and American Express, PayPal, Pix and Marginalia gift cards. A card payment can be split into up to three instalments with no interest on orders over 120. We do not accept cash on delivery."),
    ("h22", "Charged twice for one order",
     "When a payment fails and you try again, the bank sometimes holds both amounts for a few days. Only one is collected and the other disappears without action from you within seven days. If both are still there after that, send us the order number and a bank statement."),
    ("h24", "Using a gift card",
     "Enter the sixteen-digit code at checkout. A gift card can pay for part of an order and the rest can go on a card. Gift cards are valid for two years from purchase and cannot be exchanged for cash."),
    ("h33", "Refunds for e-books",
     "An e-book can be refunded within 14 days of purchase if you have not downloaded it or opened it in the app. Once it has been downloaded, the sale is final, as the law allows for digital content delivered with your consent."),
]

DATA.mkdir(exist_ok=True)
(DATA / "shop.db").unlink(missing_ok=True)
db = sqlite3.connect(DATA / "shop.db")
db.executescript(SCHEMA)
db.executemany("INSERT INTO customers VALUES (?, ?, ?, ?)", CUSTOMERS)
db.executemany("INSERT INTO orders VALUES (?, ?, ?, ?, ?, ?, ?)", ORDERS)
db.executemany("INSERT INTO order_lines VALUES (?, ?, ?, ?)", LINES)
db.executemany("INSERT INTO prices VALUES (?, ?, ?)", [(b[0], b[5], b[6]) for b in BOOKS])
db.commit()
with open(DATA / "books.jsonl", "w") as f:
    for id, title, author, year, genre, *_ in BOOKS:
        f.write(json.dumps({"id": id, "title": title, "author": author, "year": year, "genre": genre},
                           ensure_ascii=False) + "\n")
with open(DATA / "help.jsonl", "w") as f:
    for id, title, body in HELP:
        f.write(json.dumps({"id": id, "title": title, "body": body}) + "\n")
(DATA / "help.vectors.json").unlink(missing_ok=True)
print(f"{len(ORDERS)} orders, {len(BOOKS)} books and {len(HELP)} help articles in {DATA}")
```

E as funções que os agentes vão receber para chamar, como `~/agents/shop.py`. Elas não sabem nada de modelos: cada aula as embrulha no que um modelo precisa, um esquema, um decorador ou um servidor MCP, e por baixo elas continuam as mesmas. A busca é a do `embeddings-vectors`, por significado, com o `all-minilm` transformando texto em vetores.

```python
"""shop.py: Marginalia's data as plain functions, which every lesson wraps as tools.

Nothing here knows about models, tools or MCP. The help-centre search asks
Ollama for embeddings from all-minilm, the model embeddings-vectors uses.
"""
import json
import math
import sqlite3
import urllib.request
from datetime import date
from pathlib import Path

DATA = Path(__file__).resolve().parent / "data"
TODAY = date(2026, 10, 6)   # the shop's calendar stops here, so every date in the lessons holds


def _db(readonly=True):
    mode = "ro" if readonly else "rw"
    db = sqlite3.connect(f"file:{DATA / 'shop.db'}?mode={mode}", uri=True)
    db.row_factory = sqlite3.Row
    return db


def get_order(order_id):
    """The order, its lines and its refunds, as a dict. Amounts are in cents."""
    with _db() as db:
        o = db.execute("SELECT * FROM orders WHERE id = ?", (order_id,)).fetchone()
        if o is None:
            raise LookupError(f"no order {order_id}")
        lines = db.execute("SELECT book_id, quantity, cents FROM order_lines WHERE order_id = ?",
                           (order_id,)).fetchall()
        refunded = db.execute("SELECT coalesce(sum(cents), 0) FROM refunds WHERE order_id = ?",
                              (order_id,)).fetchone()[0]
    out = dict(o)
    out["lines"] = [dict(r) for r in lines]
    out["total"] = sum(r["quantity"] * r["cents"] for r in lines) + o["shipping"]
    out["refunded"] = refunded
    return out


def get_customer(customer_id):
    with _db() as db:
        c = db.execute("SELECT * FROM customers WHERE id = ?", (customer_id,)).fetchone()
    if c is None:
        raise LookupError(f"no customer {customer_id}")
    return dict(c)


def get_book(book_id):
    """A book from the catalogue, with its price and stock."""
    for line in open(DATA / "books.jsonl"):
        b = json.loads(line)
        if b["id"] == book_id:
            with _db() as db:
                p = db.execute("SELECT cents, stock FROM prices WHERE book_id = ?", (book_id,)).fetchone()
            b.update(dict(p))
            return b
    raise LookupError(f"no book {book_id}")


def _embed(texts):
    req = urllib.request.Request("http://127.0.0.1:11434/api/embed",
                                 json.dumps({"model": "all-minilm", "input": texts}).encode(),
                                 {"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.load(r)["embeddings"]   # each one already has length 1


def search_help(query, k=3):
    """The k help-centre articles closest in meaning to QUERY, by cosine similarity."""
    arts = [json.loads(line) for line in open(DATA / "help.jsonl")]
    cache = DATA / "help.vectors.json"
    if not cache.exists():
        cache.write_text(json.dumps(_embed([a["title"] + ". " + a["body"] for a in arts])))
    vecs = json.loads(cache.read_text())
    q = _embed([query])[0]
    scores = [math.sumprod(v, q) for v in vecs]
    best = sorted(range(len(arts)), key=lambda i: -scores[i])[:k]
    return [{"id": arts[i]["id"], "title": arts[i]["title"], "body": arts[i]["body"],
             "score": round(scores[i], 3)} for i in best]


def refund(order_id, cents, reason, approved_by):
    """Record a refund. It refuses more than is left to refund on the order."""
    order = get_order(order_id)
    left = order["total"] - order["refunded"]
    if cents <= 0 or cents > left:
        raise ValueError(f"cannot refund {cents} cents on {order_id}: {left} left to refund")
    with _db(readonly=False) as db:
        db.execute("INSERT INTO refunds (order_id, cents, reason, approved_by, at) VALUES (?, ?, ?, ?, ?)",
                   (order_id, cents, reason, approved_by, TODAY.isoformat()))
    return {"order_id": order_id, "refunded": cents, "left": left - cents}
```

## Conferindo

Rode uma vez o programa da loja e depois confira cada peça. A linha do `ollama run` faz ao modelo uma pergunta sem nada em volta; o `ollama ps` logo depois mostra quanto o modelo custa enquanto está carregado.

```
ana@lab:~/agents$ python --version
Python 3.12.3
ana@lab:~/agents$ ollama --version
ollama version is 0.40.0
ana@lab:~/agents$ ollama list
NAME                 ID              SIZE      MODIFIED       
all-minilm:latest    1b226e2802db    45 MB     15 minutes ago    
qwen2.5:3b           357c53fb659c    1.9 GB    15 minutes ago    
llama3.2:1b          baf6a787fdff    1.3 GB    15 minutes ago    
llama3.2:3b          a80c4f17acd5    2.0 GB    15 minutes ago    
ana@lab:~/agents$ python make_shop.py
8 orders, 17 books and 14 help articles in /home/ana/agents/data
ana@lab:~/agents$ ls data
books.jsonl
help.jsonl
shop.db
ana@lab:~/agents$ python -c "import shop; print(shop.get_order(\"M-1042\"))"
{'id': 'M-1042', 'customer_id': 'c-101', 'placed_on': '2026-09-20', 'status': 'delivered', 'delivered_on': '2026-09-24', 'shipping': 490, 'tracking': 'BR5512340002', 'lines': [{'book_id': 'b39', 'quantity': 1, 'cents': 2990}], 'total': 3480, 'refunded': 0}
ana@lab:~/agents$ ollama run llama3.2:3b "Say hello in five words."
Hello, how are you doing?
ana@lab:~/agents$ ollama ps
NAME                 ID              SIZE      PROCESSOR          CONTEXT    RUNNER      UNTIL              
llama3.2:3b          a80c4f17acd5    3.5 GB    41%/59% CPU/GPU    8192       llamacpp    4 minutes from now    
all-minilm:latest    1b226e2802db    48 MB     56%/44% CPU/GPU    256        llamacpp    4 minutes from now    
ana@lab:~/agents$ du -sh .venv
572M	.venv
```

Se o seu computador for diferente, leia os tamanhos na sua tela e não nesta, mas estes são os números para planejar: o `llama3.2:3b` é um download de 2,0 GB e ocupa 3,5 GB de memória enquanto responde, e as bibliotecas ocupam 572 MB. O modelo fica na memória por cinco minutos depois da última resposta e então sai sozinho. Num computador com menos de 8 GB no total, use o `llama3.2:1b` onde uma aula disser `llama3.2:3b`: ele tem 1,3 GB, e os erros dele são mais frequentes e do mesmo tipo.

**Toda vez que voltar ao curso**, abra um terminal e digite `cd ~/agents && . .venv/bin/activate`. O Ollama continua rodando como serviço; o ambiente, não.
