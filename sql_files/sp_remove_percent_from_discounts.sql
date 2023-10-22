CREATE OR REPLACE PROCEDURE
    sp_remove_percent_from_discounts(
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(30),
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
            deleted_at = NOW()
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

CALL sp_remove_percent_from_discounts(
    'merchandising_staff_user_first',
    'merchandising_password_first',
    '10002',
    2);