USE financer;

DELIMITER $$

-- Trigger for adding entry in hiring_audit after employee insertion
CREATE TRIGGER after_employee_insert_manage_hiring_audit 
AFTER INSERT ON employee
FOR EACH ROW 
BEGIN 
    DECLARE insert_date DATE;
    SET insert_date = CURDATE();
INSERT INTO hiring_audit(staff_id, title, dept_type, company_id, position,managed_by,date,status)
VALUES(NEW.emp_id, NEW.title,NEW.dept_type,NEW.company_id,"employee", NEW.manager_id,insert_date, "active");
END;

-- Trigger for addding entry in hiring audit after manager insertion 
CREATE TRIGGER after_manager_insert_manage_hiring_audit
AFTER INSERT ON manager
FOR EACH ROW 
BEGIN 
    -- Declaring local variables 
    DECLARE insert_date DATE;
    DECLARE managed_by INT;

    -- Setting a local variable 
    SET insert_date = CURDATE();

    -- Call the FindManagersManager function and store the result in managed_by
    SET managed_by = find_managers_manager(NEW.manager_id);

    -- Insert the audit entry using the function result
    INSERT INTO hiring_audit(staff_id, title, dept_type, company_id, position, managed_by, date, status)
    VALUES(NEW.manager_id, NEW.title, NEW.dept_type, NEW.company_id, "manager", managed_by, insert_date, "active");
END;

-- Trigger for handling removal of Employee in hiring audit
CREATE TRIGGER after_employee_removal_manage_hiring_audit
AFTER DELETE ON employee
FOR EACH ROW 
BEGIN 
    DECLARE insert_date DATE;
    SET insert_date = CURDATE();
INSERT INTO hiring_audit(staff_id, title, dept_type, company_id, position,managed_by,date,status)
VALUES(OLD.emp_id, OLD.title,OLD.dept_type,OLD.company_id,"employee", OLD.manager_id,insert_date, "inactive");
END;


-- Trigger for handling hiring audit after manager removal *
CREATE TRIGGER after_manager_removal_manage_hiring_audit
AFTER DELETE ON manager
FOR EACH ROW 
BEGIN 
    -- Declaring local variables 
    DECLARE insert_date DATE;
    DECLARE managed_by INT;

    -- Setting a local variable 
    SET insert_date = CURDATE();

    -- Call the FindManagersManager function and store the result in managed_by
    SET managed_by = check_has_manager_post_manager_deletion_or_insertion(OLD.manager_id);

    -- Insert the audit entry using the function result
    INSERT INTO hiring_audit(staff_id, title, dept_type, company_id, position, managed_by, date, status)
    VALUES(OLD.manager_id, OLD.title, OLD.dept_type, OLD.company_id, "manager", managed_by, insert_date, "inactive");
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
END

$$
