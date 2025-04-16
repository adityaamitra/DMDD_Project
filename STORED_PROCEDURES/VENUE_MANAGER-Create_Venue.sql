CREATE OR REPLACE PROCEDURE CREATE_VENUE(
    p_venue_name IN VARCHAR2,
    p_venue_capacity IN NUMBER,
    p_user_id IN NUMBER,
    p_venue_id OUT NUMBER
) IS
    v_user_exists NUMBER;
    v_duplicate_count NUMBER;
    v_trimmed_venue_name VARCHAR2(100);
    
    -- Custom exception definitions
    e_empty_venue_name EXCEPTION;
    e_invalid_capacity EXCEPTION;
    e_user_not_exists EXCEPTION;
    e_duplicate_venue EXCEPTION;
    
    PRAGMA EXCEPTION_INIT(e_empty_venue_name, -20001);
    PRAGMA EXCEPTION_INIT(e_invalid_capacity, -20002);
    PRAGMA EXCEPTION_INIT(e_user_not_exists, -20003);
    PRAGMA EXCEPTION_INIT(e_duplicate_venue, -20005);
BEGIN
    -- Trim the venue name first
    v_trimmed_venue_name := TRIM(p_venue_name);
    
    -- Check if venue name is NULL or empty after trimming
    IF v_trimmed_venue_name IS NULL OR LENGTH(v_trimmed_venue_name) = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Venue name cannot be empty or blank');
    END IF;
    
    -- Check if capacity is valid
    IF p_venue_capacity <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Venue capacity must be greater than zero');
    END IF;
    
    -- Check if user exists
    SELECT COUNT(*) INTO v_user_exists 
    FROM EVENT_ADMIN.EVENT_USERS 
    WHERE USER_ID = p_user_id;
    
    IF v_user_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'User ID does not exist in the system');
    END IF;
    
    -- Check for duplicate venue name for the same user (case insensitive)
    SELECT COUNT(*) INTO v_duplicate_count 
    FROM EVENT_ADMIN.VENUE 
    WHERE UPPER(VENUE_NAME) = UPPER(v_trimmed_venue_name) 
    AND USER_USER_ID = p_user_id;
    
    IF v_duplicate_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Venue with the same name already exists for this user');
    END IF;
    
    -- Generate venue ID
    SELECT NVL(MAX(VENUE_ID), 0) + 1 INTO p_venue_id FROM EVENT_ADMIN.VENUE;
    
    -- Insert new venue record
    INSERT INTO EVENT_ADMIN.VENUE (
        VENUE_ID,
        VENUE_NAME,
        VENUE_CAPACITY,
        USER_USER_ID
    ) VALUES (
        p_venue_id,
        v_trimmed_venue_name,
        p_venue_capacity,
        p_user_id
    );
    
    COMMIT;
    
EXCEPTION
    WHEN e_empty_venue_name THEN
        RAISE;
    WHEN e_invalid_capacity THEN
        RAISE;
    WHEN e_user_not_exists THEN
        RAISE;
    WHEN e_duplicate_venue THEN
        RAISE;
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Unexpected error in CREATE_VENUE: ' || SQLERRM);
END CREATE_VENUE;
/



-- Execute the test procedure
BEGIN
    DBMS_OUTPUT.PUT_LINE('STARTING TEST SUITE FOR CREATE_VENUE PROCEDURE');
    DBMS_OUTPUT.PUT_LINE('========================================');
    BEGIN
    DELETE FROM EVENT_ADMIN.VENUE
    WHERE USER_USER_ID IN (1, 2) -- or all test users
    AND VENUE_NAME LIKE 'Test%'; -- match pattern
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Global cleanup failed: ' || SQLERRM);
END;

 
    
    -- Test Case 1: Valid Venue Creation
    DECLARE
        v_venue_id NUMBER;
        v_test_user_id NUMBER := 1; -- Assuming this user exists
    BEGIN
        CREATE_VENUE('Test Conference Hall', 100, v_test_user_id, v_venue_id);
        DBMS_OUTPUT.PUT_LINE('Test #1: Valid Venue Creation - PASSED');
        DBMS_OUTPUT.PUT_LINE('   Created venue ID: ' || v_venue_id);
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Test #1: Valid Venue Creation - FAILED');
            DBMS_OUTPUT.PUT_LINE('   Error: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
    -- Test Case 2: NULL Venue Name
    DECLARE
        v_venue_id NUMBER;
        v_test_user_id NUMBER := 1; -- Assuming this user exists
    BEGIN
        CREATE_VENUE(NULL, 100, v_test_user_id, v_venue_id);
        DBMS_OUTPUT.PUT_LINE('Test #2: NULL Venue Name - FAILED');
        DBMS_OUTPUT.PUT_LINE('   No exception was raised');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20001 THEN
                DBMS_OUTPUT.PUT_LINE('Test #2: NULL Venue Name - PASSED');
            ELSE
                DBMS_OUTPUT.PUT_LINE('Test #2: NULL Venue Name - FAILED');
                DBMS_OUTPUT.PUT_LINE('   Expected error code -20001 but got ' || SQLCODE || ': ' || SQLERRM);
            END IF;
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
    -- Test Case 3: Empty Venue Name
    DECLARE
        v_venue_id NUMBER;
        v_test_user_id NUMBER := 1; -- Assuming this user exists
    BEGIN
        CREATE_VENUE('', 100, v_test_user_id, v_venue_id);
        DBMS_OUTPUT.PUT_LINE('Test #3: Empty Venue Name - FAILED');
        DBMS_OUTPUT.PUT_LINE('   No exception was raised');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20001 THEN
                DBMS_OUTPUT.PUT_LINE('Test #3: Empty Venue Name - PASSED');

            ELSE
                DBMS_OUTPUT.PUT_LINE('Test #3: Empty Venue Name - FAILED');
                DBMS_OUTPUT.PUT_LINE('   Expected error code -20001 but got ' || SQLCODE || ': ' || SQLERRM);
            END IF;
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
    -- Test Case 4: Blank Venue Name (spaces only)
    DECLARE
        v_venue_id NUMBER;
        v_test_user_id NUMBER := 1; -- Assuming this user exists
    BEGIN
        CREATE_VENUE('   ', 100, v_test_user_id, v_venue_id);
        DBMS_OUTPUT.PUT_LINE('Test #4: Blank Venue Name (spaces only) - FAILED');
        DBMS_OUTPUT.PUT_LINE('   No exception was raised');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20001 THEN
                DBMS_OUTPUT.PUT_LINE('Test #4: Blank Venue Name (spaces only) - PASSED');

            ELSE
                DBMS_OUTPUT.PUT_LINE('Test #4: Blank Venue Name (spaces only) - FAILED');
                DBMS_OUTPUT.PUT_LINE('   Expected error code -20001 but got ' || SQLCODE || ': ' || SQLERRM);
            END IF;
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
    -- Test Case 5: Zero Capacity
    DECLARE
        v_venue_id NUMBER;
        v_test_user_id NUMBER := 1; -- Assuming this user exists
    BEGIN
        CREATE_VENUE('Zero Capacity Venue', 0, v_test_user_id, v_venue_id);
        DBMS_OUTPUT.PUT_LINE('Test #5: Zero Capacity - FAILED');
        DBMS_OUTPUT.PUT_LINE('   No exception was raised');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20002 THEN
                DBMS_OUTPUT.PUT_LINE('Test #5: Zero Capacity - PASSED');

            ELSE
                DBMS_OUTPUT.PUT_LINE('Test #5: Zero Capacity - FAILED');
                DBMS_OUTPUT.PUT_LINE('   Expected error code -20002 but got ' || SQLCODE || ': ' || SQLERRM);
            END IF;
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
    -- Test Case 6: Negative Capacity
    DECLARE
        v_venue_id NUMBER;
        v_test_user_id NUMBER := 1; -- Assuming this user exists
    BEGIN
        CREATE_VENUE('Negative Capacity Venue', -50, v_test_user_id, v_venue_id);
        DBMS_OUTPUT.PUT_LINE('Test #6: Negative Capacity - FAILED');
        DBMS_OUTPUT.PUT_LINE('   No exception was raised');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20002 THEN
                DBMS_OUTPUT.PUT_LINE('Test #6: Negative Capacity - PASSED');

            ELSE
                DBMS_OUTPUT.PUT_LINE('Test #6: Negative Capacity - FAILED');
                DBMS_OUTPUT.PUT_LINE('   Expected error code -20002 but got ' || SQLCODE || ': ' || SQLERRM);
            END IF;
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
    -- Test Case 7: Non-existent User ID
    DECLARE
        v_venue_id NUMBER;
        v_non_existent_user_id NUMBER := 99999; -- A user ID that doesn't exist
    BEGIN
        CREATE_VENUE('Invalid User Venue', 100, v_non_existent_user_id, v_venue_id);
        DBMS_OUTPUT.PUT_LINE('Test #7: Non-existent User ID - FAILED');
        DBMS_OUTPUT.PUT_LINE('   No exception was raised');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20003 THEN
                DBMS_OUTPUT.PUT_LINE('Test #7: Non-existent User ID - PASSED');

            ELSE
                DBMS_OUTPUT.PUT_LINE('Test #7: Non-existent User ID - FAILED');
                DBMS_OUTPUT.PUT_LINE('   Expected error code -20003 but got ' || SQLCODE || ': ' || SQLERRM);
            END IF;
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
    -- Test Case 8: Name Trimming
    DECLARE
        v_venue_id NUMBER;
        v_test_user_id NUMBER := 1; -- Assuming this user exists
        v_venue_name VARCHAR2(100);
    BEGIN
        -- First delete any existing venues with this name
        BEGIN
            EXECUTE IMMEDIATE 'DELETE FROM EVENT_ADMIN.VENUE WHERE VENUE_NAME = ''Conference Room XYZ''';
            COMMIT;
        EXCEPTION WHEN OTHERS THEN NULL; END;
        
        CREATE_VENUE('  Conference Room XYZ  ', 150, v_test_user_id, v_venue_id);
        
        -- Check the stored name
        SELECT VENUE_NAME INTO v_venue_name FROM EVENT_ADMIN.VENUE WHERE VENUE_ID = v_venue_id;
        
        IF v_venue_name = 'Conference Room XYZ' THEN
            DBMS_OUTPUT.PUT_LINE('Test #8: Name Trimming - PASSED');
            DBMS_OUTPUT.PUT_LINE('   Spaces correctly trimmed. Stored as "' || v_venue_name || '"');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Test #8: Name Trimming - FAILED');
            DBMS_OUTPUT.PUT_LINE('   Expected "Conference Room XYZ", got "' || v_venue_name || '"');
        END IF;
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Test #8: Name Trimming - FAILED');
            DBMS_OUTPUT.PUT_LINE('   Error: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
    -- Test Case 9: Large Capacity
    DECLARE
        v_venue_id NUMBER;
        v_test_user_id NUMBER := 1; -- Assuming this user exists
        v_capacity NUMBER;
    BEGIN
        -- First delete any existing venues with this name
        BEGIN
            EXECUTE IMMEDIATE 'DELETE FROM EVENT_ADMIN.VENUE WHERE VENUE_NAME = ''Huge Stadium''';
            COMMIT;
        EXCEPTION WHEN OTHERS THEN NULL; END;
        
        CREATE_VENUE('Huge Stadium', 999999, v_test_user_id, v_venue_id);
        
        -- Check the stored capacity
        SELECT VENUE_CAPACITY INTO v_capacity FROM EVENT_ADMIN.VENUE WHERE VENUE_ID = v_venue_id;
        
        IF v_capacity = 999999 THEN
            DBMS_OUTPUT.PUT_LINE('Test #9: Large Capacity - PASSED');
            DBMS_OUTPUT.PUT_LINE('   Large capacity stored correctly: ' || v_capacity);
        ELSE
            DBMS_OUTPUT.PUT_LINE('Test #9: Large Capacity - FAILED');
            DBMS_OUTPUT.PUT_LINE('   Expected 999999, got ' || v_capacity);
        END IF;
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Test #9: Large Capacity - FAILED');
            DBMS_OUTPUT.PUT_LINE('   Error: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
    -- Test Case 10: Duplicate Venue
    DECLARE
        v_venue_id NUMBER;
        v_test_user_id NUMBER := 1; -- Assuming this user exists
    BEGIN
        -- First delete any existing venues with this name
        BEGIN
            EXECUTE IMMEDIATE 'DELETE FROM EVENT_ADMIN.VENUE WHERE VENUE_NAME = ''Duplicate Test Venue''';
            COMMIT;
        EXCEPTION WHEN OTHERS THEN NULL; END;
        
        -- First insert
        CREATE_VENUE('Duplicate Test Venue', 200, v_test_user_id, v_venue_id);
        
        -- Second insert (should fail)
        CREATE_VENUE('Duplicate Test Venue', 200, v_test_user_id, v_venue_id);
        
        DBMS_OUTPUT.PUT_LINE('Test #10: Duplicate Venue - FAILED');
        DBMS_OUTPUT.PUT_LINE('   No exception was raised');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20005 THEN
                DBMS_OUTPUT.PUT_LINE('Test #10: Duplicate Venue - PASSED');

            ELSE
                DBMS_OUTPUT.PUT_LINE('Test #10: Duplicate Venue - FAILED');
                DBMS_OUTPUT.PUT_LINE('   Expected error code -20005 but got ' || SQLCODE || ': ' || SQLERRM);
            END IF;
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
    -- Test Case 11: Case Insensitive Duplicate Check
    DECLARE
        v_venue_id NUMBER;
        v_test_user_id NUMBER := 1; -- Assuming this user exists
    BEGIN
        -- First delete any existing venues with this name
        BEGIN
            EXECUTE IMMEDIATE 'DELETE FROM EVENT_ADMIN.VENUE WHERE UPPER(VENUE_NAME) = ''CASE SENSITIVE VENUE''';
            COMMIT;
        EXCEPTION WHEN OTHERS THEN NULL; END;
        
        -- First insert
        CREATE_VENUE('Case Sensitive Venue', 200, v_test_user_id, v_venue_id);
        
        -- Second insert with different case (should fail)
        CREATE_VENUE('CASE SENSITIVE VENUE', 200, v_test_user_id, v_venue_id);
        
        DBMS_OUTPUT.PUT_LINE('Test #11: Case Insensitive Duplicate Check - FAILED');
        DBMS_OUTPUT.PUT_LINE('   No exception was raised');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20005 THEN
                DBMS_OUTPUT.PUT_LINE('Test #11: Case Insensitive Duplicate Check - PASSED');

            ELSE
                DBMS_OUTPUT.PUT_LINE('Test #11: Case Insensitive Duplicate Check - FAILED');
                DBMS_OUTPUT.PUT_LINE('   Expected error code -20005 but got ' || SQLCODE || ': ' || SQLERRM);
            END IF;
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
    -- Test Case 12: Maximum Name Length
    DECLARE
        v_venue_id NUMBER;
        v_test_user_id NUMBER := 1; -- Assuming this user exists
        v_venue_name VARCHAR2(100);
        v_name_length NUMBER;
        v_max_length_name VARCHAR2(100) := RPAD('X', 100, 'X');
    BEGIN
        -- First delete any existing venues with max length
        BEGIN
            EXECUTE IMMEDIATE 'DELETE FROM EVENT_ADMIN.VENUE WHERE LENGTH(VENUE_NAME) = 100';
            COMMIT;
        EXCEPTION WHEN OTHERS THEN NULL; END;
        
        CREATE_VENUE(v_max_length_name, 100, v_test_user_id, v_venue_id);
        
        -- Check the stored name length
        SELECT VENUE_NAME, LENGTH(VENUE_NAME) INTO v_venue_name, v_name_length 
        FROM EVENT_ADMIN.VENUE WHERE VENUE_ID = v_venue_id;
        
        IF v_name_length = 100 THEN
            DBMS_OUTPUT.PUT_LINE('Test #12: Maximum Name Length - PASSED');
            DBMS_OUTPUT.PUT_LINE('   Successfully created venue with 100-character name');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Test #12: Maximum Name Length - FAILED');
            DBMS_OUTPUT.PUT_LINE('   Expected length 100, got ' || v_name_length);
        END IF;
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Test #12: Maximum Name Length - FAILED');
            DBMS_OUTPUT.PUT_LINE('   Error: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
    -- Test Case 13: Same Venue Different Users
    DECLARE
        v_venue_id1 NUMBER;
        v_venue_id2 NUMBER;
        v_test_user_id1 NUMBER := 1; -- Assuming this user exists
        v_test_user_id2 NUMBER := 2; -- Assuming this user exists
    BEGIN
        -- First delete any existing venues with this name
        BEGIN
            EXECUTE IMMEDIATE 'DELETE FROM EVENT_ADMIN.VENUE WHERE VENUE_NAME = ''Shared Venue Name''';
            COMMIT;
        EXCEPTION WHEN OTHERS THEN NULL; END;
        
        -- First user's venue
        CREATE_VENUE('Shared Venue Name', 150, v_test_user_id1, v_venue_id1);
        
        -- Second user's venue with same name (should succeed)
        CREATE_VENUE('Shared Venue Name', 150, v_test_user_id2, v_venue_id2);
        
        IF v_venue_id2 IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('Test #13: Same Venue Different Users - PASSED');
            DBMS_OUTPUT.PUT_LINE('   Successfully created venues with same name for different users');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Test #13: Same Venue Different Users - FAILED');
            DBMS_OUTPUT.PUT_LINE('   Failed to create second venue');
        END IF;
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Test #13: Same Venue Different Users - FAILED');
            DBMS_OUTPUT.PUT_LINE('   Error: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
    -- Test Case 14: Rollback on Error
    DECLARE
        v_venue_id NUMBER;
        v_non_existent_user_id NUMBER := 99999; -- A user ID that doesn't exist
        v_venue_count_before NUMBER;
        v_venue_count_after NUMBER;
    BEGIN
        -- Get current count of venues
        SELECT COUNT(*) INTO v_venue_count_before FROM EVENT_ADMIN.VENUE;
        
        -- Try to create venue with invalid user (should fail)
        BEGIN
            CREATE_VENUE('Rollback Test Venue', 100, v_non_existent_user_id, v_venue_id);
        EXCEPTION
            WHEN OTHERS THEN
                NULL; -- Expected error
        END;
        
        -- Check if count changed
        SELECT COUNT(*) INTO v_venue_count_after FROM EVENT_ADMIN.VENUE;
        
        IF v_venue_count_before = v_venue_count_after THEN
            DBMS_OUTPUT.PUT_LINE('Test #14: Rollback on Error - PASSED');
            DBMS_OUTPUT.PUT_LINE('   Transaction was properly rolled back');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Test #14: Rollback on Error - FAILED');
            DBMS_OUTPUT.PUT_LINE('   Transaction was not rolled back properly');
        END IF;
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Test #14: Rollback on Error - FAILED');
            DBMS_OUTPUT.PUT_LINE('   Error: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
   
    
    
    -- Final summary
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('TEST SUITE COMPLETED');
    DBMS_OUTPUT.PUT_LINE('========================================');
END;
/