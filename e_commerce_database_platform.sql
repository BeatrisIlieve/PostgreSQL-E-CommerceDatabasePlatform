CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE countries(
    id SERIAL PRIMARY KEY,
    name VARCHAR(30) UNIQUE NOT NULL
);

INSERT INTO
    countries(
        name
)
VALUES
    (
     'Albania'
    ),
    (
     'Andorra'
    ),
    (
     'Austria'
    ),
    (
     'Belarus'
    ),
    (
     'Belgium'
    ),
    (
     'Bosnia and Herzegovina'
    ),
    (
     'Bulgaria'
    ),
    (
     'Croatia'
    ),
    (
     'Czechia'
    ),
    (
     'Denmark'
    ),
    (
     'Estonia'
    ),
    (
     'Finland'
    ),
    (
     'France'
    ),
    (
     'Germany'
    ),
    (
     'Greece'
    ),
    (
     'Hungary'
    ),
    (
     'Iceland'
    ),
    (
     'Ireland'
    ),
    (
     'Italy'
    ),
    (
     'Latvia'
    ),
    (
     'Liechtenstein'
    ),
    (
     'Lithuania'
    ),
    (
     'Luxembourg'
    ),
    (
     'Malta'
    ),
    (
     'Moldova'
    ),
    (
     'Monaco'
    ),
    (
     'Montenegro'
    ),
    (
     'Netherlands'
    ),
    (
     'North Macedonia'
    ),
    (
     'Norway'
    ),
    (
     'Poland'
    ),
    (
     'Portugal'
    ),
    (
     'Romania'
    ),
    (
     'Russia'
    ),
    (
     'San Marino'
    ),
    (
     'Serbia'
    ),
    (
     'Slovakia'
    ),
    (
     'Slovenia'
    ),
    (
     'Spain'
    ),
    (
     'Sweden'
    ),
    (
     'Switzerland'
    ),
    (
     'Ukraine'
    ),
    (
     'United Kingdom'
    )
;

CREATE TABLE cities(
    id SERIAL PRIMARY KEY,
    name VARCHAR(30) UNIQUE  NOT NULL
);

INSERT INTO
    cities(
           name
)

VALUES
    (
     'Tirana'
    ),
    (
     'Vlorë'
    ),
    (
     'Kamëz'
    ),
    (
     'Andorra la Vella'
    ),
    (
     'Escaldes-Engordany'
    ),
    (
     'Encamp'
    ),
    (
     'Vienna'
    ),
    (
     'Graz'
    ),
    (
     'Linz'
    ),
    (
     'Minsk'
    ),
    (
     'Homyel’'
    ),
    (
     'Vitsyebsk'
    ),
    (
     'Brussels'
    ),
    (
     'Antwerp'
    ),
    (
     'Gent'
    ),
    (
     'Sarajevo'
    ),
    (
     'Banja Luka'
    ),
    (
     'Bijeljina'
    ),
    (
     'Sofia'
    ),
    (
     'Plovdiv'
    ),
    (
     'Varna'
    ),
    (
     'Zagreb'
    ),
    (
     'Rijeka'
    ),
    (
     'Split'
    ),
    (
     'Prague'
    ),
    (
     'Olomouc'
    ),
    (
     'Brno'
    ),
    (
     'Copenhagen'
    ),
    (
     'Aarhus'
    ),
    (
     'Odense'
    ),
    (
     'Tallinn'
    ),
    (
     'Tartu'
    ),
    (
     'Narva'
    ),
    (
     'Helsinki'
    ),
    (
     'Tampere'
    ),
    (
     'Espoo'
    ),
    (
     'Paris'
    ),
    (
     'Marseille'
    ),
    (
     'Lyon'
    ),
    (
     'Berlin'
    ),
    (
     'Stuttgart'
    ),
    (
     'Munich'
    ),
    (
     'Athens'
    ),
    (
     'Thessaloníki'
    ),
    (
     'Piraeus'
    ),
    (
     'Budapest'
    ),
    (
     'Debrecen'
    ),
    (
     'Székesfehérvár'
    ),
    (
     'Reykjavik'
    ),
    (
     'Kópavogur'
    ),
    (
     'Hafnarfjörður'
    ),
    (
     'Dublin'
    ),
    (
     'Finglas'
    ),
    (
     'Cork'
    ),
    (
     'Rome'
    ),
    (
     'Milan'
    ),
    (
     'Naples'
    ),
    (
     'Riga'
    ),
    (
     'Daugavpils'
    ),
    (
     'Liepāja'
    ),
    (
     'Vaduz'
    ),
    (
     'Schaan'
    ),
    (
     'Triesen'
    ),
    (
     'Vilnius'
    ),
    (
     'Kaunas'
    ),
    (
     'Klaipėda'
    ),
    (
     'Luxembourg'
    ),
    (
     'Esch-sur-Alzette'
    ),
    (
     'Dudelange'
    ),
    (
     'Valletta'
    ),
    (
     'Birkirkara'
    ),
    (
     'Saint Paul’s Bay'
    ),
    (
     'Chisinau'
    ),
    (
     'Tiraspol'
    ),
    (
     'Bălţi'
    ),
    (
     'Monaco'
    ),
    (
     'Podgorica'
    ),
    (
     'Amsterdam'
    ),
    (
     'Rotterdam'
    ),
    (
     'The Hague'
    ),
    (
     'Skopje'
    ),
    (
     'Oslo'
    ),
    (
     'Bergen'
    ),
    (
     'Stavanger'
    ),
    (
     'Warsaw'
    ),
    (
     'Lisbon'
    ),
    (
     'Porto'
    ),
    (
     'Aves'
    ),
    (
     'Bucharest'
    ),
    (
     'Moscow'
    ),
    (
     'San Marino'
    ),
    (
     'Belgrade'
    ),
    (
     'Bratislava'
    ),
    (
     'Ljubljana'
    ),
    (
     'Madrid'
    ),
    (
     'Barcelona'
    ),
    (
     'Sevilla'
    ),
    (
     'Stockholm'
    ),
    (
     'Bern'
    ),
    (
     'Geneva'
    ),
    (
     'Zürich'
    ),
    (
     'Kiev'
    ),
    (
     'London'
    ),
    (
     'Birmingham'
    ),
    (
     'Manchester'
    )
;

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

INSERT INTO
    countries_cities(
        country_id,
        city_id
)

VALUES
    (
     1, 1
     ),
    (
     1, 2
     ),
    (
     1, 3
     ),
    (
     2, 4
     ),
    (
     2, 5
     ),
    (
     2, 6
     ),
    (
     3, 7
     ),
    (
     3, 8
     ),
    (
     3, 9
     ),
    (
     4, 10
     ),
    (
     4, 11
     ),
    (
     4, 12
     ),
    (
     5, 13
     ),
    (
     5, 14
     ),
    (
     5, 15
     ),
    (
     6, 16
     ),
    (
     6, 17
     ),
    (
     6, 18
     ),
    (
     7, 19
     ),
    (
     7, 20
     ),
    (
     7, 21
     ),
    (
     8, 22
     ),
    (
     8, 23
     ),
    (
     8, 24
     ),
    (
     9, 25
     ),
    (
     9, 26
     ),
    (
     9, 27
     ),
    (
     10, 28
     ),
    (
     10, 29
     ),
    (
     10, 30
     ),
    (
     11, 31
     ),
    (
     11, 32
     ),
    (
     11, 33
     ),
    (
     12, 34
     ),
    (
     12, 35
     ),
    (
     12, 36
     ),
    (
     13, 37
     ),
    (
     13, 38
     ),
    (
     13, 49
     ),
    (
     14, 40
     ),
    (
     14, 41
     ),
    (
     14, 42
     ),
    (
     15, 43
     ),
    (
     15, 44
     ),
    (
     15, 45
     ),
    (
     16, 46
     ),
    (
     16, 47
     ),
    (
     16, 48
     ),
    (
     17, 49
     ),
    (
     17, 50
     ),
    (
     17, 51
     ),
    (
     18, 52
     ),
    (
     18, 53
     ),
    (
     18, 54
     ),
    (
     19, 55
     ),
    (
     19, 56
     ),
    (
     19, 57
     ),
    (
     20, 58
     ),
    (
     20, 59
     ),
    (
     20, 60
     ),
    (
     21, 61
     ),
    (
     21, 62
     ),
    (
     21, 63
     ),
    (
     22, 64
     ),
    (
     22, 65
     ),
    (
     22, 66
     ),
    (
     23, 67
     ),
    (
     23, 68
     ),
    (
     23, 69
     ),
    (
     24, 70
     ),
    (
     24, 71
     ),
    (
     24, 72
     ),
    (
     25, 73
     ),
    (
     25, 74
     ),
    (
     25, 75
     ),
    (
     26, 76
     ),
    (
     27, 77
     ),
    (
     28, 78
     ),
    (
     28, 79
     ),
    (
     28, 80
     ),
    (
     29, 81
     ),
    (
     30, 82
     ),
    (
     30, 83
     ),
    (
     30, 84
     ),
    (
     31, 85
     ),
    (
     32, 86
     ),
    (
     32, 87
     ),
    (
     32, 88
     ),
    (
     33, 89
     ),
    (
     34, 90
     ),
    (
     35, 91
     ),
    (
     36, 92
     ),
    (
     37, 93
     ),
    (
     38, 94
     ),
    (
     39, 95
     ),
    (
     39, 96
     ),
    (
     39, 97
     ),
    (
     40, 98
     ),
    (
     41, 99
     ),
    (
     41, 100
     ),
    (
     41, 101
     ),
    (
     42, 102
     ),
    (
     43, 103
     ),
    (
     43, 104
     ),
    (
     43, 105
     );

CREATE TABLE
    customer_users(
        id SERIAL PRIMARY KEY NOT NULL,
        email VARCHAR(30) UNIQUE NOT NULL,
        password VARCHAR(100) NOT NULL,
        created_at DATE NOT NULL
);

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
            (email, password, created_at)
        VALUES
            (provided_email, hashed_password , NOW());

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

CREATE TABLE
    staff_users(
        id SERIAL PRIMARY KEY,
        staff_user_role VARCHAR(50) NOT NULL,
        staff_user_password VARCHAR(50) NOT NULL
);

INSERT INTO
    staff_users(
            staff_user_role,
            staff_user_password
                )
VALUES
    (
     'super_staff_user',
     'super_staff_user_password'
     ),
    (
     'merchandising_staff_user_first',
     'merchandising_password_first'
     ),
    (
     'merchandising_staff_user_second',
     'merchandising_password_second'
     ),
    (
     'inventory_staff_user_first',
     'inventory_password_first'
     ),
    (
     'inventory_staff_user_second',
     'inventory_password_second'
     );

CREATE TABLE
    departments(
        id INTEGER GENERATED ALWAYS AS IDENTITY ( START WITH 20001 INCREMENT 1 ) PRIMARY KEY,
        name VARCHAR(30) NOT NULL
);

INSERT INTO
    departments(
                name
                )
VALUES
    (
     'Supervisory'
     );
INSERT INTO
    departments(
                name
                )
VALUES
    (
     'Merchandising'
     );
INSERT INTO
    departments(
                name
                )
VALUES
    (
     'Inventory'
     );

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
    employees(
              staff_user_id,
              department_id,
              first_name,
              last_name, email,
              phone_number
              )
VALUES
    (
     1,
     20001,
     'Beatris',
     'Ilieve',
     'beatris@icloud.com',
     '000-000-000'
     );
INSERT INTO
    employees(
              staff_user_id,
              department_id,
              first_name,
              last_name,
              email,
              phone_number
              )
VALUES
    (
     2,
     20002,
     'Terri',
     'Aldersley',
     'taldersley0@army.mil',
     '198-393-2278'
     );
INSERT INTO
    employees(
              staff_user_id,
              department_id,
              first_name,
              last_name,
              email,
              phone_number
              )
VALUES
    (
     3,
     20002,
     'Rose',
     'Obrey',
     'r@obrey.net',
     '631-969-8114'
     );
INSERT INTO
    employees(
              staff_user_id,
              department_id,
              first_name,
              last_name,
              email,
              phone_number
              )
VALUES
    (
     4,
     20003,
     'Mariette',
     'Caltera',
     'mcaltera4@cpanel.net',
     '515-969-8114'
     );
INSERT INTO
    employees(
              staff_user_id,
              department_id,
              first_name,
              last_name,
              email,
              phone_number
              )
VALUES
    (
     5,
     20003,
     'Elen',
     'Williams',
     'elen@ebay.com',
     '812-263-4473'
     );

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
    jewelry_type(
        id SERIAL PRIMARY KEY,
        name VARCHAR(30) NOT NULL
);

INSERT INTO
    jewelry_type(
                 name
                 )
VALUES
    (
     'Ring'
     ),
    (
     'Earring'
     ),
    (
     'Necklace'
     ),
    (
     'Bracelet'
     );

CREATE TABLE
    jewelry_name(
        id SERIAL PRIMARY KEY,
        name VARCHAR(100)
);

INSERT INTO
    jewelry_name(
        name
)
VALUES
    (
    'BUDDING ROUND BRILLIANT DIAMOND HALO ENGAGEMENT RING'
    ),
    (
    'DIAMOND HALO DROP EARRING'
    ),
    (
    'ROUND DIAMOND HALO PENDANT'
    ),
    (
     'OVAL DIAMOND DETAIL BANGLE'
    );

CREATE TABLE
    gold_color(
        id SERIAL PRIMARY KEY,
        color VARCHAR(15)
);

INSERT INTO
    gold_color(
        color
)
VALUES
    (
    'ROSE GOLD'
    ),
    (
    'YELLOW GOLD'
    ),
    (
    'WHITE GOLD'
    );

CREATE TABLE
    diamond_color(
        id SERIAL PRIMARY KEY,
        color VARCHAR(15)
);

INSERT INTO
    diamond_color(
            color
)
VALUES
    (
     'D'
    ),
    (
     'E'
    ),
    (
     'G'
    );

CREATE TABLE
    diamond_carat_weight(
        id SERIAL PRIMARY KEY,
        weight VARCHAR(15)
);

INSERT INTO
    diamond_carat_weight(
            weight
)
VALUES
    (
     '3.00ctw'
    ),
    (
     '2.50ctw'
    ),
    (
     '2.25ctw'
    );

CREATE TABLE
    diamond_clarity(
        id SERIAL PRIMARY KEY,
        clarity VARCHAR(15)
);

INSERT INTO
    diamond_clarity(
        clarity
)
VALUES
    (
     'FL'
    ),
    (
     'IF'
    ),
    (
     'VVS1'
    );

CREATE TABLE
    description(
        id SERIAL PRIMARY KEY,
        description TEXT
);

INSERT INTO
    description(
        description
)
VALUES
    (
     'This stunning engagement ring features a round brilliant diamond with surrounded by a sparkling halo of marquise diamonds. Crafted to the highest standards and ethically sourced, it is the perfect ring to dazzle for any gift, proposal, or occasion. Its timeless design and exquisite craftsmanship will ensure an everlasting memory.'
    ),
    (
    'These Diamond Halo Drop Earrings are perfect for any occasion. Featuring a halo of diamonds set around a drop earring design, they are beautifully crafted and certainly eye-catching. The diamonds provide exceptional sparkle and a luxurious feel that will make you shine.'
    ),
    (
    'This classic Modern Diamond Bar Necklace is perfect for any occasion. Crafted with three shimmering diamonds and lustrous 14k gold, this chain is a timeless and elegant piece. The sparkle and shine of the diamonds will make you feel well dressed.'
    ),
    (
     'This Gorgeous Pear Halo Bangle Bracelet will make a statement with two pear diamond centers and a halo of shimmering stones. Crafted from 14k gold, this beautiful bracelet is sure to make you shine.'
    );

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

CREATE TABLE
    discounts(
        id SERIAL PRIMARY KEY,
        last_modified_by_emp_id CHAR(5) NOT NULL,
        jewelry_id INTEGER NOT NULL,
        color_id INTEGER NOT NULL,
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

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    30001,
    1,
    1,
    'https://res.cloudinary.com/deztgvefu/image/upload/v1698161350/Rings/BUDDING_ROUND_BRILLIANT_DIAMOND_HALO_ENGAGEMENT_RING_ROSE_watsbc.webp',
    19879.00,
    1,
    1,
    3,
    2,
    1
);

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    30001,
    1,
    1,
    'https://res.cloudinary.com/deztgvefu/image/upload/v1698161350/Rings/BUDDING_ROUND_BRILLIANT_DIAMOND_HALO_ENGAGEMENT_RING_YELLOW_vvqx9m.webp',
    19879.00,
    2,
    1,
    3,
    2,
    1
);

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    30001,
    1,
    1,
    'https://res.cloudinary.com/deztgvefu/image/upload/v1698161350/Rings/BUDDING_ROUND_BRILLIANT_DIAMOND_HALO_ENGAGEMENT_RING_WHITE_cuu8dz.webp',
    19879.00,
    3,
    1,
    3,
    2,
    1
);

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_second',
    'merchandising_password_second',
    '10003',
    40001,
    2,
    2,
    'https://res.cloudinary.com/deztgvefu/image/upload/v1698162227/Rings/DIAMOND_HALO_DROP_EARRING_ROSE_sf6dfj.webp',
    22749.00,
    1,
    2,
    1,
    3,
    2
);

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_second',
    'merchandising_password_second',
    '10003',
    40001,
    2,
    2,
    'https://res.cloudinary.com/deztgvefu/image/upload/v1698162227/Rings/DIAMOND_HALO_DROP_EARRING_YELLOW_mdwtqu.webp',
    22749.00,
    2,
    2,
    1,
    3,
    2
);

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_second',
    'merchandising_password_second',
    '10003',
    40001,
    2,
    2,
    'https://res.cloudinary.com/deztgvefu/image/upload/v1698162228/Rings/DIAMOND_HALO_DROP_EARRING_WHITE_kjf8zt.webp',
    22749.00,
    3,
    2,
    1,
    3,
    2
);

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_second',
    'merchandising_password_second',
    '10003',
    50001,
    3,
    3,
    'https://res.cloudinary.com/deztgvefu/image/upload/v1698163016/Rings/ROUND_DIAMOND_HALO_PENDANT_ROSE_h7njim.webp',
    17599.00,
    1,
    3,
    3,
    3,
    3
);

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_second',
    'merchandising_password_second',
    '10003',
    50001,
    3,
    3,
    'https://res.cloudinary.com/deztgvefu/image/upload/v1698163016/Rings/ROUND_DIAMOND_HALO_PENDANT_YELLOW_e6srd6.webp',
    17599.00,
    2,
    3,
    3,
    3,
    3
);

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_second',
    'merchandising_password_second',
    '10003',
    50001,
    3,
    3,
    'https://res.cloudinary.com/deztgvefu/image/upload/v1698163016/Rings/ROUND_DIAMOND_HALO_PENDANT_WHITE_tilgrt.webp',
    17599.00,
    3,
    3,
    3,
    3,
    3
);

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_second',
    'merchandising_password_second',
    '10003',
    60001,
    4,
    4,
    'https://res.cloudinary.com/deztgvefu/image/upload/v1698163533/Rings/OVAL_DIAMOND_DETAIL_BANGLE_ROSE_y2tqfd.webp',
    15743.00,
    1,
    3,
    2,
    3,
    4
);

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_second',
    'merchandising_password_second',
    '10003',
    60001,
    4,
    4,
    'https://res.cloudinary.com/deztgvefu/image/upload/v1698163532/Rings/OVAL_DIAMOND_DETAIL_BANGLE_YELLOW_zrny35.webp',
    15743.00,
    2,
    3,
    2,
    3,
    4
);

CALL sp_insert_jewelry_into_jewelries(
    'merchandising_staff_user_second',
    'merchandising_password_second',
    '10003',
    60001,
    4,
    4,
    'https://res.cloudinary.com/deztgvefu/image/upload/v1698163533/Rings/OVAL_DIAMOND_DETAIL_BANGLE_WHITE_i05ggo.webp',
    15743.00,
    3,
    3,
    2,
    3,
    4
);

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

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_first',
    'inventory_password_first',
    '10004',
    NULL,
    30001,
    1,
    23);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_second',
    'inventory_password_second',
    '10005',
    NULL,
    30001,
    2,
    7);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_first',
    'inventory_password_first',
    '10004',
    NULL,
    30001,
    3,
    5);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_first',
    'inventory_password_first',
    '10004',
    NULL,
    40001,
    1,
    9);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_second',
    'inventory_password_second',
    '10005',
    NULL,
    40001,
    2,
    7);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_first',
    'inventory_password_first',
    '10004',
    NULL,
    40001,
    3,
    5);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_first',
    'inventory_password_first',
    '10004',
    NULL,
    50001,
    1,
    9);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_second',
    'inventory_password_second',
    '10005',
    NULL,
    50001,
    2,
    7);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_first',
    'inventory_password_first',
    '10004',
    NULL,
    50001,
    3,
    5);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_first',
    'inventory_password_first',
    '10004',
    NULL,
    60001,
    1,
    9);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_second',
    'inventory_password_second',
    '10005',
    NULL,
    60001,
    2,
    7);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_first',
    'inventory_password_first',
    '10004',
    NULL,
    60001,
    3,
    5);


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
            id = provided_jewelry_id
                    AND
            gold_color_id = provided_color_id;

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
                 provided_last_modified_by_emp_id,
                 provided_jewelry_id,
                 provided_color_id,
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
    30001,
    1,
    0.10);

CALL sp_insert_percent_into_discounts(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    40001,
    1,
    0.15);

CALL sp_insert_percent_into_discounts(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    50001,
    1,
    0.20);

CALL sp_insert_percent_into_discounts(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    60001,
    1,
    0.25);


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
    30001,
    1);

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

CREATE TABLE payment_providers(
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

INSERT INTO
    payment_providers
    (
    name
    )
VALUES
    (
     'PayPal'
     ),
    (
     'Amazon Pay'
     ),
    (
     'Stripe'
     );

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

        CALL sp_remove_quantity_from_inventory(
            provided_inventory_id,
            provided_quantity,
            current_quantity
            );
    END IF;
END;
$$
LANGUAGE plpgsql;

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
            inventory_id = provided_inventory_id;

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
        CALL sp_insert_into_shipping_label(current_transaction_id);
    END IF;
END;
$$
LANGUAGE plpgsql;

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
            in_transaction_id);
END;
$$
LANGUAGE plpgsql;

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

SELECT fn_register_user('beatris@icloud.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(1, 1, 3);
CALL sp_complete_order(
    1,
    'Beatris',
    'Ilieve',
    '711-704-9768',
    'Bulgaria',
    'Sofia',
    'Some address',
    200000.00,
    'PayPal'
);

SELECT fn_register_user('peter@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(2, 5, 3);
CALL sp_complete_order(
    2,
    'Peter',
    'Harris',
    '703-679-220',
    'United Kingdom',
    'London',
    'Some address',
    200000.00,
    'PayPal'
);

SELECT fn_register_user('welch@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(3, 1, 2);
CALL sp_complete_order(
    3,
    'Welch',
    'Gorries',
    '711-704-9768',
    'Czechia',
    'Brno',
    'Some address',
    200000.00,
    'Amazon Pay'
);

SELECT fn_register_user('kellie@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(4, 1, 2);
CALL sp_complete_order(
    4,
    'Kellie',
    'Minihane',
    '231-204-9598',
    'Iceland',
    'Banja Luka',
    'Some address',
    200000.00,
    'PayPal'
);

SELECT fn_register_user('flora@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(5, 11, 3);
CALL sp_complete_order(
    5,
    'Flora',
    'Keating',
    '203-679-4950',
    'Denmark',
    'Copenhagen',
    'Some address',
    200000.00,
    'Stripe'
);

SELECT fn_register_user('james@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(6, 1, 2);
CALL sp_complete_order(
    6,
    'James',
    'Evans',
    '303-689-4950',
    'Finland',
    'Helsinki',
    'Some address',
    200000.00,
    'PayPal'
);

SELECT fn_register_user('even@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(7, 12, 3);
CALL sp_complete_order(
    7,
    'Even',
    'Davis',
    '503-689-4950',
    'Malta',
    'Valletta',
    'Some address',
    200000.00,
    'Stripe'
);

SELECT fn_register_user('george@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(8, 10, 3);
CALL sp_complete_order(
    8,
    'George',
    'Thompson',
    '993-689-4950',
    'Austria',
    'Vienna',
    'Some address',
    200000.00,
    'PayPal'
);

SELECT fn_register_user('john@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(9, 1, 3);
CALL sp_complete_order(
    9,
    'John',
    'Davis',
    '493-689-4950',
    'Portugal',
    'Lisbon',
    'Some address',
    200000.00,
    'PayPal'
);

SELECT fn_register_user('hans@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(10, 2, 1);
CALL sp_complete_order(
    10,
    'Hans',
    'Davis',
    '893-689-4950',
    'Austria',
    'Vienna',
    'Some address',
    200000.00,
    'Amazon Pay'
);

SELECT fn_register_user('mary@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(11, 3, 1);
CALL sp_complete_order(
    11,
    'Mary',
    'Evens',
    '893-689-4950',
    'Austria',
    'Vienna',
    'Some address',
    200000.00,
    'Amazon Pay'
);

SELECT fn_register_user('daisy@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(12, 4, 3);
CALL sp_complete_order(
    12,
    'Daisy',
    'Davis',
    '103-689-4950',
    'Finland',
    'Helsinki',
    'Some address',
    200000.00,
    'PayPal'
);

SELECT fn_register_user('victoria@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(13, 1, 3);
CALL sp_complete_order(
    13,
    'Victoria',
    'Nikolova',
    '293-689-4950',
    'Bulgaria',
    'Plovdiv',
    'Some address',
    200000.00,
    'Stripe'
);

SELECT fn_register_user('angel@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(14, 1, 4);
CALL sp_complete_order(
    14,
    'Angel',
    'Campbell',
    '573-689-4998',
    'Belgium',
    'Brussels',
    'Some address',
    200000.00,
    'PayPal'
);

SELECT fn_register_user('bern@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(15, 7, 1);
CALL sp_complete_order(
    15,
    'Bern',
    'Wilson',
    '983-689-4998',
    'Sweden',
    'Stockholm',
    'Some address',
    200000.00,
    'PayPal'
);

SELECT fn_register_user('mark@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(16, 6, 1);
CALL sp_complete_order(
    16,
    'Mark',
    'Davis',
    '103-689-4998',
    'Belgium',
    'Brussels',
    'Some address',
    200000.00,
    'PayPal'
);

SELECT fn_register_user('berry@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(17, 8, 2);
CALL sp_complete_order(
    17,
    'Berry',
    'Johnson',
    '333-639-4998',
    'Belgium',
    'Brussels',
    'Some address',
    200000.00,
    'Amazon Pay'
);

SELECT fn_register_user('garry@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(18, 9, 2);
CALL sp_complete_order(
    18,
    'Garry',
    'Thompson',
    '452-639-4998',
    'Belgium',
    'Brussels',
    'Some address',
    200000.00,
    'Amazon Pay'
);

CREATE OR REPLACE FUNCTION
    fn_best_selling_to_most_buying_country_via_best_provider(
        provided_employee_id CHAR(5),
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(30)
)
RETURNS TABLE(
            type VARCHAR(10),
            color VARCHAR(15),
            quantity BIGINT,
            provider VARCHAR(30),
            country VARCHAR(30)
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
    ELSIF NOT (
        SELECT credentials_authentication(
        provided_staff_user_role,
        provided_staff_user_password,
        provided_employee_id)
        )
    THEN
        SELECT fn_raise_error_message(
            authorisation_failed
            );
    ELSE
        RETURN QUERY
        SELECT
            jt.name AS jewelry_type,
            gc.color as jewelry_color,
            SUM(sc.quantity) AS sold_quantity,
            (SELECT fn_find_country_by_id(
                cd.countries_cities_id)
             ) as country_name,
            pp.name AS payment_provider_name
        FROM
            shopping_cart AS sc
        JOIN
            inventory AS i
        ON
            sc.inventory_id = i.id
        JOIN
            jewelries AS j
        ON
            i.jewelry_id = j.id
                AND
            i.color_id = j.gold_color_id
        JOIN
            jewelry_type AS jt
        ON
            j.type_id = jt.id
        JOIN
            gold_color AS gc
        ON
            j.gold_color_id = gc.id
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
            orders AS o
        ON
            sc.id = o.shopping_cart_id
        JOIN
            payment_providers AS pp
        ON
            o.payment_provider_id = pp.id
        GROUP BY
            jewelry_type,
            jewelry_color,
            payment_provider_name,
            country_name
        ORDER BY
            sold_quantity DESC
        LIMIT 1;
    END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
    fn_find_country_by_id(in_country_id INTEGER)
RETURNS VARCHAR(30)
AS
$$
BEGIN
    RETURN (
        SELECT
            cou.name
        FROM
            countries AS cou
        JOIN
            countries_cities AS cc
        ON
            cou.id = cc.country_id
        WHERE
            cc.id = in_country_id
        );
END;
$$
LANGUAGE plpgsql;

SELECT fn_best_selling_to_most_buying_country_via_best_provider(
    '10001',
    'super_staff_user',
    'super_staff_user_password');