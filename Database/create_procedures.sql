USE FINANCER;
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
    IN title VARCHAR(40),
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


-- This procdure handles insertion of all the employees related to the manager being removed and inserts them into hiring audit
CREATE PROCEDURE employees_of_manager_into_hiring_audit_after_manager_removal(IN input_manager_id INT)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE emp_id INT;
    DECLARE emp_manager_id INT;
    DECLARE emp_title VARCHAR(255);
    DECLARE emp_dept_type VARCHAR(255);
    DECLARE emp_company_id INT;
    
    DECLARE emp_cursor CURSOR FOR 
        SELECT emp_id, manager_id, title, dept_type, company_id 
        FROM employee 
        WHERE manager_id = input_manager_id;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Open cursor
    OPEN emp_cursor;

    -- Fetch data from cursor
    fetch_loop: LOOP
        FETCH emp_cursor INTO emp_id, emp_manager_id, emp_title, emp_dept_type, emp_company_id;
        IF done THEN
            LEAVE fetch_loop;
        END IF;
        
        -- Call the procedure for each employee
        CALL insert_into_hiring_audit(emp_id, emp_manager_id, emp_title, emp_dept_type, emp_company_id, 'active', 'employee');
    END LOOP;

    -- Close cursor
    CLOSE emp_cursor;
END $$



DELIMITER ;
