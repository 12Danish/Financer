DELIMITER //

CREATE FUNCTION FindManagersManager(manager_id INT) RETURNS INT
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
END //

DELIMITER ;
