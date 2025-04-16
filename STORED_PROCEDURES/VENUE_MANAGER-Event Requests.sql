-- Procedure for VENUE_MANAGER user to respond to Event Requests

CREATE OR REPLACE PROCEDURE respond_to_venue_request(
    p_event_id IN NUMBER,
    p_approve IN BOOLEAN
)
AS
    v_event_exists NUMBER;
    v_event_status VARCHAR2(50);
    v_event_name VARCHAR2(100);
    v_schedule_exists NUMBER;
    v_schedule_id NUMBER;w
    v_venue_id NUMBER;
    v_venue_name VARCHAR2(100);
    v_schedule_time TIMESTAMP;
    
    -- Custom exceptions
    event_not_found EXCEPTION;
    invalid_parameters EXCEPTION;
    request_expired EXCEPTION;
    invalid_event_status EXCEPTION;
    schedule_not_found EXCEPTION;
BEGIN
    -- Input validation
    IF p_event_id IS NULL THEN
        RAISE invalid_parameters;
    END IF;
    
    -- Check if the event exists and get its status
    SELECT COUNT(*), MAX(STATUS), MAX(EVENT_NAME)
    INTO v_event_exists, v_event_status, v_event_name
    FROM EVENT_ADMIN.EVENT
    WHERE EVENT_ID = p_event_id;
    
    IF v_event_exists = 0 THEN
        RAISE event_not_found;
    END IF;
    
    -- Check if the event has "Requested" status
    IF v_event_status != 'Requested' THEN
        RAISE invalid_event_status;
    END IF;
    
    -- Check if there's a matching record in EVENT_SCHEDULE
    SELECT COUNT(*), MAX(SCHEDULE_ID), MAX(VENUE_VENUE_ID), MAX(START_TIME)
    INTO v_schedule_exists, v_schedule_id, v_venue_id, v_schedule_time
    FROM EVENT_ADMIN.EVENT_SCHEDULE
    WHERE EVENT_EVENT_ID = p_event_id;
    
    IF v_schedule_exists = 0 THEN
        RAISE schedule_not_found;
    END IF;
    
    -- Get venue name
    SELECT VENUE_NAME INTO v_venue_name
    FROM EVENT_ADMIN.VENUE
    WHERE VENUE_ID = v_venue_id;
    
    -- Check if event is already in the past
    IF v_schedule_time <= SYSTIMESTAMP THEN
        RAISE request_expired;
    END IF;
    
    -- Process the response
    IF p_approve THEN
        -- Update event status to completed
        UPDATE EVENT_ADMIN.EVENT
        SET STATUS = 'Completed'
        WHERE EVENT_ID = p_event_id;
        
        DBMS_OUTPUT.PUT_LINE('Venue request approved successfully.');
        DBMS_OUTPUT.PUT_LINE('Event: "' || v_event_name || '" (ID: ' || p_event_id || ')');
        DBMS_OUTPUT.PUT_LINE('Venue: "' || v_venue_name || '" (ID: ' || v_venue_id || ')');
        DBMS_OUTPUT.PUT_LINE('Event status updated to Completed.');
    ELSE
        -- If declined, remove the schedule entry
        DELETE FROM EVENT_ADMIN.EVENT_SCHEDULE
        WHERE SCHEDULE_ID = v_schedule_id;
        
        -- Update event status to cancelled
        UPDATE EVENT_ADMIN.EVENT
        SET STATUS = 'Cancelled'
        WHERE EVENT_ID = p_event_id;
        
        DBMS_OUTPUT.PUT_LINE('Venue request declined.');
        DBMS_OUTPUT.PUT_LINE('Event: "' || v_event_name || '" (ID: ' || p_event_id || ')');
        DBMS_OUTPUT.PUT_LINE('Venue: "' || v_venue_name || '" (ID: ' || v_venue_id || ')');
        DBMS_OUTPUT.PUT_LINE('Event status updated to Cancelled.');
    END IF;
    
    COMMIT;
    
EXCEPTION
    WHEN invalid_parameters THEN
        DBMS_OUTPUT.PUT_LINE('Error: Event ID is required.');
        ROLLBACK;
    WHEN event_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: Event with ID ' || p_event_id || ' not found.');
        ROLLBACK;
    WHEN schedule_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: No venue request found for event ID ' || p_event_id || '.');
        ROLLBACK;
    WHEN request_expired THEN
        DBMS_OUTPUT.PUT_LINE('Error: Cannot respond to a request for an event that is in the past.');
        ROLLBACK;
    WHEN invalid_event_status THEN
        DBMS_OUTPUT.PUT_LINE('Error: Can only respond to events with "Requested" status. Current status: ' || v_event_status);
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM || ' - Error code: ' || SQLCODE);
        ROLLBACK;
END respond_to_venue_request;
/

-- Test cases for respond_to_venue_request procedure
SET SERVEROUTPUT ON;

-- TEST CASE 1: Create a venue request for an existing event and test approval
DECLARE
    v_schedule_id NUMBER;
    v_event_id NUMBER := 1;  -- Using existing Tech Conference event
    v_venue_id NUMBER := 1;  -- Using existing Grand Hall venue
BEGIN
    DBMS_OUTPUT.PUT_LINE('Setup: Creating venue request for testing');
    
    -- Save original event status to restore later
    DECLARE
        v_original_status VARCHAR2(50);
    BEGIN
        SELECT STATUS INTO v_original_status FROM EVENT_ADMIN.EVENT WHERE EVENT_ID = v_event_id;
        DBMS_OUTPUT.PUT_LINE('Original event status: ' || v_original_status);
    END;
    
    -- Update existing event to Pending status
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Pending'
    WHERE EVENT_ID = v_event_id;
    COMMIT;
    
    -- Clear any existing schedule for this event
    DELETE FROM EVENT_ADMIN.EVENT_SCHEDULE
    WHERE EVENT_EVENT_ID = v_event_id;
    COMMIT;
    
    -- Create schedule record for the existing event
    INSERT INTO EVENT_ADMIN.EVENT_SCHEDULE(
        SCHEDULE_ID,
        EVENT_SCHEDULE_DATE,
        START_TIME,
        END_TIME,
        VENUE_VENUE_ID,
        EVENT_EVENT_ID
    ) VALUES (
        EVENT_ADMIN.EVENT_SCHEDULE_SEQ.NEXTVAL,
        SYSTIMESTAMP + INTERVAL '30' DAY,
        SYSTIMESTAMP + INTERVAL '30' DAY + INTERVAL '9' HOUR,
        SYSTIMESTAMP + INTERVAL '30' DAY + INTERVAL '17' HOUR,
        v_venue_id,
        v_event_id
    ) RETURNING SCHEDULE_ID INTO v_schedule_id;
    
    -- Update event status to 'Requested'
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Requested'
    WHERE EVENT_ID = v_event_id;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Created schedule with ID: ' || v_schedule_id);
    
    -- TEST CASE 1: Valid approval
    DBMS_OUTPUT.PUT_LINE('TEST CASE 1: Valid approval');
    
    -- Execute the procedure
    respond_to_venue_request(
        p_event_id => v_event_id,
        p_approve => TRUE
    );
    
    -- Verify results
    DECLARE
        v_status VARCHAR2(50);
        v_schedule_exists NUMBER;
    BEGIN
        SELECT STATUS INTO v_status FROM EVENT_ADMIN.EVENT WHERE EVENT_ID = v_event_id;
        SELECT COUNT(*) INTO v_schedule_exists FROM EVENT_ADMIN.EVENT_SCHEDULE 
        WHERE EVENT_EVENT_ID = v_event_id;
        
        DBMS_OUTPUT.PUT_LINE('Event status after approval: ' || v_status);
        DBMS_OUTPUT.PUT_LINE('Schedule record still exists: ' || (CASE WHEN v_schedule_exists > 0 THEN 'Yes' ELSE 'No' END));
    END;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in Test Case 1: ' || SQLERRM);
        ROLLBACK;
END;
/

-- TEST CASE 2: Create a venue request for another existing event and test rejection
DECLARE
    v_schedule_id NUMBER;
    v_event_id NUMBER := 2;  -- Using existing Art Exhibition event
    v_venue_id NUMBER := 2;  -- Using existing Art Gallery venue
BEGIN
    DBMS_OUTPUT.PUT_LINE('Setup: Creating venue request for rejection test');
    
    -- Save original event status to restore later
    DECLARE
        v_original_status VARCHAR2(50);
    BEGIN
        SELECT STATUS INTO v_original_status FROM EVENT_ADMIN.EVENT WHERE EVENT_ID = v_event_id;
        DBMS_OUTPUT.PUT_LINE('Original event status: ' || v_original_status);
    END;
    
    -- Update existing event to Pending status
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Pending'
    WHERE EVENT_ID = v_event_id;
    COMMIT;
    
    -- Clear any existing schedule for this event
    DELETE FROM EVENT_ADMIN.EVENT_SCHEDULE
    WHERE EVENT_EVENT_ID = v_event_id;
    COMMIT;
    
    -- Create schedule record for the existing event
    INSERT INTO EVENT_ADMIN.EVENT_SCHEDULE(
        SCHEDULE_ID,
        EVENT_SCHEDULE_DATE,
        START_TIME,
        END_TIME,
        VENUE_VENUE_ID,
        EVENT_EVENT_ID
    ) VALUES (
        EVENT_ADMIN.EVENT_SCHEDULE_SEQ.NEXTVAL,
        SYSTIMESTAMP + INTERVAL '45' DAY,
        SYSTIMESTAMP + INTERVAL '45' DAY + INTERVAL '9' HOUR,
        SYSTIMESTAMP + INTERVAL '45' DAY + INTERVAL '17' HOUR,
        v_venue_id,
        v_event_id
    ) RETURNING SCHEDULE_ID INTO v_schedule_id;
    
    -- Update event status to 'Requested'
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Requested'
    WHERE EVENT_ID = v_event_id;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Created schedule with ID: ' || v_schedule_id);
    
    -- TEST CASE 2: Valid rejection
    DBMS_OUTPUT.PUT_LINE('TEST CASE 2: Valid rejection');
    
    -- Execute the procedure
    respond_to_venue_request(
        p_event_id => v_event_id,
        p_approve => FALSE
    );
    
    -- Verify results
    DECLARE
        v_status VARCHAR2(50);
        v_schedule_exists NUMBER;
    BEGIN
        SELECT STATUS INTO v_status FROM EVENT_ADMIN.EVENT WHERE EVENT_ID = v_event_id;
        SELECT COUNT(*) INTO v_schedule_exists FROM EVENT_ADMIN.EVENT_SCHEDULE 
        WHERE EVENT_EVENT_ID = v_event_id;
        
        DBMS_OUTPUT.PUT_LINE('Event status after rejection: ' || v_status);
        DBMS_OUTPUT.PUT_LINE('Schedule record removed: ' || (CASE WHEN v_schedule_exists = 0 THEN 'Yes' ELSE 'No' END));
    END;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in Test Case 2: ' || SQLERRM);
        ROLLBACK;
END;
/

-- TEST CASE 3: Missing event ID
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 3: Missing event ID');
    
    respond_to_venue_request(
        p_event_id => NULL,
        p_approve => TRUE
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST CASE 4: Non-existent event ID
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 4: Non-existent event ID');
    
    respond_to_venue_request(
        p_event_id => 9999,  -- Non-existent
        p_approve => TRUE
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST CASE 5: Event with wrong status
DECLARE
    v_event_id NUMBER := 4;  -- Using existing Food Fair event
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 5: Event with wrong status');
    
    -- Set event to a status other than 'Requested'
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Pending'
    WHERE EVENT_ID = v_event_id;
    COMMIT;
    
    -- Try to respond
    respond_to_venue_request(
        p_event_id => v_event_id,
        p_approve => TRUE
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST CASE 6: Event without schedule record
DECLARE
    v_event_id NUMBER := 5;  -- Using existing Sports Day event
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 6: Event without schedule record');
    
    -- Set event to 'Requested' status
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Requested'
    WHERE EVENT_ID = v_event_id;
    COMMIT;
    
    -- Clear any existing schedule for this event
    DELETE FROM EVENT_ADMIN.EVENT_SCHEDULE
    WHERE EVENT_EVENT_ID = v_event_id;
    COMMIT;
    
    -- Try to respond
    respond_to_venue_request(
        p_event_id => v_event_id,
        p_approve => TRUE
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST CASE 7: Event with past schedule
DECLARE
    v_schedule_id NUMBER;
    v_event_id NUMBER := 3;  -- Using existing Music Festival event
    v_venue_id NUMBER := 3;  -- Using existing Music Arena venue
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 7: Event with past schedule');
    
    -- Set event to 'Requested' status
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Requested'
    WHERE EVENT_ID = v_event_id;
    COMMIT;
    
    -- Clear any existing schedule for this event
    DELETE FROM EVENT_ADMIN.EVENT_SCHEDULE
    WHERE EVENT_EVENT_ID = v_event_id;
    COMMIT;
    
    -- Create past schedule record
    INSERT INTO EVENT_ADMIN.EVENT_SCHEDULE(
        SCHEDULE_ID,
        EVENT_SCHEDULE_DATE,
        START_TIME,
        END_TIME,
        VENUE_VENUE_ID,
        EVENT_EVENT_ID
    ) VALUES (
        EVENT_ADMIN.EVENT_SCHEDULE_SEQ.NEXTVAL,
        SYSTIMESTAMP - INTERVAL '10' DAY,  -- Past date
        SYSTIMESTAMP - INTERVAL '10' DAY,
        SYSTIMESTAMP - INTERVAL '10' DAY + INTERVAL '8' HOUR,
        v_venue_id,
        v_event_id
    ) RETURNING SCHEDULE_ID INTO v_schedule_id;
    COMMIT;
    
    -- Try to respond
    respond_to_venue_request(
        p_event_id => v_event_id,
        p_approve => TRUE
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/
