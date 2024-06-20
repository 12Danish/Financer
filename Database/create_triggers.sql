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
CREATE trigger after_manager_insert_manage_hiring_audit
AFTER INSERT ON manager
FOR EACH ROW 
BEGIN 
	
	-- Declaring local varaibles 
    DECLARE insert_date DATE;
    DECLARE managed_by INT;
    
    -- Setting a local variable 
    SET insert_date = CURDATE();

    -- Declaring a session variable
    SET @managed_by = NULL;
    
    CALL find_managers_manager(NEW.manager_id, @managed_by);
    SET managed_by = @managed_by;
INSERT INTO hiring_audit(staff_id, title, dept_type, company_id, position,managed_by,date,status)
VALUES(NEW.manager_id, NEW.title,NEW.dept_type,NEW.company_id,"manager", managed_by,insert_date, "active");
END;
$$