USE Financer;

CREATE TABLE user (
    reg_id INT AUTO_INCREMENT,
    cnic CHAR(13),
    dob DATE,
    first_name VARCHAR(70),
    last_name VARCHAR(70),
    status ENUM ('active', 'inactive'),
    CONSTRAINT PRIMARY KEY (reg_id),
    CONSTRAINT user_check_len_cnic CHECK (
        CHAR_LENGTH(cnic) = 13
        AND cnic REGEXP '^[0-9]+$'
    )
);

CREATE TABLE company (
    company_id INT AUTO_INCREMENT,
    name VARCHAR(100),
    reg_date DATE,
    status ENUM ('active', 'inactive'),
    CONSTRAINT PRIMARY KEY (company_id)
);

CREATE TABLE owner (
    owner_id INT,
    company_id INT,
    CONSTRAINT PRIMARY KEY (owner_id, company_id),
    CONSTRAINT owner_fk_owner_id FOREIGN KEY (owner_id) REFERENCES user (reg_id) ON DELETE CASCADE,
    CONSTRAINT owner_fk_company_id FOREIGN KEY (company_id) REFERENCES company (company_id) ON DELETE CASCADE
);

CREATE TABLE department_type (
    dept_id INT auto_increment,
    dept_name VARCHAR(100),
    CONSTRAINT PRIMARY KEY (dept_id)
);

CREATE TABLE department (
    dept_type INT,
    company_id INT,
    status ENUM ('active', 'inactive'),
    CONSTRAINT dept_comp_pk PRIMARY KEY (dept_type, company_id),
    CONSTRAINT department_fk_dept_type FOREIGN KEY (dept_type) REFERENCES department_type (dept_id) ON DELETE CASCADE,
    CONSTRAINT department_fk_company_id FOREIGN KEY (company_id) REFERENCES company (company_id) ON DELETE CASCADE
);

CREATE TABLE manager (
    manager_id INT,
    dept_type INT,
    title varchar(70),
    company_id INT,
    salary DECIMAL,
    CONSTRAINT manager_pk PRIMARY KEY (manager_id),
    CONSTRAINT manager_salary_gt_0 CHECK (salary > 0),
    CONSTRAINT manager_fk_manager_id FOREIGN KEY (manager_id) REFERENCES user (reg_id) ON DELETE cascade,
    CONSTRAINT manager_fk_dept_type FOREIGN KEY (dept_type) REFERENCES department_type (dept_id) ON DELETE SET NULL,
    CONSTRAINT manager_fk_company_id FOREIGN KEY (company_id) REFERENCES company (company_id) ON DELETE SET NULL
);

CREATE TABLE employee (
    emp_id INT,
    manager_id INT,
    title varchar(70),
    dept_type INT,
    company_id INT,
    salary DECIMAL,
    CONSTRAINT employee_pk PRIMARY KEY (emp_id),
    CONSTRAINT employee_salary_check check (salary > -1),
    CONSTRAINT employee_fk_manager_id FOREIGN KEY (manager_id) REFERENCES manager (manager_id) ON DELETE SET NULL,
    CONSTRAINT employee_fk_dept_type FOREIGN KEY (dept_type) REFERENCES department_type (dept_id) ON DELETE SET NULL,
    CONSTRAINT employee_fk_company_id FOREIGN KEY (company_id) REFERENCES company (company_id) ON DELETE SET NULL
);

CREATE TABLE salary_audit (
    audit_id INT auto_increment,
    staff_id INT,
    salary DECIMAL(10, 2),
    date DATE,
    CONSTRAINT salary_audit_pk PRIMARY KEY (audit_id),
    CONSTRAINT salary_audit_check_salary_gt_0 CHECK (salary >= 0),
    CONSTRAINT salary_audit_fk_staff_id FOREIGN KEY (staff_id) REFERENCES user (reg_id) ON DELETE set null
);

CREATE TABLE hiring_audit (
    audit_id INT auto_increment,
    staff_id INT,
    date DATE,
    title varchar(70),
    dept_type INT,
    company_id INT,
    position ENUM ('manager', 'employee'),
    status ENUM ('active', 'inactive'),
    CONSTRAINT hiring_audit_pk PRIMARY KEY (audit_id),
    CONSTRAINT hiring_audit_fk_staff_id FOREIGN KEY (staff_id) REFERENCES user (reg_id) ON DELETE set null,
    CONSTRAINT hiring_audit_fk_dept_type FOREIGN KEY (dept_type) REFERENCES department_type (dept_id) ON DELETE SET NULL,
    CONSTRAINT hiring_audit_fk_company_id FOREIGN KEY (company_id) REFERENCES company (company_id) ON DELETE SET NULL
);

CREATE TABLE account (
    account_number VARCHAR(12),
    status ENUM ('active', 'inactive'),
    balance DECIMAL(10, 2),
    staff_id INT,
    company_id INT,
    dept_type INT NULL,
    CONSTRAINT account_pk PRIMARY KEY (account_number),
    CONSTRAINT account_chk_account_number CHECK (
        LENGTH (account_number) BETWEEN 8 AND 12
        AND account_number REGEXP '^[a-zA-Z0-9]{8,12}$'
    ),
    CONSTRAINT account_check_amount_gt_0 CHECK (balance >= 0),
    CONSTRAINT account_fk_staff_id FOREIGN KEY (staff_id) references user (reg_id) ON DELETE cascade,
    CONSTRAINT account_fk_company FOREIGN KEY (company_id) REFERENCES company (company_id) ON DELETE SET NULL,
    CONSTRAINT account_fk_department FOREIGN KEY (dept_type) REFERENCES department_type (dept_id) ON DELETE SET NULL
);

CREATE TABLE account_audit (
    audit_id INT AUTO_INCREMENT,
    account_number VARCHAR(12),
    balance DECIMAL(10, 2),
    datetime DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_account_audit PRIMARY KEY (audit_id),
    CONSTRAINT account_audit_check_amount_gt_0 CHECK (balance >= 0),
    CONSTRAINT account_audit_fk_account_number FOREIGN KEY (account_number) REFERENCES account (account_number) ON DELETE CASCADE
);

CREATE TABLE transaction (
    transaction_number INT auto_increment primary key,
    transaction_type ENUM ('credit', 'debit'),
    sender VARCHAR(12),
    amount DECIMAL(12, 2),
    receiver VARCHAR(12),
    datetime DATETIME,
    CONSTRAINT transaction_chk_receiver_account_number CHECK (
        LENGTH (receiver) BETWEEN 8 AND 12
        AND receiver REGEXP '^[a-zA-Z0-9]{8,12}$'
    ),
    CONSTRAINT transaction_chk_sender_account_number CHECK (
        LENGTH (sender) BETWEEN 8 AND 12
        AND sender REGEXP '^[a-zA-Z0-9]{8,12}$'
    ),
    CONSTRAINT transaction_check_amount_gt_0 CHECK (amount > 0)
);

CREATE TABLE budget (
    budget_id INT auto_increment,
    amount DECIMAL(15, 3),
    company_id INT,
    dept_type INT,
    CONSTRAINT budget_pk PRIMARY KEY (budget_id),
    CONSTRAINT budget_check_amount_gt_0 CHECK (amount > 0),
    CONSTRAINT budget_fk_company_id FOREIGN KEY (company_id) REFERENCES company (company_id) ON DELETE SET NULL,
    CONSTRAINT budget_fk_department_type FOREIGN KEY (dept_type) REFERENCES department_type (dept_id) ON DELETE SET NULL
);

CREATE TABLE credit_transaction_type (
    type_id INT auto_increment,
    type_category ENUM ('expense', 'investment'),
    type_name VARCHAR(120),
    CONSTRAINT credit_transaction_type_pk PRIMARY KEY (type_id)
);

CREATE TABLE credit_transaction (
    type_id INT,
    transaction_number INT,
    budget_id INT default NULL,
    CONSTRAINT credit_transaction_pk PRIMARY KEY credit_transaction (type_id, transaction_number),
    CONSTRAINT credit_transaction_fk_type_id FOREIGN KEY (type_id) REFERENCES credit_transaction_type (type_id) ON DELETE CASCADE,
    CONSTRAINT credit_transaction_fk_transaction_number FOREIGN KEY (transaction_number) REFERENCES transaction (transaction_number) ON DELETE CASCADE,
    CONSTRAINT credit_transaction_fk_budget_id FOREIGN KEY (budget_id) references budget (budget_id) ON DELETE SET NULL
);

CREATE TABLE credit_transaction_audit (
    audit_id INT auto_increment,
    type_id INT,
    transaction_number INT,
    company_id INT,
    dept_type INT,
    budget DECIMAL(15, 3),
    datetime datetime default current_timestamp,
    CONSTRAINT credit_transaction_audit_pk PRIMARY KEY (audit_id),
    CONSTRAINT credit_transaction_audit_fk_type_id FOREIGN KEY (type_id) REFERENCES credit_transaction_type (type_id) ON delete SET NULL,
    CONSTRAINT credit_transaction_audit_fk_company_id FOREIGN KEY (company_id) REFERENCES company (company_id) ON delete cascade,
    CONSTRAINT credit_transaction_audit_fk_dept_type FOREIGN KEY (dept_type) REFERENCES department_type (dept_id) ON delete CASCADE,
    CONSTRAINT credit_transaction_audit_transaction_number FOREIGN KEY (transaction_number) REFERENCES transaction (transaction_number) ON DELETE CASCADE,
    CONSTRAINT credit_transaction_audit_budget_check_gt_0 CHECK (budget >= 0)
);
