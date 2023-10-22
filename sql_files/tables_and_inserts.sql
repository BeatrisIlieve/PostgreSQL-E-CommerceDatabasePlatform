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
