-- The operational database of Ponto Final: what the tills and the website
-- write to, one transaction at a time. Third normal form, keys enforced, and
-- the CURRENT state of everything: a customer's city is where they live now,
-- a book's price is what it costs today.

CREATE TABLE shops (
    shop_id    integer PRIMARY KEY,
    name       text NOT NULL,
    city       text,
    state      char(2),
    channel    text NOT NULL CHECK (channel IN ('store', 'online')),
    opened_on  date NOT NULL
);

CREATE TABLE categories (
    category_id integer PRIMARY KEY,
    name        text NOT NULL,
    parent_id   integer REFERENCES categories
);

CREATE TABLE publishers (
    publisher_id integer PRIMARY KEY,
    name         text NOT NULL
);

CREATE TABLE authors (
    author_id integer PRIMARY KEY,
    name      text NOT NULL,
    country   char(2) NOT NULL
);

CREATE TABLE books (
    book_id          integer PRIMARY KEY,
    isbn             char(13) NOT NULL UNIQUE,
    title            text NOT NULL,
    category_id      integer NOT NULL REFERENCES categories,
    publisher_id     integer NOT NULL REFERENCES publishers,
    format           text NOT NULL CHECK (format IN ('paperback', 'hardcover', 'ebook')),
    list_price_cents integer NOT NULL CHECK (list_price_cents > 0),
    published_on     date NOT NULL
);

CREATE TABLE book_authors (
    book_id   integer NOT NULL REFERENCES books,
    author_id integer NOT NULL REFERENCES authors,
    position  smallint NOT NULL,
    PRIMARY KEY (book_id, author_id)
);

CREATE TABLE customers (
    customer_id integer PRIMARY KEY,
    email       text NOT NULL UNIQUE,
    name        text NOT NULL,
    city        text NOT NULL,
    state       char(2) NOT NULL,
    tier        text NOT NULL CHECK (tier IN ('reader', 'regular', 'patron')),
    created_at  timestamptz NOT NULL,
    updated_at  timestamptz NOT NULL
);

-- Written by the application beside every UPDATE of a customer, because the
-- row itself only remembers the latest value.
CREATE TABLE customer_changes (
    change_id   bigint PRIMARY KEY,
    customer_id integer NOT NULL REFERENCES customers,
    changed_at  timestamptz NOT NULL,
    field       text NOT NULL,
    old_value   text NOT NULL,
    new_value   text NOT NULL
);

CREATE TABLE promotions (
    promotion_id integer PRIMARY KEY,
    code         text NOT NULL UNIQUE,
    name         text NOT NULL,
    percent_off  integer NOT NULL,
    starts_on    date NOT NULL,
    ends_on      date NOT NULL,
    category     text
);

CREATE TABLE orders (
    order_id       bigint PRIMARY KEY,
    shop_id        integer NOT NULL REFERENCES shops,
    customer_id    integer REFERENCES customers,
    ordered_at     timestamptz NOT NULL,
    status         text NOT NULL,
    shipping_cents integer NOT NULL DEFAULT 0,
    paid_at        timestamptz,
    shipped_at     timestamptz,
    delivered_at   timestamptz
);

CREATE TABLE order_lines (
    order_id         bigint NOT NULL REFERENCES orders,
    line_no          smallint NOT NULL,
    book_id          integer NOT NULL REFERENCES books,
    quantity         smallint NOT NULL CHECK (quantity > 0),
    unit_price_cents integer NOT NULL,
    discount_cents   integer NOT NULL DEFAULT 0,
    promotion_id     integer REFERENCES promotions,
    PRIMARY KEY (order_id, line_no)
);

CREATE TABLE payments (
    payment_id   bigint PRIMARY KEY,
    order_id     bigint NOT NULL REFERENCES orders,
    method       text NOT NULL,
    installments smallint NOT NULL,
    amount_cents integer NOT NULL
);

-- The count somebody makes at the end of every month, shelf by shelf.
CREATE TABLE stock_counts (
    count_date date NOT NULL,
    shop_id    integer NOT NULL REFERENCES shops,
    book_id    integer NOT NULL REFERENCES books,
    on_hand    integer NOT NULL,
    PRIMARY KEY (count_date, shop_id, book_id)
);

CREATE TABLE events (
    event_id  integer PRIMARY KEY,
    shop_id   integer NOT NULL REFERENCES shops,
    author_id integer NOT NULL REFERENCES authors,
    held_on   date NOT NULL
);

CREATE TABLE event_attendance (
    event_id    integer NOT NULL REFERENCES events,
    customer_id integer NOT NULL REFERENCES customers,
    PRIMARY KEY (event_id, customer_id)
);

CREATE INDEX ON orders (customer_id);
CREATE INDEX ON orders (ordered_at);
CREATE INDEX ON order_lines (book_id);
CREATE INDEX ON payments (order_id);
CREATE INDEX ON customer_changes (customer_id);
