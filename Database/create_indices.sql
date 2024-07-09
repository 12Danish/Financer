-- Indexes
USE Financer;

-- Indexing for user table
-- Index on dob for queries filtering by date of birth
CREATE INDEX idx_dob_user ON user (dob);

-- Composite index on first_name and last_name for queries filtering by both
CREATE INDEX idx_name_user ON user (first_name, last_name);

--  index on status
CREATE INDEX idx_status_user ON user (status);

-- Indexing for company
CREATE INDEX idx_name_company ON company (name);

CREATE INDEX idx_reg_datetime_company ON company (reg_datetime);

CREATE INDEX idx_status_company ON company (status);

-- Indexing for dept_type
CREATE UNIQUE INDEX idx_name_dept_type ON department_type (dept_name);

-- Indexing on department
CREATE INDEX idx_status_department ON department (status);

-- Indexing on MANAGER 
CREATE INDEX idx_company_id_manager ON manager (company_id);

CREATE INDEX idx_company_dept_manager ON manager (company_id, dept_type);

CREATE INDEX idx_title_manager ON manager (title);

-- Indexing on employee
CREATE INDEX idx_company_id_employee ON employee (company_id);

CREATE INDEX idx_company_dept_employee ON employee (company_id, dept_type);

CREATE INDEX idx_title_employee ON employee (title);

CREATE INDEX idx_manager_id_employee ON employee (manager_id);

-- Indexing on salary_audit
CREATE INDEX idx_staff_id_salary_audit ON salary_audit (staff_id);
CREATE INDEX idx_dept_type_salary_audit ON salary_audit(dept_type);
CREATE INDEX idx_company_id_salary_audit ON salary_audit(company_id);
CREATE INDEX idx_date_salary_audit ON salary_audit (date);

-- Indexing for hiring_audit
CREATE INDEX idx_staff_id_hiring_audit ON hiring_audit (staff_id);
CREATE INDEX idx_date_hiring_audit ON hiring_audit (date);

CREATE INDEX idx_company_id_hiring_audit ON hiring_audit (company_id);

CREATE INDEX idx_dept_type_hiring_audit ON hiring_audit (dept_type);

CREATE INDEX idx_managed_by_hiring_audit ON hiring_audit (managed_by);

CREATE INDEX idx_title_hiring_audit ON hiring_audit (title);

CREATE INDEX idx_position_hiring_audit ON hiring_audit (position);

CREATE INDEX idx_status_hiring_audit ON hiring_audit (status);

-- Indexing for account
CREATE index idx_company_id_account ON account (company_id);

CREATE index idx_dept_account ON account (company_id, dept_type);

CREATE index idx_status_account ON account (status);

-- Indexing for account_audit
CREATE INDEX idx_account_number_account_audit ON account_audit (account_number);

CREATE INDEX idx_date_account_audit ON account_audit (datetime);

-- Indexing for transaction
CREATE INDEX idx_transaction_sender ON transaction (sender);

CREATE INDEX idx_transaction_receiver ON transaction (receiver);

CREATE INDEX idx_transaction_datetime ON transaction (datetime);

CREATE INDEX idx_transaction_transaction_type ON transaction (transaction_type);

-- Indexing for budget
CREATE INDEX idx_budget_company_id ON budget (company_id);

CREATE INDEX idx_budget_dept ON budget (company_id, dept_type);

-- Indexing for Credit transaction type
CREATE INDEX idx_credit_transaction_type_type_name ON credit_transaction_type (type_name);

CREATE INDEX idx_credit_transaction_type_type_category ON credit_transaction_type (type_category);

-- Indexing for credit transaction 
CREATE INDEX idx_credit_transaction_budget_id ON credit_transaction (budget_id);

CREATE INDEX idx_credit_transaction_transaction_number ON credit_transaction (transaction_number);

CREATE INDEX idx_credit_transaction_type_id ON credit_transaction (type_id);

-- indexing for credit_transaction
CREATE INDEX idx_credit_transaction_audit_type_id ON credit_transaction_audit (type_id);

CREATE INDEX idx_credit_transaction_audit_transaction_budget ON credit_transaction_audit (budget);

CREATE INDEX idx_credit_transaction_audit_company_id ON credit_transaction_audit (company_id);

CREATE INDEX idx_credit_transaction_audit_dept_type ON credit_transaction_audit (dept_type);

CREATE INDEX idx_credit_transaction_audit_datetime ON credit_transaction_audit (datetime);
