CREATE TABLE
    jewelry_inventory(
        jewelry_id INTEGER NOT NULL,
        jewelry_type_id INTEGER NOT NULL,
        quantity INTEGER DEFAULT 0 NOT NULL,
        created_at TIMESTAMP NOT NULL,
        updated_at TIMESTAMP,
        deleted_at TIMESTAMP
);