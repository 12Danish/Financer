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
        WHERE user_id = staff_id;
    END IF;
END $$

-- This procedure handles insertion into hiring audit for manager 
CREATE PROCEDURE insert_into_hiring_audit_emp_deletion_or_insertion(IN emp_id INT,IN emp_manager_id INT,IN title VARCHAR(40),IN dept_type INT, IN company_id INT,IN status VARCHAR(15))
BEGIN 
DECLARE insert_date DATE;
SET insert_date = CURDATE();
INSERT INTO hiring_audit(staff_id,date,title,dept_type,company_id,position,status,managed_by)
VALUES(emp_id,insert_date,title,dept_type,company_id,"manager",status,emp_manager_id);
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
    
    IF is_manager IS NOT NULL THEN
        IF action_type = 'insert' THEN
            CALL insert_into_hiring_audit_emp_deletion_or_insertion(emp_id, emp_manager_id, title, dept_type, company_id, 'active');
        ELSEIF action_type = 'delete' THEN
            CALL insert_into_hiring_audit_emp_deletion_or_insertion(emp_id, emp_manager_id, title, dept_type, company_id, 'inactive');
        END IF;
    END IF;
END $$


DELIMITER ;
