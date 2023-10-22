CREATE OR REPLACE FUNCTION
    trigger_fn_insert_new_entity_into_inventory_records_on_create()
RETURNS TRIGGER
AS
$$
DECLARE
    operation_type VARCHAR(6);
BEGIN
    operation_type := 'Create';
    INSERT INTO
            inventory_records(inventory_id, operation, date)
    VALUES
        (NEW.id, operation_type, NOW());
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER
    tr_insert_new_entity_into_inventory_records_on_create
AFTER INSERT ON
    inventory
FOR EACH ROW
EXECUTE FUNCTION
    trigger_fn_insert_new_entity_into_inventory_records_on_create();

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    1,
    'BUDDING ROUND BRILLIANT DIAMOND HALO ENGAGEMENT RING',
    'https://res.cloudinary.com/deztgvefu/image/upload/v1697350935/Rings/BUDDING_ROUND_BRILLIANT_DIAMOND_HALO_ENGAGEMENT_RING_s1ydsv.webp',
    19879.00,
    'ROSE GOLD',
    '1.75ctw',
    'SI1-SI2',
    'G-H',
    'This stunning engagement ring features a round brilliant diamond with surrounded by a sparkling halo of marquise diamonds. Crafted to the highest standards and ethically sourced, it is the perfect ring to dazzle for any gift, proposal, or occasion. Its timeless design and exquisite craftsmanship will ensure an everlasting memory.'
);

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_second',
    'merchandising_password_second',
    '10003',
    2,
    'ALMOST A HALO ROUND DIAMOND STUD EARRING',
    'https://res.cloudinary.com/deztgvefu/image/upload/v1697351117/Rings/ALMOST_A_HALO_ROUND_DIAMOND_STUD_EARRING_giloj0.webp',
    3749.00,
    'ROSE GOLD',
    '1.11ctw',
    'SI1-SI2',
    'G-H',
    'This Almost A Halo Round Diamond Stud Earring is the perfect choice for any occasion. It features an 0.60cttw round diamonds set in a half halo design, creating a unique and timeless look. Crafted from the finest materials, this earring is sure to be an eye-catching addition to any collection.'
);

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    3,
    'DROP HALO PENDANT NECKLACE',
    'https://res.cloudinary.com/deztgvefu/image/upload/v1697351447/Rings/DROP_HALO_PENDANT_NECKLACE_u811d4.webp',
    17999.00,
    'ROSE GOLD',
    '1.11ctw',
    'SI1-SI2',
    'G-H',
    'This Drop Halo Pendant Necklace is a true statement piece. Crafted with a luxurious drop design, it combines stylish elegance with sophisticated charm. Its brilliant gold plating adds timeless sophistication and shine to any outfit. Refined and timeless, this necklace will ensure you stand out in any crowd.'
);

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_second',
    'merchandising_password_second',
    '10003',
    4,
    'CLASSIC DIAMOND TENNIS BRACELET',
    'https://res.cloudinary.com/deztgvefu/image/upload/v1697351731/Rings/CLASSIC_DIAMOND_TENNIS_BRACELET_f1etis.webp',
    7249.00,
    'ROSE GOLD',
    '1.11ctw',
    'SI1-SI2',
    'G-H',
    'This classic diamond tennis bracelet is crafted from sterling silver and made with 18 round-cut diamonds. Each diamond is hand-selected for sparkle and set in a four-prong setting for maximum brilliance. This timeless piece is the perfect piece for any special occasion.Wear it to work, special events, or everyday activities to make a statement.'
);