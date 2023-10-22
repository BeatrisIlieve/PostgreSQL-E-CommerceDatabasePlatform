CREATE OR REPLACE FUNCTION
    trigger_fn_insert_new_entity_into_inventory_records_on_update()
RETURNS TRIGGER
AS
$$
DECLARE
    operation_type VARCHAR(6);
BEGIN
    operation_type :=
        (CASE
            WHEN OLD.quantity < NEW.quantity THEN 'Update'
            WHEN OLD.quantity > NEW.quantity THEN 'Delete'
        END);
    INSERT INTO
            inventory_records(inventory_id, operation, date)
    VALUES
        (OLD.id, operation_type, NOW());
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER
    tr_insert_new_entity_into_inventory_records_on_update
AFTER UPDATE ON
    inventory
FOR EACH ROW
EXECUTE FUNCTION
    trigger_fn_insert_new_entity_into_inventory_records_on_update();

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_first',
    'inventory_password_first',
    '10004',
    NULL,
    1,
    9);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_second',
    'inventory_password_second',
    '10005',
    NULL,
    2,
    7);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_first',
    'inventory_password_first',
    '10004',
    NULL,
    3,
    5);

CALL sp_add_quantity_into_inventory(
    'inventory_staff_user_second',
    'inventory_password_second',
    '10005',
    NULL,
    4,
    3);