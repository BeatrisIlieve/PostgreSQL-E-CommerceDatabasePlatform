CREATE OR REPLACE PROCEDURE
    sp_add_quantity_into_inventory(
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(9),
        provided_employee_id CHAR(5),
        provided_session_id INTEGER,
        provided_jewelry_id INTEGER,
        added_quantity INTEGER
)
AS
$$
DECLARE
    access_denied CONSTANT TEXT := 'Access Denied: You do not have the required authorization to perform actions into this department.';
    authorisation_failed CONSTANT TEXT := 'Authorization failed: Incorrect password';
BEGIN
    IF
        provided_session_id IS NOT NULL
    THEN
        UPDATE
            inventory
        SET
            session_id = provided_session_id,
            quantity = quantity + added_quantity,
            updated_at = NOW()
        WHERE
            jewelry_id = provided_jewelry_id;
        UPDATE
            jewelries
        SET
            is_active = TRUE
        WHERE
            id = provided_jewelry_id;
    ELSE
        IF NOT(
            SELECT fn_role_authentication(
                        'inventory', provided_employee_id
                        )
            )
        THEN
            SELECT fn_raise_error_message(access_denied);
        END IF;
        IF(
            SELECT credentials_authentication(
                provided_staff_user_role,
                provided_staff_user_password,
                provided_employee_id)
            )IS TRUE
        THEN
            UPDATE
                inventory
            SET
                employee_id = provided_employee_id::INTEGER,
                quantity = quantity + added_quantity,
                updated_at = NOW()
            WHERE
                jewelry_id = provided_jewelry_id;
            UPDATE
                jewelries
            SET
                is_active = TRUE
            WHERE
                id = provided_jewelry_id;
        ELSE
            SELECT fn_raise_error_message(authorisation_failed);
        END IF;
    END IF;
END;
$$
LANGUAGE plpgsql;