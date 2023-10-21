# <p align="center">PostgreSQL-E-Commerce-Database-Platform</p>

## <p align="center">Entity Relationship Diagram:</p>
![Diagram](https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/82eb2acf-a104-46b1-bbda-d8ca7573cffc)

### <p align="center"> The current project represents a relational database management system designed to support the architecture of an online store specializing in diamond jewelry. However, we believe it can be applied to a wide range of business ideas. In this document, we provide explanations and examples for every part of the code. 
### The provided input data is intended solely for demonstration and testing purposes, facilitating the evaluation and verification of the code's functionality. </p>

#### Furthermore, we created process similiar to bank transfer verifying that a customer has enough balance to process a transaction with the total cost of their order.
### We have created process similiar to generating cookie tokens using JSON format

#### We have used the <ins>SHA-256</ins> hash encription for storing customer users passwords in the database:
```plpgsql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```
#### Customer accounts are seperated into two tables related through" Foreign Key - one for their login details - <ins>Email and Password</ins>:
```plpgsql
CREATE TABLE
    customer_users(
        id SERIAL PRIMARY KEY NOT NULL,
        email VARCHAR(30) UNIQUE NOT NULL,
        password VARCHAR(100) NOT NULL,
        created_at DATE NOT NULL,
        updated_at DATE,
        deleted_at DATE
);
```
#### And another one for their <ins>Personal Information</ins> - which is obligatory for a putchase to be made so as to proceed with payment and delivery:
```plpgsql
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
```
#### We have isolated the error-raising logic in a separate function:
```plpgsql
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
```
#### We have simulated user registration process that inludes providing <ins>Unique</ins> email as a username and a <ins>Secure Confirmed Password</ins> inserted into into the 'customer_users' table:
```plpgsql
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
            (provided_email, hashed_password , DATE(NOW()), NULL, NULL);

        CALL sp_login_user(provided_email, provided_password);
    END IF;
END;
$$
LANGUAGE plpgsql;
```
#### The Trigger function below executes inserting the created <ins>Customer ID</ins> into 'custumers_details' table:
```plpgsql
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
```
#### The next Procedure takes care of <ins>Automatically logging-in</ins> customers who have just completed the registration process. It also calls Procedure that simulates generating <ins>Cookie Tokens</ins> using <ins>JSON format</ins>:
```plpgsql
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
```
#### Session token is saved in 'sessions' table:
```plpgsql
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
```
#### The token expires one hour after the trigger register, respectively login function, has been selected:
```plpgsql
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
```
#### The following line is doing the magic so we can see the result below:
```plpgsql
SELECT fn_register_user(
    'beatris@icloud.com',
    '#6hhhhh',
    '#6hhhhh'
);
```
##### If we try to enter a password which does not contain at least one special character and one digit:
<img width="917" alt="Screenshot 2023-10-19 at 19 11 22" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/a842a763-0c50-4e90-b17a-361103d73033">

##### If passwords do not match:
<img width="836" alt="Screenshot 2023-10-19 at 19 15 05" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/fb43824a-de63-49a5-9aec-4357f1fda683">

##### If email is already taken:
<img width="833" alt="Screenshot 2023-10-19 at 19 17 41" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/b37dedd0-0566-448d-adaa-215577e6efef">

##### When registration is successfully completed (null values are allowed here, because the fields are obligatory upon order confirmation):

##### 'customer_users' table:
<img width="1043" alt="Screenshot 2023-10-19 at 19 20 45" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/26f87f45-af7c-458e-b1b9-eda7b956ea53">

##### 'customer_details' table:
<img width="1080" alt="Screenshot 2023-10-19 at 19 21 55" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/c1c04b7d-a322-4d29-b6f1-46ad18efe379">

##### 'sessions' table:
<img width="1029" alt="Screenshot 2023-10-19 at 19 22 56" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/9dc59408-8924-452a-a3c5-ad1a71b9dd1a">

#### For the Demo purposes of this project we have created two departments - 'Merchandising' and 'Inventory'. We simulated having Super User and Regular Users, having specific roles at the departments they belong to. They authenticate themselves via username and password kept in the database:
```plpgsql
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
```
##### Users:
<img width="657" alt="Screenshot 2023-10-19 at 19 37 38" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/ec1a85a3-152a-417a-b370-66851b704ceb">

##### Departments:
<img width="220" alt="Screenshot 2023-10-19 at 19 38 19" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/1e277c50-1d1f-433c-873a-3f2324bce56b">

#### Next we have created 'employees' table and related the staff to the respective departments:
```plpgsql
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
```
##### Employees:
<img width="1229" alt="Screenshot 2023-10-19 at 19 48 24" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/832a2aed-065e-4e46-9718-fca833a30c9a">

#### Afterwards, we authenticate employees by their password, username and ID and we also check if the employee is ACTIVE (if he/she is still employeed at the store):
```plpgsql
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
```
#### Next step is to verify if the provided employee ID corresponds to the respective authorised department:
```plpgsql
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
```
#### We proceed with creating tables that will contain information about the type of jewelries we sell as well as the jewelries themselves (the 'jewelries' table stays empty for now since later on the devoted employees would insert the items by their own):
```plpgsql
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
```
##### 'types' table:

<img width="174" alt="Screenshot 2023-10-19 at 20 13 39" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/b042a250-eb0b-464e-b811-7ec1751b073a">

#### The 'inventory' table serves to keep information about either ID of an employee who modified the state of a specific jewelry or a shopping session ID, and certainly it stores information about the available quantities:
```plpgsql
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
```
#### Furthermore, 'inventory_records' table shows all events that occured on inventory with their corresponding acctions - create, update, delete and their dates:
```plpgsql
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
```
#### Similiarly to 'inventory' the 'discounts' table shows the percentage, the jewelry ID and the ID of the employee who inserted it:
```plpgsql
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
```
#### The next procedure is responsible for inserting items into the 'jewelries' table after authenticating a user belonging to the 'Merchandising' department:
```plpgsql
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
```
#### Let us test the <ins>staff authentication process</ins> by inserting an item into the 'jewelries' table. For that purpose we will need to provide a <ins>username</ins>, <ins>password</ins>, <ins>employee id</ins> and item characteristics:
```plpgsql
CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10004',
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
```
##### From the tables above, we can see that every employee ID is retated to a 'staff_users' table with his/her credentials. So if we enter correct credentials but they do NOT correspond to employee ID (10004 that is related to the 'Inventory' and not Merchandising) passed to the 'sp_insert_jewelry_into_jewelries' procedure, we will get the following error message:
<img width="727" alt="Screenshot 2023-10-20 at 13 30 15" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/ed92c365-48b9-4e56-90f9-3a749c6b9055">

##### Let us insert an earring into the 'jelelries' table using correct credentions, correct ID, meaning that it belongs to the devoted department, however the ID is assigned to another employee:
```plpgsql
CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_second',
    'merchandising_password_second',
    '10002',
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
```
<img width="1005" alt="Screenshot 2023-10-20 at 13 46 39" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/988c88a8-1168-4e7a-b42b-af45d6c01101">

##### Wrong password or username:
```plpgsql
CALL sp_insert_jewelry_into_jewelries(
    '_staff_user_first',
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
```
<img width="1001" alt="Screenshot 2023-10-20 at 13 48 44" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/d0cf29e0-78e0-44b4-8d1c-73e0edf859ae">

##### Correct input ('sp_insert_jewelry_into_jewelries' should be executed after 'trigger_fn_insert_new_entity_into_inventory_records_on_create', presented down below, has been created in order to observe the correct flow of the demo):
```plpgsql
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
```
##### 'trigger_fn_insert_new_entity_into_inventory_records_on_create' serves to automatically add records when an insert operation occurs on the 'inventory' table proceeded by inserting on the 'jewelries' one:
```plpgsql
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
```
##### 'jewerly' table (the 'is_active' field is 'false' because no quantity has been added yet):
<img width="1328" alt="Screenshot 2023-10-20 at 15 59 03" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/55a4fdc0-bbef-4321-a15f-8e6b1d3f4c48">

##### 'inventory' table (the 'session_id' field is needed in the cases when a customer is adding to or removing from their shopping cart which we will create later on):
<img width="1171" alt="Screenshot 2023-10-20 at 16 00 07" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/0072fd2b-91e1-4b25-a510-7d3e3d304f5c">

##### 'inventory_records' table that keeps information about every single <ins>create</ins>, <ins>update</ins> or <ins>delete</ins> operation on 'inventory' table:
<img width="736" alt="Screenshot 2023-10-20 at 15 59 42" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/fca895f6-e7a7-43db-940d-2fe4ae9ed825">


#### After the items has been inserted, the Inventory department needs to declare available quantities. For that purpose, credentials and employee id must be passed to the next procedure :
```plpgsql
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
```
#### As the name suggests, the next trigger function serves to insert records into inventory on <ins>update</> and <ins>delete</ins>:
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
##### 'jewerly' table:
<img width="1322" alt="Screenshot 2023-10-20 at 16 27 23" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/36ccd7b6-f607-4232-8656-d86d474566af">

##### 'inventory' table:
<img width="1286" alt="Screenshot 2023-10-20 at 16 27 46" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/43d118c0-f101-460e-b347-39a3b8f80d70">

##### 'inventory_records' table :
<img width="740" alt="Screenshot 2023-10-20 at 16 28 06" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/f26b1e80-e695-471f-860f-9aac0892a6a5">

#### We are able to insert discount percetanges using the procedure in the subsequent section:
```plpgsql
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
```
#### The 'discounts' table is related to the 'jewelries' table so after we insert a percantage we can notice 'discount_price' in the latter:
```plpgsql
CALL sp_insert_percent_into_discounts(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    1,
    0.10
);

CALL sp_insert_percent_into_discounts(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    2,
    0.10);
```
##### 'jewelries' table:
<img width="1275" alt="Screenshot 2023-10-20 at 16 58 05" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/9801abea-1700-4abd-bea2-8320af8c112b">

#### To return back to regular price of an item we use the procedure down below:
```plpgsql
CREATE OR REPLACE PROCEDURE
    sp_remove_percent_from_discounts(
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(9),
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
            deleted_at = DATE(NOW())
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
```
#### We delete the discount applied to the item with ID 2:
```plpgsql
CALL sp_remove_percent_from_discounts(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    2
);
```
##### The discount is deleted and the jewelry 'discount_price' is set back to Null:

##### 'discounts' table:
<img width="1260" alt="Screenshot 2023-10-20 at 17 10 43" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/db2bb9c9-2176-4e85-9467-1a8fd325070d">

##### 'jewelries' table:
<img width="1317" alt="Screenshot 2023-10-20 at 17 11 19" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/6bfc3d8f-9509-493d-af36-fb5bcf024e50">

#### The 'shopping_cart' table is related to the 'sessions' and 'jewelries' ones:
```plpgsql
CREATE TABLE
    shopping_cart(
        id SERIAL PRIMARY KEY,
        session_id INTEGER DEFAULT NULL,
        jewelry_id INTEGER DEFAULT NULL,
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
```
#### For the demo pusposes of this project, we have added three random payment providers in our database:
```plpgsql
CREATE TABLE payment_providers(
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

INSERT INTO payment_providers (name) VALUES
    ('PayPal'),
    ('Amazon Pay'),
    ('Stripe');
```
#### What connects the 'shopping_cart' and 'payment_providers' is the 'orders' table:
```plpgsql
CREATE TABLE
    orders(
        id SERIAL PRIMARY KEY,
        shopping_cart_id INTEGER,
        payment_provider_id INTEGER NOT NULL,
        total_amount DECIMAL(8, 2) NOT NULL,
        is_completed BOOLEAN DEFAULT FALSE,

        CONSTRAINT fk_orders_shopping_cart
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
```
#### 'transactions' table is related to 'orders':
```plpgsql
CREATE TABLE
    transactions(
        id SERIAL PRIMARY KEY,
        order_id INTEGER,
        amount DECIMAL (8, 2),

        CONSTRAINT fk_transactions_orders
                FOREIGN KEY (order_id)
                REFERENCES orders(id)
                ON UPDATE RESTRICT
                ON DELETE RESTRICT
);
```
#### In order to proceed with actual shopping activities, we need to create a function that checks if the shopping session has exprired, which will be called from the procedures later on:
```plpgsql
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
```
#### The procedure 'sp_add_to_shopping_cart' performs a few checks:
```plpgsql
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
```
#### We call the procedure with 'sessiond_id', so as to be able to authenticate the current customer, and we also provide the item ID and desired quantity:
```plpgsql
CALL sp_add_to_shopping_cart(
    1,
    1,
    2
);

CALL sp_add_to_shopping_cart(
    1,
    1,
    1
);
```
1. If the shopping session has expired:
<img width="603" alt="Screenshot 2023-10-20 at 18 18 48" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/3d48ac52-4c89-4313-9efb-9f7f7e71869a">

##### Now we can login and call sp_add_to_shopping_cart as above (the password we enter is hashed again and compared with the hashed password kept in the databse):
```plpgsql
CALL sp_login_user(
    'beatris@icloud.com',
    '#6hhhhh');
```

2. The procedure checks if there is any available quantity of the given item;
##### For example, if we add to our shopping cart 4 pieces of item with ID 3 (that initially had 4 pieces available), we will get the following result:
<img width="551" alt="Screenshot 2023-10-20 at 18 53 41" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/18a5b31d-8691-4f12-8783-814878b0c92b">

<img width="837" alt="Screenshot 2023-10-20 at 18 54 17" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/59f5fc32-ef86-4fdf-b670-04d72879e933">

<img width="1253" alt="Screenshot 2023-10-20 at 18 51 59" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/307ed593-34a5-4209-90aa-74dae3c17229">

##### If we try to get one more of the same item:
<img width="552" alt="Screenshot 2023-10-20 at 18 58 16" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/b98c1afd-dff5-4563-999d-9bd4f99f2902">

3. The procedure checks if is enough available quantity:
##### If we try to get 10 items of jewelry with ID 10 (available only 9):
<img width="541" alt="Screenshot 2023-10-20 at 19 13 34" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/eb652fb0-25f1-4964-a4c6-7e1d0fe1b38f">

4. If the all checks passes, and the given item ID has not already been inserted into the 'shopping_cart' table, it is being inserted, otherwise the quantity is just being increased;
<img width="542" alt="Screenshot 2023-10-20 at 19 20 59" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/498e57f2-2401-4010-a10e-0f31968231a5">

<img width="544" alt="Screenshot 2023-10-20 at 19 21 38" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/a3c62c25-0353-4359-9bc9-c2d93100593f">

#### Afterwards, another procedure is being called that reduces the quantities in the 'inventories' table (also sets the files 'is_active' to FALSE if the quantity reaches 0 as we saw above):
```plpgsql
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
```
#### In order to remove an item from the shopping cart, we select the procedure 'sp_remove_from_shopping_cart' that executes the usual checks, and then invokes the  'sp_return_back_quantity_to_inventory':
```plpgsql
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
```
Updates the quantities both in the shopping cart and inventory:
```plpgsql
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
```
#### Let us remove 4 pieces of item with ID 3 (we currently have 5 pieces added into the shopping cart). Here, we need to provided session ID, as well as jewelry ID and quantity:
```plpgsql
CALL sp_remove_from_shopping_cart(
    1,
    3,
    4
);
```
##### `shopping_cart' table:
<img width="542" alt="Screenshot 2023-10-21 at 16 08 56" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/9a95a5d0-b4f7-401b-88cd-525f10e4f77d">

##### 'inventory' table
<img width="1010" alt="Screenshot 2023-10-21 at 16 10 33" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/b8acf016-9b31-4aa7-a4a6-1ca36163ac1d">

##### 'inventory_records' table:
<img width="749" alt="Screenshot 2023-10-21 at 16 10 59" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/08124a35-6f1b-447e-b5c2-3648f26100ed">

#### The final steps are to complete the order and store information about the money transaction. Firstly, we need to create a `transactions' table:
```plpgsql
CREATE TABLE
    transactions(
        id SERIAL PRIMARY KEY,
        order_id INTEGER,
        amount DECIMAL (8, 2),

        CONSTRAINT fk_transactions_orders
                FOREIGN KEY (order_id)
                REFERENCES orders(id)
                ON UPDATE RESTRICT
                ON DELETE RESTRICT
);
```
#### For the pusposes of the project, a customer needs to declare a payment provider name, also must insert their personal details, and most importantly - available balance, so we can check if the transfer could be procedeed. After the 'sp_complete_order' procedure is called, it will calculate the total amount, taking into consideration if the product has a discount price or not, it will then select the 'sp_transfer_money' procedure:
```plpgsql
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
        (session_id, payment_provider_id, total_amount)
    VALUES
        (provided_session_id, current_payment_provider_id, current_total_amount);

    CALL sp_transfer_money(
        provided_customer_id, 
        provided_current_balance, 
        current_total_amount);
END;
$$
LANGUAGE plpgsql;
```
#### In case of insufficient balance, an error would be raised. Otherwise, data would be inserted into the 'transactions' and 'orders' tables:
```plpgsql
CREATE OR REPLACE PROCEDURE
    sp_transfer_money(
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

    current_order_id INTEGER;
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

        current_order_id :=(
            SELECT
                o.id
            FROM
                orders AS o
            JOIN
                sessions AS s
            ON
                o.session_id = s.id
            WHERE
                s.customer_id = provided_customer_id
                        AND
                o.is_completed = FALSE
            );

            UPDATE
                orders
            SET
                is_completed = True
            WHERE
                id = current_order_id;


            INSERT INTO
                transactions(
                             order_id,
                             amount,
                             date
                             )
            VALUES
                (
                 current_order_id,
                 needed_balance,
                 NOW()
                );

                UPDATE
                    shopping_cart
                SET
                    quantity = 0,
                    jewelry_id = NULL,
                    session_id = NULL
                WHERE
                    session_id = (
                        SELECT
                            s.id
                        FROM
                            sessions AS s
                        JOIN
                            customer_users AS cu
                        ON
                            s.customer_id = cu.id
                        WHERE
                            cu.id = provided_customer_id
                        );
    END IF;
END;
$$
LANGUAGE plpgsql;
```
#### Let us complete the order:
```plpgsql
CALL sp_complete_order(
    1,
    'Beatris',
    'Ilieve',
    '000000000',
    100000.00,
    'PayPal'
);
```
##### 'customer_details' table:
<img width="1017" alt="Screenshot 2023-10-21 at 17 55 39" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/a29b6b5f-6b0a-4ea7-8a12-5412e9c33747">

##### 'orders' table:
<img width="839" alt="Screenshot 2023-10-21 at 17 56 02" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/6a74168a-d834-4488-a279-76bcf00852ad">

##### 'transactions' table:
<img width="675" alt="Screenshot 2023-10-21 at 17 56 31" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/efa007ce-c4f9-4b2b-9275-aefe637af88e">

#### Finally we will create a few 'Views', to which the Superuser would be having an access to, so as to check <ins>of what type are the most sold jewelries and what is the total sum of transactions made to pay for those</ins>. To create a better image, it would be good to register a few customers, add to their shopping carts, and complete orders:
```plpgsql
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
CALL sp_add_to_shopping_cart(3, 3, 1);
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
```


