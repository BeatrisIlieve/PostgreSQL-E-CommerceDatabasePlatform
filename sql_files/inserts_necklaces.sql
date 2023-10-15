CREATE TABLE necklaces(
    id SERIAL PRIMARY KEY NOT NULL,
    jewelry_type_id INTEGER NOT NULL,
    image_url VARCHAR(200) NOT NULL,
    necklace_name VARCHAR(100) NOT NULL,
    price DECIMAL(7, 2) NOT NULL,
    metal_color VARCHAR(12) NOT NULL,
    diamond_carat_weight VARCHAR(10) NOT NULL,
    diamond_clarity VARCHAR(10) NOT NULL,
    diamond_color VARCHAR(5) NOT NULL,
    description TEXT NOT NULL,

    CONSTRAINT fk_necklaces_jewelry_types
                  FOREIGN KEY (jewelry_type_id)
                  REFERENCES jewelry_types(id)
                  ON UPDATE CASCADE
                  ON DELETE CASCADE
);

INSERT INTO
    necklaces(
          jewelry_type_id,
          image_url,
          necklace_name,
          price,
          metal_color,
          diamond_carat_weight,
          diamond_clarity,
          diamond_color,
          description
    )

VALUES (
        3,
        'https://res.cloudinary.com/deztgvefu/image/upload/v1697351447/Rings/DROP_HALO_PENDANT_NECKLACE_u811d4.webp',
        'DROP HALO PENDANT NECKLACE',
        17999.00,
        'ROSE GOLD',
        '1.17ctw',
        'SI1-SI2',
        'G-H',
        'This Drop Halo Pendant Necklace is a true statement piece. Crafted with a luxurious drop design, it combines stylish elegance with sophisticated charm. Its brilliant gold plating adds timeless sophistication and shine to any outfit. Refined and timeless, this necklace will ensure you stand out in any crowd.'
       );
