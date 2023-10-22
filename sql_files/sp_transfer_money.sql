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