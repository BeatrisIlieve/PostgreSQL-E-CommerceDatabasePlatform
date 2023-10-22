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