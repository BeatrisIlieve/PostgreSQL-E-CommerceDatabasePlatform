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




CREATE EXTENSION IF NOT EXISTS pgcrypto;


CREATE OR REPLACE FUNCTION
    trigger_fn_register_user(
    provided_email VARCHAR(30),
    provided_password VARCHAR(15),
    provided_verifying_password VARCHAR(15)
)
RETURNS VOID
AS
$$
DECLARE
    email_already_in_use CONSTANT TEXT :=
        'This email address is already in use. Please use a different email address or try logging in with your existing account.';
    password_not_secure CONSTANT TEXT :=
        'The password should contain at least one special character and at least one digit. Please make sure you enter a secure password.';
    passwords_do_not_match CONSTANT TEXT :=
        'The password and password verification do not match. Please make sure that both fields contain the same password.';
    hashed_password VARCHAR;
BEGIN
    IF
        provided_email IN (
        SELECT
            email
        FROM
            customer_users
        )
    THEN
        SELECT
            fn_raise_error_message(email_already_in_use);
    ELSIF
        provided_password NOT SIMILAR TO '%[!\"#$%&\''()*+,-./:;<=>?@\\[\\]^_`{|}~]%'
    THEN
        SELECT
            fn_raise_error_message(password_not_secure);
    ELSIF
        provided_password NOT LIKE provided_verifying_password
    THEN
        SELECT
            fn_raise_error_message(passwords_do_not_match);
    ELSE
        hashed_password := crypt(provided_password, gen_salt('bf'));

        INSERT INTO
            customer_users(email, password, created_at, updated_at, deleted_at)
        VALUES ( provided_email, hashed_password , DATE(NOW()), NULL, NULL);
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
    INSERT INTO
        customer_details(customer_user_id, first_name, last_name, phone_number)
    VALUES
        (NEW.id, NULL, NULL, NULL);
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


CREATE OR REPLACE FUNCTION
    fn_login_user(
    provided_email VARCHAR(30),
    provided_password VARCHAR(15)
)
RETURNS BOOLEAN
AS
$$
DECLARE
    credentials_not_correct CONSTANT TEXT := 'The email or password you entered is incorrect. Please check your email and password, and try again.';
    is_authenticated BOOLEAN;
BEGIN
    IF NOT provided_email AND provided_password IN (
        SELECT
            email,
            password
        FROM
            customer_users
        )
    THEN
        SELECT fn_raise_error_message(credentials_not_correct);
    ELSE
        CALL sp_generate_session_token((
                SELECT
                    id
                FROM
                    customer_users
                WHERE
                    email = provided_email
                            AND
                    password = provided_password
                           )
                   );
    END IF;
RETURN is_authenticated;
END;
$$
LANGUAGE plpgsql;



CREATE OR REPLACE PROCEDURE
    sp_generate_session_token(
    customer_id INTEGER
)
AS
$$
DECLARE
    session_data JSONB;
    expiration_time TIMESTAMPTZ;
BEGIN
    session_data := jsonb_build_object(
        'customer_id', customer_id,
        'created_at', NOW()
    );
    expiration_time := NOW() + INTERVAL '1 HOUR';
    INSERT INTO
        sessions(customer_id, session_data, expiration_time)
    VALUES
        (customer_id, session_data, expiration_time);
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE
    sp_add_to_shopping_cart(provided_session_id INTEGER, provided_jewelry_id INTEGER, provided_quantity INTEGER)
AS
$$
DECLARE
    session_has_expired CONSTANT TEXT := 'Your shopping session has expired. To continue shopping, please log in again.';
    item_has_been_sold_out CONSTANT TEXT := 'This item has been sold out.';
BEGIN
    IF NOT (
        SELECT
            expiration_time
        FROM
            sessions
        ) < NOW()
    THEN
        SELECT
            fn_raise_error_message(session_has_expired);
    ELSIF (
        SELECT
            is_active
        FROM
            jewelries
        WHERE
            id= provided_jewelry_id
        ) IS FALSE
    THEN
        SELECT fn_raise_error_message(item_has_been_sold_out);
    ELSE
        CALL sp_remove_quantity_from_inventory(provided_session_id, provided_jewelry_id, provided_quantity)
    END IF;
END;
$$
LANGUAGE plpgsql;




CREATE OR REPLACE PROCEDURE
    sp_remove_quantity_from_inventory(
        in_session_id CHAR(5),
        in_jewelry_id INTEGER,
        requested_quantity INTEGER
)
AS
$$
DECLARE
    current_quantity INTEGER;
    not_enough_quantity CONSTANT TEXT := ('There are only % left.', current_quantity);
BEGIN
    current_quantity := (
        SELECT
            quantity
        FROM
            inventory
        WHERE
            jewelry_id = in_jewelry_id
        );
    IF
        current_quantity < requested_quantity
    THEN
        CALL fn_raise_error_message(not_enough_quantity);
    ELSE
        UPDATE
            inventory
        SET
            employee_or_session_id = in_session_id,
            quantity = quantity - requested_quantity,
            deleted_at = DATE(NOW())
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
    END IF;
END;
$$
LANGUAGE plpgsql;



CREATE OR REPLACE PROCEDURE
    sp_complete_order()



CREATE TABLE
    customer_users(
        id SERIAL PRIMARY KEY NOT NULL,
        email VARCHAR(30) UNIQUE NOT NULL,
        password VARCHAR(15) NOT NULL,
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

        CONSTRAINT fk_customers_details_customer_users
                     FOREIGN KEY (customer_user_id)
                     REFERENCES customer_users(id)
                     ON UPDATE CASCADE
                     ON DELETE CASCADE
);

CREATE TABLE
    orders(
        id SERIAL PRIMARY KEY,
        is_active BOOLEAN NOT NULL,
        created_at TIMESTAMPTZ NOT NULL,
        updated_at TIMESTAMPTZ NOT NULL,
        deleted_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE payment_providers(
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

INSERT INTO payment_providers (name) VALUES
    ('PayPal'),
    ('Amazon Pay'),
    ('Stripe');

CREATE TABLE sessions(
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    session_data JSONB NOT NULL,
    expiration_time TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_sessions_customer_users
                     FOREIGN KEY (customer_id)
                     REFERENCES customer_users
                     ON UPDATE CASCADE
                     ON DELETE CASCADE
);

CREATE TABLE
    shopping_cart(
        id SERIAL PRIMARY KEY,
        session_id INTEGER NOT NULL,
        jewelry_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,

        CONSTRAINT ck_shopping_cart_quantity
            CHECK ( quantity > 0 ),


        CONSTRAINT fk_shopping_cart_sessions
                    FOREIGN KEY (session_id)
                    REFERENCES sessions(id)
                    ON UPDATE CASCADE
                    ON DELETE CASCADE,

        CONSTRAINT fk_shopping_cart_jewelries
                    FOREIGN KEY (jewelry_id)
                    REFERENCES jewelries(id)
                    ON UPDATE CASCADE
                    ON DELETE CASCADE
);


CREATE TABLE
    orders_details(
        order_id INTEGER NOT NULL,
        shopping_cart_id INTEGER NOT NULL,
        payment_provider_id INTEGER NOT NULL,
        total_amount DECIMAL(8, 2) NOT NULL,

        CONSTRAINT pk_orders_details
                    PRIMARY KEY (order_id, shopping_cart_id, payment_provider_id),
        CONSTRAINT fk_orders_details_orders
                    FOREIGN KEY (order_id)
                    REFERENCES orders(id)
                    ON UPDATE CASCADE
                    ON DELETE CASCADE,
        CONSTRAINT fk_orders_details_shopping_cart
                    FOREIGN KEY (shopping_cart_id)
                    REFERENCES shopping_cart(id)
                    ON UPDATE CASCADE
                    ON DELETE CASCADE,
        CONSTRAINT fk_orders_details_payment_providers
                    FOREIGN KEY (payment_provider_id)
                    REFERENCES payment_providers(id)
                    ON UPDATE CASCADE
                    ON DELETE CASCADE
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
    ('receiving_inventory_staff_user_first', 'receiving_inventory_password_first'),
    ('receiving_inventory_staff_user_second', 'receiving_inventory_password_second'),
    ('issuing_inventory_staff_user_first', 'issuing_inventory_password_first'),
    ('issuing_inventory_staff_user_second', 'issuing_inventory_password_second');

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
        staff_user_id INTEGER NOT NULL,
        is_active BOOLEAN DEFAULT TRUE,
        department_id INTEGER NOT NULL,
        first_name VARCHAR(30) NOT NULL,
        last_name VARCHAR(30) NOT NULL,
        email VARCHAR(30) NOT NULL,
        phone_number VARCHAR(20) NOT NULL,
        employed_at DATE DEFAULT DATE(NOW()),

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

insert into employees (staff_user_id, department_id, first_name, last_name, email, phone_number) values (1, 20001, 'Beatris', 'Ilieve', 'beatris@icloud.com', '000-000-000');
insert into employees (staff_user_id, department_id, first_name, last_name, email, phone_number) values (2, 20002, 'Terri', 'Aldersley', 'taldersley0@army.mil', '198-393-2278');
insert into employees (staff_user_id, department_id, first_name, last_name, email, phone_number) values (3, 20002, 'PerrY', 'Oldersley', 'poldersley0@army.mil', '231-393-2278');
insert into employees (staff_user_id, department_id, first_name, last_name, email, phone_number) values (4, 20003, 'Rose', 'Obrey', 'r@obrey.net', '631-969-8114');
insert into employees (staff_user_id, department_id, first_name, last_name, email, phone_number) values (5, 20003,'Mariette', 'Caltera', 'mcaltera4@cpanel.net', '515-969-8114');
insert into employees (staff_user_id, department_id, first_name, last_name, email, phone_number) values (6, 20004, 'Elen', 'Williams', 'elen@ebay.com', '812-263-4473');
insert into employees (staff_user_id, department_id, first_name, last_name, email, phone_number) values (7, 20004, 'Nicky', 'Attewill', 'nattewill5@ebay.com', '342-225-4473');


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
        employee_or_session_id INTEGER NOT NULL,
        jewelry_id INTEGER NOT NULL,
        quantity INTEGER DEFAULT 0,
        created_at TIMESTAMPTZ NOT NULL,
        updated_at TIMESTAMPTZ,
        deleted_at TIMESTAMPTZ,

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
            provided_staff_user_role,
            provided_staff_user_password,
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
            inventory(user_id, jewelry_id, created_at, updated_at, deleted_at)
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
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(9),
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
            provided_staff_user_role,
            provided_staff_user_password,
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


-- CREATE OR REPLACE PROCEDURE
--     sp_remove_quantity_from_inventory(
--         provided_staff_user_role VARCHAR(30),
--         provided_staff_user_password VARCHAR(9),
--         provided_last_modified_by_emp_id CHAR(5),
--         provided_jewelry_id INTEGER,
--         requested_quantity INTEGER
-- )
-- AS
-- $$
-- DECLARE
--     current_quantity INTEGER;
-- BEGIN
--     IF NOT
--         (SELECT fn_role_authentication(
--                     'issuing_inventory', provided_last_modified_by_emp_id
--                     ))
--     THEN
--         RAISE EXCEPTION 'Access Denied: You do not have the required authorization to perform actions into this department.';
--     END IF;
--         IF
--         (SELECT credentials_authentication(
--             provided_staff_user_role,
--             provided_staff_user_password,
--             provided_last_modified_by_emp_id)) IS TRUE
--     THEN
--         current_quantity := (
--             SELECT
--                 quantity
--             FROM
--                 inventory
--             WHERE
--                 jewelry_id = provided_jewelry_id
--             );
--         CASE
--             WHEN current_quantity >= requested_quantity THEN
--                 UPDATE
--                     inventory
--                 SET
--                     last_modified_by_emp_id = provided_last_modified_by_emp_id::INTEGER,
--                     quantity = quantity - requested_quantity,
--                     deleted_at = DATE(NOW())
--                 WHERE
--                     jewelry_id = provided_jewelry_id;
--             IF current_quantity - requested_quantity = 0 THEN
--                     UPDATE
--                         jewelries
--                     SET
--                         is_active = FALSE
--                     WHERE
--                         id = provided_jewelry_id;
--             END IF;
--         ELSE
--             RAISE NOTICE 'Not enough quantity. AVAILABLE ONLY: %', current_quantity;
--         END CASE;
--     ELSE
--         RAISE EXCEPTION 'Authorization failed: Incorrect password';
--     END IF;
-- END;
-- $$
-- LANGUAGE plpgsql;


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
    tr_insert_new_entity_into_inventory_records_on_update
AFTER UPDATE ON
    inventory
FOR EACH ROW
EXECUTE FUNCTION trigger_fn_insert_new_entity_into_inventory_records_on_update();


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
        (NEW.id,  operation_type, DATE(NOW()));
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER
    tr_insert_new_entity_into_inventory_records_on_create
AFTER INSERT ON
    inventory
FOR EACH ROW
EXECUTE FUNCTION trigger_fn_insert_new_entity_into_inventory_records_on_create();


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
            provided_staff_user_role,
            provided_staff_user_password,
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
                updated_at = DATE(NOW())
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

CREATE OR REPLACE PROCEDURE
    sp_remove_percent_from_discounts(
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(9),
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
            provided_staff_user_role,
            provided_staff_user_password,
            provided_last_modified_by_emp_id)) IS TRUE
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
            deleted_at = DATE(NOW())
        WHERE
            jewelry_id = provided_jewelry_id;
    ELSE
        RAISE EXCEPTION 'Authorization failed: Incorrect password';
    END IF;
END;
$$
LANGUAGE plpgsql;


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

CALL sp_add_quantity_into_inventory('receiving_inventory_staff_user_first', 'receiving_inventory_password_first', '10004', 1, 100);

CALL sp_remove_quantity_from_inventory('issuing_inventory_staff_user_first', 'issuing_inventory_password_first', '10006', 1, 90);

CALL sp_insert_percent_into_discounts('merchandising_staff_user_first', 'merchandising_password_first', '10002', 1, 0.20);

CALL sp_remove_percent_from_discounts('merchandising_staff_user_first', 'merchandising_password_first', '10002', 1);



CREATE OR REPLACE FUNCTION
    trigger_fn_is_item_sold_out(
        staff_user_role VARCHAR(50),
        staff_user_password VARCHAR(50),
        provided_super_staff_user_id CHAR(5),
        is_item_sold_out BOOLEAN
)
RETURNS TABLE(
    type_id INTEGER,
    name VARCHAR(100),
    regular_price DECIMAL(7, 2)
)
AS
$$
BEGIN
    IF NOT
        (SELECT fn_role_authentication(
                    'super', provided_super_staff_user_id
                    ))
    THEN
        RAISE EXCEPTION 'Access Denied: You do not have the required authorization to perform actions into this department.';
    END IF;

    RETURN QUERY
    SELECT
        j.type_id,
        j.name,
        j.regular_price
    FROM
        jewelries AS j
    WHERE
        j.is_active = is_item_sold_out;
END;
$$
LANGUAGE plpgsql;

SELECT trigger_fn_is_item_sold_out('super_staff_user', 'super_staff_user_password', '10001')




