CREATE OR REPLACE PROCEDURE
    sp_return_back_quantity_to_inventory(
        in_session_id INTEGER,
        in_jewelry_id INTEGER,
        requested_quantity INTEGER
)
AS
$$
BEGIN
    UPDATE
        inventory
    SET
        session_id = in_session_id,
        quantity = quantity + requested_quantity,
        updated_at = NOW()
    WHERE
        jewelry_id = in_jewelry_id;
    IF(
        SELECT
            is_active
        FROM
            jewelries
        WHERE
            id = in_jewelry_id
        ) IS FALSE
    THEN
        UPDATE
            jewelries
        SET
            is_active = TRUE
        WHERE
            id = in_jewelry_id;
    END IF;
    UPDATE
        shopping_cart
    SET
        quantity = quantity - requested_quantity
    WHERE
        jewelry_id = in_jewelry_id;
END;
$$
LANGUAGE plpgsql;

CALL sp_remove_from_shopping_cart(
    1,
    3,
    4
);