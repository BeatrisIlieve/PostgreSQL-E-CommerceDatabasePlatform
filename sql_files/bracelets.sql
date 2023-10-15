CREATE TABLE bracelets(
    id SERIAL PRIMARY KEY,
    image_url VARCHAR(200),
    bracelet_name VARCHAR(100),
    price DECIMAL(7, 2),
    metal_color VARCHAR(12),
    diamond_carat_weight VARCHAR(10),
    diamond_clarity VARCHAR(10),
    diamond_color VARCHAR(5),
    description TEXT
);