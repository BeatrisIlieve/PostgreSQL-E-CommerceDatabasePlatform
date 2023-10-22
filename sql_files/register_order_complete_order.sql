SELECT fn_register_user('welch@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(2, 2, 3);
CALL sp_complete_order(
    2,
    'Welch',
    'Gorries',
    '711-704-9768',
    39556.55,
    'Amazon Pay'
);

SELECT fn_register_user('kellie@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(3, 4, 1);
CALL sp_complete_order(
    3,
    'Kellie',
    'Minihane',
    '231-204-9598',
    73205.18,
    'PayPal'
);


SELECT fn_register_user('flora@email.com', '#6hhh', '#6hhh');
CALL sp_add_to_shopping_cart(4, 2, 3);
CALL sp_complete_order(
    4,
    'Flora',
    'Keating',
    '203-679-4950',
    52205.18,
    'Stripe'
);
