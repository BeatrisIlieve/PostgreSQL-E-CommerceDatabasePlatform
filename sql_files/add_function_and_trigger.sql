CREATE OR REPLACE FUNCTION
    trigger_fn_insert_new_entry_into_jewelry_details()
RETURNS TRIGGER
AS
$$
BEGIN
    INSERT INTO
        jewelry_inventory(jewelry_id, jewelry_type_id, quantity, created_at, updated_at, deleted_at)
    VALUES
        (NEW.id, NEW.jewelry_type_id, DEFAULT, DATE(NOW()), NULL, NULL);
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER
    tr_insert_new_entry_rings
AFTER INSERT ON
    rings
FOR EACH ROW
EXECUTE FUNCTION trigger_fn_insert_new_entry_into_jewelry_details();

CREATE OR REPLACE TRIGGER
    tr_insert_new_entry_earrings
AFTER INSERT ON
    earrings
FOR EACH ROW
EXECUTE FUNCTION trigger_fn_insert_new_entry_into_jewelry_details();

CREATE OR REPLACE TRIGGER
    tr_insert_new_entry_necklaces
AFTER INSERT ON
    necklaces
FOR EACH ROW
EXECUTE FUNCTION trigger_fn_insert_new_entry_into_jewelry_details();

CREATE OR REPLACE TRIGGER
    tr_insert_new_entry_bracelets
AFTER INSERT ON
    bracelets
FOR EACH ROW
EXECUTE FUNCTION trigger_fn_insert_new_entry_into_jewelry_details();