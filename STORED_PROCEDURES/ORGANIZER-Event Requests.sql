-- Procedure for EVENT_ORGANIZER user to request a Venue
CREATE OR REPLACE PROCEDURE request_venue(
    p_event_id IN NUMBER,
    p_venue_id IN NUMBER,
    p_event_date IN TIMESTAMP,
    p_start_time IN TIMESTAMP,
    p_end_time IN TIMESTAMP
)
AS
    v_event_exists NUMBER;
    v_event_status VARCHAR2(50);
    v_organizer_id NUMBER;
    v_venue_exists NUMBER;
    v_venue_manager_id NUMBER;
    v_same_day_event_count NUMBER;
    v_existing_request_count NUMBER;
    v_request_id NUMBER;
    v_event_name VARCHAR2(100);
    v_venue_name VARCHAR2(100);
    
    -- Custom exceptions
    event_not_found EXCEPTION;
    venue_not_found EXCEPTION;
    venue_already_booked_same_day EXCEPTION;
    invalid_parameters EXCEPTION;
    invalid_schedule_time EXCEPTION;
    request_already_exists EXCEPTION;
    invalid_event_status EXCEPTION;
BEGIN
    -- Input validation
    IF p_event_id IS NULL OR p_venue_id IS NULL OR 
       p_event_date IS NULL OR p_start_time IS NULL OR p_end_time IS NULL THEN
        RAISE invalid_parameters;
    END IF;
    
    -- Verify time logic
    IF p_start_time >= p_end_time THEN
        RAISE invalid_schedule_time;
    END IF;
    
    -- Event must be in future
    IF p_start_time <= SYSTIMESTAMP THEN
        RAISE invalid_schedule_time;
    END IF;
    
    -- Check if the event exists and get status and name
    SELECT COUNT(*), MAX(STATUS), MAX(ORGANIZER_ORGANIZER_ID), MAX(EVENT_NAME)
    INTO v_event_exists, v_event_status, v_organizer_id, v_event_name
    FROM EVENT_ADMIN.EVENT 
    WHERE EVENT_ID = p_event_id;
    
    IF v_event_exists = 0 THEN
        RAISE event_not_found;
    END IF;
    
    -- Only events with status 'Pending' can be scheduled
    IF v_event_status != 'Pending' THEN
        RAISE invalid_event_status;
    END IF;
    
    -- Check if the venue exists and get venue name
    SELECT COUNT(*), MAX(USER_USER_ID), MAX(VENUE_NAME)
    INTO v_venue_exists, v_venue_manager_id, v_venue_name
    FROM EVENT_ADMIN.VENUE 
    WHERE VENUE_ID = p_venue_id;
    
    IF v_venue_exists = 0 THEN
        RAISE venue_not_found;
    END IF;
    
    -- Check if a request already exists for this event-venue pair
    SELECT COUNT(*) INTO v_existing_request_count
    FROM EVENT_ADMIN.EVENT_SCHEDULE
    WHERE EVENT_EVENT_ID = p_event_id
    AND VENUE_VENUE_ID = p_venue_id;
    
    IF v_existing_request_count > 0 THEN
        RAISE request_already_exists;
    END IF;
    
    -- Check for same-day events (ignoring time)
    SELECT COUNT(*) INTO v_same_day_event_count
    FROM EVENT_ADMIN.EVENT_SCHEDULE
    WHERE VENUE_VENUE_ID = p_venue_id
    AND TRUNC(EVENT_SCHEDULE_DATE) = TRUNC(p_event_date);
    
    IF v_same_day_event_count > 0 THEN
        RAISE venue_already_booked_same_day;
    END IF;
    
    -- Create a venue request entry in EVENT_SCHEDULE
    INSERT INTO EVENT_ADMIN.EVENT_SCHEDULE(
        SCHEDULE_ID,
        EVENT_SCHEDULE_DATE,
        START_TIME,
        END_TIME,
        VENUE_VENUE_ID,
        EVENT_EVENT_ID
    ) VALUES (
        EVENT_ADMIN.EVENT_SCHEDULE_SEQ.NEXTVAL,
        p_event_date,
        p_start_time,
        p_end_time,
        p_venue_id,
        p_event_id
    ) RETURNING SCHEDULE_ID INTO v_request_id;
    
    -- Update event status to 'Requested'
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Requested'
    WHERE EVENT_ID = p_event_id;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Venue request sent successfully for event "' || v_event_name || '"');
    DBMS_OUTPUT.PUT_LINE('Venue: ' || v_venue_name || ' (ID: ' || p_venue_id || ')');
    DBMS_OUTPUT.PUT_LINE('Request ID: ' || v_request_id);
    DBMS_OUTPUT.PUT_LINE('Event status updated to Requested.');
    
EXCEPTION
    WHEN invalid_parameters THEN
        DBMS_OUTPUT.PUT_LINE('Error: All parameters (event ID, venue ID, event date, start time, end time) are required.');
        ROLLBACK;
    WHEN invalid_schedule_time THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid schedule times. End time must be after start time, and the event must be scheduled in the future.');
        ROLLBACK;
    WHEN event_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: Event with ID ' || p_event_id || ' not found.');
        ROLLBACK;
    WHEN venue_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: Venue with ID ' || p_venue_id || ' not found.');
        ROLLBACK;
    WHEN venue_already_booked_same_day THEN
        DBMS_OUTPUT.PUT_LINE('Error: The venue is already booked for another event on the requested date. Each venue can only host one event per day.');
        ROLLBACK;
    WHEN request_already_exists THEN
        DBMS_OUTPUT.PUT_LINE('Error: A venue request already exists for this event and venue combination.');
        ROLLBACK;
    WHEN invalid_event_status THEN
        DBMS_OUTPUT.PUT_LINE('Error: Only events with "Pending" status can be scheduled. Current status: ' || v_event_status);
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM || ' - Error code: ' || SQLCODE);
        ROLLBACK;
END request_venue;
/


-- Setup for request_venue test cases
SET SERVEROUTPUT ON;

-- TEST CASE 1: Valid venue request
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 1: Valid venue request');
    
    -- First ensure event is in Pending status
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Pending'
    WHERE EVENT_ID = 1;  -- Tech Conference
    COMMIT;
    
    -- Clear any existing schedule for this event-venue pair
    DELETE FROM EVENT_ADMIN.EVENT_SCHEDULE
    WHERE EVENT_EVENT_ID = 1 AND VENUE_VENUE_ID = 1;
    COMMIT;
    
    -- Execute the procedure
    request_venue(
        p_event_id => 1,  -- Tech Conference
        p_venue_id => 1,  -- Grand Hall
        p_event_date => SYSTIMESTAMP + INTERVAL '30' DAY,
        p_start_time => SYSTIMESTAMP + INTERVAL '30' DAY + INTERVAL '9' HOUR,
        p_end_time => SYSTIMESTAMP + INTERVAL '30' DAY + INTERVAL '17' HOUR
    );
    
    -- Verify results
    DECLARE
        v_status VARCHAR2(50);
        v_schedule_count NUMBER;
    BEGIN
        SELECT STATUS INTO v_status FROM EVENT_ADMIN.EVENT WHERE EVENT_ID = 1;
        SELECT COUNT(*) INTO v_schedule_count FROM EVENT_ADMIN.EVENT_SCHEDULE 
        WHERE EVENT_EVENT_ID = 1 AND VENUE_VENUE_ID = 1;
        
        DBMS_OUTPUT.PUT_LINE('Event status after request: ' || v_status);
        DBMS_OUTPUT.PUT_LINE('Schedule records created: ' || v_schedule_count);
    END;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
        ROLLBACK;
END;
/

-- TEST CASE 2: Missing parameters
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 2: Missing parameters (NULL venue_id)');
    
    -- Reset event status
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Pending'
    WHERE EVENT_ID = 1;
    COMMIT;
    
    -- Execute with NULL venue_id
    request_venue(
        p_event_id => 1,  -- Tech Conference
        p_venue_id => NULL,  -- NULL venue_id
        p_event_date => SYSTIMESTAMP + INTERVAL '30' DAY,
        p_start_time => SYSTIMESTAMP + INTERVAL '30' DAY + INTERVAL '9' HOUR,
        p_end_time => SYSTIMESTAMP + INTERVAL '30' DAY + INTERVAL '17' HOUR
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST CASE 3: Invalid time logic (end before start)
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 3: Invalid time logic (end before start)');
    
    request_venue(
        p_event_id => 1,  -- Tech Conference
        p_venue_id => 1,  -- Grand Hall
        p_event_date => SYSTIMESTAMP + INTERVAL '30' DAY,
        p_start_time => SYSTIMESTAMP + INTERVAL '30' DAY + INTERVAL '17' HOUR,
        p_end_time => SYSTIMESTAMP + INTERVAL '30' DAY + INTERVAL '9' HOUR  -- End before start
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST CASE 4: Past event date
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 4: Past event date');
    
    request_venue(
        p_event_id => 1,  -- Tech Conference
        p_venue_id => 1,  -- Grand Hall
        p_event_date => SYSTIMESTAMP - INTERVAL '1' DAY,
        p_start_time => SYSTIMESTAMP - INTERVAL '1' DAY,
        p_end_time => SYSTIMESTAMP - INTERVAL '1' DAY + INTERVAL '8' HOUR
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST CASE 5: Non-existent event
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 5: Non-existent event');
    
    request_venue(
        p_event_id => 9999,  -- Non-existent event
        p_venue_id => 1,     -- Grand Hall
        p_event_date => SYSTIMESTAMP + INTERVAL '30' DAY,
        p_start_time => SYSTIMESTAMP + INTERVAL '30' DAY + INTERVAL '9' HOUR,
        p_end_time => SYSTIMESTAMP + INTERVAL '30' DAY + INTERVAL '17' HOUR
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST CASE 6: Non-existent venue
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 6: Non-existent venue');
    
    request_venue(
        p_event_id => 1,     -- Tech Conference
        p_venue_id => 9999,  -- Non-existent venue
        p_event_date => SYSTIMESTAMP + INTERVAL '30' DAY,
        p_start_time => SYSTIMESTAMP + INTERVAL '30' DAY + INTERVAL '9' HOUR,
        p_end_time => SYSTIMESTAMP + INTERVAL '30' DAY + INTERVAL '17' HOUR
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST CASE 7: Event with non-Pending status
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 7: Event with non-Pending status');
    
    -- Change event status to non-Pending
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Completed'
    WHERE EVENT_ID = 1;
    COMMIT;
    
    request_venue(
        p_event_id => 1,  -- Tech Conference (now not Pending)
        p_venue_id => 1,  -- Grand Hall
        p_event_date => SYSTIMESTAMP + INTERVAL '30' DAY,
        p_start_time => SYSTIMESTAMP + INTERVAL '30' DAY + INTERVAL '8' HOUR,
        p_end_time => SYSTIMESTAMP + INTERVAL '30' DAY + INTERVAL '23' HOUR
    );
    
    -- Reset status for other tests
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Pending'
    WHERE EVENT_ID = 1;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
        
        -- Reset status for other tests
        UPDATE EVENT_ADMIN.EVENT
        SET STATUS = 'Pending'
        WHERE EVENT_ID = 1;
        COMMIT;
END;
/

-- TEST CASE 8: Venue already booked on the same date
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 8: Venue already booked on the same date');
    
    -- First create a valid booking
    BEGIN
        -- Clear any existing schedules first
        DELETE FROM EVENT_ADMIN.EVENT_SCHEDULE
        WHERE VENUE_VENUE_ID = 1 AND 
              TRUNC(EVENT_SCHEDULE_DATE) = TRUNC(SYSTIMESTAMP + INTERVAL '60' DAY);
        COMMIT;
        
        -- Reset event status
        UPDATE EVENT_ADMIN.EVENT
        SET STATUS = 'Pending'
        WHERE EVENT_ID = 1;
        COMMIT;
        
        -- Create a valid booking
        request_venue(
            p_event_id => 1,  -- Tech Conference
            p_venue_id => 1,  -- Grand Hall
            p_event_date => SYSTIMESTAMP + INTERVAL '60' DAY,
            p_start_time => SYSTIMESTAMP + INTERVAL '60' DAY + INTERVAL '9' HOUR,
            p_end_time => SYSTIMESTAMP + INTERVAL '60' DAY + INTERVAL '17' HOUR
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error in setup: ' || SQLERRM);
    END;
    
    -- Reset event status for second event
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Pending'
    WHERE EVENT_ID = 2;  -- Art Exhibition
    COMMIT;
    
    -- Now try to book the same venue on the same date
    request_venue(
        p_event_id => 2,  -- Art Exhibition
        p_venue_id => 1,  -- Grand Hall (already booked on this date)
        p_event_date => SYSTIMESTAMP + INTERVAL '60' DAY,
        p_start_time => SYSTIMESTAMP + INTERVAL '60' DAY + INTERVAL '13' HOUR,
        p_end_time => SYSTIMESTAMP + INTERVAL '60' DAY + INTERVAL '20' HOUR
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST CASE 9: Duplicate request for the same event-venue pair
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 9: Duplicate request for the same event-venue pair');
    
    -- Try to request the same venue again for the first event
    -- (Event should now be in 'Requested' status from Test Case 8)
    request_venue(
        p_event_id => 1,  -- Tech Conference
        p_venue_id => 1,  -- Grand Hall
        p_event_date => SYSTIMESTAMP + INTERVAL '90' DAY,  -- Different date
        p_start_time => SYSTIMESTAMP + INTERVAL '90' DAY + INTERVAL '9' HOUR,
        p_end_time => SYSTIMESTAMP + INTERVAL '90' DAY + INTERVAL '17' HOUR
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Clean up after tests
BEGIN
    DBMS_OUTPUT.PUT_LINE('Cleaning up after request_venue tests');
    
    -- Reset event statuses
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Pending'
    WHERE EVENT_ID IN (1, 2);
    
    -- Delete test schedules
    DELETE FROM EVENT_ADMIN.EVENT_SCHEDULE
    WHERE EVENT_EVENT_ID IN (1, 2) AND VENUE_VENUE_ID = 1;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Cleanup complete');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error during cleanup: ' || SQLERRM);
        ROLLBACK;
END;
/