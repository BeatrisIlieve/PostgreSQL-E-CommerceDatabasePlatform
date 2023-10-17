CREATE TABLE
    users(
        id SERIAL PRIMARY KEY,
        user_role VARCHAR(50) NOT NULL,
        user_password VARCHAR(50) NOT NULL
);

INSERT INTO
    users(user_role, user_password)
VALUES
    ('super_user', 'super_user_password'),
    ('merchandising_user_first', 'merchandising_password_first'),
    ('merchandising_user_second', 'merchandising_password_second'),
    ('receiving_inventory_user_first', 'receiving_inventory_password_first'),
    ('receiving_inventory_user_second', 'receiving_inventory_password_second'),
    ('issuing_inventory_user_first', 'issuing_inventory_password_first'),
    ('issuing_inventory_user_second', 'issuing_inventory_password_second');

CREATE TABLE
    departments(
        id INTEGER GENERATED ALWAYS AS IDENTITY ( START WITH 20001 INCREMENT 1 ) PRIMARY KEY,
        name VARCHAR(30) NOT NULL
);

insert into departments (name) values ('Supervisory');
insert into departments (name) values ('Merchandising');
insert into departments (name) values ('Receiving Inventory');
insert into departments (name) values ('Issuing  Inventory');

CREATE TABLE
    employees(
        id INTEGER GENERATED ALWAYS AS IDENTITY ( START WITH 10001 INCREMENT 1 ) PRIMARY KEY,
        user_id INTEGER NOT NULL,
        is_active BOOLEAN DEFAULT TRUE,
        department_id INTEGER NOT NULL,
        first_name VARCHAR(30) NOT NULL,
        last_name VARCHAR(30) NOT NULL,
        email VARCHAR(30) NOT NULL,
        phone_number VARCHAR(20) NOT NULL,
        employed_at DATE DEFAULT DATE(NOW()),

        CONSTRAINT fk_employees_users
            FOREIGN KEY (user_id)
            REFERENCES users(id)
            ON UPDATE CASCADE
            ON DELETE CASCADE,

        CONSTRAINT fk_employees_departments
             FOREIGN KEY (department_id)
             REFERENCES departments(id)
             ON UPDATE CASCADE
             ON DELETE CASCADE
);

insert into employees (user_id, department_id, first_name, last_name, email, phone_number) values (1, 20001, 'Beatris', 'Ilieve', 'beatris@icloud.com', '000-000-000');
insert into employees (user_id, department_id, first_name, last_name, email, phone_number) values (2, 20002, 'Terri', 'Aldersley', 'taldersley0@army.mil', '198-393-2278');
insert into employees (user_id, department_id, first_name, last_name, email, phone_number) values (3, 20002, 'PerrY', 'Oldersley', 'poldersley0@army.mil', '231-393-2278');
insert into employees (user_id, department_id, first_name, last_name, email, phone_number) values (4, 20003, 'Rose', 'Obrey', 'r@obrey.net', '631-969-8114');
insert into employees (user_id, department_id, first_name, last_name, email, phone_number) values (5, 20003,'Mariette', 'Caltera', 'mcaltera4@cpanel.net', '515-969-8114');
insert into employees (user_id, department_id, first_name, last_name, email, phone_number) values (6, 20004, 'Elen', 'Williams', 'elen@ebay.com', '812-263-4473');
insert into employees (user_id, department_id, first_name, last_name, email, phone_number) values (7, 20004, 'Nicky', 'Attewill', 'nattewill5@ebay.com', '342-225-4473');


CREATE OR REPLACE FUNCTION
    credentials_authentication(
    provided_user_role VARCHAR(30),
    provided_user_password VARCHAR(30),
    provided_user_id CHAR(5)
)
RETURNS BOOLEAN
AS
$$
DECLARE
    id_as_integer INTEGER;
    is_authenticated BOOLEAN;
BEGIN
    id_as_integer := provided_user_id::INTEGER;
    IF
        id_as_integer = (
            SELECT
                e.id
            FROM
                employees AS e
            JOIN
                users
            ON
                e.user_id = users.id
            WHERE
                 user_role = provided_user_role
                        AND
                 user_password = provided_user_password
                        AND
                is_active IS TRUE
            )
    THEN
        is_authenticated := TRUE;
    ELSE
        is_authenticated := FALSE;
    END IF;
RETURN
    is_authenticated;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
    fn_role_authentication(
    department_name VARCHAR(30),
    provided_emp_id CHAR(5)
)
RETURNS BOOLEAN
AS
$$
DECLARE
    actual_department_name VARCHAR(40);
    is_role_authorised BOOLEAN;
BEGIN
    actual_department_name :=
        (SELECT
            u.user_role
        FROM
            users AS u
        JOIN
            employees AS e
        ON
            u.id = e.user_id
        WHERE
            e.id = provided_emp_id::INTEGER);
    IF
        actual_department_name LIKE department_name || '%'
    THEN
        is_role_authorised := TRUE;
    ELSE
        is_role_authorised := FALSE;
    END IF;
    RETURN is_role_authorised;
END;
$$
LANGUAGE plpgsql;


CREATE TABLE
    types(
        id SERIAL PRIMARY KEY,
        name VARCHAR(30) NOT NULL
);

INSERT INTO
    types(name)
VALUES
    ('Ring'),
    ('Earring'),
    ('Necklace'),
    ('Bracelet');




CREATE TABLE
    jewelries(
        id SERIAL PRIMARY KEY,
        type_id INTEGER NOT NULL,
        is_active BOOLEAN DEFAULT FALSE,
        name VARCHAR(100) NOT NULL,
        image_url VARCHAR(200) NOT NULL,
        regular_price DECIMAL(7, 2) NOT NULL,
        discount_price DECIMAL(7, 2),
        metal_color VARCHAR(12) NOT NULL,
        diamond_carat_weight VARCHAR(10) NOT NULL,
        diamond_clarity VARCHAR(10) NOT NULL,
        diamond_color VARCHAR(5) NOT NULL,
        description TEXT NOT NULL,

        CONSTRAINT fk_jewelries_types
             FOREIGN KEY (type_id)
             REFERENCES types(id)
             ON UPDATE CASCADE
             ON DELETE CASCADE
);

CREATE TABLE
    inventory(
        id SERIAL PRIMARY KEY,
        last_modified_by_emp_id INTEGER NOT NULL,
        jewelry_id INTEGER NOT NULL,
        quantity INTEGER DEFAULT 0,
        created_at TIMESTAMPTZ NOT NULL,
        updated_at TIMESTAMPTZ,
        deleted_at TIMESTAMPTZ,

        CONSTRAINT fk_inventory_users
                     FOREIGN KEY (last_modified_by_emp_id)
                     REFERENCES employees(id)
                     ON UPDATE CASCADE
                     ON DELETE CASCADE,

        CONSTRAINT fk_inventory_jewelries
                FOREIGN KEY (jewelry_id)
                REFERENCES jewelries(id)
                ON UPDATE CASCADE
                ON DELETE CASCADE
);

CREATE TABLE
    inventory_records(
        id SERIAL PRIMARY KEY,
        inventory_id INTEGER NOT NULL,
        operation VARCHAR(6) NOT NULL,
        date TIMESTAMPTZ DEFAULT DATE(NOW()),

        CONSTRAINT fk_inventory_records_inventory
                     FOREIGN KEY (inventory_id)
                     REFERENCES inventory(id)
                     ON UPDATE CASCADE
                     ON DELETE CASCADE
);


CREATE TABLE
    discounts(
        id SERIAL PRIMARY KEY,
        last_modified_by_emp_id CHAR(5) NOT NULL,
        jewelry_id INTEGER NOT NULL,
        percentage DECIMAL(3,2) NOT NULL,
        is_active BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ,
        updated_at TIMESTAMPTZ,
        deleted_at TIMESTAMPTZ,

        CONSTRAINT ck_discounts_percentage
             CHECK ( LEFT(CAST(percentage AS TEXT), 1) = '0' )
);

CREATE TABLE
    discounts_records(
        id SERIAL PRIMARY KEY,
        discount_id INTEGER NOT NULL,
        operation VARCHAR(6) NOT NULL,
        date TIMESTAMPTZ DEFAULT DATE(NOW()),

        CONSTRAINT fk_discounts_records_discounts
                     FOREIGN KEY (discount_id)
                     REFERENCES discounts(id)
                     ON UPDATE CASCADE
                     ON DELETE CASCADE
);


CREATE OR REPLACE PROCEDURE
    sp_insert_jewelry_into_jewelries(
    provided_user_role VARCHAR(30),
    provided_user_password VARCHAR(9),
    provided_last_modified_by_emp_id CHAR(5),
    provided_type_id INTEGER,
    provided_name VARCHAR(100),
    provided_image_url VARCHAR(200) ,
    provided_regular_price DECIMAL(7, 2),
    provided_metal_color VARCHAR(12),
    provided_diamond_carat_weight VARCHAR(10),
    provided_diamond_clarity VARCHAR(10),
    provided_diamond_color VARCHAR(5),
    provided_description TEXT
)
AS
$$
DECLARE current_jewelry_id INTEGER;
BEGIN
    IF NOT
        (SELECT fn_role_authentication(
                    'merchandising', provided_last_modified_by_emp_id
                    ))
    THEN
        RAISE EXCEPTION 'Access Denied: You do not have the required authorization to perform actions into this department.';
    END IF;
    IF
        (SELECT credentials_authentication(
            provided_user_role,
            provided_user_password,
            provided_last_modified_by_emp_id)) IS TRUE
    THEN
        INSERT INTO
            jewelries(type_id, name, image_url, regular_price, metal_color, diamond_carat_weight, diamond_clarity, diamond_color, description)
        VALUES
            (
            provided_type_id,
            provided_name,
            provided_image_url,
            provided_regular_price,
            provided_metal_color,
            provided_diamond_carat_weight,
            provided_diamond_clarity,
            provided_diamond_color,
            provided_description
            );

        current_jewelry_id := (
            SELECT
                MAX(id)
            FROM
                jewelries
        );

        INSERT INTO
            inventory(last_modified_by_emp_id, jewelry_id, created_at, updated_at, deleted_at)
        VALUES
            (provided_last_modified_by_emp_id::INTEGER, current_jewelry_id, DATE(NOW()), NULL, NULL);
    ELSE
        RAISE EXCEPTION 'Authorization failed: Incorrect credentials';
    END IF;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE
    sp_add_quantity_into_inventory(
        provided_user_role VARCHAR(30),
        provided_user_password VARCHAR(9),
        provided_last_modified_by_emp_id CHAR(5),
        provided_jewelry_id INTEGER,
        added_quantity INTEGER
)
AS
$$
BEGIN
    IF NOT
        (SELECT fn_role_authentication(
                    'receiving_inventory', provided_last_modified_by_emp_id
                    ))
    THEN
        RAISE EXCEPTION 'Access Denied: You do not have the required authorization to perform actions into this department.';
    END IF;
    IF
        (SELECT credentials_authentication(
            provided_user_role,
            provided_user_password,
            provided_last_modified_by_emp_id)) IS TRUE
    THEN
        UPDATE
            inventory
        SET
            last_modified_by_emp_id = provided_last_modified_by_emp_id::INTEGER,
            quantity = quantity + added_quantity,
            updated_at = DATE(NOW())
        WHERE
            jewelry_id = provided_jewelry_id;
        UPDATE
            jewelries
        SET
            is_active = TRUE
        WHERE
            id = provided_jewelry_id;
    ELSE 
        RAISE EXCEPTION 'Authorization failed: Incorrect password';
    END IF;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE
    sp_remove_quantity_from_inventory(
        provided_user_role VARCHAR(30),
        provided_user_password VARCHAR(9),
        provided_last_modified_by_emp_id CHAR(5),
        provided_jewelry_id INTEGER,
        requested_quantity INTEGER
)
AS
$$
DECLARE
    current_quantity INTEGER;
BEGIN
    IF NOT
        (SELECT fn_role_authentication(
                    'issuing_inventory', provided_last_modified_by_emp_id
                    ))
    THEN
        RAISE EXCEPTION 'Access Denied: You do not have the required authorization to perform actions into this department.';
    END IF;
        IF
        (SELECT credentials_authentication(
            provided_user_role,
            provided_user_password,
            provided_last_modified_by_emp_id)) IS TRUE
    THEN
        current_quantity := (
            SELECT
                quantity
            FROM
                inventory
            WHERE
                jewelry_id = provided_jewelry_id
            );
        CASE
            WHEN current_quantity >= requested_quantity THEN
                UPDATE
                    inventory
                SET
                    last_modified_by_emp_id = provided_last_modified_by_emp_id::INTEGER,
                    quantity = quantity - requested_quantity,
                    deleted_at = DATE(NOW())
                WHERE
                    jewelry_id = provided_jewelry_id;
            IF current_quantity - requested_quantity = 0 THEN
                    UPDATE
                        jewelries
                    SET
                        is_active = FALSE
                    WHERE
                        id = provided_jewelry_id;
            END IF;
        ELSE
            RAISE NOTICE 'Not enough quantity. AVAILABLE ONLY: %', current_quantity;
        END CASE;
    ELSE
        RAISE EXCEPTION 'Authorization failed: Incorrect password';
    END IF;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
    trigger_fn_insert_new_entity_into_inventory_records_on_update()
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
            inventory_records(inventory_id, operation, date)
    VALUES
        (OLD.id, operation_type, DATE(NOW()));
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER
    tr_insert_new_entity_into_jewelry_records_on_update
AFTER UPDATE ON
    inventory
FOR EACH ROW
EXECUTE FUNCTION trigger_fn_insert_new_entity_into_inventory_records_on_update();


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
            inventory_records(inventory_id, operation, date)
    VALUES
        (NEW.id,  operation_type, DATE(NOW()));
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

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_user_first',
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

CALL sp_add_quantity_into_inventory('receiving_inventory_user_first', 'receiving_inventory_password_first', '10004', 1, 100);

CALL sp_remove_quantity_from_inventory('issuing_inventory_user_first', 'issuing_inventory_password_first', '10006', 1, 10);






CREATE OR REPLACE PROCEDURE
    sp_insert_percent_into_discounts(
        provided_user_role VARCHAR(30),
        provided_user_password VARCHAR(9),
        provided_last_modified_by_emp_id CHAR(5),
        provided_jewelry_id INTEGER,
        provided_percent DECIMAL(3,2)
)
AS
$$
BEGIN
    IF NOT
        (SELECT fn_role_authentication(
                    'merchandising', provided_last_modified_by_emp_id
                    ))
    THEN
        RAISE EXCEPTION 'Access Denied: You do not have the required authorization to perform actions into this department.';
    END IF;
    IF
        (SELECT credentials_authentication(
            provided_user_role,
            provided_user_password,
            provided_last_modified_by_emp_id)) IS TRUE
    THEN
        UPDATE
            jewelries
        SET
            discount_price = regular_price - (regular_price * provided_percent)
        WHERE
            id = provided_jewelry_id;
        IF provided_jewelry_id IN (
            SELECT
                jewelry_id
            FROM
                discounts
            )
        THEN
            UPDATE
                discounts
            SET
                percentage = provided_percent,
                is_active = TRUE
            WHERE
                jewelry_id = provided_jewelry_id;
        ELSE
            INSERT INTO
                discounts(last_modified_by_emp_id, jewelry_id, percentage, created_at, updated_at, deleted_at)
            VALUES
                (
                provided_last_modified_by_emp_id, provided_jewelry_id, provided_percent, DATE(NOW()), NULL, NULL
                );
        END IF;
    ELSE
        RAISE EXCEPTION 'Authorization failed: Incorrect credentials';
    END IF;
END;
$$
LANGUAGE plpgsql;

CALL sp_insert_percent_into_discounts('merchandising_user_first', 'merchandising_password_first', '10002', 1, 0.40);
CALL sp_remove_percent_from_discounts('merchandising_user_first', 'merchandising_password_first', '10002', 1);




CREATE OR REPLACE PROCEDURE
    sp_remove_percent_from_discounts(
        provided_user_role VARCHAR(30),
        provided_user_password VARCHAR(9),
        provided_last_modified_by_emp_id CHAR(5),
        provided_jewelry_id INTEGER
)
AS
$$
BEGIN
    IF NOT
        (SELECT fn_role_authentication(
                    'merchandising', provided_last_modified_by_emp_id
                    ))
    THEN
        RAISE EXCEPTION 'Access Denied: You do not have the required authorization to perform actions into this department.';
    END IF;
        IF
        (SELECT credentials_authentication(
            provided_user_role,
            provided_user_password,
            provided_last_modified_by_emp_id)) IS TRUE
    THEN
        UPDATE
            jewelries
        SET
            discount_price = NULL
        WHERE
            id = provided_jewelry_id;
        DELETE FROM
            discounts
        WHERE
            jewelry_id = provided_jewelry_id;
    ELSE
        RAISE EXCEPTION 'Authorization failed: Incorrect password';
    END IF;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
    trigger_fn_insert_new_entity_into_inventory_records_on_update()
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
            inventory_records(inventory_id, operation, date)
    VALUES
        (OLD.id, operation_type, DATE(NOW()));
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER
    tr_insert_new_entity_into_jewelry_records_on_update
AFTER UPDATE ON
    inventory
FOR EACH ROW
EXECUTE FUNCTION trigger_fn_insert_new_entity_into_inventory_records_on_update();


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
            inventory_records(inventory_id, operation, date)
    VALUES
        (NEW.id,  operation_type, DATE(NOW()));
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











CALL sp_insert_jewelry_into_jewelries(
    'merchandising_user_first',
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

CALL sp_add_quantity_into_inventory('receiving_inventory_user_first', 'receiving_inventory_password_first', '10004', 1, 100);

CALL sp_remove_quantity_from_inventory('issuing_inventory_user_first', 'issuing_inventory_password_first', '10006', 1, 10);