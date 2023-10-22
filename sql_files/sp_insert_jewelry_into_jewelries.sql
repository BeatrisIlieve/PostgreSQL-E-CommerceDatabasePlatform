CREATE OR REPLACE PROCEDURE
    sp_insert_jewelry_into_jewelries(
        provided_staff_user_role VARCHAR(30),
        provided_staff_user_password VARCHAR(9),
        provided_employee_id CHAR(5),
        provided_type_id INTEGER,
        provided_name VARCHAR(100),
        provided_image_url VARCHAR(200) ,
        provided_regular_price DECIMAL(7, 2),
        provided_metal_color VARCHAR(12),
        provided_diamond_carat_weight VARCHAR(10),
        provided_diamond_clarity VARCHAR(10),
        provided_diamond_color VARCHAR(5),
        provided_description TEXT
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
                      type_id, name, image_url,
                      regular_price, metal_color,
                      diamond_carat_weight,
                      diamond_clarity,
                      diamond_color,
                      description
                )
        VALUES
            (
            provided_type_id,
            provided_name,
            provided_image_url,
            provided_regular_price,
            provided_metal_color,
            provided_diamond_carat_weight,
            provided_diamond_clarity,
            provided_diamond_color,
            provided_description
            );

        current_jewelry_id := (
            SELECT
                MAX(id)
            FROM
                jewelries
        );

        INSERT INTO
            inventory(
                      employee_id,
                      jewelry_id,
                      created_at,
                      updated_at,
                      deleted_at
                      )
        VALUES
            (
             provided_employee_id::INTEGER,
             current_jewelry_id,
             NOW(),
             NULL,
             NULL
             );
    ELSE
        SELECT fn_raise_error_message(authorisation_failed);
    END IF;
END;
$$
LANGUAGE plpgsql;