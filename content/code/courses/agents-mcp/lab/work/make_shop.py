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
