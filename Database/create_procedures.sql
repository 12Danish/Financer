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


CREATE PROCEDURE insert_into_company_audit(
IN company_id INT,
IN name VARCHAR(100),
IN status enum('active', 'inactive')
)

BEGIN 
DECLARE insert_date DATE;
SET insert_date = CURDATE();

INSERT INTO company_audit(company_id,name,date,status)
VALUES(company_id,name,insert_date,status);

END$$

CREATE PROCEDURE insert_into_owner_audit(
IN owner_id INT,
IN company_id INT,
IN status enum('active', 'inactive')
)

BEGIN 
DECLARE insert_date DATE;
SET insert_date = CURDATE();

INSERT INTO owner_audit(owner_id,company_id,date,status)
VALUES(owner_id,company_id,insert_date,status);

END$$

CREATE PROCEDURE insert_into_department_audit(
IN dept_type INT,
IN company_id INT,
IN status enum('active', 'inactive')
)
BEGIN 
DECLARE insert_date DATE;
SET insert_date = CURDATE();

INSERT INTO department_audit(dept_type,company_id,date,status)
VALUES(dept_type,company_id,insert_date,status);

END$$


-- This procedure takes in the the company_id and then adds all employees related to company to hiring_audit
CREATE PROCEDURE employees_of_company_into_hiring_audit_after_company_deletion(IN input_company_id INT)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE company_emp_id INT;
    DECLARE company_emp_manager_id INT;
    DECLARE company_emp_title VARCHAR(70);
    DECLARE company_emp_dept_type INT;
    DECLARE company_emp_company_id INT;
    
    DECLARE company_emp_cursor CURSOR FOR 
        SELECT emp_id, manager_id, title, dept_type, company_id 
        FROM employee 
        WHERE employee.company_id = input_company_id;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	
    -- Open cursor
    OPEN company_emp_cursor;
	
    -- Fetch data from cursor
    fetch_loop: LOOP
        FETCH company_emp_cursor INTO company_emp_id, company_emp_manager_id, company_emp_title, company_emp_dept_type, company_emp_company_id;
        IF done THEN
            LEAVE fetch_loop;
        END IF;
         
        -- Call the procedure for each employee
        CALL insert_into_hiring_audit(company_emp_id, company_emp_manager_id, company_emp_title, company_emp_dept_type, company_emp_company_id, 'inactive', 'employee');
    END LOOP;
END$$


-- This procedure takes in the the company_id and then inserts all relevant managers into hiring audit
CREATE PROCEDURE managers_of_company_into_hiring_audit_after_company_deletion(IN input_company_id INT)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE company_manager_id INT;
    DECLARE company_manager_title VARCHAR(70);
    DECLARE company_manager_dept_type INT;
    DECLARE company_manager_company_id INT;
    DECLARE company_manager_managed_by INT;

    DECLARE company_manager_cursor CURSOR FOR 
        SELECT manager_id, title, dept_type, company_id 
        FROM manager
        WHERE manager.company_id = input_company_id;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	
    SET company_manager_managed_by = check_has_manager_post_manager_deletion_or_insertion(input_manager_id);
    -- Open cursor
    OPEN company_manager_cursor;
	
    -- Fetch data from cursor
    fetch_loop: LOOP
        FETCH company_manager_cursor INTO company_manager_id, company_manager_title, company_manager_dept_type, company_manager_company_id;
        IF done THEN
            LEAVE fetch_loop;
        END IF;
         
        -- Call the procedure for each employee
        CALL insert_into_hiring_audit(company_manager_id, company_manager_managed_by, company_manager_title, company_manager_dept_type, company_manager_company_id, 'inactive', 'manager');
    END LOOP;
END$$

-- This procedure takes in the the company_id and then adds all employees related to company to hiring_audit
CREATE PROCEDURE employees_of_company_into_hiring_audit_after_company_deletion(IN input_company_id INT)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE company_emp_id INT;
    DECLARE company_emp_manager_id INT;
    DECLARE company_emp_title VARCHAR(70);
    DECLARE company_emp_dept_type INT;
    DECLARE company_emp_cursor CURSOR FOR 
        SELECT emp_id, manager_id, title, dept_type
        FROM employee 
        WHERE employee.company_id = input_company_id;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	
    -- Open cursor
    OPEN company_emp_cursor;
	
    -- Fetch data from cursor
    fetch_loop: LOOP
        FETCH company_emp_cursor INTO company_emp_id, company_emp_manager_id, company_emp_title, company_emp_dept_type;
        IF done THEN
            LEAVE fetch_loop;
        END IF;
         
        -- Call the procedure for each employee
        CALL insert_into_hiring_audit(company_emp_id, company_emp_manager_id, company_emp_title, company_emp_dept_type, input_company_id, 'inactive', 'employee');
    END LOOP;
END$$


-- This procedure takes in the the company_id and then inserts all relevant managers into hiring audit
CREATE PROCEDURE managers_of_company_into_hiring_audit_after_company_deletion(IN input_company_id INT)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE company_manager_id INT;
    DECLARE company_manager_title VARCHAR(70);
    DECLARE company_manager_dept_type INT;
    DECLARE company_manager_managed_by INT;

    DECLARE company_manager_cursor CURSOR FOR 
        SELECT manager_id, title, dept_type
        FROM manager
        WHERE manager.company_id = input_company_id;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	
    SET company_manager_managed_by = check_has_manager_post_manager_deletion_or_insertion(input_manager_id);
    -- Open cursor
    OPEN company_manager_cursor;
	
    -- Fetch data from cursor
    fetch_loop: LOOP
        FETCH company_manager_cursor INTO company_manager_id, company_manager_title, company_manager_dept_type;
        IF done THEN
            LEAVE fetch_loop;
        END IF;
         
        -- Call the procedure for each employee
        CALL insert_into_hiring_audit(company_manager_id, company_manager_managed_by, company_manager_title, company_manager_dept_type, input_company_id, 'inactive', 'manager');
    END LOOP;
END$$

-- This procedure takes in the the company_id and then adds all employees related to company to hiring_audit
CREATE PROCEDURE employees_of_dept_into_hiring_audit_after_dept_deletion(IN input_department_type INT, IN input_company_id INT)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE department_emp_id INT;
    DECLARE department_emp_manager_id INT;
    DECLARE department_emp_title VARCHAR(70);
    
    DECLARE department_emp_cursor CURSOR FOR 
        SELECT emp_id, manager_id, title 
        FROM employee 
        WHERE employee.dept_type = input_department_type AND employee.company_id = input_company_id ;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	
    -- Open cursor
    OPEN department_emp_cursor;
	
    -- Fetch data from cursor
    fetch_loop: LOOP
        FETCH department_emp_cursor INTO department_emp_id, department_emp_manager_id, department_emp_title;
        IF done THEN
            LEAVE fetch_loop;
        END IF;
         
        -- Call the procedure for each employee
        CALL insert_into_hiring_audit(department_emp_id, department_emp_manager_id, department_emp_title,input_dept_type,input_company_id, 'inactive', 'employee');
    END LOOP;
END$$


-- This procedure takes in the the company_id and then inserts all relevant managers into hiring audit
CREATE PROCEDURE managers_of_dept_into_hiring_audit_after_dept_deletion(IN input_company_id INT, IN input_dept_type INT )
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE department_manager_id INT;
    DECLARE department_manager_title VARCHAR(70);
    DECLARE department_manager_managed_by INT;
    DECLARE department_manager_cursor CURSOR FOR 
        SELECT manager_id, title
        FROM manager
        WHERE manager.company_id = input_company_id and manager.dept_type = input_dept_type;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	
    -- Open cursor
    OPEN department_manager_cursor;
	
    -- Fetch data from cursor
    fetch_loop: LOOP
        FETCH department_manager_cursor INTO department_manager_id, department_manager_title;
        IF done THEN
            LEAVE fetch_loop;
        END IF;
         SET department_manager_managed_by = check_has_manager_post_manager_deletion_or_insertion(department_manager_id);
        -- Call the procedure for each employee
        CALL insert_into_hiring_audit(department_manager_id, department_manager_managed_by, department_manager_title, input_dept_type, input_company_id, 'inactive', 'manager');
    END LOOP;
END$$


DELIMITER ;
