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