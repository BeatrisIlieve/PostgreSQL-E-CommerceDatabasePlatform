CREATE OR REPLACE PROCEDURE
    sp_remove_from_shopping_cart(
        provided_session_id INTEGER,
        provided_jewelry_id INTEGER,
        provided_quantity INTEGER
    )
AS
$$
DECLARE
    session_has_expired CONSTANT TEXT :=
        'Your shopping session has expired. ' ||
        'To continue shopping, please log in again.';

BEGIN
    IF (
        SELECT fn_check_session_has_expired(
            provided_session_id
            )
        ) IS TRUE
    THEN
        SELECT
            fn_raise_error_message(
                session_has_expired
                );
    ELSE
        CALL sp_return_back_quantity_to_inventory(
            provided_session_id,
            provided_jewelry_id,
            provided_quantity
            );
    END IF;
END;
$$
LANGUAGE plpgsql;
