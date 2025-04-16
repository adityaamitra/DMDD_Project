CREATE OR REPLACE PROCEDURE update_event(
    p_event_id IN NUMBER,
    p_event_name IN VARCHAR2 DEFAULT NULL,
    p_event_description IN VARCHAR2 DEFAULT NULL,
    p_event_type IN VARCHAR2 DEFAULT NULL,
    p_event_budget IN NUMBER DEFAULT NULL,
    p_status IN VARCHAR2 DEFAULT NULL
)
AS
    v_event_exists NUMBER;
    v_event_owner NUMBER;
    v_current_status VARCHAR2(50);
    v_organizer_id NUMBER;
    v_name_exists NUMBER;
    
    -- Custom exceptions
    event_not_found EXCEPTION;
    invalid_parameters EXCEPTION;
    duplicate_event_name EXCEPTION;
    negative_budget EXCEPTION;
    invalid_status EXCEPTION;
    event_status_locked EXCEPTION;
BEGIN
    -- Input validation
    IF p_event_id IS NULL THEN
        RAISE invalid_parameters;
    END IF;
    
    IF p_event_budget IS NOT NULL AND p_event_budget < 1 THEN
        RAISE negative_budget;
    END IF;
    
    -- Validate status if provided
    IF p_status IS NOT NULL AND p_status NOT IN ('Pending', 'Scheduled', 'Completed', 'Cancelled') THEN
        RAISE invalid_status;
    END IF;
    
    -- Check if the event exists and get current values
    SELECT COUNT(*), MAX(ORGANIZER_ORGANIZER_ID), MAX(STATUS)
    INTO v_event_exists, v_organizer_id, v_current_status
    FROM EVENT_ADMIN.EVENT
    WHERE EVENT_ID = p_event_id;
    
    IF v_event_exists = 0 THEN
        RAISE event_not_found;
    END IF;
    
    -- Check if event status allows updates
    IF v_current_status IN ('Confirmed', 'Cancelled') THEN
        RAISE event_status_locked;
    END IF;
    
    -- Check for duplicate event name if name is being updated
    IF p_event_name IS NOT NULL THEN
        -- Trim whitespace to prevent empty strings
        IF TRIM(p_event_name) IS NULL OR LENGTH(TRIM(p_event_name)) = 0 THEN
            RAISE invalid_parameters;
        END IF;
        
        SELECT COUNT(*) INTO v_name_exists
        FROM EVENT_ADMIN.EVENT
        WHERE UPPER(EVENT_NAME) = UPPER(TRIM(p_event_name))
        AND ORGANIZER_ORGANIZER_ID = v_organizer_id
        AND EVENT_ID != p_event_id;
        
        IF v_name_exists > 0 THEN
            RAISE duplicate_event_name;
        END IF;
    END IF;
    
    -- Update the event with conditional updates for each field
    UPDATE EVENT_ADMIN.EVENT
    SET EVENT_NAME = CASE WHEN p_event_name IS NOT NULL THEN TRIM(p_event_name) ELSE EVENT_NAME END,
        EVENT_DESCRIPTION = CASE WHEN p_event_description IS NOT NULL THEN TRIM(p_event_description) ELSE EVENT_DESCRIPTION END,
        EVENT_TYPE = CASE WHEN p_event_type IS NOT NULL THEN TRIM(p_event_type) ELSE EVENT_TYPE END,
        EVENT_BUDGET = CASE WHEN p_event_budget IS NOT NULL THEN p_event_budget ELSE EVENT_BUDGET END,
        STATUS = CASE WHEN p_status IS NOT NULL THEN p_status ELSE STATUS END
    WHERE EVENT_ID = p_event_id;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Event with ID ' || p_event_id || ' updated successfully.');
    
EXCEPTION
    WHEN invalid_parameters THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid parameters provided. Event ID is required and event name cannot be empty.');
        ROLLBACK;
    WHEN negative_budget THEN
        DBMS_OUTPUT.PUT_LINE('Error: Event budget must be at least 1.');
        ROLLBACK;
    WHEN event_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: Event with ID ' || p_event_id || ' not found.');
        ROLLBACK;
    WHEN duplicate_event_name THEN
        DBMS_OUTPUT.PUT_LINE('Error: An event with the name "' || p_event_name || '" already exists for this organizer.');
        ROLLBACK;
    WHEN invalid_status THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid status. Status must be one of: Pending, Requested, Confirmed, Rejected.');
        ROLLBACK;
    WHEN event_status_locked THEN
        DBMS_OUTPUT.PUT_LINE('Error: Cannot update event with status "' || v_current_status || '". Only events with status "Pending" or "Requested" can be updated.');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM || ' - Error code: ' || SQLCODE);
        ROLLBACK;
END update_event;
/

-- Test cases for the update_event procedure
-- Set server output on to see results
SET SERVEROUTPUT ON;

-- Create a test event to update
DECLARE
    v_event_exists NUMBER;
BEGIN
    -- Check if our test event already exists
    SELECT COUNT(*) INTO v_event_exists
    FROM EVENT_ADMIN.EVENT
    WHERE EVENT_NAME = 'Test Event For Updates';
    
    -- If not, create it
    IF v_event_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Creating test event for update tests');
        add_event(
            p_organizer_id => 1,
            p_event_name => 'Test Event For Updates',
            p_event_description => 'Initial description',
            p_event_type => 'Conference',
            p_event_budget => 5000
        );
    END IF;
END;
/

-- Get the event ID for testing
DECLARE
    v_event_id NUMBER;
BEGIN
    SELECT EVENT_ID INTO v_event_id
    FROM EVENT_ADMIN.EVENT
    WHERE EVENT_NAME = 'Test Event For Updates';
    
    -- Test Case 1: Valid event update - change name
    DBMS_OUTPUT.PUT_LINE('Test Case 1: Valid event update - change name');
    update_event(
        p_event_id => v_event_id,
        p_event_name => 'Updated Test Event'
    );
    
    -- Test Case 2: Valid event update - change multiple fields
    DBMS_OUTPUT.PUT_LINE('Test Case 2: Valid event update - change multiple fields');
    update_event(
        p_event_id => v_event_id,
        p_event_description => 'Updated description',
        p_event_type => 'Workshop',
        p_event_budget => 7500
    );
    
    -- Test Case 3: Valid event update - change status
    DBMS_OUTPUT.PUT_LINE('Test Case 3: Valid event update - change status');
    update_event(
        p_event_id => v_event_id,
        p_status => 'Requested'
    );
    
    -- Test Case 4: Attempt to update with invalid status
    DBMS_OUTPUT.PUT_LINE('Test Case 4: Attempt to update with invalid status');
    BEGIN
        update_event(
            p_event_id => v_event_id,
            p_status => 'Invalid Status'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    -- Create another test event for duplicate name test
    DECLARE
        v_event_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_event_exists
        FROM EVENT_ADMIN.EVENT
        WHERE EVENT_NAME = 'Another Test Event';
        
        IF v_event_exists = 0 THEN
            add_event(
                p_organizer_id => 1,
                p_event_name => 'Another Test Event',
                p_event_description => 'For duplicate name test',
                p_event_type => 'Conference',
                p_event_budget => 5000
            );
        END IF;
    END;
    
    -- Test Case 5: Attempt to update to duplicate name
    DBMS_OUTPUT.PUT_LINE('Test Case 5: Attempt to update to duplicate name');
    BEGIN
        update_event(
            p_event_id => v_event_id,
            p_event_name => 'Another Test Event'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    -- Test Case 6: Attempt to update with negative budget
    DBMS_OUTPUT.PUT_LINE('Test Case 6: Attempt to update with negative budget');
    BEGIN
        update_event(
            p_event_id => v_event_id,
            p_event_budget => -100
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    -- Test Case 7: Update with NULL event_id
    DBMS_OUTPUT.PUT_LINE('Test Case 7: Update with NULL event_id');
    BEGIN
        update_event(
            p_event_id => NULL,
            p_event_name => 'Should Fail'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    -- Test Case 8: Update non-existent event
    DBMS_OUTPUT.PUT_LINE('Test Case 8: Update non-existent event');
    BEGIN
        update_event(
            p_event_id => 99999,
            p_event_name => 'Non-existent Event'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    -- Change status to 'Confirmed' to test locked status
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Confirmed'
    WHERE EVENT_ID = v_event_id;
    COMMIT;
    
    -- Test Case 9: Attempt to update locked status event
    DBMS_OUTPUT.PUT_LINE('Test Case 9: Attempt to update locked status event');
    BEGIN
        update_event(
            p_event_id => v_event_id,
            p_event_name => 'Should Fail Due To Status'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    -- Clean up test events
    DBMS_OUTPUT.PUT_LINE('Cleaning up test events');
    DELETE FROM EVENT_ADMIN.EVENT
    WHERE EVENT_NAME IN ('Updated Test Event', 'Another Test Event');
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Test event not found. Test cases skipped.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in test cases: ' || SQLERRM);
        ROLLBACK;
END;
/


-- Test cases for the update_event procedure
-- Set server output on to see results
SET SERVEROUTPUT ON;

-- Create a test event to update
DECLARE
    v_event_exists NUMBER;
BEGIN
    -- Check if our test event already exists
    SELECT COUNT(*) INTO v_event_exists
    FROM EVENT_ADMIN.EVENT
    WHERE EVENT_NAME = 'Test Event For Updates';
    
    -- If not, create it
    IF v_event_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Creating test event for update tests');
        add_event(
            p_organizer_id => 1,
            p_event_name => 'Test Event For Updates',
            p_event_description => 'Initial description',
            p_event_type => 'Conference',
            p_event_budget => 5000
        );
    END IF;
END;
/

-- Get the event ID for testing
DECLARE
    v_event_id NUMBER;
BEGIN
    SELECT EVENT_ID INTO v_event_id
    FROM EVENT_ADMIN.EVENT
    WHERE EVENT_NAME = 'Test Event For Updates';
    
    -- Test Case 1: Valid event update - change name
    DBMS_OUTPUT.PUT_LINE('Test Case 1: Valid event update - change name');
    update_event(
        p_event_id => v_event_id,
        p_event_name => 'Updated Test Event'
    );
    
    -- Test Case 2: Valid event update - change multiple fields
    DBMS_OUTPUT.PUT_LINE('Test Case 2: Valid event update - change multiple fields');
    update_event(
        p_event_id => v_event_id,
        p_event_description => 'Updated description',
        p_event_type => 'Workshop',
        p_event_budget => 7500
    );
    
    -- Test Case 3: Valid event update - change status to valid status
    DBMS_OUTPUT.PUT_LINE('Test Case 3: Valid event update - change status');
    update_event(
        p_event_id => v_event_id,
        p_status => 'Scheduled'  -- Changed from 'Requested' to 'Scheduled'
    );
    
    -- Test Case 4: Attempt to update with invalid status
    DBMS_OUTPUT.PUT_LINE('Test Case 4: Attempt to update with invalid status');
    BEGIN
        update_event(
            p_event_id => v_event_id,
            p_status => 'Invalid Status'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    -- Create another test event for duplicate name test
    DECLARE
        v_event_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_event_exists
        FROM EVENT_ADMIN.EVENT
        WHERE EVENT_NAME = 'Another Test Event';
        
        IF v_event_exists = 0 THEN
            add_event(
                p_organizer_id => 1,
                p_event_name => 'Another Test Event',
                p_event_description => 'For duplicate name test',
                p_event_type => 'Conference',
                p_event_budget => 5000
            );
        END IF;
    END;
    
    -- Test Case 5: Attempt to update to duplicate name
    DBMS_OUTPUT.PUT_LINE('Test Case 5: Attempt to update to duplicate name');
    BEGIN
        update_event(
            p_event_id => v_event_id,
            p_event_name => 'Another Test Event'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    -- Test Case 6: Attempt to update with negative budget
    DBMS_OUTPUT.PUT_LINE('Test Case 6: Attempt to update with negative budget');
    BEGIN
        update_event(
            p_event_id => v_event_id,
            p_event_budget => -100
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    -- Test Case 7: Update with NULL event_id
    DBMS_OUTPUT.PUT_LINE('Test Case 7: Update with NULL event_id');
    BEGIN
        update_event(
            p_event_id => NULL,
            p_event_name => 'Should Fail'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    -- Test Case 8: Update non-existent event
    DBMS_OUTPUT.PUT_LINE('Test Case 8: Update non-existent event');
    BEGIN
        update_event(
            p_event_id => 99999,
            p_event_name => 'Non-existent Event'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    -- Change status to 'Confirmed' to test locked status
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Completed'
    WHERE EVENT_ID = v_event_id;
    COMMIT;
    
    -- Test Case 9: Attempt to update locked status event
    DBMS_OUTPUT.PUT_LINE('Test Case 9: Attempt to update locked status event');
    BEGIN
        update_event(
            p_event_id => v_event_id,
            p_event_name => 'Should Fail Due To Status'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;

    -- Test Case 10: Attempt to update to Cancelled status
    DBMS_OUTPUT.PUT_LINE('Test Case 10: Attempt to update to Cancelled status');
    -- First reset the event status to Pending
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Pending'
    WHERE EVENT_ID = v_event_id;
    COMMIT;
    
    -- Now try to update to Cancelled
    update_event(
        p_event_id => v_event_id,
        p_status => 'Cancelled'
    );
    
    -- Clean up test events
    DBMS_OUTPUT.PUT_LINE('Cleaning up test events');
    DELETE FROM EVENT_ADMIN.EVENT
    WHERE EVENT_NAME IN ('Updated Test Event', 'Another Test Event');
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Test event not found. Test cases skipped.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in test cases: ' || SQLERRM);
        ROLLBACK;
END;
/