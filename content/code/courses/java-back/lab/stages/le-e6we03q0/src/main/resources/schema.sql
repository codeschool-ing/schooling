CREATE TABLE IF NOT EXISTS book (
    id          bigserial PRIMARY KEY,
    isbn        char(13)  NOT NULL UNIQUE,
    title       text      NOT NULL,
    author      text      NOT NULL,
    price_cents integer   NOT NULL CHECK (price_cents >= 0)
);
