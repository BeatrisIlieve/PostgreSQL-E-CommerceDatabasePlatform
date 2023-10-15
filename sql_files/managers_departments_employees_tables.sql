CREATE TABLE
    managers(
        id INTEGER GENERATED ALWAYS AS IDENTITY ( START WITH 30001 INCREMENT 1 ) PRIMARY KEY,
        first_name VARCHAR(30),
        last_name VARCHAR(30),
        email VARCHAR(30),
        phone_number VARCHAR(20),
        employed_at DATE
);

insert into managers (first_name, last_name, email, phone_number, employed_at) values ('Bab', 'Delagua', 'bdelagua1@buzzfeed.com', '805-186-8739', '9/5/2023');
insert into managers (first_name, last_name, email, phone_number, employed_at) values ('Rubia', 'Franssen', 'rfranssen0@umich.edu', '638-526-2342', '8/3/2023');
insert into managers (first_name, last_name, email, phone_number, employed_at) values ('Rem', 'Cordell', 'rcordell3@tuttocitta.it', '522-523-4027', '7/16/2023');
insert into managers (first_name, last_name, email, phone_number, employed_at) values ('Danice', 'Dunne', 'ddunne4@noaa.gov', '922-710-6398', '10/16/2022');
insert into managers (first_name, last_name, email, phone_number, employed_at) values ('Grenville', 'Addie', 'gaddie6@ehow.com', '809-184-2377', '9/3/2023');

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

insert into departments (manager_id, department_name) values (30001, 'Merchandising');
insert into departments (manager_id, department_name) values (30002, 'Purchasing');
insert into departments (manager_id, department_name) values (30003, 'Shipping');
insert into departments (manager_id, department_name) values (30004, 'Quality Control');
insert into departments (manager_id, department_name) values (30005, 'Customer Service');

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

insert into employees (department_id, first_name, last_name, email, phone_number, employed_at) values (20001, 'Terri', 'Aldersley', 'taldersley0@army.mil', '198-393-2278', '5/9/2023');
insert into employees (department_id, first_name, last_name, email, phone_number, employed_at) values (20002, 'Gustav', 'Harte', 'gharte1@usa.gov', '448-500-3956', '2/3/2023');
insert into employees (department_id, first_name, last_name, email, phone_number, employed_at) values (20003, 'Moina', 'Smy', 'msmy2@weather.com', '704-615-7509', '1/19/2023');
insert into employees (department_id, first_name, last_name, email, phone_number, employed_at) values (20005, 'Mariette', 'Caltera', 'mcaltera4@cpanel.net', '515-969-8114', '12/26/2022');
insert into employees (department_id, first_name, last_name, email, phone_number, employed_at) values (20006, 'Nicky', 'Attewill', 'nattewill5@ebay.com', '342-225-4473', '9/11/2023');
