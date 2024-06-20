
-- This stored procedure finds a managers manager
DELIMITER $$
CREATE PROCEDURE find_managers_manager(
    IN manager_id INT,
    OUT managed_by INT
)
BEGIN 
    -- Select emp_id into the OUT parameter
    SELECT employee.manager_id 
    INTO managed_by
    FROM employee 
    WHERE employee.emp_id = manager_id
    LIMIT 1; -- Assuming emp_id is unique, but LIMIT 1 ensures only one row is selected
END $$

DELIMITER ;

