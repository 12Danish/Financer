-- Procedures
USE Financer;
DELIMITER $$

-- This procedure sets the user to active on staff insertion
CREATE PROCEDURE set_user_status_active_on_staff_insertion(IN staff_id INT)
BEGIN
    DECLARE user_status VARCHAR(13);
    -- Retrieve the user_id corresponding to the staff_id
    SELECT user.status INTO user_status
    FROM user
    WHERE user.reg_id = staff_id;

    -- Check if the user status is inactive
    IF user_status = 'inactive' THEN
        -- Set the user status to active
        UPDATE user
        SET user.status = 'active'
        WHERE user.reg_id = staff_id;
    END IF;
END $$

-- This procedure handles insertion into hiring audit for manager 
CREATE PROCEDURE insert_into_hiring_audit(IN staff_id INT,IN staff_manager_id INT,IN title VARCHAR(40),IN dept_type INT, IN company_id INT,IN status VARCHAR(15), IN 	position VARCHAR(20))
BEGIN
DECLARE insert_date DATE;
SET insert_date = CURDATE();
INSERT INTO hiring_audit(staff_id,date,title,dept_type,company_id,position,status,managed_by)
VALUES(staff_id,insert_date,title,dept_type,company_id,position,status,staff_manager_id);
END$$

-- This procedure checks if employee is a manager as well and handles hiring audit accordingly
CREATE PROCEDURE check_has_manager_post_emp_deletion_or_insertion(
    IN emp_id INT,
    IN emp_manager_id INT,
    IN title VARCHAR(70),
    IN dept_type INT,
    IN company_id INT,
    IN action_type VARCHAR(10)
)
BEGIN
    DECLARE is_manager INT;
    SET is_manager = check_is_manager(emp_id);
    
    IF is_manager = 1 THEN
        IF action_type = 'insert' THEN
            CALL insert_into_hiring_audit(emp_id, emp_manager_id, title, dept_type, company_id, 'active', 'manager');
        ELSEIF action_type = 'delete' THEN
            CALL insert_into_hiring_audit(emp_id, emp_manager_id, title, dept_type, company_id, 'inactive','manager');
        END IF;
    END IF;
END $$


CREATE PROCEDURE set_user_status_inactive_on_staff_deletion(IN staff_id INT)
BEGIN
	-- Set the user status to inactive
        UPDATE user
        SET user.status = 'inactive'
        WHERE user.reg_id = staff_id;
END $$

-- entering employees of manager into hiring audit on manager delete 
CREATE PROCEDURE employees_of_manager_into_hiring_audit_after_manager_removal(IN input_manager_id INT)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE managed_emp_id INT;
    DECLARE managed_emp_manager_id INT;
    DECLARE managed_emp_title VARCHAR(70);
    DECLARE managed_emp_dept_type INT;
    DECLARE managed_emp_company_id INT;
    
    DECLARE managed_emp_cursor CURSOR FOR 
        SELECT emp_id, manager_id, title, dept_type, company_id 
        FROM employee 
        WHERE employee.manager_id = input_manager_id;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	
    -- Open cursor
    OPEN managed_emp_cursor;
	
    -- Fetch data from cursor
    fetch_loop: LOOP
        FETCH managed_emp_cursor INTO managed_emp_id, managed_emp_manager_id, managed_emp_title, managed_emp_dept_type, managed_emp_company_id;
        IF done THEN
            LEAVE fetch_loop;
        END IF;
         
        -- Call the procedure for each employee
        CALL insert_into_hiring_audit(managed_emp_id, managed_emp_manager_id, managed_emp_title, managed_emp_dept_type, managed_emp_company_id, 'inactive', 'employee');
    END LOOP;

    -- Close cursor
    CLOSE managed_emp_cursor;
    
END $$

CREATE PROCEDURE insert_into_salary_audit (
    IN staff_id INT,
    IN salary DECIMAL(10,2),
    IN company_id INT, 
    IN dept_type INT
)
BEGIN 
    DECLARE insert_date DATE;
    SET insert_date = CURDATE();

    INSERT INTO salary_audit (staff_id, salary, company_id, dept_type,date)
    VALUES (staff_id, salary, company_id, dept_type, insert_date);
END $$


DELIMITER ;
