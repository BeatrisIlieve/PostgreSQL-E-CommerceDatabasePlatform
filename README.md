# PostgreSQL-E-Commerce-Database-Platform

## Entity Relationship Diagram:
![Diagram](https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/82eb2acf-a104-46b1-bbda-d8ca7573cffc)


#### We have also simulated customer user registration. Customers credentials are also kept in the databsase. We have seperated their accounts into two tables - one for their login details - Email and Password, and another one for their personal information - that is obligatory for a putchase to be made so as to proceed with payment and delivery.
#### Furthermore, we created process similiar to bank transfer verifying that a customer has enough balance to process a transaction with the total cost of their order.
### We have created process similiar to generating cookie tokens using JSON format

#### We have used the <ins>SHA-256</ins> hash encription for storing customer users passwords in the database:
```plpgsql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```
#### Customer accounts are seperated into two tables connected through Foreign Key - one for their login details - <ins>Email and Password</ins>:
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
### Session token is saved in 'sessions' table:
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
#### The token expires one hour after the trigger register, respectively login function has been selected:
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
<img width="1043" alt="Screenshot 2023-10-19 at 19 20 45" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/26f87f45-af7c-458e-b1b9-eda7b956ea53">
<img width="1080" alt="Screenshot 2023-10-19 at 19 21 55" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/c1c04b7d-a322-4d29-b6f1-46ad18efe379">
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

