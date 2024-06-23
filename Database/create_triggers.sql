USE financer;

DELIMITER $$
-- Trigger for adding entry in hiring_audit after employee insertion
CREATE TRIGGER after_employee_insert_manage_hiring_audit 
AFTER INSERT ON employee
FOR EACH ROW 
BEGIN 
   CALL set_user_status_active_on_staff_insertion(NEW.emp_id);
   CALL check_has_manager_post_emp_deletion_or_insertion(
     NEW.emp_id ,
     NEW.manager_id ,
     NEW.title ,
     NEW.dept_type ,
     NEW.company_id ,
     "insert"
);
CALL insert_into_hiring_audit(NEW.emp_id, NEW.manager_id, NEW.title, NEW.dept_type, NEW.company_id, 'active', 'employee');
END;

-- Trigger for addding entry in hiring audit after manager insertion 
CREATE TRIGGER after_manager_insert_manage_hiring_audit
AFTER INSERT ON manager
FOR EACH ROW 
BEGIN 
	 
    -- Declaring local variables 
    DECLARE managed_by INT;
	CALL set_user_status_active_on_staff_insertion(NEW.manager_id);

    -- Call the FindManagersManager function and store the result in managed_by
    SET managed_by = find_managers_manager(NEW.manager_id);

    -- Insert the audit entry using the function result
    CALL insert_into_hiring_audit(NEW.manager_id, managed_by, NEW.title, NEW.dept_type, NEW.company_id, 'active', 'manager');
END;

-- Trigger for handling removal of Employee in hiring audit
CREATE TRIGGER after_employee_removal_manage_hiring_audit
AFTER DELETE ON employee
FOR EACH ROW 
BEGIN

	CALL check_has_manager_post_emp_deletion_or_insertion(
     OLD.emp_id ,
     OLD.manager_id ,
     OLD.title ,
     OLD.dept_type ,
     OLD.company_id ,
     "delete"
);
CALL insert_into_hiring_audit(OLD.emp_id, OLD.manager_id, OLD.title, OLD.dept_type, OLD.company_id, 'inactive', 'employee');
END;

-- Trigger for handling hiring audit after manager removal *
CREATE TRIGGER after_manager_removal_manage_hiring_audit
AFTER DELETE ON manager
FOR EACH ROW 
BEGIN 
    -- Declaring local variables 
    DECLARE managed_by INT;

    -- Call the FindManagersManager function and store the result in managed_by
    SET managed_by = check_has_manager_post_manager_deletion_or_insertion(OLD.manager_id);

    -- Insert the audit entry using the function result
    CALL insert_into_hiring_audit(OLD.manager_id, managed_by, OLD.title, OLD.dept_type, OLD.company_id, 'inactive', 'manager');
END;

-- Creating a trigger to handle status on user after deletion in employee table *
CREATE TRIGGER after_employee_removal_handle_user_status
AFTER DELETE ON employee
FOR EACH ROW 
BEGIN 
    DECLARE manager_position INT;
    SET manager_position = find_possible_position_after_employee_deletion(OLD.emp_id);
    IF manager_position = 0 THEN
        UPDATE user 
        SET status = 'inactive'
        WHERE reg_id = OLD.emp_id;
    END IF;
END;
-- Creating a trigger to handle status on user after deletion in manager table
CREATE TRIGGER after_manager_removal_handle_user_status
AFTER DELETE ON manager
FOR EACH ROW 
BEGIN 
    DECLARE emp_position INT;
    SET emp_position = find_possible_position_after_employee_deletion(OLD.manager_id);
    IF emp_position = 0 THEN
        UPDATE user 
        SET status = 'inactive'
        WHERE reg_id = OLD.manager_id;
    END IF;
    
END;


-- This trigger prevents updating manager_id and compnay_id for manager
CREATE TRIGGER prevent_update_on_manager_id_and_company_id
BEFORE UPDATE ON manager
FOR EACH ROW
BEGIN
    IF NEW.manager_id != OLD.manager_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You are not allowed to update the manager_id column.';
    END IF;

    IF NEW.company_id != OLD.company_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You are not allowed to update the manager_id column.';
    END IF;
END;

-- This trigger prevents updating emp_id and compnay_id for manager
CREATE TRIGGER prevent_update_on_emp_id_and_company_id
BEFORE UPDATE ON employee
FOR EACH ROW
BEGIN
    IF NEW.emp_id != OLD.emp_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You are not allowed to update the emp_id column.';
    END IF;

    IF NEW.company_id != OLD.company_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You are not allowed to update the manager_id column.';
    END IF;
END;
$$
