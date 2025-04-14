


CREATE OR REPLACE PROCEDURE create_venue(
    p_venue_name IN VARCHAR2,
    p_venue_capacity IN NUMBER,
    p_user_user_id IN NUMBER,
    p_venue_id OUT NUMBER
)
AS
BEGIN
    -- Input validation based on your constraints
    IF TRIM(p_venue_name) IS NULL OR LENGTH(TRIM(p_venue_name)) = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Venue name cannot be empty or blank');
    END IF;
    
    IF p_venue_capacity <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Venue capacity must be greater than zero');
    END IF;
    
    -- Check if user exists (using EVENT_USERS without schema qualifier)
    DECLARE
        v_user_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_user_count FROM EVENT_ADMIN.EVENT_USERS WHERE USER_ID = p_user_user_id;
        IF v_user_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'User ID does not exist in EVENT_USERS table');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20004, 'Error verifying user: ' || SQLERRM);
    END;
    
    -- Get the next value for VENUE_ID from sequence with correct schema
    SELECT EVENT_ADMIN.VENUE_ID_SEQ.NEXTVAL INTO p_venue_id FROM DUAL;
    
    -- Insert the new venue
    INSERT INTO EVENT_ADMIN.VENUE (VENUE_ID, VENUE_NAME, VENUE_CAPACITY, USER_USER_ID)
    VALUES (p_venue_id, TRIM(p_venue_name), p_venue_capacity, p_user_user_id);
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20000, 'Error creating venue: ' || SQLERRM);
END create_venue;
/

-- Test suite for create_venue procedure (with cleaner error messages)
SET SERVEROUTPUT ON;
DECLARE
    v_venue_id NUMBER;
    
    -- Helper procedure to display test result
    PROCEDURE test_result(p_test_name VARCHAR2, p_status VARCHAR2, p_message VARCHAR2 DEFAULT NULL) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Test: ' || p_test_name || ' - ' || p_status);
        IF p_message IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('   ' || p_message);
        END IF;
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
    -- Helper function to extract user-friendly message from ORA error
    FUNCTION get_friendly_message(p_error_msg VARCHAR2) RETURN VARCHAR2 IS
        v_start_pos NUMBER;
        v_end_pos NUMBER;
        v_msg VARCHAR2(4000);
    BEGIN
        -- Find the actual error message without ORA codes
        IF INSTR(p_error_msg, 'Venue name cannot be empty') > 0 THEN
            RETURN 'Venue name cannot be empty or blank';
        ELSIF INSTR(p_error_msg, 'Venue capacity must be greater than zero') > 0 THEN
            RETURN 'Venue capacity must be greater than zero';
        ELSIF INSTR(p_error_msg, 'User ID does not exist') > 0 THEN
            RETURN 'User ID does not exist in the system';
        ELSE
            -- Extract message from between colons for other errors
            v_start_pos := INSTR(p_error_msg, ':', 1, 2) + 1;
            IF v_start_pos > 1 THEN
                RETURN TRIM(SUBSTR(p_error_msg, v_start_pos));
            ELSE
                RETURN 'Unknown error occurred';
            END IF;
        END IF;
    END;
BEGIN
    DBMS_OUTPUT.PUT_LINE('STARTING TEST SUITE FOR CREATE_VENUE PROCEDURE');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    
    -- Test Case 1: Valid venue creation
    BEGIN
        create_venue('Convention Center', 500, 1, v_venue_id);
        test_result('Valid Venue Creation', 'PASSED', 'New venue ID: ' || v_venue_id);
    EXCEPTION
        WHEN OTHERS THEN
            test_result('Valid Venue Creation', 'FAILED', get_friendly_message(SQLERRM));
    END;
    
    -- Test Case 2: Empty venue name
    BEGIN
        create_venue('', 300, 1, v_venue_id);
        test_result('Empty Venue Name', 'FAILED', 'Should have raised an exception');
    EXCEPTION
        WHEN OTHERS THEN
            IF INSTR(SQLERRM, 'Venue name cannot be empty or blank') > 0 THEN
                test_result('Empty Venue Name', 'PASSED', 'Correctly rejected: ' || 
                    get_friendly_message(SQLERRM));
            ELSE
                test_result('Empty Venue Name', 'FAILED', 'Unexpected error: ' || 
                    get_friendly_message(SQLERRM));
            END IF;
    END;
    
    -- Test Case 3: NULL venue name
    BEGIN
        create_venue(NULL, 300, 1, v_venue_id);
        test_result('NULL Venue Name', 'FAILED', 'Should have raised an exception');
    EXCEPTION
        WHEN OTHERS THEN
            IF INSTR(SQLERRM, 'Venue name cannot be empty or blank') > 0 THEN
                test_result('NULL Venue Name', 'PASSED', 'Correctly rejected: ' || 
                    get_friendly_message(SQLERRM));
            ELSE
                test_result('NULL Venue Name', 'FAILED', 'Unexpected error: ' || 
                    get_friendly_message(SQLERRM));
            END IF;
    END;
    
    -- Test Case 4: Zero capacity
    BEGIN
        create_venue('Cinema Hall', 0, 1, v_venue_id);
        test_result('Zero Capacity', 'FAILED', 'Should have raised an exception');
    EXCEPTION
        WHEN OTHERS THEN
            IF INSTR(SQLERRM, 'Venue capacity must be greater than zero') > 0 THEN
                test_result('Zero Capacity', 'PASSED', 'Correctly rejected: ' || 
                    get_friendly_message(SQLERRM));
            ELSE
                test_result('Zero Capacity', 'FAILED', 'Unexpected error: ' || 
                    get_friendly_message(SQLERRM));
            END IF;
    END;
    
    -- Test Case 5: Negative capacity
    BEGIN
        create_venue('Theater', -100, 1, v_venue_id);
        test_result('Negative Capacity', 'FAILED', 'Should have raised an exception');
    EXCEPTION
        WHEN OTHERS THEN
            IF INSTR(SQLERRM, 'Venue capacity must be greater than zero') > 0 THEN
                test_result('Negative Capacity', 'PASSED', 'Correctly rejected: ' || 
                    get_friendly_message(SQLERRM));
            ELSE
                test_result('Negative Capacity', 'FAILED', 'Unexpected error: ' || 
                    get_friendly_message(SQLERRM));
            END IF;
    END;
    
    -- Test Case 6: Non-existent user ID
    BEGIN
        create_venue('Auditorium', 250, 9999, v_venue_id); -- Assuming 9999 is not a valid user ID
        test_result('Non-existent User ID', 'FAILED', 'Should have raised an exception');
    EXCEPTION
        WHEN OTHERS THEN
            IF INSTR(SQLERRM, 'User ID does not exist') > 0 THEN
                test_result('Non-existent User ID', 'PASSED', 'Correctly rejected: ' || 
                    get_friendly_message(SQLERRM));
            ELSE
                test_result('Non-existent User ID', 'FAILED', 'Unexpected error: ' || 
                    get_friendly_message(SQLERRM));
            END IF;
    END;
    
    -- Test Case 7: Venue name with spaces (should be trimmed)
    BEGIN
        create_venue('  Conference Room B  ', 150, 1, v_venue_id);
        
        -- Verify the name was trimmed properly
        DECLARE
            v_name VARCHAR2(100);
        BEGIN
            SELECT VENUE_NAME INTO v_name 
            FROM EVENT_ADMIN.VENUE 
            WHERE VENUE_ID = v_venue_id;
            
            IF v_name = 'Conference Room B' THEN
                test_result('Name Trimming', 'PASSED', 'Spaces correctly trimmed');
            ELSE
                test_result('Name Trimming', 'FAILED', 'Expected "Conference Room B" but got "' || v_name || '"');
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                test_result('Name Trimming', 'FAILED', 'Error verifying: ' || get_friendly_message(SQLERRM));
        END;
    EXCEPTION
        WHEN OTHERS THEN
            test_result('Name Trimming', 'FAILED', 'Error during creation: ' || get_friendly_message(SQLERRM));
    END;
    
    -- Test Case 8: Large capacity
    DECLARE
        v_large_capacity NUMBER := 999999;
    BEGIN
        create_venue('Stadium', v_large_capacity, 1, v_venue_id);
        
        -- Verify the capacity was stored correctly
        DECLARE
            v_capacity NUMBER;
        BEGIN
            SELECT VENUE_CAPACITY INTO v_capacity 
            FROM EVENT_ADMIN.VENUE 
            WHERE VENUE_ID = v_venue_id;
            
            IF v_capacity = v_large_capacity THEN
                test_result('Large Capacity', 'PASSED', 'Large capacity stored correctly');
            ELSE
                test_result('Large Capacity', 'FAILED', 
                    'Expected ' || v_large_capacity || ' but got ' || v_capacity);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                test_result('Large Capacity', 'FAILED', 'Error verifying: ' || get_friendly_message(SQLERRM));
        END;
    EXCEPTION
        WHEN OTHERS THEN
            test_result('Large Capacity', 'FAILED', 'Error during creation: ' || get_friendly_message(SQLERRM));
    END;
    
    DBMS_OUTPUT.PUT_LINE('TEST SUITE COMPLETED');
END;
/