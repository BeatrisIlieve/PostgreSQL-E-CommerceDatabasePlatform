CREATE TABLE rings(
    id SERIAL PRIMARY KEY NOT NULL,
    jewelry_type_id INTEGER NOT NULL,
    image_url VARCHAR(200) NOT NULL,
    ring_name VARCHAR(100) NOT NULL,
    price DECIMAL(7, 2) NOT NULL,
    metal_color VARCHAR(12) NOT NULL,
    diamond_carat_weight VARCHAR(10) NOT NULL,
    diamond_clarity VARCHAR(10) NOT NULL,
    diamond_color VARCHAR(5) NOT NULL,
    description TEXT NOT NULL,

    CONSTRAINT fk_rings_jewelry_types
                  FOREIGN KEY (jewelry_type_id)
                  REFERENCES jewelry_types(id)
                  ON UPDATE CASCADE
                  ON DELETE CASCADE
);

INSERT INTO
    rings(
          jewelry_type_id,
          image_url,
          ring_name,
          price,
          metal_color,
          diamond_carat_weight,
          diamond_clarity,
          diamond_color,
          description
    )
VALUES (
        1,
        'https://res.cloudinary.com/deztgvefu/image/upload/v1697350935/Rings/BUDDING_ROUND_BRILLIANT_DIAMOND_HALO_ENGAGEMENT_RING_s1ydsv.webp',
        'BUDDING ROUND BRILLIANT DIAMOND HALO ENGAGEMENT RING',
        19879.00,
        'ROSE GOLD',
        '1.75ctw',
        'SI1-SI2',
        'G-H',
        'This stunning engagement ring features a round brilliant diamond with surrounded by a sparkling halo of marquise diamonds. Crafted to the highest standards and ethically sourced, it is the perfect ring to dazzle for any gift, proposal, or occasion. Its timeless design and exquisite craftsmanship will ensure an everlasting memory.'
       );