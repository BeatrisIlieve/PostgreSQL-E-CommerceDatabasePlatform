CREATE OR REPLACE PROCEDURE
    sp_add_to_shopping_cart(
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

    item_has_been_sold_out CONSTANT TEXT :=
        'This item has been sold out.';

    current_quantity INTEGER;

    not_enough_quantity CONSTANT TEXT :=
        'Not enough quantity';

BEGIN
    current_quantity := (
        SELECT
            quantity
        FROM
            inventory
        WHERE
            jewelry_id = provided_jewelry_id
        );

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

    ELSIF (
        SELECT
            is_active
        FROM
            jewelries
        WHERE
            id = provided_jewelry_id
        ) IS FALSE
    THEN
        SELECT fn_raise_error_message(
            item_has_been_sold_out
            );

    ELSIF
        current_quantity < provided_quantity
    THEN
        SELECT fn_raise_error_message(
            not_enough_quantity
            );

    ELSE
        IF provided_jewelry_id IN (
            SELECT
                jewelry_id
            FROM
                shopping_cart
            WHERE
                session_id = provided_session_id
            )
        THEN
            UPDATE
                shopping_cart
            SET
                quantity = quantity + provided_quantity
            WHERE
                jewelry_id = provided_jewelry_id;

        ELSE
            INSERT INTO
                shopping_cart(
                              session_id,
                              jewelry_id,
                              quantity
                              )
            VALUES
                (provided_session_id,
                 provided_jewelry_id,
                 provided_quantity
                 );
        END IF;

        CALL sp_remove_quantity_from_inventory(
            provided_session_id,
            provided_jewelry_id,
            provided_quantity,
            current_quantity
            );
    END IF;
END;
$$
LANGUAGE plpgsql;
