-- Triggers
USE Financer;

DELIMITER $$

-- Trigger for adding entry in hiring_audit after employee insertion
CREATE TRIGGER after_employee_insert_manage_hiring_audit 
AFTER INSERT ON employee
FOR EACH ROW 
BEGIN 
   CALL set_user_status_active_on_staff_insertion(NEW.emp_id);
   CALL check_has_manager_post_emp_deletion_or_insertion(
     NEW.emp_id,
     NEW.manager_id,
     NEW.title,
     NEW.dept_type,
     NEW.company_id,
     "insert"
   );
   CALL insert_into_hiring_audit(NEW.emp_id, NEW.manager_id, NEW.title, NEW.dept_type, NEW.company_id, 'active', 'employee');
END$$

-- Trigger for adding entry in hiring audit after manager insertion 
CREATE TRIGGER after_manager_insert_manage_hiring_audit
AFTER INSERT ON manager
FOR EACH ROW 
BEGIN 
    -- Declaring local variables 
    DECLARE managed_by INT;
    CALL set_user_status_active_on_staff_insertion(NEW.manager_id);

    -- Call the FindManagersManager function and store the result in managed_by
    SET managed_by = check_has_manager_post_manager_deletion_or_insertion(NEW.manager_id);

    -- Insert the audit entry using the function result
    CALL insert_into_hiring_audit(NEW.manager_id, managed_by, NEW.title, NEW.dept_type, NEW.company_id, 'active', 'manager');
END$$

-- Trigger for handling removal of Employee in hiring audit
CREATE TRIGGER after_employee_removal_manage_hiring_audit
AFTER DELETE ON employee
FOR EACH ROW 
BEGIN
    CALL check_has_manager_post_emp_deletion_or_insertion(
     OLD.emp_id,
     OLD.manager_id,
     OLD.title,
     OLD.dept_type,
     OLD.company_id,
     "delete"
    );
    CALL insert_into_hiring_audit(OLD.emp_id, OLD.manager_id, OLD.title, OLD.dept_type, OLD.company_id, 'inactive', 'employee');
END$$

-- Trigger for handling insertion of manager's employees into hiring audit
CREATE TRIGGER before_manager_delete_insert_managed_employees_in_hiring_audit
BEFORE DELETE ON manager
FOR EACH ROW 
BEGIN 
 -- Inserting all the manager's employees who have manager_id as null now 
    CALL employees_of_manager_into_hiring_audit_after_manager_removal(OLD.manager_id);
END$$

-- Trigger for handling hiring audit after manager removal
CREATE TRIGGER after_manager_removal_manage_hiring_audit
AFTER DELETE ON manager
FOR EACH ROW 
BEGIN 
    -- Declaring local variables 
    DECLARE managed_by INT;

    -- Call the function and store the result in managed_by
    SET managed_by = check_has_manager_post_manager_deletion_or_insertion(OLD.manager_id);

    -- Insert the audit entry using the function result
    CALL insert_into_hiring_audit(OLD.manager_id, managed_by, OLD.title, OLD.dept_type, OLD.company_id, 'inactive', 'manager');
END$$

-- Creating a trigger to handle status on user after deletion in employee table
CREATE TRIGGER after_employee_removal_handle_user_status
AFTER DELETE ON employee
FOR EACH ROW 
BEGIN 
    DECLARE manager_position INT;
    SET manager_position = find_possible_position_after_employee_deletion(OLD.emp_id);
    IF manager_position = 0 THEN
        CALL set_user_status_inactive_on_staff_deletion(OLD.emp_id);
    END IF;
END$$

-- Creating a trigger to handle status on user after deletion in manager table
CREATE TRIGGER after_manager_removal_handle_user_status
AFTER DELETE ON manager
FOR EACH ROW 
BEGIN 
    DECLARE emp_position INT;
    SET emp_position = find_possible_position_after_manager_deletion(OLD.manager_id);
    IF emp_position = 0 THEN
        CALL set_user_status_inactive_on_staff_deletion(OLD.manager_id);
    END IF;
END$$

-- This trigger prevents updating manager_id and company_id for manager
CREATE TRIGGER prevent_update_on_manager_id_and_company_id
BEFORE UPDATE ON manager
FOR EACH ROW
BEGIN
    IF NEW.manager_id != OLD.manager_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You are not allowed to update the manager_id column.';
    END IF;

    IF NEW.company_id != OLD.company_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You are not allowed to update the company_id column.';
    END IF;
END$$

-- This trigger prevents updating emp_id and company_id for employee
CREATE TRIGGER prevent_update_on_emp_id_and_company_id
BEFORE UPDATE ON employee
FOR EACH ROW
BEGIN
    IF NEW.emp_id != OLD.emp_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You are not allowed to update the emp_id column.';
    END IF;

    IF NEW.company_id != OLD.company_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You are not allowed to update the company_id column.';
    END IF;
END$$

-- Handling user status after owner insertion 
CREATE TRIGGER after_owner_insert_handle_user_status
AFTER INSERT ON owner
FOR EACH ROW
BEGIN 
    CALL set_user_status_active_on_staff_insertion(NEW.owner_id);
END$$

-- Handling user status after owner deletion
CREATE TRIGGER after_owner_delete_handle_user_status
AFTER DELETE ON owner
FOR EACH ROW
BEGIN 
    DECLARE is_active_owner INT;
    SET is_active_owner = check_is_owner(OLD.owner_id);
    IF is_active_owner = 0 THEN
        CALL set_user_status_inactive_on_staff_deletion(OLD.owner_id);
    END IF;
END$$

-- This trigger handles updating managed_by, title, dept_type 
CREATE TRIGGER update_employee_handle_hiring_audit
AFTER UPDATE ON employee
FOR EACH ROW
BEGIN
    DECLARE is_manager INT;
    
    -- Check if manager_id is being updated
    IF (NEW.manager_id != OLD.manager_id) OR 
       (NEW.manager_id IS NULL AND OLD.manager_id IS NOT NULL) OR
       (NEW.manager_id IS NOT NULL AND OLD.manager_id IS NULL)
    THEN
        SET is_manager = check_is_manager(OLD.emp_id);
        
        -- If the employee is a manager
        IF is_manager = 1 THEN
            CALL insert_into_hiring_audit(OLD.emp_id, OLD.manager_id, OLD.title, OLD.dept_type, OLD.company_id, 'inactive', 'employee');
            CALL insert_into_hiring_audit(OLD.emp_id, NEW.manager_id, NEW.title, NEW.dept_type, OLD.company_id, 'active', 'employee');
            CALL insert_into_hiring_audit(OLD.emp_id, OLD.manager_id, OLD.title, OLD.dept_type, OLD.company_id, 'inactive', 'manager');
            CALL insert_into_hiring_audit(OLD.emp_id, NEW.manager_id, NEW.title, NEW.dept_type, OLD.company_id, 'active', 'manager');
        ELSE
            -- If the employee is not a manager
            CALL insert_into_hiring_audit(OLD.emp_id, OLD.manager_id, OLD.title, OLD.dept_type, OLD.company_id, 'inactive', 'employee');
            CALL insert_into_hiring_audit(OLD.emp_id, NEW.manager_id, NEW.title, NEW.dept_type, OLD.company_id, 'active', 'employee');
        END IF;
        
    -- Check if title or dept_type is being updated
    ELSEIF NEW.title != OLD.title OR NEW.dept_type != OLD.dept_type THEN
        CALL insert_into_hiring_audit(OLD.emp_id, OLD.manager_id, OLD.title, OLD.dept_type, OLD.company_id, 'inactive', 'employee');
        CALL insert_into_hiring_audit(OLD.emp_id, NEW.manager_id, NEW.title, NEW.dept_type, OLD.company_id, 'active', 'employee');
    END IF;
END$$

-- This trigger handles changes in manager related to hiring audit 
CREATE TRIGGER update_manager_handle_hiring_audit
AFTER UPDATE ON manager 
FOR EACH ROW 
BEGIN 
	DECLARE managed_by INT;
    SET managed_by = check_has_manager_post_manager_deletion_or_insertion(OLD.manager_id);
IF NEW.title != OLD.title OR NEW.dept_type != OLD.dept_type THEN
        CALL insert_into_hiring_audit(OLD.manager_id,managed_by, OLD.title, OLD.dept_type, OLD.company_id, 'inactive', 'manager');
        CALL insert_into_hiring_audit(NEW.manager_id,managed_by, NEW.title, NEW.dept_type, OLD.company_id, 'active', 'manager');
    END IF;
END$$

-- handling salary audit for employee on insertion
CREATE TRIGGER after_employee_insert_handle_salary_audit
AFTER INSERT ON employee
FOR EACH ROW 
BEGIN 
CALL insert_into_salary_audit (
    NEW.emp_id,
    NEW.salary,
	NEW.company_id,
    NEW.dept_type
);
END$$

-- handling salary audit for manager on insertion
CREATE TRIGGER after_manager_insert_handle_salary_audit
AFTER INSERT ON manager
FOR EACH ROW 
BEGIN 
CALL insert_into_salary_audit (
    NEW.manager_id,
    NEW.salary,
	NEW.company_id,
    NEW.dept_type
);
END$$

-- Handling salary update for employee
CREATE TRIGGER after_employee_salary_update_handle_salary_audit
AFTER UPDATE ON employee
FOR EACH ROW 
BEGIN
IF NEW.salary != OLD.salary 
THEN 
CALL insert_into_salary_audit (
    OLD.emp_id,
    NEW.salary,
	OLD.company_id,
    NEW.dept_type
); 
END IF;
END$$

-- Handling salary update for manager
CREATE TRIGGER after_manager_salary_update_handle_salary_audit
AFTER UPDATE ON manager
FOR EACH ROW 
BEGIN
IF NEW.salary != OLD.salary 
THEN 
CALL insert_into_salary_audit (
    OLD.manager_id,
    NEW.salary,
	OLD.company_id,
    NEW.dept_type
); 
END IF;
END$$

-- Inserting into compnay_audit whenever new company is added 
CREATE TRIGGER after_company_insertion_handle_company_audit
AFTER INSERT ON company 
FOR EACH ROW
BEGIN 
CALL insert_into_company_audit(NEW.company_id,NEW.name, 'active');
END $$

-- Inserting into company_audit whenever comapny is deleted 
CREATE TRIGGER after_company_delete_handle_company_audit
AFTER DELETE ON company 
FOR EACH ROW
BEGIN 
CALL insert_into_company_audit(OLD.company_id,OLD.name, 'inactive');
END $$

-- Inserting into company audit whenever name is changed
CREATE TRIGGER after_company_name_change_handle_company_audit
AFTER UPDATE ON company 
FOR EACH ROW 
BEGIN 
CAll insert_into_company_audit(OLD.company_id,OLD.name, 'inactive');
CALL insert_into_company_audit(OLD.company_id,NEW.name, 'active');
END $$



-- Preventing insertion in employee if user is owner
CREATE TRIGGER before_emp_insert_verify_owner_status
BEFORE INSERT ON employee
FOR EACH ROW
BEGIN
    DECLARE is_owner INT;

    SET is_owner = check_is_owner(NEW.emp_id);

    IF is_owner = 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This person owns their own company, you can not keep them as your employee';
    END IF;
END$$


-- Preventing insertion in employee if user is owner
CREATE TRIGGER before_manager_insert_verify_owner_status
BEFORE INSERT ON manager
FOR EACH ROW
BEGIN
DECLARE is_owner INT; 

SET is_owner = check_is_owner(NEW.manager_id);

IF is_owner = 1 THEN 
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This person owns their own company, you can not keep them as your manager';
END IF;
END$$


CREATE TRIGGER after_owner_insert_handle_owner_audit
AFTER INSERT ON owner 
FOR EACH ROW
BEGIN 
CALL insert_into_owner_audit(NEW.owner_id,NEW.company_id, 'active');
END$$


CREATE TRIGGER after_owner_delete_handle_owner_audit
AFTER DELETE ON owner 
FOR EACH ROW
BEGIN 
CALL insert_into_owner_audit(OLD.owner_id,OLD.company_id, 'inactive');
END$$


CREATE TRIGGER after_department_insert_handle_department_audit
AFTER INSERT ON department 
FOR EACH ROW
BEGIN 
CALL insert_into_department_audit(NEW.dept_type,NEW.company_id, 'active');
END$$


CREATE TRIGGER after_department_delete_handle_department_audit
AFTER DELETE ON department 
FOR EACH ROW
BEGIN 
CALL insert_into_department_audit(OLD.dept_type,OLD.company_id, 'inactive');
END$$

-- Trigger for moving employees and managers into hiring audit once department/company is deleted
CREATE TRIGGER before_company_delete_handle_employees_and_managers
BEFORE DELETE ON company
FOR EACH ROW 
BEGIN 
CALL employees_of_company_into_hiring_audit_after_company_deletion(OLD.company_id);
CALL managers_of_company_into_hiring_audit_after_company_deletion(OLD.company_id);
END$$


CREATE TRIGGER before_dept_delete_handle_employees_and_managers
BEFORE DELETE ON department 
FOR EACH ROW 
BEGIN
CALL employees_of_dept_into_hiring_audit_after_dept_deletion( OLD.dept_type,OLD.company_id); 
CALL managers_of_dept_into_hiring_audit_after_dept_deletion(OLD.company_id, OLD.dept_type);
END$$

DELIMITER ;