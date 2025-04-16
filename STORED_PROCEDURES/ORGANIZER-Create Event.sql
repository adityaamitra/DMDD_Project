-- Create or replace the add_event procedure
CREATE OR REPLACE PROCEDURE add_event(
    p_organizer_id IN NUMBER,
    p_event_name IN VARCHAR2,
    p_event_description IN VARCHAR2,
    p_event_type IN VARCHAR2,
    p_event_budget IN NUMBER
)
AS
    v_event_id NUMBER;
    v_organizer_exists NUMBER;
    v_event_exists NUMBER;
    
    -- Custom exceptions
    organizer_not_found EXCEPTION;
    invalid_parameters EXCEPTION;
    duplicate_event_name EXCEPTION;
    negative_budget EXCEPTION;
BEGIN
    -- Input validation
    IF p_organizer_id IS NULL OR p_event_name IS NULL OR p_event_type IS NULL THEN
        RAISE invalid_parameters;
    END IF;
    
    -- Trim whitespace to prevent empty strings
    IF TRIM(p_event_name) IS NULL OR LENGTH(TRIM(p_event_name)) = 0 THEN
        RAISE invalid_parameters;
    END IF;
    
    IF p_event_budget < 1 THEN
        RAISE negative_budget;
    END IF;
    
    -- Check if the organizer exists
    SELECT COUNT(*) INTO v_organizer_exists 
    FROM EVENT_ADMIN.ORGANIZER 
    WHERE ORGANIZER_ID = p_organizer_id;
    
    IF v_organizer_exists = 0 THEN
        RAISE organizer_not_found;
    END IF;
    
    -- Check for duplicate event name
    SELECT COUNT(*) INTO v_event_exists
    FROM EVENT_ADMIN.EVENT
    WHERE UPPER(EVENT_NAME) = UPPER(TRIM(p_event_name))
    AND ORGANIZER_ORGANIZER_ID = p_organizer_id;
    
    IF v_event_exists > 0 THEN
        RAISE duplicate_event_name;
    END IF;
    
    -- Insert the new event with proper trimming
    INSERT INTO EVENT_ADMIN.EVENT(
        EVENT_ID,
        ORGANIZER_ORGANIZER_ID,
        EVENT_NAME,
        EVENT_DESCRIPTION,
        EVENT_TYPE,
        STATUS,
        EVENT_BUDGET
    ) VALUES (
        EVENT_ADMIN.EVENT_ID_SEQ.NEXTVAL,
        p_organizer_id,
        TRIM(p_event_name),
        TRIM(p_event_description),
        TRIM(p_event_type),
        'Pending', -- Initial status
        p_event_budget
    ) RETURNING EVENT_ID INTO v_event_id;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Event created successfully with ID: ' || v_event_id);
    
EXCEPTION
    WHEN invalid_parameters THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid parameters provided. Organizer ID, event name, and event type are required.');
        ROLLBACK;
    WHEN negative_budget THEN
        DBMS_OUTPUT.PUT_LINE('Error: Event budget cannot be negative.');
        ROLLBACK;
    WHEN organizer_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: Organizer with ID ' || p_organizer_id || ' not found.');
        ROLLBACK;
    WHEN duplicate_event_name THEN
        DBMS_OUTPUT.PUT_LINE('Error: An event with the name "' || p_event_name || '" already exists for this organizer.');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM || ' - Error code: ' || SQLCODE);
        ROLLBACK;
END add_event;
/

-- Test cases for the add_event procedure
-- Set server output on to see results
SET SERVEROUTPUT ON;

-- Test Case 1: Valid event creation
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 1: Valid event creation');
    add_event(
        p_organizer_id => 1, -- Organizer ID 1
        p_event_name => 'Annual Tech Conference',
        p_event_description => 'A gathering of tech enthusiasts',
        p_event_type => 'Conference',
        p_event_budget => 5000.00
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END;
/

-- Test Case 2: NULL organizer ID
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 2: NULL organizer ID');
    add_event(
        p_organizer_id => NULL,
        p_event_name => 'Test Event',
        p_event_description => 'This should fail',
        p_event_type => 'Conference',
        p_event_budget => 5000.00
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 3: NULL event name
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 3: NULL event name');
    add_event(
        p_organizer_id => 1, -- Organizer ID 1
        p_event_name => NULL,
        p_event_description => 'This should fail',
        p_event_type => 'Conference',
        p_event_budget => 5000.00
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 4: Empty event name (only whitespace)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 4: Empty event name (whitespace only)');
    add_event(
        p_organizer_id => 1, -- Organizer ID 1
        p_event_name => '   ',
        p_event_description => 'This should fail',
        p_event_type => 'Conference',
        p_event_budget => 5000.00
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 5: NULL event type
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 5: NULL event type');
    add_event(
        p_organizer_id => 1, -- Organizer ID 1
        p_event_name => 'Test Event',
        p_event_description => 'This should fail',
        p_event_type => NULL,
        p_event_budget => 5000.00
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 6: Negative budget
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 6: Negative budget');
    add_event(
        p_organizer_id => 1, -- Organizer ID 1
        p_event_name => 'Test Event',
        p_event_description => 'This should fail',
        p_event_type => 'Conference',
        p_event_budget => -1000.00
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 7: Non-existent organizer
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 7: Non-existent organizer');
    add_event(
        p_organizer_id => 9999, -- Non-existent organizer ID
        p_event_name => 'Test Event',
        p_event_description => 'This should fail',
        p_event_type => 'Conference',
        p_event_budget => 5000.00
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 8: Duplicate event name
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 8: Duplicate event name - First attempt');
    -- Create an initial event
    BEGIN
        add_event(
            p_organizer_id => 1, -- Organizer ID 1
            p_event_name => 'Duplicate Event',
            p_event_description => 'First creation',
            p_event_type => 'Conference',
            p_event_budget => 5000.00
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Unexpected error in first creation: ' || SQLERRM);
    END;
    
    -- Try to create another event with the same name
    DBMS_OUTPUT.PUT_LINE('Test Case 8: Duplicate event name - Second attempt');
    add_event(
        p_organizer_id => 1, -- Organizer ID 1
        p_event_name => 'Duplicate Event',
        p_event_description => 'This should fail',
        p_event_type => 'Workshop',
        p_event_budget => 6000.00
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 9: Same event name but different organizer (should succeed)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 9: Same event name with different organizer');
    add_event(
        p_organizer_id => 3, -- Different organizer ID
        p_event_name => 'Duplicate Event',
        p_event_description => 'This should succeed',
        p_event_type => 'Conference',
        p_event_budget => 5000.00
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END;
/

-- Test Case 10: Event name with mixed case (should be caught by duplicate check)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 10: Mixed case duplicate event name');
    add_event(
        p_organizer_id => 1, -- Organizer ID 1
        p_event_name => 'DUPLICATE event',  -- Different case, same name
        p_event_description => 'This should fail',
        p_event_type => 'Conference',
        p_event_budget => 5000.00
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 11: NULL event description (should succeed as it's optional)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 11: NULL event description');
    add_event(
        p_organizer_id => 1, -- Organizer ID 1
        p_event_name => 'Event With No Description',
        p_event_description => NULL,
        p_event_type => 'Conference',
        p_event_budget => 5000.00
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END;
/

-- Test Case 12: Zero budget (should succeed as it's not negative)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 12: Zero budget');
    add_event(
        p_organizer_id => 1, -- Organizer ID 1
        p_event_name => 'Zero Budget Event',
        p_event_description => 'This should succeed',
        p_event_type => 'Conference',
        p_event_budget => 0
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END;
/
