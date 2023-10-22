CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE
    customer_users(
        id SERIAL PRIMARY KEY NOT NULL,
        email VARCHAR(30) UNIQUE NOT NULL,
        password VARCHAR(100) NOT NULL,
        created_at DATE NOT NULL,
        updated_at DATE,
        deleted_at DATE
);

CREATE TABLE
    customer_details(
        id SERIAL PRIMARY KEY,
        customer_user_id INTEGER NOT NULL,
        first_name VARCHAR(30),
        last_name VARCHAR(30),
        phone_number VARCHAR(20),
        current_balance DECIMAL(8, 2),
        payment_provider VARCHAR(100),

        CONSTRAINT fk_customers_details_customer_users
                     FOREIGN KEY (customer_user_id)
                     REFERENCES customer_users(id)
                     ON UPDATE CASCADE
                     ON DELETE CASCADE
);

CREATE OR REPLACE FUNCTION
    fn_raise_error_message(
        provided_error_message VARCHAR(300)
)
RETURNS VOID
AS
$$
BEGIN
    RAISE EXCEPTION '%', provided_error_message;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
    fn_register_user(
        provided_email VARCHAR(30),
        provided_password VARCHAR(15),
        provided_verifying_password VARCHAR(15)
)
RETURNS VOID
AS
$$
DECLARE
    email_already_in_use CONSTANT TEXT :=
        'This email address is already in use. ' ||
        'Please use a different email address or try logging in with your existing account.';

    password_not_secure CONSTANT TEXT :=
        'The password should contain at least one special character and at least one digit. ' ||
        'Please make sure you enter a secure password.';

    passwords_do_not_match CONSTANT TEXT :=
        'The password and password verification do not match. ' ||
        'Please make sure that both fields contain the same password.';

    hashed_password VARCHAR;

BEGIN
    IF provided_email IN (
            SELECT
                email
            FROM
                customer_users
            )
    THEN
        SELECT
            fn_raise_error_message(email_already_in_use);

    ELSIF
        NOT provided_password ~ '[0-9!#$%&()*+,-./:;<=>?@^_`{|}~]'
    THEN
        SELECT
            fn_raise_error_message(password_not_secure);

    ELSIF
        provided_password NOT LIKE provided_verifying_password
    THEN
        SELECT
            fn_raise_error_message(passwords_do_not_match);

    ELSE
        hashed_password := encode(digest(provided_password, 'sha256'), 'hex');

        INSERT INTO customer_users
            (email, password, created_at, updated_at, deleted_at)
        VALUES
            (provided_email, hashed_password , NOW(), NULL, NULL);

        CALL sp_login_user(provided_email, provided_password);

    END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
    trigger_fn_insert_id_into_customer_details()
RETURNS TRIGGER
AS
$$
BEGIN
    INSERT INTO customer_details
        (customer_user_id)
    VALUES
        (NEW.id);
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER
    tr_insert_id_into_customer_details
AFTER INSERT ON
    customer_users
FOR EACH ROW
EXECUTE FUNCTION
    trigger_fn_insert_id_into_customer_details();

CREATE OR REPLACE PROCEDURE
    sp_login_user(
    provided_email VARCHAR(30),
    provided_password VARCHAR(15)
)
AS
$$
DECLARE
    credentials_not_correct CONSTANT TEXT :=
        'The email or password you entered is incorrect. ' ||
        'Please check your email and password, and try again.';

    is_email_valid BOOLEAN;

    is_password_valid BOOLEAN;

    hashed_password VARCHAR(100);

    user_id INTEGER;
BEGIN
    IF provided_email IN (
        SELECT
            cu.email
        FROM
            customer_users AS cu
        )
    THEN
        is_email_valid := TRUE;
    ELSE
        is_email_valid := FALSE;
    END IF;

    hashed_password := encode(digest(provided_password, 'sha256'), 'hex');

    IF hashed_password IN (
        SELECT
            cu.password
        FROM
            customer_users AS cu
        )
        THEN
            is_password_valid := TRUE;

    ELSE
        is_password_valid := FALSE;
    END IF;

    IF
        is_email_valid IS FALSE
            OR
        is_password_valid IS FALSE
    THEN
        SELECT fn_raise_error_message(credentials_not_correct);

    ELSE
        user_id := (
                SELECT
                    id
                FROM
                    customer_users
                WHERE
                    email = provided_email
                            AND
                    password = hashed_password
                );
        CALL sp_generate_session_token(
                user_id
        );
    END IF;
END;
$$
LANGUAGE plpgsql;

CREATE TABLE sessions(
    id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    is_active BOOLEAN,
    session_data JSONB NOT NULL,
    expiration_time TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_sessions_customer_users
                     FOREIGN KEY (customer_id)
                     REFERENCES customer_users
                     ON UPDATE CASCADE
                     ON DELETE CASCADE
);

CREATE OR REPLACE PROCEDURE
    sp_generate_session_token(
        current_customer_id INTEGER
)
AS
$$
DECLARE
    current_session_data JSONB;
    current_expiration_time TIMESTAMPTZ;
BEGIN
    current_session_data := jsonb_build_object(
        'customer_id', current_customer_id,
        'created_at', NOW()
    );

    current_expiration_time := NOW() + INTERVAL '1 HOUR';

    IF current_customer_id IN (
        SELECT
            customer_id
        FROM
            sessions
        )
    THEN
        UPDATE
            sessions
        SET
            session_data = current_session_data,
            expiration_time = current_expiration_time
        WHERE
            customer_id = current_customer_id;

    ELSE
        INSERT INTO
            sessions(customer_id, is_active, session_data, expiration_time)
        VALUES
            (current_customer_id, TRUE, current_session_data, current_expiration_time);

    END IF;
END;
$$
LANGUAGE plpgsql;

SELECT fn_register_user(
    'beatris@icloud.com',
    '#6hhhhh',
    '#6hhhhh'
);

CREATE TABLE
    staff_users(
        id SERIAL PRIMARY KEY,
        staff_user_role VARCHAR(50) NOT NULL,
        staff_user_password VARCHAR(50) NOT NULL
);

INSERT INTO
    staff_users(staff_user_role, staff_user_password)
VALUES
    ('super_staff_user', 'super_staff_user_password'),
    ('merchandising_staff_user_first', 'merchandising_password_first'),
    ('merchandising_staff_user_second', 'merchandising_password_second'),
    ('inventory_staff_user_first', 'inventory_password_first'),
    ('inventory_staff_user_second', 'inventory_password_second');

CREATE TABLE
    departments(
        id INTEGER GENERATED ALWAYS AS IDENTITY ( START WITH 20001 INCREMENT 1 ) PRIMARY KEY,
        name VARCHAR(30) NOT NULL
);

INSERT INTO
    departments(name)
VALUES
    ('Supervisory');
INSERT INTO
    departments(name)
VALUES
    ('Merchandising');
INSERT INTO
    departments(name)
VALUES
    ('Inventory');

CREATE TABLE
    employees(
        id INTEGER GENERATED ALWAYS AS IDENTITY ( START WITH 10001 INCREMENT 1 ) PRIMARY KEY,
        staff_user_id INTEGER NOT NULL,
        is_active BOOLEAN DEFAULT TRUE,
        department_id INTEGER NOT NULL,
        first_name VARCHAR(30) NOT NULL,
        last_name VARCHAR(30) NOT NULL,
        email VARCHAR(30) NOT NULL,
        phone_number VARCHAR(20) NOT NULL,
        employed_at DATE,

        CONSTRAINT fk_employees_staff_users
            FOREIGN KEY (staff_user_id)
            REFERENCES staff_users(id)
            ON UPDATE CASCADE
            ON DELETE CASCADE,

        CONSTRAINT fk_employees_departments
             FOREIGN KEY (department_id)
             REFERENCES departments(id)
             ON UPDATE CASCADE
             ON DELETE CASCADE
);

INSERT INTO
    employees(staff_user_id, department_id, first_name, last_name, email, phone_number)
VALUES
    (1, 20001, 'Beatris', 'Ilieve', 'beatris@icloud.com', '000-000-000');
INSERT INTO
    employees(staff_user_id, department_id, first_name, last_name, email, phone_number)
VALUES
    (2, 20002, 'Terri', 'Aldersley', 'taldersley0@army.mil', '198-393-2278');
INSERT INTO
    employees(staff_user_id, department_id, first_name, last_name, email, phone_number)
VALUES
    (3, 20002, 'Rose', 'Obrey', 'r@obrey.net', '631-969-8114');
INSERT INTO
    employees(staff_user_id, department_id, first_name, last_name, email, phone_number)
VALUES
    (4, 20003,'Mariette', 'Caltera', 'mcaltera4@cpanel.net', '515-969-8114');
INSERT INTO
    employees(staff_user_id, department_id, first_name, last_name, email, phone_number)
VALUES
    (5, 20003, 'Elen', 'Williams', 'elen@ebay.com', '812-263-4473');

CREATE OR REPLACE FUNCTION
    credentials_authentication(
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(30),
        provided_staff_user_id CHAR(5)
)
RETURNS BOOLEAN
AS
$$
DECLARE
    id_as_integer INTEGER;
    is_authenticated BOOLEAN;
BEGIN
    id_as_integer := provided_staff_user_id::INTEGER;
    IF
        id_as_integer = (
            SELECT
                e.id
            FROM
                employees AS e
            JOIN
                staff_users
            ON
                e.staff_user_id = staff_users.id
            WHERE
                 staff_user_role = provided_staff_user_role
                        AND
                 staff_user_password = provided_staff_user_password
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
            u.staff_user_role
        FROM
            staff_users AS u
        JOIN
            employees AS e
        ON
            u.id = e.staff_user_id
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
        employee_id INTEGER,
        session_id INTEGER,
        jewelry_id INTEGER NOT NULL,
        quantity INTEGER DEFAULT 0,
        created_at TIMESTAMPTZ NOT NULL,
        updated_at TIMESTAMPTZ,
        deleted_at TIMESTAMPTZ,

        CONSTRAINT fk_inventory_employees
             FOREIGN KEY (employee_id)
             REFERENCES employees(id)
             ON UPDATE CASCADE
             ON DELETE SET NULL,

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
        date TIMESTAMPTZ,

        CONSTRAINT fk_inventory_records_inventory
                     FOREIGN KEY (inventory_id)
                     REFERENCES inventory(id)
                     ON UPDATE CASCADE
                     ON DELETE SET NULL
);

CREATE TABLE
    discounts(
        id SERIAL PRIMARY KEY,
        last_modified_by_emp_id CHAR(5) NOT NULL,
        jewelry_id INTEGER NOT NULL,
        percentage DECIMAL(3,2) NOT NULL,
        created_at TIMESTAMPTZ,
        updated_at TIMESTAMPTZ,
        deleted_at TIMESTAMPTZ,

        CONSTRAINT ck_discounts_percentage
             CHECK ( LEFT(CAST(percentage AS TEXT), 1) = '0' )
);

CREATE OR REPLACE PROCEDURE
    sp_insert_jewelry_into_jewelries(
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(9),
        provided_employee_id CHAR(5),
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
DECLARE
    current_jewelry_id INTEGER;

    access_denied CONSTANT TEXT :=
        'Access Denied: ' ||
        'You do not have the required authorization to perform actions into this department.';

    authorisation_failed CONSTANT TEXT :=
        'Authorization failed: Incorrect password';
BEGIN
    IF NOT (
        SELECT fn_role_authentication(
                    'merchandising', provided_employee_id
                )
        )
    THEN
        SELECT fn_raise_error_message(
            access_denied
            );
    END IF;

    IF (
        SELECT credentials_authentication(
            provided_staff_user_role,
            provided_staff_user_password,
            provided_employee_id)
        ) IS TRUE
    THEN
        INSERT INTO
            jewelries(
                      type_id, name, image_url,
                      regular_price, metal_color,
                      diamond_carat_weight,
                      diamond_clarity,
                      diamond_color,
                      description
                )
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
            inventory(
                      employee_id,
                      jewelry_id,
                      created_at,
                      updated_at,
                      deleted_at
                      )
        VALUES
            (
             provided_employee_id::INTEGER,
             current_jewelry_id,
             NOW(),
             NULL,
             NULL
             );
    ELSE
        SELECT fn_raise_error_message(authorisation_failed);
    END IF;
END;
$$
LANGUAGE plpgsql;

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

CREATE OR REPLACE PROCEDURE
    sp_add_quantity_into_inventory(
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(9),
        provided_employee_id CHAR(5),
        provided_session_id INTEGER,
        provided_jewelry_id INTEGER,
        added_quantity INTEGER
)
AS
$$
DECLARE
    access_denied CONSTANT TEXT := 'Access Denied: You do not have the required authorization to perform actions into this department.';
    authorisation_failed CONSTANT TEXT := 'Authorization failed: Incorrect password';
BEGIN
    IF
        provided_session_id IS NOT NULL
    THEN
        UPDATE
            inventory
        SET
            session_id = provided_session_id,
            quantity = quantity + added_quantity,
            updated_at = NOW()
        WHERE
            jewelry_id = provided_jewelry_id;
        UPDATE
            jewelries
        SET
            is_active = TRUE
        WHERE
            id = provided_jewelry_id;
    ELSE
        IF NOT(
            SELECT fn_role_authentication(
                        'inventory', provided_employee_id
                        )
            )
        THEN
            SELECT fn_raise_error_message(access_denied);
        END IF;
        IF(
            SELECT credentials_authentication(
                provided_staff_user_role,
                provided_staff_user_password,
                provided_employee_id)
            )IS TRUE
        THEN
            UPDATE
                inventory
            SET
                employee_id = provided_employee_id::INTEGER,
                quantity = quantity + added_quantity,
                updated_at = NOW()
            WHERE
                jewelry_id = provided_jewelry_id;
            UPDATE
                jewelries
            SET
                is_active = TRUE
            WHERE
                id = provided_jewelry_id;
        ELSE
            SELECT fn_raise_error_message(authorisation_failed);
        END IF;
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
        (OLD.id, operation_type, NOW());
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER
    tr_insert_new_entity_into_inventory_records_on_update
AFTER UPDATE ON
    inventory
FOR EACH ROW
EXECUTE FUNCTION
    trigger_fn_insert_new_entity_into_inventory_records_on_update();

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_first',
    'inventory_password_first',
    '10004',
    NULL,
    1,
    9);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_second',
    'inventory_password_second',
    '10005',
    NULL,
    2,
    7);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_first',
    'inventory_password_first',
    '10004',
    NULL,
    3,
    5);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_second',
    'inventory_password_second',
    '10005',
    NULL,
    4,
    3);

CREATE OR REPLACE PROCEDURE
    sp_insert_percent_into_discounts(
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(9),
        provided_last_modified_by_emp_id CHAR(5),
        provided_jewelry_id INTEGER,
        provided_percent DECIMAL(3,2)
)
AS
$$
DECLARE
    access_denied CONSTANT TEXT :=
        'Access Denied: ' ||
        'You do not have the required authorization to perform actions into this department.';

    authorisation_failed CONSTANT TEXT :=
        'Authorization failed: ' ||
        'Incorrect password';
BEGIN
    IF NOT(
        SELECT fn_role_authentication(
                    'merchandising', provided_last_modified_by_emp_id
                )
        )
    THEN
        SELECT fn_raise_error_message(
            access_denied
            );
    END IF;

    IF(
        SELECT credentials_authentication(
            provided_staff_user_role,
            provided_staff_user_password,
            provided_last_modified_by_emp_id
            )
        ) IS TRUE
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
                updated_at = NOW()
            WHERE
                jewelry_id = provided_jewelry_id;

        ELSE
            INSERT INTO
                discounts(
                          last_modified_by_emp_id,
                          jewelry_id,
                          percentage,
                          created_at,
                          updated_at,
                          deleted_at
                          )
            VALUES
                (
                 provided_last_modified_by_emp_id,
                 provided_jewelry_id,
                 provided_percent,
                 NOW(),
                 NULL,
                 NULL
                );
        END IF;

    ELSE
        SELECT fn_raise_error_message(
            authorisation_failed
            );
    END IF;
END;
$$
LANGUAGE plpgsql;

CALL sp_insert_percent_into_discounts(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    1,
    0.10);

CALL sp_insert_percent_into_discounts(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    2,
    0.10);

CREATE OR REPLACE PROCEDURE
    sp_remove_percent_from_discounts(
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(30),
        provided_last_modified_by_emp_id CHAR(5),
        provided_jewelry_id INTEGER
)
AS
$$
DECLARE
    access_denied CONSTANT TEXT :=
        'Access Denied: ' ||
        'You do not have the required authorization to perform actions into this department.';

    authorisation_failed CONSTANT TEXT :=
        'Authorization failed: ' ||
        'Incorrect password';
BEGIN
    IF NOT(
        SELECT fn_role_authentication(
                'merchandising',
                provided_last_modified_by_emp_id
                    )
        )
    THEN
        SELECT fn_raise_error_message(
            access_denied
            );
    END IF;

    IF(
        SELECT credentials_authentication(
    provided_staff_user_role,
    provided_staff_user_password,
    provided_last_modified_by_emp_id)
        )IS TRUE
    THEN
        UPDATE
            jewelries
        SET
            discount_price = NULL
        WHERE
            id = provided_jewelry_id;
        UPDATE
            discounts
        SET
            deleted_at = NOW()
        WHERE
            jewelry_id = provided_jewelry_id;

    ELSE
        SELECT fn_raise_error_message(
            authorisation_failed
            );
    END IF;
END;
$$
LANGUAGE plpgsql;

CALL sp_remove_percent_from_discounts(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    2);

CREATE TABLE
    shopping_cart(
        id SERIAL PRIMARY KEY,
        session_id INTEGER NOT NULL ,
        jewelry_id INTEGER NOT NULL,
        quantity INTEGER DEFAULT 0,

        CONSTRAINT ck_shopping_cart_quantity
            CHECK ( quantity >= 0 ),


        CONSTRAINT fk_shopping_cart_sessions
                    FOREIGN KEY (session_id)
                    REFERENCES sessions(id)
                    ON UPDATE CASCADE
                    ON DELETE SET NULL,

        CONSTRAINT fk_shopping_cart_jewelries
                    FOREIGN KEY (jewelry_id)
                    REFERENCES jewelries(id)
                    ON UPDATE CASCADE
                    ON DELETE CASCADE
);

CREATE TABLE payment_providers(
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

INSERT INTO payment_providers (name) VALUES
    ('PayPal'),
    ('Amazon Pay'),
    ('Stripe');

CREATE TABLE
    orders(
        id INTEGER NOT NULL PRIMARY KEY,
        shopping_cart_id INTEGER,
        payment_provider_id INTEGER NOT NULL,
        total_amount DECIMAL(8, 2) NOT NULL,
        is_completed BOOLEAN DEFAULT FALSE,

        CONSTRAINT fk_orders_shopping_cart_id
                    FOREIGN KEY (shopping_cart_id)
                    REFERENCES shopping_cart(id)
                    ON UPDATE RESTRICT
                    ON DELETE RESTRICT ,

        CONSTRAINT fk_orders_payment_providers
                    FOREIGN KEY (payment_provider_id)
                    REFERENCES payment_providers(id)
                    ON UPDATE RESTRICT
                    ON DELETE RESTRICT
);

CREATE OR REPLACE FUNCTION
    fn_check_session_has_expired(
        provided_session_id INTEGER
)
RETURNS BOOLEAN
AS
$$
DECLARE
    old_expiration_time TIMESTAMPTZ;
BEGIN
    old_expiration_time := (
        SELECT
            expiration_time
        FROM
            sessions
        WHERE
            id = provided_session_id
        );
    IF
        NOW() >= old_expiration_time
    THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE
    sp_add_to_shopping_cart(
        provided_session_id INTEGER,
        provided_jewelry_id INTEGER,
        provided_quantity INTEGER
    )
AS
$$
DECLARE
    session_has_expired CONSTANT TEXT :=
        'Your shopping session has expired. ' ||
        'To continue shopping, please log in again.';

    item_has_been_sold_out CONSTANT TEXT :=
        'This item has been sold out.';

    current_quantity INTEGER;

    not_enough_quantity CONSTANT TEXT :=
        'Not enough quantity';

BEGIN
    current_quantity := (
        SELECT
            quantity
        FROM
            inventory
        WHERE
            jewelry_id = provided_jewelry_id
        );

    IF (
        SELECT fn_check_session_has_expired(
            provided_session_id
            )
        ) IS TRUE
    THEN
        SELECT
            fn_raise_error_message(
                session_has_expired
                );

    ELSIF (
        SELECT
            is_active
        FROM
            jewelries
        WHERE
            id = provided_jewelry_id
        ) IS FALSE
    THEN
        SELECT fn_raise_error_message(
            item_has_been_sold_out
            );

    ELSIF
        current_quantity < provided_quantity
    THEN
        SELECT fn_raise_error_message(
            not_enough_quantity
            );

    ELSE
        IF provided_jewelry_id IN (
            SELECT
                jewelry_id
            FROM
                shopping_cart
            WHERE
                session_id = provided_session_id
            )
        THEN
            UPDATE
                shopping_cart
            SET
                quantity = quantity + provided_quantity
            WHERE
                jewelry_id = provided_jewelry_id;

        ELSE
            INSERT INTO
                shopping_cart(
                              session_id,
                              jewelry_id,
                              quantity
                              )
            VALUES
                (provided_session_id,
                 provided_jewelry_id,
                 provided_quantity
                 );
        END IF;

        CALL sp_remove_quantity_from_inventory(
            provided_session_id,
            provided_jewelry_id,
            provided_quantity,
            current_quantity
            );
    END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE
    sp_remove_quantity_from_inventory(
        in_session_id INTEGER,
        in_jewelry_id INTEGER,
        requested_quantity INTEGER,
        current_quantity INTEGER
)
AS
$$
BEGIN
    UPDATE
        inventory
    SET
        quantity = quantity - requested_quantity,
        session_id = in_session_id,
        deleted_at = NOW()
    WHERE
        jewelry_id = in_jewelry_id;
    IF
        current_quantity - requested_quantity = 0
    THEN
        UPDATE
            jewelries
        SET
            is_active = FALSE
        WHERE
            id = in_jewelry_id;
    END IF;
END;
$$
LANGUAGE plpgsql;


CALL sp_add_to_shopping_cart(
    1,
    3,
    5
);

CALL sp_add_to_shopping_cart(
    1,
    1,
    3
);

CALL sp_login_user(
    'beatris@icloud.com',
    '#6hhhhh');

CREATE OR REPLACE PROCEDURE
    sp_remove_from_shopping_cart(
        provided_session_id INTEGER,
        provided_jewelry_id INTEGER,
        provided_quantity INTEGER
    )
AS
$$
DECLARE
    session_has_expired CONSTANT TEXT :=
        'Your shopping session has expired. ' ||
        'To continue shopping, please log in again.';

BEGIN
    IF (
        SELECT fn_check_session_has_expired(
            provided_session_id
            )
        ) IS TRUE
    THEN
        SELECT
            fn_raise_error_message(
                session_has_expired
                );
    ELSE
        CALL sp_return_back_quantity_to_inventory(
            provided_session_id,
            provided_jewelry_id,
            provided_quantity
            );
    END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE
    sp_return_back_quantity_to_inventory(
        in_session_id INTEGER,
        in_jewelry_id INTEGER,
        requested_quantity INTEGER
)
AS
$$
BEGIN
    UPDATE
        inventory
    SET
        session_id = in_session_id,
        quantity = quantity + requested_quantity,
        updated_at = NOW()
    WHERE
        jewelry_id = in_jewelry_id;
    IF(
        SELECT
            is_active
        FROM
            jewelries
        WHERE
            id = in_jewelry_id
        ) IS FALSE
    THEN
        UPDATE
            jewelries
        SET
            is_active = TRUE
        WHERE
            id = in_jewelry_id;
    END IF;
    UPDATE
        shopping_cart
    SET
        quantity = quantity - requested_quantity
    WHERE
        jewelry_id = in_jewelry_id;
END;
$$
LANGUAGE plpgsql;

CALL sp_remove_from_shopping_cart(
    1,
    3,
    4
);

CREATE TABLE
    transactions(
        id SERIAL PRIMARY KEY,
        order_id INTEGER,
        amount DECIMAL (8, 2),
        date TIMESTAMPTZ,

        CONSTRAINT fk_transactions_orders
                FOREIGN KEY (order_id)
                REFERENCES orders(id)
                ON UPDATE RESTRICT
                ON DELETE RESTRICT
);

CREATE OR REPLACE PROCEDURE
    sp_complete_order(
        provided_session_id INTEGER,
        provided_first_name VARCHAR(30),
        provided_last_name VARCHAR(30),
        provided_phone_number VARCHAR(20),
        provided_current_balance DECIMAL(8, 2),
        provided_payment_provider VARCHAR(100)
)
AS
$$
DECLARE
    provider_not_supported CONSTANT TEXT :=
        'Payment provider not available. ' ||
        'Please choose "PayPal", "Amazon Pay" or "Stripe" and try again.' ;

    current_total_amount DECIMAL(8, 2);

    provided_customer_id INTEGER;

    current_payment_provider_id INTEGER;
BEGIN
    IF
        provided_payment_provider NOT IN (
        SELECT
            name
        FROM
            payment_providers
        )
    THEN
        SELECT fn_raise_error_message(provider_not_supported);
    END IF;

    current_payment_provider_id := (
        SELECT
            id
        FROM
            payment_providers
        WHERE
            name = provided_payment_provider
        );

    provided_customer_id := (
            SELECT
                cd.id
            FROM
                customer_details AS cd
            JOIN
                customer_users AS cu
            ON
                cd.customer_user_id = cu.id
            JOIN
                sessions AS s
            ON
                cu.id = s.customer_id
            WHERE
                s.id = provided_session_id
            );

    UPDATE
        customer_details
    SET
        first_name = provided_first_name,
        last_name = provided_last_name,
        phone_number = provided_phone_number,
        current_balance = provided_current_balance,
        payment_provider = provided_payment_provider
    WHERE
        id = provided_customer_id;

    current_total_amount := (
        SELECT
            SUM((CASE
                WHEN j.discount_price IS NULL THEN j.regular_price
                ELSE j.discount_price
            END) * sc.quantity)
        FROM
            jewelries AS j
        JOIN
            shopping_cart AS sc
        ON
            j.id = sc.jewelry_id
        JOIN
            sessions AS s
        ON
            sc.session_id = s.id
        WHERE
            s.id = provided_session_id
        );

    INSERT INTO orders
        (id, shopping_cart_id, payment_provider_id, total_amount)
    VALUES
        (provided_session_id, provided_session_id, current_payment_provider_id, current_total_amount);

    CALL sp_transfer_money(
        provided_session_id,
        provided_customer_id,
        provided_current_balance,
        current_total_amount);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE
    sp_transfer_money(
        in_session_id INTEGER,
        provided_customer_id INTEGER,
        available_balance DECIMAL(8, 2),
        needed_balance DECIMAL(8, 2)
)
AS
$$
DECLARE
    insufficient_balance CONSTANT TEXT :=
        ('Insufficient balance to complete the transaction. ' ||
         'Needed amount: %', needed_balance);
BEGIN
    IF
        (available_balance - needed_balance) < 0
    THEN
        SELECT fn_raise_error_message(
            insufficient_balance
            );

    ELSE
        UPDATE
            customer_details
        SET
            current_balance = current_balance - needed_balance
        WHERE
            id = provided_customer_id;

            UPDATE
                orders
            SET
                is_completed = True
            WHERE
                id = in_session_id;


            INSERT INTO
                transactions(
                             order_id,
                             amount,
                             date
                             )
            VALUES
                (
                 in_session_id,
                 needed_balance,
                 NOW()
                );

    END IF;
END;
$$
LANGUAGE plpgsql;


CALL sp_complete_order(
    1,
    'Beatris',
    'Ilieve',
    '000000000',
    100000.00,
    'PayPal'
);

SELECT fn_register_user('welch@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(2, 2, 3);
CALL sp_complete_order(
    2,
    'Welch',
    'Gorries',
    '711-704-9768',
    39556.55,
    'Amazon Pay'
);

SELECT fn_register_user('kellie@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(3, 4, 1);
CALL sp_complete_order(
    3,
    'Kellie',
    'Minihane',
    '231-204-9598',
    73205.18,
    'PayPal'
);


SELECT fn_register_user('flora@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(4, 2, 3);
CALL sp_complete_order(
    4,
    'Flora',
    'Keating',
    '203-679-4950',
    52205.18,
    'Stripe'
);

CREATE OR REPLACE FUNCTION
    fn_show_most_sold_jewelry_type(
        provided_employee_id CHAR(5),
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(30)
)
RETURNS TABLE(
            type VARCHAR(10),
            quantity BIGINT
        )
AS
$$
DECLARE
    access_denied CONSTANT TEXT :=
        'Access Denied: ' ||
        'You do not have the required authorization to perform actions into this department.';

    authorisation_failed CONSTANT TEXT :=
        'Authorization failed: Incorrect password';
BEGIN
    IF NOT (
        SELECT fn_role_authentication(
                    'super', provided_employee_id
                )
        )
    THEN
        SELECT fn_raise_error_message(
            access_denied
            );
    ELSIF (
        SELECT credentials_authentication(
        provided_staff_user_role,
        provided_staff_user_password,
        provided_employee_id)
        )IS TRUE
    THEN

        RETURN QUERY
        SELECT
            jewelry_type,
            MAX(sold_quantity)
        FROM (
            SELECT
                t.name AS jewelry_type,
                SUM(sc.quantity) AS sold_quantity
            FROM
                shopping_cart AS sc
            JOIN
                jewelries AS j
            ON
                sc.jewelry_id = j.id
            JOIN
                types AS t
            ON
                j.type_id = t.id
            GROUP BY
                t.name
             ) AS favourite_item
        GROUP BY
            jewelry_type
        ORDER BY
            MAX(sold_quantity) DESC
        LIMIT 1;
    ELSE
        SELECT fn_raise_error_message(
            authorisation_failed
            );
    END IF;
END;
$$
LANGUAGE plpgsql;

SELECT fn_show_most_sold_jewelry_type(
    '10001',
    'super_staff_user',
    'super_staff_user_password');

