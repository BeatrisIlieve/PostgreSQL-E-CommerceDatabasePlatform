CREATE TABLE
    managers(
        id INTEGER GENERATED ALWAYS AS IDENTITY ( START WITH 30001 INCREMENT 1 ) PRIMARY KEY,
        first_name VARCHAR(30),
        last_name VARCHAR(30),
        email VARCHAR(30),
        phone_number VARCHAR(20),
        employed_at DATE
);

insert into managers (first_name, last_name, email, phone_number, employed_at) values ('Bab', 'Delagua', 'bdelagua1@buzzfeed.com', '805-186-8739', '9/5/2023');
insert into managers (first_name, last_name, email, phone_number, employed_at) values ('Rubia', 'Franssen', 'rfranssen0@umich.edu', '638-526-2342', '8/3/2023');
insert into managers (first_name, last_name, email, phone_number, employed_at) values ('Rem', 'Cordell', 'rcordell3@tuttocitta.it', '522-523-4027', '7/16/2023');
insert into managers (first_name, last_name, email, phone_number, employed_at) values ('Danice', 'Dunne', 'ddunne4@noaa.gov', '922-710-6398', '10/16/2022');
insert into managers (first_name, last_name, email, phone_number, employed_at) values ('Grenville', 'Addie', 'gaddie6@ehow.com', '809-184-2377', '9/3/2023');

CREATE TABLE
    departments(
        id INTEGER GENERATED ALWAYS AS IDENTITY ( START WITH 20001 INCREMENT 1 ) PRIMARY KEY,
        manager_id INTEGER UNIQUE NOT NULL,
        department_name VARCHAR(30),

        CONSTRAINT fk_departments_managers
               FOREIGN KEY (manager_id)
               REFERENCES managers(id)
               ON UPDATE CASCADE
               ON DELETE CASCADE
);

insert into departments (manager_id, department_name) values (30001, 'Merchandising');
insert into departments (manager_id, department_name) values (30002, 'Purchasing');
insert into departments (manager_id, department_name) values (30003, 'Shipping');
insert into departments (manager_id, department_name) values (30004, 'Quality Control');
insert into departments (manager_id, department_name) values (30005, 'Customer Service');

CREATE TABLE
    employees(
        id INTEGER GENERATED ALWAYS AS IDENTITY ( START WITH 10001 INCREMENT 1 ) PRIMARY KEY,
        department_id INTEGER,
        first_name VARCHAR(30),
        last_name VARCHAR(30),
        email VARCHAR(30),
        phone_number VARCHAR(20),
        employed_at DATE,

        CONSTRAINT fk_employees_departments
             FOREIGN KEY (department_id)
             REFERENCES departments(id)
             ON UPDATE CASCADE
             ON DELETE CASCADE
);

insert into employees (department_id, first_name, last_name, email, phone_number, employed_at) values (20001, 'Terri', 'Aldersley', 'taldersley0@army.mil', '198-393-2278', '5/9/2023');
insert into employees (department_id, first_name, last_name, email, phone_number, employed_at) values (20002, 'Gustav', 'Harte', 'gharte1@usa.gov', '448-500-3956', '2/3/2023');
insert into employees (department_id, first_name, last_name, email, phone_number, employed_at) values (20003, 'Moina', 'Smy', 'msmy2@weather.com', '704-615-7509', '1/19/2023');
insert into employees (department_id, first_name, last_name, email, phone_number, employed_at) values (20004, 'Mariette', 'Caltera', 'mcaltera4@cpanel.net', '515-969-8114', '12/26/2022');
insert into employees (department_id, first_name, last_name, email, phone_number, employed_at) values (20005, 'Nicky', 'Attewill', 'nattewill5@ebay.com', '342-225-4473', '9/11/2023');

CREATE TABLE
    categories(
        id SERIAL PRIMARY KEY,
        name VARCHAR(30) NOT NULL
);

INSERT INTO
    categories(name)
VALUES
    ('Ring'),
    ('Earring'),
    ('Necklace'),
    ('Bracelet');

CREATE TABLE
    jewelries(
        id SERIAL PRIMARY KEY,
        category_id INTEGER NOT NULL,
        is_active BOOLEAN DEFAULT TRUE,
        name VARCHAR(100) NOT NULL,
        image_url VARCHAR(200) NOT NULL,
        price DECIMAL(7, 2) NOT NULL,
        metal_color VARCHAR(12) NOT NULL,
        diamond_carat_weight VARCHAR(10) NOT NULL,
        diamond_clarity VARCHAR(10) NOT NULL,
        diamond_color VARCHAR(5) NOT NULL,
        description TEXT NOT NULL
);

CREATE TABLE
    categories_jewelries(
        category_id INTEGER NOT NULL,
        jewelry_id INTEGER NOT NULL,

        CONSTRAINT pk_categories_jewelries
                       PRIMARY KEY (category_id, jewelry_id),

        CONSTRAINT fk_categories_jewelries_categories
                        FOREIGN KEY (category_id)
                        REFERENCES categories(id)
                        ON UPDATE CASCADE
                        ON DELETE CASCADE,

        CONSTRAINT fk_categories_jewelries_jewelries
                        FOREIGN KEY (jewelry_id)
                        REFERENCES jewelries(id)
                        ON UPDATE CASCADE
                        ON DELETE CASCADE
);

CREATE TABLE
    inventory(
        id SERIAL PRIMARY KEY,
        last_modified_by_id INTEGER,
        category_id INTEGER NOT NULL,
        jewelry_id INTEGER NOT NULL,
        quantity INTEGER DEFAULT 0 NOT NULL,
        created_at TIMESTAMPTZ NOT NULL,
        updated_at TIMESTAMPTZ,
        deleted_at TIMESTAMPTZ,

        CONSTRAINT fk_inventory_employees
                     FOREIGN KEY (last_modified_by_id)
                     REFERENCES employees(id)
                     ON UPDATE CASCADE
                     ON DELETE CASCADE,

        CONSTRAINT fk_inventory_categories
            FOREIGN KEY (category_id)
                REFERENCES categories(id)
                ON UPDATE CASCADE
                ON DELETE CASCADE,

        CONSTRAINT fk_inventory_jewelries
             FOREIGN KEY (jewelry_id)
             REFERENCES jewelries(id)
             ON UPDATE CASCADE
             ON DELETE CASCADE
);

CREATE TABLE
    records(
        id SERIAL PRIMARY KEY,
        inventory_id INTEGER NOT NULL,
        employee_id INTEGER NOT NULL,
        operation VARCHAR(6) NOT NULL,
        date TIMESTAMPTZ DEFAULT DATE(NOW()),

        CONSTRAINT fk_records_inventory
                     FOREIGN KEY (inventory_id)
                     REFERENCES inventory(id)
                     ON UPDATE CASCADE
                     ON DELETE CASCADE,

        CONSTRAINT fk_records_employees
                     FOREIGN KEY (employee_id)
                     REFERENCES employees(id)
                     ON UPDATE CASCADE
                     ON DELETE CASCADE
);

CREATE OR REPLACE FUNCTION
    trigger_fn_insert_new_jewelry_into_inventory()
RETURNS TRIGGER
AS
$$
BEGIN
    INSERT INTO
        inventory(last_modified_by_id, category_id, jewelry_id, created_at, updated_at, deleted_at)
    VALUES
        (NEW.id, NEW.category_id, NEW.jewelry_id, DATE(NOW()), NULL, NULL);
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER
    tr_insert_new_jewelry_into_inventory
AFTER INSERT ON
    jewelries
FOR EACH ROW
EXECUTE FUNCTION trigger_fn_insert_new_jewelry_into_inventory();

CREATE OR REPLACE PROCEDURE
    sp_add_quantity_into_inventory(
        id_of_employee INTEGER,
        id_of_category INTEGER,
        id_of_jewelry INTEGER,
        added_quantity INTEGER
)
AS
$$
BEGIN
    UPDATE
        inventory
    SET
        last_modified_by_id = id_of_employee,
        quantity = quantity + added_quantity,
        updated_at = DATE(NOW())
    WHERE
        jewelry_id = id_of_jewelry
            AND
        category_id = id_of_category;
END;
$$
LANGUAGE plpgsql;

CALL sp_add_quantity_into_inventory(10002, 1, 1, 10);

CREATE OR REPLACE PROCEDURE
    sp_remove_quantity_from_inventory(
        id_of_employee INTEGER,
        id_of_category INTEGER,
        id_of_jewelry INTEGER,
        requested_quantity INTEGER
)
AS
$$
DECLARE
    current_quantity INTEGER;
BEGIN
    current_quantity := (
        SELECT
            quantity
        FROM
            inventory
        WHERE
            category_id = id_of_category
                    AND
            jewelry_id = id_of_jewelry
        );
    CASE
        WHEN current_quantity >= requested_quantity THEN
            UPDATE
                inventory
            SET
                last_modified_by_id = id_of_employee,
                quantity = quantity - requested_quantity,
                updated_at = DATE(NOW())
            WHERE
                jewelry_id = id_of_jewelry
                        AND
                category_id = id_of_category;
        CASE
            WHEN current_quantity - requested_quantity = 0 THEN
                UPDATE
                    jewelries
                SET
                    is_active = FALSE
                WHERE
                    id = id_of_jewelry
                        AND
                    category_id = id_of_category;
        END CASE;
        ELSE
            RAISE NOTICE 'Not enough quantity. AVAILABLE ONLY: %', current_quantity;
    END CASE;
END;
$$
LANGUAGE plpgsql;

CALL sp_remove_quantity_from_inventory(10002, 1, 1, 1);

CREATE OR REPLACE FUNCTION
    trigger_fn_insert_new_entity_into_records()
RETURNS TRIGGER
AS
$$
DECLARE
    operation_type VARCHAR(6);
BEGIN
    operation_type :=
        (CASE
            WHEN OLD.quantity < NEW.quantity THEN 'Update'
            WHEN OLD.quantity > NEW.quantity THEN 'Delete'
        END);
    INSERT INTO
            records(inventory_id, employee_id, operation, date)
    VALUES
        (OLD.inventory_id, NEW.employee_id, operation_type, DATE(NOW()));
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER
    tr_insert_new_entity_into_records
AFTER UPDATE ON
    inventory
FOR EACH ROW
EXECUTE FUNCTION trigger_fn_insert_new_entity_into_records();



INSERT INTO
    jewelries(
        category_id,
        is_active,
        name,
        image_url,
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

INSERT INTO
    jewelries(
        category_id,
        is_active,
        name,
        image_url,
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

INSERT INTO
    jewelries(
        category_id,
        is_active,
        name,
        image_url,
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

INSERT INTO
    jewelries(
        category_id,
        is_active,
        name,
        image_url,
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








-- CREATE OR REPLACE FUNCTION
--     trigger_fn_insert_new_record_into_sold_out_items()
-- RETURNS TRIGGER
-- AS
-- $$
--     DECLARE current_quantity INTEGER;
-- BEGIN
--     current_quantity := (
--
--                             )
-- END;
-- $$
-- LANGUAGE plpgsql;
--
-- CREATE OR REPLACE TRIGGER
--     tr_insert_new_record_into_sold_out_items
-- AFTER DELETE ON
--     jewelry_inventory
-- FOR EACH ROW
-- EXECUTE FUNCTION trigger_fn_insert_new_record_into_sold_out_items();





-- CREATE OR REPLACE PROCEDURE
--     sp_update_updated_at_into_jewelry_inventory(item_id INTEGER, item_type_id INTEGER, ring_name VARCHAR(100))
-- AS
-- $$
-- BEGIN
--     UPDATE
--         jewelry_inventory
--     SET
--         updated_at = DATE(NOW())
--     WHERE
--         jewelry_id = item_id
--             AND
--         jewelry_type_id = item_type_id;
-- END;
-- $$
-- LANGUAGE plpgsql;
--
--
-- CALL sp_update_updated_at_into_jewelry_inventory(3, 1, 'BUDDING ROUND BRILLIANT DIAMOND HALO ENGAGEMENT RING');



-- CREATE TABLE rings(
--     id SERIAL PRIMARY KEY,
--     is_active BOOLEAN DEFAULT TRUE,
--     type_id INTEGER NOT NULL,
--     image_url VARCHAR(200) NOT NULL,
--     ring_name VARCHAR(100) NOT NULL,
--     price DECIMAL(7, 2) NOT NULL,
--     metal_color VARCHAR(12) NOT NULL,
--     diamond_carat_weight VARCHAR(10) NOT NULL,
--     diamond_clarity VARCHAR(10) NOT NULL,
--     diamond_color VARCHAR(5) NOT NULL,
--     description TEXT NOT NULL,
--
--     CONSTRAINT fk_rings_types_jewelries
--                   FOREIGN KEY (jewelry_type_id)
--                   REFERENCES jewelry_types(id)
--                   ON UPDATE CASCADE
--                   ON DELETE CASCADE
-- );
--
-- CREATE TABLE earrings(
--     id SERIAL PRIMARY KEY,
--     is_active BOOLEAN DEFAULT TRUE,
--     jewelry_type_id INTEGER NOT NULL,
--     image_url VARCHAR(200) NOT NULL,
--     earring_name VARCHAR(100) NOT NULL,
--     price DECIMAL(7, 2) NOT NULL,
--     metal_color VARCHAR(12) NOT NULL,
--     diamond_carat_weight VARCHAR(10) NOT NULL,
--     diamond_clarity VARCHAR(10) NOT NULL,
--     diamond_color VARCHAR(5) NOT NULL,
--     description TEXT NOT NULL,
--
--     CONSTRAINT fk_earrings_jewelry_types
--                   FOREIGN KEY (jewelry_type_id)
--                   REFERENCES jewelry_types(id)
--                   ON UPDATE CASCADE
--                   ON DELETE CASCADE
-- );
--
-- CREATE TABLE necklaces(
--     id SERIAL PRIMARY KEY,
--     is_active BOOLEAN DEFAULT TRUE,
--     jewelry_type_id INTEGER NOT NULL,
--     image_url VARCHAR(200) NOT NULL,
--     necklace_name VARCHAR(100) NOT NULL,
--     price DECIMAL(7, 2) NOT NULL,
--     metal_color VARCHAR(12) NOT NULL,
--     diamond_carat_weight VARCHAR(10) NOT NULL,
--     diamond_clarity VARCHAR(10) NOT NULL,
--     diamond_color VARCHAR(5) NOT NULL,
--     description TEXT NOT NULL,
--
--     CONSTRAINT fk_necklaces_jewelry_types
--                   FOREIGN KEY (jewelry_type_id)
--                   REFERENCES jewelry_types(id)
--                   ON UPDATE CASCADE
--                   ON DELETE CASCADE
-- );
--
-- CREATE TABLE bracelets(
--     id SERIAL PRIMARY KEY,
--     is_active BOOLEAN DEFAULT TRUE,
--     jewelry_type_id INTEGER NOT NULL,
--     image_url VARCHAR(200) NOT NULL,
--     bracelet_name VARCHAR(100) NOT NULL,
--     price DECIMAL(7, 2) NOT NULL,
--     metal_color VARCHAR(12) NOT NULL,
--     diamond_carat_weight VARCHAR(10) NOT NULL,
--     diamond_clarity VARCHAR(10) NOT NULL,
--     diamond_color VARCHAR(5) NOT NULL,
--     description TEXT NOT NULL,
--
--     CONSTRAINT fk_bracelets_jewelry_types
--                   FOREIGN KEY (jewelry_type_id)
--                   REFERENCES jewelry_types(id)
--                   ON UPDATE CASCADE
--                   ON DELETE CASCADE
-- );


-- CREATE OR REPLACE TRIGGER
--     tr_insert_new_entry_earrings
-- AFTER INSERT ON
--     earrings
-- FOR EACH ROW
-- EXECUTE FUNCTION trigger_fn_insert_new_jewelry_into_jewelry_inventory();
--
-- CREATE OR REPLACE TRIGGER
--     tr_insert_new_entry_necklaces
-- AFTER INSERT ON
--     necklaces
-- FOR EACH ROW
-- EXECUTE FUNCTION trigger_fn_insert_new_jewelry_into_jewelry_inventory();
--
-- CREATE OR REPLACE TRIGGER
--     tr_insert_new_jewelry_bracelets
-- AFTER INSERT ON
--     bracelets
-- FOR EACH ROW
-- EXECUTE FUNCTION trigger_fn_insert_new_jewelry_into_jewelry_inventory();