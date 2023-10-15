CREATE OR REPLACE PROCEDURE
    sp_insert_new_quantity_into_jewelry_details(added_quantity INTEGER, item_id INTEGER, item_type_id INTEGER)
AS
$$
BEGIN
    UPDATE
        jewelry_inventory
    SET
        quantity = quantity + added_quantity
    WHERE
        jewelry_id = item_id
            AND
        jewelry_type_id = item_type_id;
END;
$$
LANGUAGE plpgsql;



CALL sp_insert_new_quantity_into_jewelry_details(200, 2, 1);