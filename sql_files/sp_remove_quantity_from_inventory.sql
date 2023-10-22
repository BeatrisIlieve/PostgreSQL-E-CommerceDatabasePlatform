CREATE OR REPLACE PROCEDURE
    sp_remove_quantity_from_inventory(
        in_session_id INTEGER,
        in_jewelry_id INTEGER,
        requested_quantity INTEGER,
        current_quantity INTEGER
)
AS
$$
BEGIN
    UPDATE
        inventory
    SET
        quantity = quantity - requested_quantity,
        session_id = in_session_id,
        deleted_at = NOW()
    WHERE
        jewelry_id = in_jewelry_id;
    IF
        current_quantity - requested_quantity = 0
    THEN
        UPDATE
            jewelries
        SET
            is_active = FALSE
        WHERE
            id = in_jewelry_id;
    END IF;
END;
$$
LANGUAGE plpgsql;