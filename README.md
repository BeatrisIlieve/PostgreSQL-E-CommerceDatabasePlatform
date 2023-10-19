# PostgreSQL-E-Commerce-Database-Platform

## Entity Relationship Diagram:
![Diagram](https://github.com/BeatrisIlieve/PostgreSQL-E-CommerceDatabasePlatform/assets/122045435/82eb2acf-a104-46b1-bbda-d8ca7573cffc)

#### For the Demo purposes of this project we have created two departments - 'Merchandising' and 'Inventory'. We simulated having Super User and Regular Users, having specific roles at the departments they belong to. They authenticate themselves via username and password kept in the database.
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
#### 
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



#### After registration process is finished, customers are <ins>Automatically logged-in</ins> via Tigger that executes login-function on Insert into the 
