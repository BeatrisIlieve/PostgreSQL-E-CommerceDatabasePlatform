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

CALL sp_insert_percent_into_discounts(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    1,
    0.10);

CALL sp_insert_percent_into_discounts(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    2,
    0.10);