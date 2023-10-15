CREATE TABLE
    managers(
        id INTEGER GENERATED ALWAYS AS IDENTITY ( START WITH 30001 INCREMENT 1 ) PRIMARY KEY,
        first_name VARCHAR(30),
        last_name VARCHAR(30),
        email VARCHAR(30),
        phone_number VARCHAR(20),
        employed_at DATE
);


CREATE TABLE
    departments(
        id INTEGER GENERATED ALWAYS AS IDENTITY ( START WITH 20001 INCREMENT 1 ) PRIMARY KEY,
        manager_id INTEGER UNIQUE NOT NULL,
        department_name VARCHAR(30),

        CONSTRAINT fk_departments_managers
               FOREIGN KEY (manager_id)
               REFERENCES managers(id)
               ON UPDATE CASCADE
               ON DELETE CASCADE
);

CREATE TABLE
    employees(
        id INTEGER GENERATED ALWAYS AS IDENTITY ( START WITH 10001 INCREMENT 1 ) PRIMARY KEY,
        department_id INTEGER,
        first_name VARCHAR(30),
        last_name VARCHAR(30),
        email VARCHAR(30),
        phone_number VARCHAR(20),
        employed_at DATE,
        
        CONSTRAINT fk_employees_departments
             FOREIGN KEY (department_id)
             REFERENCES departments(id)
             ON UPDATE CASCADE 
             ON DELETE CASCADE 
);

CREATE TABLE 
    activities_record(
        id SERIAL PRIMARY KEY,
        employee_id INTEGER NOT NULL,
        type_of_activity VARCHAR(6) NOT NULL,
        description VARCHAR(200) NOT NULL,
        date_and_time TIMESTAMPTZ,
        
        CONSTRAINT fk_activities_record_employees
                     FOREIGN KEY (employee_id)
                     REFERENCES employees(id)
                     ON UPDATE CASCADE 
                     ON DELETE CASCADE 
);

