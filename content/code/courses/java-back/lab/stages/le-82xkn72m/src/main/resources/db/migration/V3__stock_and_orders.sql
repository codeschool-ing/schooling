ALTER TABLE book ADD COLUMN stock integer NOT NULL DEFAULT 0 CHECK (stock >= 0);

UPDATE book SET stock = 5;
UPDATE book SET stock = 1 WHERE isbn = '9786500000030';

CREATE TABLE customer_order (
    id        bigserial   PRIMARY KEY,
    customer  text        NOT NULL,
    placed_at timestamptz NOT NULL
);

CREATE TABLE order_line (
    id          bigserial PRIMARY KEY,
    order_id    bigint    NOT NULL REFERENCES customer_order (id),
    book_id     bigint    NOT NULL REFERENCES book (id),
    quantity    integer   NOT NULL CHECK (quantity > 0),
    price_cents integer   NOT NULL CHECK (price_cents >= 0)
);

CREATE INDEX order_line_order_id ON order_line (order_id);
