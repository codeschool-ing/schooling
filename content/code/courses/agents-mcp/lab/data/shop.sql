-- Marginalia's orders, as the support agent in this course sees them.
-- Written for the course: the people, the addresses and the orders do not
-- exist, and every address is under example.com, the domain reserved for
-- examples. Amounts are integer cents. The books are embeddings-vectors'
-- catalogue (data/books.jsonl), whose ids these lines use.

CREATE TABLE customers (
  id        TEXT PRIMARY KEY,
  name      TEXT NOT NULL,
  email     TEXT NOT NULL,
  city      TEXT NOT NULL
);

CREATE TABLE prices (
  book_id   TEXT PRIMARY KEY,
  cents     INTEGER NOT NULL,
  stock     INTEGER NOT NULL
);

CREATE TABLE orders (
  id           TEXT PRIMARY KEY,
  customer_id  TEXT NOT NULL REFERENCES customers(id),
  placed_on    TEXT NOT NULL,
  status       TEXT NOT NULL CHECK (status IN ('received', 'packed', 'shipped', 'delivered', 'cancelled')),
  delivered_on TEXT,
  shipping     INTEGER NOT NULL,
  tracking     TEXT
);

CREATE TABLE order_lines (
  order_id   TEXT NOT NULL REFERENCES orders(id),
  book_id    TEXT NOT NULL,
  quantity   INTEGER NOT NULL,
  cents      INTEGER NOT NULL
);

CREATE TABLE refunds (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  order_id   TEXT NOT NULL REFERENCES orders(id),
  cents      INTEGER NOT NULL,
  reason     TEXT NOT NULL,
  approved_by TEXT NOT NULL,
  at         TEXT NOT NULL
);

INSERT INTO customers VALUES
  ('c-101', 'Bia Moreira',     'bia@example.com',    'Recife'),
  ('c-102', 'Caio Fontes',     'caio@example.com',   'Curitiba'),
  ('c-103', 'Davi Rocha',      'davi@example.com',   'Belém'),
  ('c-104', 'Elisa Prado',     'elisa@example.com',  'Porto Alegre'),
  ('c-105', 'Fábio Lins',      'fabio@example.com',  'Salvador'),
  ('c-106', 'Gabi Teles',      'gabi@example.com',   'Campinas');

INSERT INTO prices VALUES
  ('b01', 3490, 12), ('b03', 3990, 4), ('b06', 2990, 7), ('b07', 2790, 0),
  ('b11', 3190, 9),  ('b13', 2490, 15), ('b14', 2590, 3), ('b19', 3890, 6),
  ('b26', 5990, 2),  ('b31', 4990, 5), ('b33', 5490, 1), ('b36', 4590, 8),
  ('b39', 2990, 20), ('b40', 3290, 11), ('b41', 2290, 14), ('b55', 3590, 0),
  ('b59', 2990, 6);

INSERT INTO orders VALUES
  ('M-1041', 'c-101', '2026-09-02', 'delivered', '2026-09-05', 0,   'BR5512340001'),
  ('M-1042', 'c-101', '2026-09-20', 'delivered', '2026-09-24', 490, 'BR5512340002'),
  ('M-1043', 'c-102', '2026-09-28', 'shipped',   NULL,         0,   'BR5512340003'),
  ('M-1044', 'c-103', '2026-08-11', 'delivered', '2026-08-14', 0,   'BR5512340004'),
  ('M-1045', 'c-104', '2026-10-01', 'packed',    NULL,         490, NULL),
  ('M-1046', 'c-105', '2026-10-02', 'received',  NULL,         0,   NULL),
  ('M-1047', 'c-106', '2026-09-15', 'delivered', '2026-09-18', 0,   'BR5512340007'),
  ('M-1048', 'c-102', '2026-09-30', 'cancelled', NULL,         490, NULL);

INSERT INTO order_lines VALUES
  ('M-1041', 'b01', 1, 3490), ('M-1041', 'b06', 1, 2990),
  ('M-1042', 'b39', 1, 2990),
  ('M-1043', 'b13', 1, 2490), ('M-1043', 'b14', 1, 2590), ('M-1043', 'b26', 1, 5990),
  ('M-1044', 'b36', 1, 4590),
  ('M-1045', 'b41', 1, 2290),
  ('M-1046', 'b31', 1, 4990), ('M-1046', 'b33', 1, 5490),
  ('M-1047', 'b19', 2, 3890),
  ('M-1048', 'b40', 1, 3290);
