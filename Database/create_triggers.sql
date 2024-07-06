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

-- Trigger for handling hiring audit after manager removal
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
    -- Inserting all the manager's employees who have manager_id as null now 
    CALL employees_of_manager_into_hiring_audit_after_manager_removal(OLD.manager_id);
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

DELIMITER ;