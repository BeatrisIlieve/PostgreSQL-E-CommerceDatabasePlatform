CREATE OR REPLACE FUNCTION
    trigger_fn_insert_new_entry_into_jewelry_details()
RETURNS TRIGGER
AS
$$
BEGIN
    INSERT INTO
        jewelry_details(jewelry_id, jewelry_type_id, created_at, updated_at, deleted_at)
    VALUES
        (NEW.id, NEW.jewelry_type_id, DATE(NOW()), NULL, NULL);
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER
    tr_insert_new_entry
AFTER INSERT ON
    rings
FOR EACH ROW
EXECUTE FUNCTION trigger_fn_insert_new_entry_into_jewelry_details();