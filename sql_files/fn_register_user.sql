CREATE OR REPLACE FUNCTION
    fn_register_user(
        provided_email VARCHAR(30),
        provided_password VARCHAR(15),
        provided_verifying_password VARCHAR(15)
)
RETURNS VOID
AS
$$
DECLARE
    email_already_in_use CONSTANT TEXT :=
        'This email address is already in use. ' ||
        'Please use a different email address or try logging in with your existing account.';

    password_not_secure CONSTANT TEXT :=
        'The password should contain at least one special character and at least one digit. ' ||
        'Please make sure you enter a secure password.';

    passwords_do_not_match CONSTANT TEXT :=
        'The password and password verification do not match. ' ||
        'Please make sure that both fields contain the same password.';

    hashed_password VARCHAR;

BEGIN
    IF provided_email IN (
            SELECT
                email
            FROM
                customer_users
            )
    THEN
        SELECT
            fn_raise_error_message(email_already_in_use);

    ELSIF
        NOT provided_password ~ '[0-9!#$%&()*+,-./:;<=>?@^_`{|}~]'
    THEN
        SELECT
            fn_raise_error_message(password_not_secure);

    ELSIF
        provided_password NOT LIKE provided_verifying_password
    THEN
        SELECT
            fn_raise_error_message(passwords_do_not_match);

    ELSE
        hashed_password := encode(digest(provided_password, 'sha256'), 'hex');

        INSERT INTO customer_users
            (email, password, created_at, updated_at, deleted_at)
        VALUES
            (provided_email, hashed_password , NOW(), NULL, NULL);

        CALL sp_login_user(provided_email, provided_password);

    END IF;
END;
$$
LANGUAGE plpgsql;