CREATE OR REPLACE FUNCTION
    fn_check_session_has_expired(
        provided_session_id INTEGER
)
RETURNS BOOLEAN
AS
$$
DECLARE
    old_expiration_time TIMESTAMPTZ;
BEGIN
    old_expiration_time := (
        SELECT
            expiration_time
        FROM
            sessions
        WHERE
            id = provided_session_id
        );
    IF
        NOW() >= old_expiration_time
    THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$
LANGUAGE plpgsql;
