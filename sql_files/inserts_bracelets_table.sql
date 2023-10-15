CREATE TABLE bracelets(
    id SERIAL PRIMARY KEY NOT NULL,
    jewelry_type_id INTEGER NOT NULL,
    image_url VARCHAR(200) NOT NULL,
    bracelet_name VARCHAR(100) NOT NULL,
    price DECIMAL(7, 2) NOT NULL,
    metal_color VARCHAR(12) NOT NULL,
    diamond_carat_weight VARCHAR(10) NOT NULL,
    diamond_clarity VARCHAR(10) NOT NULL,
    diamond_color VARCHAR(5) NOT NULL,
    description TEXT NOT NULL,

    CONSTRAINT fk_bracelets_jewelry_types
                  FOREIGN KEY (jewelry_type_id)
                  REFERENCES jewelry_types(id)
                  ON UPDATE CASCADE
                  ON DELETE CASCADE
);

INSERT INTO
    bracelets(
          jewelry_type_id,
          image_url,
          bracelet_name,
          price,
          metal_color,
          diamond_carat_weight,
          diamond_clarity,
          diamond_color,
          description
    )

VALUES (
        4,
        'https://res.cloudinary.com/deztgvefu/image/upload/v1697351731/Rings/CLASSIC_DIAMOND_TENNIS_BRACELET_f1etis.webp',
        'CLASSIC DIAMOND TENNIS BRACELET',
        7249.00,
        'ROSE GOLD',
        '1.11ctw',
        'SI1-SI2',
        'G-H',
        'This classic diamond tennis bracelet is crafted from sterling silver and made with 18 round-cut diamonds. Each diamond is hand-selected for sparkle and set in a four-prong setting for maximum brilliance. This timeless piece is the perfect piece for any special occasion.Wear it to work, special events, or everyday activities to make a statement.'
       );