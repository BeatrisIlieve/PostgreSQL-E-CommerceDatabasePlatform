CREATE TABLE
    jewelry_types(
        id SERIAL PRIMARY KEY,
        jewelry_type VARCHAR(30) NOT NULL
);

INSERT INTO
    jewelry_types(jewelry_type)
VALUES
    ('Ring'),
    ('Earring'),
    ('Necklace'),
    ('Bracelet');