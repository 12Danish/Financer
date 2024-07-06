-- Functions 
USE Financer;

DELIMITER $$

CREATE FUNCTION check_is_manager(input_id INT)
RETURNS INT 
DETERMINISTIC 
READS SQL DATA
BEGIN
    DECLARE possible_manager_result INT;
    
    SELECT EXISTS (
        SELECT 1
        FROM manager
        WHERE manager.manager_id = input_id
    ) INTO possible_manager_result;
    
    RETURN possible_manager_result;
END $$
-- Checking if a manager is an employee as well  
CREATE FUNCTION find_possible_position_after_manager_deletion(manager_id_value INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE possible_position_result INT;

    SELECT CASE
        WHEN EXISTS (
            SELECT 1 
            FROM employee
            WHERE emp_id = manager_id_value
        ) THEN 1
        ELSE 0
    END INTO possible_position_result;

    RETURN possible_position_result;
END $$

-- Checking if an employee is a manager as well
CREATE FUNCTION find_possible_position_after_employee_deletion(emp_id_value INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE possible_position_result INT;

    SELECT CASE
        WHEN EXISTS (
            SELECT 1 
            FROM manager
            WHERE manager_id = emp_id_value
        ) THEN 1
        ELSE 0
    END INTO possible_position_result;

    RETURN possible_position_result;
END $$

-- Checking if a manager is already an employee if so returning the id of their manager
CREATE FUNCTION check_has_manager_post_manager_deletion_or_insertion(manager_id INT) RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE managed_by INT;
    -- Select emp_id into the managed_by variable
    SELECT employee.manager_id INTO managed_by
    FROM employee 
    WHERE employee.emp_id = manager_id
    LIMIT 1; -- Assuming emp_id is unique, but LIMIT 1 ensures only one row is selected
    RETURN managed_by; -- Return the managed_by value
END $$

-- checking if owner exists
CREATE FUNCTION check_is_owner(input_id INT)
RETURNS INT 
DETERMINISTIC 
READS SQL DATA
BEGIN
    DECLARE possible_owner_result INT;
    
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 
            FROM owner
            WHERE owner_id = input_id
        ) THEN 1
        ELSE 0
    END INTO possible_owner_result;
    
    RETURN possible_owner_result;
END $$


DELIMITER ;


