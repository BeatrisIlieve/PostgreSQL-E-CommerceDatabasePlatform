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
        date TIMESTAMPTZ,

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
```
#### In case of insufficient balance, an error would be raised. Otherwise, data would be inserted into the 'transactions' and 'orders' tables:
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

#### Finally we will create a function, which the Superuser would be able to call via their credentials, so as to check <ins>of what type are the most sold jewelry</ins>. To create a better image, it would be good to register a few customers, add to their shopping carts, and complete orders:
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
##### 'customers_users' table:
<img width="1077" alt="Screenshot 2023-10-21 at 19 53 01" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/9558d108-c157-455c-ac13-9c5f0092bc18">

##### 'customers_details' table:
<img width="1155" alt="Screenshot 2023-10-21 at 19 53 24" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/1c5abd4c-5545-4db6-ba6e-dcc78dd15344">

##### 'sessions' table:
<img width="1054" alt="Screenshot 2023-10-21 at 19 53 43" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/fdd38424-1cce-404e-a7c6-b62eac4279c3">

##### 'inventory' table:

<img width="1286" alt="Screenshot 2023-10-21 at 19 54 45" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/72848649-e76b-4e0b-aa47-f5740c087f58">

##### 'Inventory_records' table:

<img width="753" alt="Screenshot 2023-10-21 at 19 55 04" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/b506c047-d972-47cb-a17a-c01fee700cc0">

##### 'orders' table:
<img width="846" alt="Screenshot 2023-10-21 at 19 55 24" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/c0e520b9-0886-4d39-be9d-247e3a1b7083">

##### 'transactions' table:
<img width="682" alt="Screenshot 2023-10-21 at 19 55 41" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/9d60dff1-cf11-41b1-acaf-d06b8e71e673">

#### We can use now 'fn_show_most_sold_jewelry_type' to check the type of the most sold item in the store and the sold quantity of it: 
```plpgsql
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
```
##### This is how the 'sjopping_cart' table looks like at the moment:
<img width="551" alt="Screenshot 2023-10-22 at 19 06 06" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/ec7e5d94-2cac-4d12-8d17-c5a39fcf4e9f">

#### So if we select the 'fn_show_most_sold_jewelry_type':
```plpgsql
SELECT fn_show_most_sold_jewelry_type(
    '10001',
    'super_staff_user',
    'super_staff_user_password');
```
##### We get the resulting table (because the jewelry with ID 2 is of type 'Earring'):
<img width="396" alt="Screenshot 2023-10-22 at 19 07 44" src="https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/6e7e131e-9d4c-4709-8095-a01feedbe470">

#### THE WHOLE SCRIPT CAN BE EXECUTED AT ONCE, AND IT WILL PRODUCE THE SAME OUTCOME WITHOUT NEEDING TO EXECUTE IT IN MULTIPLE STEPS. IT CAN BE FOUND HERE -> [Source Code](e_commerce_database_platform.sql)
