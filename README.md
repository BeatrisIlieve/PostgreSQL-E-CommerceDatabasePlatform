# <p align="center">*PostgreSQL-E-Commerce-Database-Platform*</p>
### <p align="center">*The current project represents a relational database management system designed to support the architecture of an online store specializing in diamonds and gold jewelry. However, we believe it can be applied to a wide range of business ideas.*</p> 
## <p align="center">*Entity Relationship Diagram:*</p>

![ERD](https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/cd1c690c-8c9e-447b-9154-1241727d75a6)

### <p align="center">*In this document, we provide explanations and examples for every part of the script. For improved organization, we have segmented the functionality related to data insertion into distinct files and provided links to them. For the best experience, it's recommended to open these links in a new tab by right-clicking and selecting 'Open link in new tab' (or your browser's equivalent option).*</p> 

#### We have used the <ins>SHA-256</ins> hash encription for storing customer users passwords in the database:
```plpgsql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```
#### Customer accounts are seperated into two tables related through Foreign Key. The first one stores their login credentials - <ins>Email and Password</ins>:
```plpgsql
CREATE TABLE
    customer_users(
        id SERIAL PRIMARY KEY NOT NULL,
        email VARCHAR(30) UNIQUE NOT NULL,
        password VARCHAR(100) NOT NULL,
        created_at DATE NOT NULL
);
```
#### We have established tables `countries` and `cities`, to store the names of the most European countries and their corresponding biggest cities. The `countries_cities` table serves as a mapper, and it is instrumental in collecting customer delivery addresses when orders are placed:
```plpgsql
CREATE TABLE countries(
    id SERIAL PRIMARY KEY,
    name VARCHAR(30) UNIQUE NOT NULL
);
```
#### To showcase data from different tables, we will utilize the following SQL query with minor adaptations tailored to each specific table as needed. It's important to note that the displayed data will represent a subset of the entire dataset, as it helps us manage the length of the displayed information:

```plpgsql
SELECT 
    *
FROM
    countries
WHERE 
    id >= 1 AND id <= 3
UNION
SELECT 
    *
FROM 
    countries
WHERE 
    id >= 10 AND id <= 13
UNION
SELECT 
    *
FROM 
    countries
WHERE 
    id >= 20 AND id <= 23
UNION
SELECT 
    *
FROM 
    countries
WHERE 
    id >= 30 AND id <= 33
UNION
SELECT 
    *
FROM 
    countries
WHERE 
    id >= 40 AND id <= 43
ORDER BY 
    id;
```

[Link to Insert Values File](insert_values_files/insert_into_countries.sql)

<img width="241" alt="Screenshot 2023-10-26 at 22 52 20" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/4bf867a4-8b2a-4228-afcd-502b3e245d01">

```plpgsql
CREATE TABLE cities(
    id SERIAL PRIMARY KEY,
    name VARCHAR(30) UNIQUE  NOT NULL
);
```
[Link to Insert Values File](insert_values_files/insert_into_cities.sql)

<img width="263" alt="Screenshot 2023-10-27 at 7 31 29" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/99c1d72c-c1ca-447f-974e-06a99b7c8a72">

```plpgsql
CREATE TABLE
    countries_cities(
        id SERIAL PRIMARY KEY,
        country_id INTEGER NOT NULL,
        city_id INTEGER NOT NULL,

        CONSTRAINT fk_countries_cities_countries
                    FOREIGN KEY (country_id)
                    REFERENCES countries(id)
                    ON UPDATE CASCADE
                    ON DELETE CASCADE,

        CONSTRAINT fk_countries_cities_cities
                    FOREIGN KEY (city_id)
                    REFERENCES cities(id)
                    ON UPDATE CASCADE
                    ON DELETE CASCADE
);
```
[Link to Insert Values File](insert_values_files/insert_into_countries_cities.sql)

<img width="386" alt="Screenshot 2023-10-27 at 7 35 44" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/7a8d38b3-8b75-4898-8da3-b9f60bb4c754">

#### The second table associated with customers keeps their <ins>Personal Information</ins> - which is obligatory for a putchase to be made so as to proceed with payment and delivery:
```plpgsql
CREATE TABLE
    customer_details(
        id SERIAL PRIMARY KEY,
        customer_user_id INTEGER NOT NULL,
        first_name VARCHAR(30),
        last_name VARCHAR(30),
        phone_number VARCHAR(20),
        countries_cities_id INTEGER,
        address VARCHAR(200),
        current_balance DECIMAL(8, 2),
        payment_provider VARCHAR(100),

        CONSTRAINT fk_customers_details_customer_users
                     FOREIGN KEY (customer_user_id)
                     REFERENCES customer_users(id)
                     ON UPDATE CASCADE
                     ON DELETE CASCADE,

        CONSTRAINT fk_customer_details_countries_cities
                    FOREIGN KEY (countries_cities_id)
                    REFERENCES countries_cities(id)
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
#### We have simulated user registration process that inludes providing <ins>Unique Email</ins>  as a username and a <ins>Secure Confirmed Password</ins>. The data is stored into the `customer_users` table. Users who have just completed the registration process are <ins>Automatically logged-in</ins>:
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

    password_does_not_contain_special_character CONSTANT TEXT :=
        'The password must contain at least one special character. ' ||
        'Please make sure you enter a secure password.';

    password_does_not_contain_digit CONSTANT TEXT :=
        'The password must contain at least one digit. ' ||
        'Please make sure you enter a secure password.';

    password_too_short CONSTANT TEXT :=
        'The password must be at least 8 characters long.' ||
        'Please make sure you enter a secure password.';

    passwords_do_not_match CONSTANT TEXT :=
        'The password and password verification do not match. ' ||
        'Please make sure that both fields contain the same password.';

    hashed_password VARCHAR;

    special_characters CONSTANT TEXT :=
        '[!#$%&()*+,-./:;<=>?@^_`{|}~]';

    digits CONSTANT TEXT :=
        '[0-9]';

    min_password_length CONSTANT INTEGER :=
        8;

BEGIN
    IF provided_email IN (
            SELECT
                email
            FROM
                customer_users
            )
    THEN
        SELECT
            fn_raise_error_message(
                email_already_in_use
                );

    ELSIF
        NOT provided_password ~ special_characters
    THEN
        SELECT
            fn_raise_error_message(
                    password_does_not_contain_special_character
                    );
    ELSIF
        NOT provided_password ~ digits
    THEN
        SELECT
            fn_raise_error_message(
                    password_does_not_contain_digit
                    );

    ELSIF
        LENGTH(provided_password) < min_password_length
    THEN
        SELECT
            fn_raise_error_message(
                    password_too_short
                    );

    ELSIF
        provided_password NOT LIKE provided_verifying_password
    THEN
        SELECT
            fn_raise_error_message(
                    passwords_do_not_match
                );

    ELSE
        hashed_password := ENCODE(
            DIGEST(
                provided_password, 'sha256'
                ), 'hex'
            );

        INSERT INTO customer_users
            (
             email,
             password,
             created_at
             )
        VALUES
            (
             provided_email,
             hashed_password ,
             NOW()
             );

        CALL sp_login_user(
                provided_email,
                provided_password
            );

    END IF;
END;
$$
LANGUAGE plpgsql;
```
#### The Trigger function below executes inserting the created <ins>Customer ID</ins> into `custumers_details` table:
```plpgsql
CREATE OR REPLACE FUNCTION
    trigger_fn_insert_id_into_customer_details()
RETURNS TRIGGER
AS
$$
BEGIN
    INSERT INTO
        customer_details(
            customer_user_id
         )
    VALUES
        (
         NEW.id
         );
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
#### The `sp_login_user` calls another procedure that simulates generating <ins>Cookie Tokens</ins> using <ins>JSON format</ins>:
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

    hashed_password VARCHAR(100);

    user_id INTEGER;
BEGIN
    hashed_password := ENCODE(
        DIGEST(
            provided_password, 'sha256'
            ), 'hex'
        );

    user_id := (
            SELECT
                id
            FROM
                customer_users
            WHERE
                email= provided_email
                        AND
                password = hashed_password
        );

    IF
        user_id IS NULL
    THEN
        SELECT fn_raise_error_message(credentials_not_correct);

    ELSE
        CALL sp_generate_session_token(
                user_id
        );
    END IF;
END;
$$
LANGUAGE plpgsql;
```
#### Session token is being saved in `sessions` table:
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
            sessions(
                     customer_id,
                     is_active,
                     session_data,
                     expiration_time
                     )
        VALUES
            (
             current_customer_id,
             TRUE,
             current_session_data,
             current_expiration_time
             );

    END IF;
END;
$$
LANGUAGE plpgsql;
```
#### Now, we are going to <ins>Test</ins> the registration process:
##### If we try to register with a password which does not contain at least one special character:
<img width="775" alt="Screenshot 2023-10-27 at 11 02 50" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/0f271256-3403-4161-9646-8ca4eda61795">

##### If the password does not contain at least one digit:
<img width="696" alt="Screenshot 2023-10-27 at 11 39 44" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/fa48b03b-55d9-419b-983d-696d9d43f9e5">

##### If the password is not at least 8 characters long:
<img width="715" alt="Screenshot 2023-10-27 at 11 40 56" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/4c0c79fe-09c8-476f-84df-a4a0d887c422">

##### If passwords do not match:
<img width="843" alt="Screenshot 2023-10-27 at 11 43 51" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/bc53f81e-0eea-421b-830c-844c076456b5">

##### If email is already taken:
<img width="834" alt="Screenshot 2023-10-27 at 11 46 54" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/f205c94f-e550-4c09-b446-bc55a5cf9812">

##### When registration is successfully completed :

##### `customer_users` table:
<img width="1065" alt="Screenshot 2023-10-27 at 11 52 58" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/43867079-ed9f-45f1-9d25-df081aeb19da">

##### `customer_details` table (null values are allowed here, because the fields are obligatory upon order completion):
<img width="1337" alt="Screenshot 2023-10-27 at 11 53 50" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/4600d660-cc9e-4eac-b91d-702c3f94e3c8">

##### `sessions` table:
<img width="1022" alt="Screenshot 2023-10-27 at 11 56 27" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/1bae2c66-abf1-44f3-a34d-9fc8813a2e46">

#### For the Demo purposes of the project we have created two departments - 'Merchandising' and 'Inventory'. We simulated having Super User and Regular Users, having specific roles at the departments they belong to. They authenticate themselves via username and password kept in the database:
```plpgsql
CREATE TABLE
    staff_users(
        id SERIAL PRIMARY KEY,
        staff_user_role VARCHAR(50) NOT NULL,
        staff_user_password VARCHAR(50) NOT NULL
);
```
[Link to Insert Values File](insert_values_files/insert_into_staff_users.sql)

##### `staff_users`:
<img width="657" alt="Screenshot 2023-10-19 at 19 37 38" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/ec1a85a3-152a-417a-b370-66851b704ceb">

```plpgsql
CREATE TABLE
    departments(
        id INTEGER GENERATED ALWAYS AS IDENTITY ( START WITH 20001 INCREMENT 1 ) PRIMARY KEY,
        name VARCHAR(30) NOT NULL
);
```
[Link to Insert Values File](insert_values_files/insert_into_departments.sql)

##### `departments`:
<img width="220" alt="Screenshot 2023-10-19 at 19 38 19" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/1e277c50-1d1f-433c-873a-3f2324bce56b">

#### Next we have created `employees` table and related the staff to the respective departments:
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
```
[Link to Insert Values File](insert_values_files/insert_into_employees.sql)
##### `employees`:
<img width="1244" alt="Screenshot 2023-10-27 at 12 18 14" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/6fdd7cdb-e3e1-4c12-bfaf-5c190ca51051">

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
#### In order not to repeat data, we have created seperate tables to store common jewelries characteristics:
```plpgsql
CREATE TABLE
    jewelry_type(
        id SERIAL PRIMARY KEY,
        name VARCHAR(30) NOT NULL
);
```
[Link to Insert Values File](insert_values_files/insert_into_jewelry_type.sql)

`jewelry_type`:

<img width="196" alt="Screenshot 2023-10-27 at 12 29 08" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/af727233-7b43-4139-9f30-10e5c81e8aa8">

```plpgsql
CREATE TABLE
    jewelry_name(
        id SERIAL PRIMARY KEY,
        name VARCHAR(100)
);
```
[Link to Insert Values File](insert_values_files/insert_into_jewelry_name.sql)

`jewelry_name`:

<img width="608" alt="Screenshot 2023-10-27 at 12 31 06" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/60e60b6b-74b0-46bc-974c-21b8df21b6cd">

```plpgsql
CREATE TABLE
    gold_color(
        id SERIAL PRIMARY KEY,
        color VARCHAR(15)
);
```
[Link to Insert Values File](insert_values_files/insert_into_gold_color.sql)

`gold_color`:

<img width="212" alt="Screenshot 2023-10-27 at 12 33 35" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/e7f4947f-d315-442b-9613-dce2765683d7">

```plpgsql
CREATE TABLE
    diamond_color(
        id SERIAL PRIMARY KEY,
        color VARCHAR(15)
);
```
[Link to Insert Values File](insert_values_files/insert_into_diamond_color.sql)

`diamond_color`:

<img width="203" alt="Screenshot 2023-10-27 at 12 35 11" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/3436647b-cdb9-4308-982c-9039ee14cf0c">

```plpgsql
CREATE TABLE
    diamond_carat_weight(
        id SERIAL PRIMARY KEY,
        weight VARCHAR(15)
);
```
[Link to Insert Values File](insert_values_files/insert_into_diamond_weight.sql)

`diamond_carat_weight`:

<img width="215" alt="Screenshot 2023-10-27 at 12 37 14" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/d6cae2c7-5f4c-4d0d-a842-3e24f26cda15">

```plpgsql
CREATE TABLE
    diamond_clarity(
        id SERIAL PRIMARY KEY,
        clarity VARCHAR(15)
);
```
[Link to Insert Values File](insert_values_files/insert_into_diamond_clarity.sql)

`diamond_clarity`:

<img width="222" alt="Screenshot 2023-10-27 at 12 38 16" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/7a82dee2-b794-40b6-84f5-a5d0f06ee00e">

```plpgsql
CREATE TABLE
    description(
        id SERIAL PRIMARY KEY,
        description TEXT
);
```

[Link to Insert Values File](insert_values_files/insert_into_description.sql)

`description`:

<img width="1053" alt="Screenshot 2023-10-27 at 12 39 52" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/d79fdbdc-7552-4a28-928a-504167ee308f">

#### We proceed with creating the `jewelries` table that contains the respective <ins>Foreign Keys</ins> as well as regular and discount prices (it stays empty for now since later on the devoted employees would insert the values by their own):
```plpgsql
CREATE TABLE
    jewelries(
        id INTEGER NOT NULL,
        regular_price DECIMAL(7, 2) NOT NULL,
        discount_price DECIMAL(7, 2),
        type_id INTEGER NOT NULL,
        name_id INTEGER NOT NULL,
        img_url VARCHAR(200) NOT NULL,
        gold_color_id INTEGER NOT NULL,
        diamond_color_id INTEGER NOT NULL,
        diamond_carat_weight_id INTEGER NOT NULL,
        diamond_clarity_id INTEGER NOT NULL,
        description_id INTEGER NOT NULL,

        CONSTRAINT pk_jewelries_gold_color
            PRIMARY KEY (id, gold_color_id),

        CONSTRAINT fk_jewelries_jewelry_type
             FOREIGN KEY (type_id)
             REFERENCES jewelry_type(id)
             ON UPDATE CASCADE
             ON DELETE CASCADE,

        CONSTRAINT fk_jewelries_jewelry_name
             FOREIGN KEY (name_id)
             REFERENCES jewelry_name(id)
             ON UPDATE CASCADE
             ON DELETE CASCADE,

        CONSTRAINT fk_jewelries_jewelry_metal_color
             FOREIGN KEY (gold_color_id)
             REFERENCES gold_color(id)
             ON UPDATE CASCADE
             ON DELETE CASCADE,

        CONSTRAINT fk_jewelries_jewelry_diamond_carat
             FOREIGN KEY (diamond_carat_weight_id)
             REFERENCES diamond_carat_weight(id)
             ON UPDATE CASCADE
             ON DELETE CASCADE,

        CONSTRAINT fk_jewelries_jewelry_diamond_clarity
             FOREIGN KEY (diamond_clarity_id)
             REFERENCES diamond_clarity(id)
             ON UPDATE CASCADE
             ON DELETE CASCADE,

        CONSTRAINT fk_jewelries_jewelry_diamond_color
             FOREIGN KEY (diamond_color_id)
             REFERENCES diamond_color(id)
             ON UPDATE CASCADE
             ON DELETE CASCADE,

        CONSTRAINT fk_jewelries_jewelry_description
             FOREIGN KEY (description_id)
             REFERENCES description(id)
             ON UPDATE CASCADE
             ON DELETE CASCADE
);
```

#### The `inventory` table tracks employee modifications on jewelry items and stores quantity information. It is related to the `jewelries` and `gold_color` tables, representing availability in three different metal colors:
```plpgsql
CREATE TABLE
    inventory(
        id SERIAL PRIMARY KEY,
        jewelry_id INTEGER NOT NULL,
        color_id INTEGER NOT NULL,
        merchandising_emp_id INTEGER,
        inventory_emp_id INTEGER,
        quantity INTEGER DEFAULT 0,
        created_at TIMESTAMPTZ,
        updated_at TIMESTAMPTZ,
        deleted_at TIMESTAMPTZ,

        CONSTRAINT fk_inventory_jewelries
                FOREIGN KEY (jewelry_id, color_id)
                REFERENCES jewelries(id, gold_color_id)
                ON UPDATE CASCADE
                ON DELETE CASCADE,

        CONSTRAINT fk_inventory_records_employees_merchandising
             FOREIGN KEY (merchandising_emp_id)
             REFERENCES employees(id)
             ON UPDATE CASCADE
             ON DELETE SET NULL,

        CONSTRAINT fk_inventory_records_employees_inventory
             FOREIGN KEY (inventory_emp_id)
             REFERENCES employees(id)
             ON UPDATE CASCADE
             ON DELETE SET NULL
);
```

#### The next procedure is responsible for inserting items into the `jewelries` table after authenticating a staff user belonging to the 'Merchandising' department. It also adds the item to the `inventory` table, with default quantity of 0 as well as the ID of the employee:
```plpgsql
CREATE OR REPLACE PROCEDURE
    sp_insert_jewelry_into_jewelries(
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(9),
        provided_employee_id CHAR(5),
        provided_jewelry_id INTEGER,
        provided_type_id INTEGER,
        provided_name_id INTEGER,
        provided_img_url VARCHAR(200),
        provided_regular_price DECIMAL(7, 2),
        provided_metal_color_id INTEGER,
        provided_diamond_carat_weight_id INTEGER,
        provided_diamond_clarity_id INTEGER,
        provided_diamond_color_id INTEGER,
        provided_description_id INTEGER
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
                id,
                type_id,
                name_id,
                img_url,
                regular_price,
                gold_color_id,
                diamond_carat_weight_id,
                diamond_clarity_id,
                diamond_color_id,
                description_id
                )
        VALUES
            (
            provided_jewelry_id,
            provided_type_id,
            provided_name_id,
            provided_img_url,
            provided_regular_price,
            provided_metal_color_id,
            provided_diamond_carat_weight_id,
            provided_diamond_clarity_id,
            provided_diamond_color_id,
            provided_description_id
            );

        current_jewelry_id := (
            SELECT
                MAX(id)
            FROM
                jewelries
        );

        INSERT INTO
            inventory(
                  jewelry_id,
                  color_id,
                  merchandising_emp_id,
                  created_at
                      )
        VALUES
            (
             current_jewelry_id,
             provided_metal_color_id,
             provided_employee_id::INTEGER,
             NOW()
             );
    ELSE
        SELECT fn_raise_error_message(authorisation_failed);
    END IF;
END;
$$
LANGUAGE plpgsql;
```
#### Let us test the <ins>staff authentication process</ins> by inserting items into the 'jewelries' table. For that purpose we will need to provide a <ins>username</ins>, <ins>password</ins>, <ins>employee id</ins> and item information:

##### From the tables above, we can see that every employee ID is retated to a 'staff_users' table with his/her credentials. So if we enter correct credentials but they do NOT correspond to employee ID (10004 that is related to the 'Inventory' and not Merchandising) passed to the `sp_insert_jewelry_into_jewelries` procedure, we will get the following error message:

<img width="1135" alt="Screenshot 2023-10-27 at 13 19 50" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/841ec100-01f9-46ba-8f2c-49e10817adea">

##### If we use correct credentials, correct ID, meaning that it belongs to the devoted department, however the ID is assigned to another employee:

<img width="1135" alt="Screenshot 2023-10-27 at 13 22 44" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/ada2e432-684d-489e-a813-12078346c1b8">

##### Wrong password or username:

<img width="1132" alt="Screenshot 2023-10-27 at 13 25 32" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/9b3724ff-d37b-4aec-88ca-bec4ea2b2b52">

#### When staff credentials are correct the `jewelries` and `inventory` tables look like this:

[Link to Insert Values File](insert_values_files/insert_into_jewelries.sql)

`jewelries` table:

<img width="1378" alt="Screenshot 2023-10-27 at 13 09 39" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/08d47d82-4f66-4c07-8c7c-27737ec3fa98">

`inventory` table:

<img width="1385" alt="Screenshot 2023-10-27 at 13 38 16" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/1164b897-e408-49e2-83af-b027f794ac15">

#### After the items has been inserted, the Inventory department needs to declare available quantities. For that purpose, credentials and employee id must be passed to the next procedure :
```plpgsql
CREATE OR REPLACE PROCEDURE
    sp_add_quantity_into_inventory(
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(9),
        provided_employee_id CHAR(5),
        provided_session_id INTEGER,
        provided_jewelry_id INTEGER,
        provided_color_id INTEGER,
        added_quantity INTEGER
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
    IF
        provided_session_id IS NULL
    THEN
        IF NOT (
            SELECT fn_role_authentication(
                        'inventory', provided_employee_id
                        )
            )
        THEN
            SELECT fn_raise_error_message(access_denied);
        END IF;

        IF NOT (
            SELECT credentials_authentication(
                provided_staff_user_role,
                provided_staff_user_password,
                provided_employee_id)
            )
        THEN
            SELECT fn_raise_error_message(authorisation_failed);
        END IF;

        UPDATE
            inventory
        SET
            inventory_emp_id = provided_employee_id::INTEGER,
            updated_at = NOW()
        WHERE
            jewelry_id = provided_jewelry_id
                    AND
            color_id = provided_color_id;

    END IF;

    UPDATE
        inventory
    SET
        quantity = quantity + added_quantity,
        deleted_at = NULL
    WHERE
        jewelry_id = provided_jewelry_id
                AND
        color_id = provided_color_id;
END;
$$
LANGUAGE plpgsql;
```

[Link to Insert Values File](insert_values_files/insert_into_inventory.sql)

<img width="1387" alt="Screenshot 2023-10-27 at 13 45 39" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/cf5ad6f9-7541-4e62-be7b-0fbea6d10593">

#### Similiarly to `inventory` the `discounts` table, stores the jewelry ID, the ID of the employee who inserted it and of course the percentage:
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

#### We are able to insert discount percetanges using the procedure in the subsequent section:
```plpgsql
CREATE OR REPLACE PROCEDURE
    sp_insert_percent_into_discounts(
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(9),
        provided_last_modified_by_emp_id CHAR(5),
        provided_jewelry_id INTEGER,
        provided_color_id INTEGER,
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
    IF NOT (
        SELECT fn_role_authentication(
                    'merchandising', provided_last_modified_by_emp_id
                )
        )
    THEN
        SELECT fn_raise_error_message(
            access_denied
            );
    END IF;

    IF NOT (
        SELECT credentials_authentication(
            provided_staff_user_role,
            provided_staff_user_password,
            provided_last_modified_by_emp_id
            )
        )
    THEN
        SELECT fn_raise_error_message(
            authorisation_failed
            );
    ELSE
        IF (
            SELECT
                discount_price
            FROM
                jewelries
            WHERE
                id = provided_jewelry_id
                        AND
                gold_color_id = provided_color_id
               ) IS NOT NULL
        THEN
            UPDATE
                discounts
            SET
                percentage = provided_percent,
                updated_at = NOW()
            WHERE
                jewelry_id = provided_jewelry_id
                        AND
                color_id = provided_color_id;

        ELSE
            INSERT INTO
                discounts(
                    last_modified_by_emp_id,
                    jewelry_id,
                    color_id,
                    percentage,
                    created_at,
                    updated_at,
                    deleted_at
                          )
            VALUES
                (
                 provided_last_modified_by_emp_id::INTEGER,
                 provided_jewelry_id,
                 provided_color_id,
                 provided_percent,
                 NOW(),
                 NULL,
                 NULL
                );
        END IF;

        UPDATE
            jewelries
        SET
            discount_price = regular_price - (regular_price * provided_percent)
        WHERE
            id = provided_jewelry_id
                    AND
            gold_color_id = provided_color_id;
    END IF;
END;
$$
LANGUAGE plpgsql;
```
#### The `discounts` table is related to the `jewelries` table so after we insert a percantage we can notice `discount_price` in the latter:

[Link to Insert Values File](insert_values_files/insert_into_discounts.sql)

##### `jewelries` table:

<img width="1384" alt="Screenshot 2023-10-27 at 14 20 04" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/ebfa6d2d-beaf-49ea-a2cd-1c346ac732ef">

##### `discounts` table:

<img width="1246" alt="Screenshot 2023-10-27 at 14 22 05" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/e31a7128-e3be-4777-ac39-413677afdf0a">

#### To return back to regular price of an item we use the procedure down below:
```plpgsql
CREATE OR REPLACE PROCEDURE
    sp_remove_percent_from_discounts(
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(30),
        provided_last_modified_by_emp_id CHAR(5),
        provided_jewelry_id INTEGER,
        provided_color_id INTEGER
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
    IF NOT (
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

    IF NOT (
        SELECT credentials_authentication(
            provided_staff_user_role,
            provided_staff_user_password,
            provided_last_modified_by_emp_id
            )
        )
    THEN
        SELECT fn_raise_error_message(
            authorisation_failed
            );
    ELSE
        UPDATE
            jewelries
        SET
            discount_price = NULL
        WHERE
            id = provided_jewelry_id
                    AND
            gold_color_id = provided_color_id;
        UPDATE
            discounts
        SET
            deleted_at = NOW()
        WHERE
            jewelry_id = provided_jewelry_id
                    AND
            color_id = provided_color_id;
    END IF;
END;
$$
LANGUAGE plpgsql;
```
#### We delete the discount applied to the item with ID 60001 and gold_color ID 1:
```plpgsql
CALL sp_remove_percent_from_discounts(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    60001,
    1);
```
##### The discount is deleted and the jewelry 'discount_price' is set back to Null:

##### `jewelries` table:

<img width="1383" alt="Screenshot 2023-10-27 at 14 29 13" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/2e1aa731-87a6-4e83-bdd5-3dc71a838073">

##### `discounts` table:

<img width="1244" alt="Screenshot 2023-10-27 at 14 28 51" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/ebfa8803-0d8d-496e-8d08-aef3d551ca13">

#### The 'shopping_cart' table is related to the 'sessions' and 'jewelries' ones:
```plpgsql
CREATE TABLE
    shopping_cart(
        id SERIAL PRIMARY KEY,
        session_id INTEGER NOT NULL ,
        inventory_id INTEGER NOT NULL,
        quantity INTEGER DEFAULT 0,

        CONSTRAINT ck_shopping_cart_quantity
            CHECK ( quantity >= 0 ),


        CONSTRAINT fk_shopping_cart_sessions
                    FOREIGN KEY (session_id)
                    REFERENCES sessions(id)
                    ON UPDATE CASCADE
                    ON DELETE SET NULL,

        CONSTRAINT fk_shopping_cart_inventory
                    FOREIGN KEY (inventory_id)
                    REFERENCES inventory(id)
                    ON UPDATE CASCADE
                    ON DELETE CASCADE
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
        provided_inventory_id INTEGER,
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
            id = provided_inventory_id
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
            deleted_at
        FROM
            inventory
        WHERE
            id = provided_inventory_id
        ) IS NOT NULL
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
        IF (
            SELECT EXISTS (
                SELECT
                    1
                FROM
                    shopping_cart
                WHERE
                    inventory_id = provided_inventory_id
                            AND
                    session_id = provided_session_id
                )
            )
        THEN
            UPDATE
                shopping_cart
            SET
                quantity = quantity + provided_quantity
            WHERE
                inventory_id = provided_inventory_id
                            AND
                session_id = provided_session_id;
        ELSE
            INSERT INTO
                shopping_cart(
                        session_id,
                        inventory_id,
                        quantity
                              )
            VALUES
                (
                 provided_session_id,
                 provided_inventory_id,
                 provided_quantity
                 );
        END IF;

        CALL sp_remove_quantity_from_inventory(
            provided_inventory_id,
            provided_quantity,
            current_quantity
            );
    END IF;
END;
$$
LANGUAGE plpgsql;
```
#### We call the procedure with 'sessiond_id', so as to be able to authenticate the current customer, and we also provide the item inventory ID and desired quantity:

1. If the shopping session has expired we would get the following message:
<img width="603" alt="Screenshot 2023-10-20 at 18 18 48" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/3d48ac52-4c89-4313-9efb-9f7f7e71869a">

2. The procedure checks if there is enough available quantity:
##### If we try to get 24 items of jewelry with inventory ID 1 (available only 23):

<img width="337" alt="Screenshot 2023-10-27 at 15 10 25" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/1de36970-5a46-4fd7-98d7-63473d6c82e6">

3. The procedure checks if there is any available quantity of the given item. For example, if we get 23 pieces of item with inventory ID 1 and then try to add one more of the same item to the shopping cart:

<img width="331" alt="Screenshot 2023-10-27 at 15 15 32" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/51279910-a336-4cd1-8848-5b41d4eb1a9d">

4. If the all checks passes, and the given item ID has not already been inserted into the 'shopping_cart' table, it is being inserted, otherwise the quantity is just being increased:

<img width="343" alt="Screenshot 2023-10-27 at 15 18 42" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/c57f2548-071e-4981-883b-dc1e5c00f409">

##### `shopping_cart` table:

<img width="572" alt="Screenshot 2023-10-27 at 15 20 00" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/92190dc0-1bb9-45bd-8fe1-505e59416e63">

#### If we add one more piece:

##### `shopping_cart` table:

<img width="574" alt="Screenshot 2023-10-27 at 16 05 49" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/0d7d03b5-a20c-4108-9ad1-affa856bfb2c">

##### `inventory' table:
<img width="1408" alt="Screenshot 2023-10-27 at 16 08 48" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/204d38e1-4cc7-4060-9de1-346834a33f9a">

#### Afterwards, another procedure is being called that reduces the quantities in the `inventories` table (also sets the `deleted_at` field if the quantity reaches 0 as we saw above):
```plpgsql
CREATE OR REPLACE PROCEDURE
    sp_remove_quantity_from_inventory(
        provided_inventory_id INTEGER,
        requested_quantity INTEGER,
        current_quantity INTEGER
)
AS
$$
BEGIN
    UPDATE
        inventory
    SET
        quantity = quantity - requested_quantity
    WHERE
        id = provided_inventory_id;
    IF
        current_quantity - requested_quantity = 0
    THEN
        UPDATE
            inventory
        SET
            deleted_at = NOW()
        WHERE
            id = provided_inventory_id;
    END IF;
END;
$$
LANGUAGE plpgsql;
```
#### In order to remove an item from the shopping cart, we select the procedure `sp_remove_from_shopping_cart` that executes the usual checks, and then invokes the  `sp_add_quantity_into_inventory`:
```plpgsql
CREATE OR REPLACE PROCEDURE
    sp_remove_from_shopping_cart(
        provided_session_id INTEGER,
        provided_inventory_id INTEGER,
        provided_quantity INTEGER
    )
AS
$$
DECLARE
    session_has_expired CONSTANT TEXT :=
        'Your shopping session has expired. ' ||
        'To continue shopping, please log in again.';

    current_jewelry_id INTEGER;

    current_color_id INTEGER;

BEGIN
    current_jewelry_id := (
        SELECT
            inv.jewelry_id
        FROM
            inventory AS inv
        WHERE
            inv.id = provided_inventory_id
            );

    current_color_id := (
        SELECT
            inv.color_id
        FROM
            inventory AS inv
        WHERE
            inv.id = provided_inventory_id
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
    ELSE
        UPDATE
            shopping_cart
        SET
            quantity = quantity - provided_quantity
        WHERE
            inventory_id = provided_inventory_id
                        AND
            session_id = provided_session_id;

        CALL sp_add_quantity_into_inventory(
            NULL,
            NULL,
            NULL,
            provided_session_id,
            current_jewelry_id,
            current_color_id,
            provided_quantity
            );
    END IF;
END;
$$
LANGUAGE plpgsql;
```

#### Let us remove 21 pieces of item with inventory ID 3 (we currently have 23 pieces added into the shopping cart). Here, we need to provided session ID, as well as inventory ID and quantity:

<img width="358" alt="Screenshot 2023-10-27 at 16 21 16" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/cdf96fcf-c83a-45c4-a9f4-809027e9a5bd">

##### `shopping_cart` table:

<img width="575" alt="Screenshot 2023-10-27 at 16 22 11" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/9c56d80d-3c4a-4cf7-9c2d-8d8e0d042646">

##### `inventory` table:
<img width="1410" alt="Screenshot 2023-10-27 at 16 23 02" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/12a82aec-f283-4197-a46e-185937091898">

#### For the demo pusposes of this project, we have added three payment providers in our database:
```plpgsql
CREATE TABLE payment_providers(
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);
```
[Link to Insert Values File](insert_values_files/insert_into_payment_providers.sql)

##### `payment_providers` table:

<img width="204" alt="Screenshot 2023-10-27 at 14 38 52" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/5f05623c-0447-466e-b3d2-6d5fa053b544">

#### What connects the `shopping_cart` and `payment_providers` is the `orders` table:
```plpgsql
CREATE TABLE
    orders(
        id INTEGER NOT NULL PRIMARY KEY,
        shopping_cart_id INTEGER,
        payment_provider_id INTEGER NOT NULL,
        date TIMESTAMPTZ,

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
```

#### `transactions` table is related to `orders`:
```plpgsql
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
```
#### Before proceeding, we need two functions that locate the `countries_cities` table ID according to the names of the city and country the customer has provided:
```plpgsql
CREATE OR REPLACE FUNCTION
    fn_find_country_by_name(
        in_country_name VARCHAR(30)
)
RETURNS INTEGER
AS
$$
DECLARE
    country_id INTEGER;
BEGIN
    country_id := (
        SELECT
            cou.id
        FROM
            countries AS cou
        WHERE
            cou.name = in_country_name
    );
    RETURN country_id;
END;
$$
LANGUAGE plpgsql;
```
```plpgsql
CREATE OR REPLACE FUNCTION
    fn_find_city_by_name(
        in_city_name VARCHAR(30)
)
RETURNS INTEGER
AS
$$
DECLARE
    city_id INTEGER;
BEGIN
    city_id := (
        SELECT
            cit.id
        FROM
            cities AS cit
        WHERE
            cit.name = in_city_name
    );
    RETURN city_id;
END;
$$
LANGUAGE plpgsql;
```
#### For the pusposes of the project, a customer needs to declare a payment provider name, also must insert their personal details and available balance, so we can check if the transfer could be procedeed. After the `sp_complete_order` procedure is called, it will calculate the total amount, taking into consideration if the product has a discount price or not, it will then select the `sp_transfer_money` procedure:
```plpgsql
CREATE OR REPLACE PROCEDURE
    sp_complete_order(
        provided_session_id INTEGER,
        provided_first_name VARCHAR(30),
        provided_last_name VARCHAR(30),
        provided_phone_number VARCHAR(20),
        provided_country_name VARCHAR(30),
        provided_city_name VARCHAR(30),
        provided_address VARCHAR(200),
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

    current_country_id INTEGER;

    current_city_id INTEGER;

    current_cities_countries_id INTEGER;
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

    current_country_id := (
        SELECT fn_find_country_by_name(
                provided_country_name
            )
        );

    current_city_id := (
    SELECT fn_find_city_by_name(
            provided_city_name
        )
        );

    current_cities_countries_id := (
        SELECT
            id
        FROM
            countries_cities
        WHERE
            country_id = current_country_id
                    AND
            city_id = current_city_id
            );

    UPDATE
        customer_details
    SET
        first_name = provided_first_name,
        last_name = provided_last_name,
        phone_number = provided_phone_number,
        countries_cities_id = current_cities_countries_id,
        address = provided_address,
        current_balance = provided_current_balance,
        payment_provider = provided_payment_provider
    WHERE
        id = provided_customer_id;

    current_total_amount := (
        SELECT
            SUM(
                (CASE
                    WHEN j.discount_price IS NULL
                        THEN j.regular_price
                    ELSE j.discount_price
                END) * sc.quantity)
        FROM
            jewelries AS j
        JOIN
            inventory AS i
        ON
            j.id = i.jewelry_id
                AND
            j.gold_color_id = i.color_id
        JOIN
            shopping_cart AS sc
        ON
            i.id = sc.inventory_id
        JOIN
            sessions AS s
        ON
            sc.session_id = s.id
        WHERE
            s.id = provided_session_id
        );

    INSERT INTO orders
        (
         id,
         shopping_cart_id,
         payment_provider_id,
         date
         )
    VALUES
        (
         provided_session_id,
         provided_session_id,
         current_payment_provider_id,
         NOW()
         );

    CALL sp_transfer_money(
        provided_session_id,
        provided_customer_id,
        provided_current_balance,
        current_total_amount);
END;
$$
LANGUAGE plpgsql;
```
#### We need two tables to store shippment details:
```plpgsql
CREATE TABLE
    shipping_label(
        id SERIAL PRIMARY KEY,
        transaction_id INTEGER NOT NULL,
        due_date TIMESTAMPTZ,
        amount DECIMAL(8, 2),
        full_name VARCHAR(70),
        phone_number VARCHAR(20),
        country_name VARCHAR(30),
        city_name VARCHAR(30),
        address VARCHAR(200) NOT NULL,

        CONSTRAINT fk_shipping_label_transactions
                    FOREIGN KEY (transaction_id)
                    REFERENCES transactions(id)
                    ON UPDATE CASCADE
                    ON DELETE CASCADE
);
```
```plpgsql
CREATE TABLE
    shipment_description(
        id SERIAL PRIMARY KEY,
        shipping_label INTEGER NOT NULL,
        jewelry_type VARCHAR(30),
        gold_color VARCHAR(15),
        diamond_color VARCHAR(15),
        diamond_carat VARCHAR(15),
        diamond_clarity VARCHAR(15),

        CONSTRAINT fk_shipment_description_shipping_label
                        FOREIGN KEY (shipping_label)
                        REFERENCES shipping_label(id)
                        ON UPDATE CASCADE
                        ON DELETE CASCADE
);
```
#### The above tables will be automatically populated in case of a successfull transaction by the following two procedures:
```plpgsql
CREATE OR REPLACE PROCEDURE
    sp_insert_into_shipping_label(
        in_transaction_id INTEGER
)
AS
$$
BEGIN
    INSERT INTO
        shipping_label(
            transaction_id,
            due_date,
            amount,
            full_name,
            phone_number,
            country_name,
            city_name,
            address
)
    SELECT
        tr.id,

        CASE
            WHEN
                cou.id = 7
            THEN
                o.date + INTERVAL '7 DAYS'
            ELSE
                o.date + INTERVAL '14 DAYS'
        END AS delivery_due_date,

        tr.amount,

        CONCAT(
            cd.first_name,
            ' ',
            cd.last_name
            ) AS customer_full_name,

        cd.phone_number,

        cou.name,

        cit.name,

        cd.address
    FROM
        transactions AS tr
    JOIN
        orders AS o
    ON
        tr.order_id = o.id
    JOIN
        shopping_cart AS sc
    ON
        o.shopping_cart_id = sc.id
    JOIN
        sessions AS s
    ON
        sc.session_id = s.id
    JOIN
        customer_users AS cu
    ON
        s.customer_id = cu.id
    JOIN
        customer_details AS cd
    ON
        cu.id = cd.customer_user_id
    JOIN
        countries_cities AS cc
    ON
        cd.countries_cities_id = cc.id
    JOIN
        countries AS cou
    ON
        cc.country_id = cou.id
    JOIN
        cities AS cit
    ON
        cc.city_id = cit.id
    WHERE
        tr.id = in_transaction_id;

    CALL sp_insert_into_shipment_description(
            in_transaction_id
        );
END;
$$
LANGUAGE plpgsql;
```
```plpgsql
CREATE OR REPLACE PROCEDURE
    sp_insert_into_shipment_description(
        in_transaction_id INTEGER
)
AS
$$
BEGIN
    INSERT INTO
        shipment_description(
            shipping_label,
            jewelry_type,
            gold_color,
            diamond_color,
            diamond_carat,
            diamond_clarity
    )
    SELECT
        sl.id,

        jt.name,

        gc.color,

        dc.color,

        dcw.weight,

        dcl.clarity
    FROM
        shipping_label AS sl
    JOIN
        transactions AS tr
    ON
        sl.transaction_id = tr.id
    JOIN
        orders AS ord
    ON
        tr.order_id = ord.id
    JOIN
        shopping_cart AS sc
    ON
        sc.id = ord.shopping_cart_id
    JOIN
        inventory AS inv
    ON
        sc.inventory_id = inv.id
    JOIN
        jewelries AS j
    ON
        inv.jewelry_id = j.id
                AND
        inv.color_id = j.gold_color_id
    JOIN
        jewelry_type AS jt
    ON
        j.type_id = jt.id
    JOIN
        gold_color AS gc
    ON
        j.gold_color_id = gc.id
    JOIN
        diamond_color AS dc
    ON
        j.diamond_color_id = dc.id
    JOIN
        diamond_carat_weight AS dcw
    ON
        j.diamond_carat_weight_id = dcw.id
    JOIN
        diamond_clarity AS dcl
    ON
        j.diamond_clarity_id = dcl.id
    WHERE
        tr.id = in_transaction_id;
END;
$$
LANGUAGE plpgsql;
```
#### In case of insufficient balance, an error would be raised. Otherwise, data would be inserted into the `transactions` and `orders` tables:
```plpgsql
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
         CONCAT('Needed amount: ', needed_balance));

    current_transaction_id INTEGER;
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

        current_transaction_id := (
            SELECT
                MAX(id)
            FROM
                transactions
                );
        CALL sp_insert_into_shipping_label(
            current_transaction_id
            );
    END IF;
END;
$$
LANGUAGE plpgsql;
```
##### If we try to spend bigger amount that we have available in our balance:

<img width="598" alt="Screenshot 2023-10-27 at 16 53 47" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/dd1c3b34-37e1-4e1a-b41c-3a72b6b901a6">

#### Let us add more customers and complete more orders, so we can see the final result better:

[Link to Insert Values File](insert_values_files/insert_register_customers.sql)

##### `customer_users` table:

<img width="1057" alt="Screenshot 2023-10-27 at 17 05 33" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/ae8029c2-0db1-4d1e-a52d-fb5827f3b551">

##### `customer_details` table:

<img width="1336" alt="Screenshot 2023-10-27 at 17 11 33" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/c20b5716-dd2a-41bc-8768-ccf474c1c809">

##### `orders` table:

<img width="887" alt="Screenshot 2023-10-27 at 17 13 07" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/dd9b862b-8c3a-4f8a-98a0-315297fbf6a1">

##### `transactions` table:

<img width="685" alt="Screenshot 2023-10-27 at 17 13 51" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/f44c40db-3b94-42ba-9579-e21cecfb4ef4">

##### `shipping_lable` table:

<img width="1309" alt="Screenshot 2023-10-27 at 17 15 12" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/4b7a8303-6372-4ee5-9933-2f77d1ba9ce9">

##### `shipment_description` table:

<img width="1134" alt="Screenshot 2023-10-27 at 17 15 47" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/dc9c334e-5602-4963-8e92-e587040ee5d2">


#### THE WHOLE SCRIPT CAN BE EXECUTED AT ONCE, AND IT WILL PRODUCE THE SAME OUTCOME WITHOUT NEEDING TO EXECUTE IT IN MULTIPLE STEPS. IT CAN BE FOUND HERE -> [Source Code](e_commerce_database_platform.sql)
