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