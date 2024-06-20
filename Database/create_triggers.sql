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
VALUES(NEW.emp_id, NEW.title,NEW.dept_type,NEW.company_id, NEW.manager_id,@insert_date);
END; 
$$
