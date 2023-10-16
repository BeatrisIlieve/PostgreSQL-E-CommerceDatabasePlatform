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
        id SERIAL PRIMARY KEY,
        categories_id INTEGER NOT NULL,
        jewelries_id INTEGER NOT NULL,

        CONSTRAINT fk_categories_jewelries_categories
                        FOREIGN KEY (categories_id)
                        REFERENCES categories(id)
                        ON UPDATE CASCADE
                        ON DELETE CASCADE,

        CONSTRAINT fk_categories_jewelries_jewelries
                        FOREIGN KEY (jewelries_id)
                        REFERENCES jewelries(id)
                        ON UPDATE CASCADE
                        ON DELETE CASCADE
);

CREATE TABLE
    inventory(
        id SERIAL PRIMARY KEY,
        last_modified_by_id INTEGER,
        categories_jewelries_id INTEGER NOT NULL,
        quantity INTEGER DEFAULT 0 NOT NULL,
        created_at TIMESTAMPTZ NOT NULL,
        updated_at TIMESTAMPTZ,
        deleted_at TIMESTAMPTZ,

        CONSTRAINT fk_inventory_employees
                     FOREIGN KEY (last_modified_by_id)
                     REFERENCES employees(id)
                     ON UPDATE CASCADE
                     ON DELETE CASCADE,

        CONSTRAINT fk_inventory_categories_jewelries
                FOREIGN KEY (categories_jewelries_id)
                REFERENCES categories_jewelries(id)
                ON UPDATE CASCADE
                ON DELETE CASCADE
);

CREATE TABLE
    jewelry_records(
        id SERIAL PRIMARY KEY,
        inventory_id INTEGER NOT NULL,
        employee_id INTEGER NOT NULL,
        operation VARCHAR(6) NOT NULL,
        date TIMESTAMPTZ DEFAULT DATE(NOW()),

        CONSTRAINT fk_jewelry_records_inventory
                     FOREIGN KEY (inventory_id)
                     REFERENCES inventory(id)
                     ON UPDATE CASCADE
                     ON DELETE CASCADE,

        CONSTRAINT fk_jewelry_records_employees
                     FOREIGN KEY (employee_id)
                     REFERENCES employees(id)
                     ON UPDATE CASCADE
                     ON DELETE CASCADE
);

CREATE OR REPLACE PROCEDURE
    sp_insert_jewelry_into_jewelries(
    inserted_last_modified_by INTEGER,
    inserted_quantity INTEGER,
    inserted_category_id INTEGER,
    inserted_name VARCHAR(100),
    inserted_image_url VARCHAR(200) ,
    inserted_price DECIMAL(7, 2),
    inserted_metal_color VARCHAR(12),
    inserted_diamond_carat_weight VARCHAR(10),
    inserted_diamond_clarity VARCHAR(10),
    inserted_diamond_color VARCHAR(5),
    inserted_description TEXT
)
AS
$$
DECLARE jel_id INTEGER;
DECLARE cat_jel_id INTEGER;
BEGIN
    INSERT INTO
        jewelries(category_id, name, image_url, price, metal_color, diamond_carat_weight, diamond_clarity, diamond_color, description)
    VALUES
        (inserted_category_id, inserted_name, inserted_image_url, inserted_price, inserted_metal_color, inserted_diamond_carat_weight, inserted_diamond_clarity, inserted_diamond_color, inserted_description);

    jel_id := (
        SELECT
            MAX(id)
        FROM
            jewelries
                  );

    INSERT INTO
        categories_jewelries(categories_id, jewelries_id)
    VALUES
        (inserted_category_id, jel_id);

    cat_jel_id := (
        SELECT
            MAX(id)
        FROM
            categories_jewelries
                      );

    INSERT INTO
        inventory(last_modified_by_id, categories_jewelries_id, quantity, created_at, updated_at, deleted_at)
    VALUES
        (inserted_last_modified_by, cat_jel_id, inserted_quantity, DATE(NOW()), NULL, NULL);
END;
$$
LANGUAGE plpgsql;

CALL sp_insert_jewelry_into_jewelries(
        10002,
        10,
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

CREATE OR REPLACE PROCEDURE
    sp_add_quantity_into_inventory(
        id_of_employee INTEGER,
        id_of_categories_jewelries INTEGER,
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
        categories_jewelries_id = id_of_categories_jewelries;
END;
$$
LANGUAGE plpgsql;

CALL sp_add_quantity_into_inventory(10002, 1, 10);

CREATE OR REPLACE PROCEDURE
    sp_remove_quantity_from_inventory(
        id_of_employee INTEGER,
        id_of_categories_jewelries INTEGER,
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
            categories_jewelries_id = id_of_categories_jewelries
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
                categories_jewelries_id = id_of_categories_jewelries;
        IF current_quantity - requested_quantity = 0 THEN
                UPDATE
                    jewelries
                SET
                    is_active = FALSE
                WHERE
                    id = (
                        SELECT
                            je.id
                        FROM
                            jewelries AS je

                        JOIN
                            categories_jewelries AS catje
                        ON
                            je.id = catje.jewelries_id
                        JOIN
                            inventory AS inv
                        ON
                            catje.id = inv.categories_jewelries_id
                        WHERE
                            catje.jewelries_id = je.id
                                AND
                            catje.id = id_of_categories_jewelries
                        );
                END IF;
        ELSE
            RAISE NOTICE 'Not enough quantity. AVAILABLE ONLY: %', current_quantity;
    END CASE;
END;
$$
LANGUAGE plpgsql;

CALL sp_remove_quantity_from_inventory(10003, 1, 9);

CREATE OR REPLACE FUNCTION
    trigger_fn_insert_new_entity_into_jewelry_records_on_update()
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
            jewelry_records(inventory_id, employee_id, operation, date)
    VALUES
        (OLD.id, NEW.last_modified_by_id, operation_type, DATE(NOW()));
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER
    tr_insert_new_entity_into_jewelry_records_on_update
AFTER UPDATE ON
    inventory
FOR EACH ROW
EXECUTE FUNCTION trigger_fn_insert_new_entity_into_jewelry_records_on_update();


CREATE OR REPLACE FUNCTION
    trigger_fn_insert_new_entity_into_jewelry_records_on_create()
RETURNS TRIGGER
AS
$$
DECLARE
    operation_type VARCHAR(6);
BEGIN
    operation_type := 'Create';
    INSERT INTO
            jewelry_records(inventory_id, employee_id, operation, date)
    VALUES
        (NEW.id, NEW.last_modified_by_id, operation_type, DATE(NOW()));
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER
    tr_insert_new_entity_into_jewelry_records_on_create
AFTER INSERT ON
    inventory
FOR EACH ROW
EXECUTE FUNCTION trigger_fn_insert_new_entity_into_jewelry_records_on_create();