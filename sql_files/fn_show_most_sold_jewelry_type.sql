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

SELECT fn_show_most_sold_jewelry_type(
    '10001',
    'super_staff_user',
    'super_staff_user_password');