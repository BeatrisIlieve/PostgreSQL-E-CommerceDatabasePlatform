CREATE TABLE earrings(
    id SERIAL PRIMARY KEY NOT NULL,
    jewelry_type_id INTEGER NOT NULL,
    image_url VARCHAR(200) NOT NULL,
    earring_name VARCHAR(100) NOT NULL,
    price DECIMAL(7, 2) NOT NULL,
    metal_color VARCHAR(12) NOT NULL,
    diamond_carat_weight VARCHAR(10) NOT NULL,
    diamond_clarity VARCHAR(10) NOT NULL,
    diamond_color VARCHAR(5) NOT NULL,
    description TEXT NOT NULL,

    CONSTRAINT fk_earrings_jewelry_types
                  FOREIGN KEY (jewelry_type_id)
                  REFERENCES jewelry_types(id)
                  ON UPDATE CASCADE
                  ON DELETE CASCADE

);

INSERT INTO
    earrings(
          jewelry_type_id,
          image_url,
          earring_name,
          price,
          metal_color,
          diamond_carat_weight,
          diamond_clarity,
          diamond_color,
          description
    )

VALUES (
        2,
        'https://res.cloudinary.com/deztgvefu/image/upload/v1697351117/Rings/ALMOST_A_HALO_ROUND_DIAMOND_STUD_EARRING_giloj0.webp',
        'ALMOST A HALO ROUND DIAMOND STUD EARRING',
        3749.00,
        'ROSE GOLD',
        '0.60ctw',
        'SI1-SI2',
        'G-H',
        'This Almost A Halo Round Diamond Stud Earring is the perfect choice for any occasion. It features an 0.60cttw round diamonds set in a half halo design, creating a unique and timeless look. Crafted from the finest materials, this earring is sure to be an eye-catching addition to any collection.'
       );