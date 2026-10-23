INSERT INTO author (name) VALUES
    ('Machado de Assis'),
    ('H. G. Wells'),
    ('Mary Shelley'),
    ('Jane Austen')
ON CONFLICT (name) DO NOTHING;

INSERT INTO book (isbn, title, author_id, price_cents)
SELECT b.isbn, b.title, a.id, b.price_cents
FROM (VALUES
    ('9786500000016', 'Dom Casmurro', 'Machado de Assis', 3990),
    ('9786500000023', 'The Time Machine', 'H. G. Wells', 2950),
    ('9786500000030', 'Frankenstein', 'Mary Shelley', 3500),
    ('9786500000047', 'Persuasion', 'Jane Austen', 3100),
    ('9786500000054', 'Quincas Borba', 'Machado de Assis', 3690),
    ('9786500000061', 'The War of the Worlds', 'H. G. Wells', 3200)
) AS b (isbn, title, author, price_cents)
JOIN author a ON a.name = b.author
ORDER BY b.isbn
ON CONFLICT (isbn) DO NOTHING;
