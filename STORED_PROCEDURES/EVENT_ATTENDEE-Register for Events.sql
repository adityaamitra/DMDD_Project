-- Procedure to register an attendee for an event with payment processing
CREATE OR REPLACE PROCEDURE register_for_event(
    p_event_id IN NUMBER,
    p_attendee_id IN NUMBER,
    p_quantity IN NUMBER,
    p_schedule_date IN DATE,
    p_payment_method IN VARCHAR2
)
AS
    v_event_exists NUMBER;
    v_event_status VARCHAR2(50);
    v_event_name VARCHAR2(100);
    v_event_budget NUMBER;
    v_venue_id NUMBER;
    v_venue_capacity NUMBER;
    v_attendee_exists NUMBER;
    v_available_seats NUMBER;
    v_registration_id NUMBER;
    v_payment_id NUMBER;
    v_ticket_price NUMBER;
    v_total_amount NUMBER;
    v_registration_date DATE := SYSDATE;
    v_payment_date DATE := SYSDATE;
    v_payment_status VARCHAR2(50);
    
    -- Custom exceptions
    event_not_found EXCEPTION;
    attendee_not_found EXCEPTION;
    invalid_parameters EXCEPTION;
    insufficient_seats EXCEPTION;
    invalid_event_status EXCEPTION;
    registration_already_exists EXCEPTION;
    venue_not_found EXCEPTION;
    division_by_zero EXCEPTION;
BEGIN
    -- Input validation
    IF p_event_id IS NULL OR p_attendee_id IS NULL OR p_quantity IS NULL OR 
       p_schedule_date IS NULL OR p_payment_method IS NULL THEN
        RAISE invalid_parameters;
    END IF;
    
    IF p_quantity <= 0 THEN
        RAISE invalid_parameters;
    END IF;
    
    -- Check if the event exists and has "Completed" status
    SELECT COUNT(*), MAX(STATUS), MAX(EVENT_NAME), MAX(EVENT_BUDGET)
    INTO v_event_exists, v_event_status, v_event_name, v_event_budget
    FROM EVENT_ADMIN.EVENT
    WHERE EVENT_ID = p_event_id;
    
    IF v_event_exists = 0 THEN
        RAISE event_not_found;
    END IF;
    
    -- For this procedure, we only allow registration for events with "Completed" status
    IF v_event_status != 'Completed' THEN
        RAISE invalid_event_status;
    END IF;
    
    -- Get the venue capacity from EVENT_SCHEDULE and VENUE tables
    BEGIN
        SELECT v.VENUE_ID, v.VENUE_CAPACITY 
        INTO v_venue_id, v_venue_capacity
        FROM EVENT_ADMIN.VENUE v
        JOIN EVENT_ADMIN.EVENT_SCHEDULE es ON v.VENUE_ID = es.VENUE_VENUE_ID
        WHERE es.EVENT_EVENT_ID = p_event_id
        AND TRUNC(es.EVENT_SCHEDULE_DATE) = TRUNC(p_schedule_date)
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE venue_not_found;
    END;
    
    -- Calculate ticket price as EVENT_BUDGET / VENUE_CAPACITY
    IF v_venue_capacity = 0 THEN
        RAISE division_by_zero;
    END IF;
    
    v_ticket_price := ROUND(v_event_budget / v_venue_capacity, 2);
    
    -- Check if the attendee exists
    SELECT COUNT(*) INTO v_attendee_exists
    FROM EVENT_ADMIN.ATTENDEE
    WHERE ATTENDEE_ID = p_attendee_id;
    
    IF v_attendee_exists = 0 THEN
        RAISE attendee_not_found;
    END IF;
    
    -- Check if a registration already exists for this attendee and event
    DECLARE
        v_registration_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_registration_exists
        FROM EVENT_ADMIN.REGISTRATION
        WHERE EVENT_EVENT_ID = p_event_id
        AND ATTENDEE_ATTENDEE_ID = p_attendee_id;
        
        IF v_registration_exists > 0 THEN
            RAISE registration_already_exists;
        END IF;
    END;
    
    -- Check seat availability
    v_available_seats := get_available_seats(p_event_id, p_schedule_date);
    
    IF v_available_seats = -1 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error checking seat availability');
    END IF;
    
    IF p_quantity > v_available_seats THEN
        RAISE insufficient_seats;
    END IF;
    
    -- Calculate total amount
    v_total_amount := v_ticket_price * p_quantity;
    
    -- Create registration record with PENDING status
    INSERT INTO EVENT_ADMIN.REGISTRATION(
        REGISTRATION_ID,
        EVENT_EVENT_ID,
        ATTENDEE_ATTENDEE_ID,
        REGISTRATION_DATE,
        STATUS,
        TICKET_PRICE,
        QUANTITY
    ) VALUES (
        EVENT_ADMIN.REGISTRATION_SEQ.NEXTVAL,
        p_event_id,
        p_attendee_id,
        v_registration_date,
        'Pending',  -- Initial status is Pending until payment is confirmed
        v_ticket_price,
        p_quantity
    ) RETURNING REGISTRATION_ID INTO v_registration_id;
    
    -- Process payment
    -- In a real system, this would integrate with a payment gateway
    -- For this demo, we'll simulate payment processing with a random success/failure
    DECLARE
        v_random NUMBER;
    BEGIN
        -- Generate random number between 0 and 1
        SELECT DBMS_RANDOM.VALUE(0, 1) INTO v_random FROM DUAL;
        
        -- 90% success rate for demo purposes
        IF v_random < 0.9 THEN
            v_payment_status := 'Completed';
        ELSE
            v_payment_status := 'Failed';
        END IF;
    END;
    
    -- Record the payment
    INSERT INTO EVENT_ADMIN.PAYMENT(
        PAYMENT_ID,
        REGISTRATION_REGISTRATION_ID,
        AMOUNT,
        PAYMENT_METHOD,
        PAYMENT_STATUS,
        PAYMENT_DATE
    ) VALUES (
        EVENT_ADMIN.PAYMENT_ID_SEQ.NEXTVAL,
        v_registration_id,
        v_total_amount,
        p_payment_method,
        v_payment_status,
        v_payment_date
    ) RETURNING PAYMENT_ID INTO v_payment_id;
    
    -- Update registration status based on payment result
    IF v_payment_status = 'Completed' THEN
        UPDATE EVENT_ADMIN.REGISTRATION
        SET STATUS = 'Confirmed'
        WHERE REGISTRATION_ID = v_registration_id;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Registration successful!');
        DBMS_OUTPUT.PUT_LINE('Event: "' || v_event_name || '" (ID: ' || p_event_id || ')');
        DBMS_OUTPUT.PUT_LINE('Registration ID: ' || v_registration_id);
        DBMS_OUTPUT.PUT_LINE('Payment ID: ' || v_payment_id);
        DBMS_OUTPUT.PUT_LINE('Quantity: ' || p_quantity);
        DBMS_OUTPUT.PUT_LINE('Ticket Price: $' || v_ticket_price || ' per ticket');
        DBMS_OUTPUT.PUT_LINE('Total Amount: $' || v_total_amount);
        DBMS_OUTPUT.PUT_LINE('Payment Status: ' || v_payment_status);
    ELSE
        -- If payment failed, keep registration as pending
        COMMIT;  -- Commit the registration and payment records for tracking purposes
        
        DBMS_OUTPUT.PUT_LINE('Payment failed! Registration is pending.');
        DBMS_OUTPUT.PUT_LINE('Please try payment again or contact support.');
        DBMS_OUTPUT.PUT_LINE('Registration ID: ' || v_registration_id);
        DBMS_OUTPUT.PUT_LINE('Payment ID: ' || v_payment_id);
    END IF;
    
EXCEPTION
    WHEN invalid_parameters THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid parameters. Event ID, attendee ID, quantity, schedule date, and payment method are required. Quantity must be positive.');
        ROLLBACK;
    WHEN event_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: Event with ID ' || p_event_id || ' not found.');
        ROLLBACK;
    WHEN venue_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: No venue schedule found for the event on the specified date.');
        ROLLBACK;
    WHEN division_by_zero THEN
        DBMS_OUTPUT.PUT_LINE('Error: Cannot calculate ticket price - venue capacity is zero.');
        ROLLBACK;
    WHEN attendee_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: Attendee with ID ' || p_attendee_id || ' not found.');
        ROLLBACK;
    WHEN invalid_event_status THEN
        DBMS_OUTPUT.PUT_LINE('Error: Registration is only available for events with "Completed" status. Current status: ' || v_event_status);
        ROLLBACK;
    WHEN registration_already_exists THEN
        DBMS_OUTPUT.PUT_LINE('Error: You are already registered for this event.');
        ROLLBACK;
    WHEN insufficient_seats THEN
        DBMS_OUTPUT.PUT_LINE('Error: Not enough seats available. Requested: ' || p_quantity || ', Available: ' || v_available_seats);
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM || ' - Error code: ' || SQLCODE);
        ROLLBACK;
END register_for_event;
/



-- Test cases for the register_for_event procedure
SET SERVEROUTPUT ON;

-- TEST CASE 1: Valid registration with successful payment
DECLARE
    v_event_id NUMBER := 1;       -- Tech Conference
    v_attendee_id NUMBER := 1;    -- An existing attendee
    v_quantity NUMBER := 2;       -- Requesting 2 seats
    v_schedule_date DATE := SYSDATE + 30;  -- Future date
    v_venue_id NUMBER := 1;       -- Grand Hall
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 1: Valid registration with successful payment');
    
    -- Set up test data
    -- 1. Set event to Completed status
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Completed',
        EVENT_BUDGET = 5000  -- Set a budget for price calculation
    WHERE EVENT_ID = v_event_id;
    
    -- 2. Ensure venue has capacity
    UPDATE EVENT_ADMIN.VENUE
    SET VENUE_CAPACITY = 500  -- Will result in $10 ticket price
    WHERE VENUE_ID = v_venue_id;
    
    -- 3. Create or update event schedule
    MERGE INTO EVENT_ADMIN.EVENT_SCHEDULE es
    USING (SELECT v_event_id AS event_id, v_venue_id AS venue_id FROM dual) src
    ON (es.EVENT_EVENT_ID = src.event_id AND es.VENUE_VENUE_ID = src.venue_id 
        AND TRUNC(es.EVENT_SCHEDULE_DATE) = TRUNC(v_schedule_date))
    WHEN MATCHED THEN
        UPDATE SET START_TIME = v_schedule_date + INTERVAL '9' HOUR,
                   END_TIME = v_schedule_date + INTERVAL '17' HOUR
    WHEN NOT MATCHED THEN
        INSERT (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID)
        VALUES (EVENT_ADMIN.EVENT_SCHEDULE_SEQ.NEXTVAL, v_schedule_date, 
                v_schedule_date + INTERVAL '9' HOUR, v_schedule_date + INTERVAL '17' HOUR, 
                v_venue_id, v_event_id);
    
    -- 4. Delete any existing registrations
    DELETE FROM EVENT_ADMIN.PAYMENT 
    WHERE REGISTRATION_REGISTRATION_ID IN (
        SELECT REGISTRATION_ID FROM EVENT_ADMIN.REGISTRATION 
        WHERE EVENT_EVENT_ID = v_event_id AND ATTENDEE_ATTENDEE_ID = v_attendee_id
    );
    
    DELETE FROM EVENT_ADMIN.REGISTRATION
    WHERE EVENT_EVENT_ID = v_event_id AND ATTENDEE_ATTENDEE_ID = v_attendee_id;
    
    COMMIT;
    
    -- Execute the procedure
    register_for_event(
        p_event_id => v_event_id,
        p_attendee_id => v_attendee_id,
        p_quantity => v_quantity,
        p_schedule_date => v_schedule_date,
        p_payment_method => 'Credit Card'
    );
    
    -- Verify results
    DECLARE
        v_reg_status VARCHAR2(20);
        v_pay_status VARCHAR2(20);
        v_ticket_price NUMBER;
        v_total_amount NUMBER;
    BEGIN
        SELECT R.STATUS, P.PAYMENT_STATUS, R.TICKET_PRICE, P.AMOUNT
        INTO v_reg_status, v_pay_status, v_ticket_price, v_total_amount
        FROM EVENT_ADMIN.REGISTRATION R
        JOIN EVENT_ADMIN.PAYMENT P ON R.REGISTRATION_ID = P.REGISTRATION_REGISTRATION_ID
        WHERE R.EVENT_EVENT_ID = v_event_id
        AND R.ATTENDEE_ATTENDEE_ID = v_attendee_id;
        
        DBMS_OUTPUT.PUT_LINE('Registration status: ' || v_reg_status);
        DBMS_OUTPUT.PUT_LINE('Payment status: ' || v_pay_status);
        DBMS_OUTPUT.PUT_LINE('Ticket price: $' || v_ticket_price);
        DBMS_OUTPUT.PUT_LINE('Total amount: $' || v_total_amount);
        DBMS_OUTPUT.PUT_LINE('Expected ticket price: $' || ROUND(5000/500, 2));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No registration found.');
    END;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in Test Case 1: ' || SQLERRM);
        ROLLBACK;
END;
/

-- TEST CASE 2: Event with minimal budget (very small ticket price)
DECLARE
    v_event_id NUMBER := 2;       -- Art Exhibition
    v_attendee_id NUMBER := 2;    -- An existing attendee
    v_quantity NUMBER := 3;       -- Requesting 3 seats
    v_schedule_date DATE := SYSDATE + 35;  -- Future date
    v_venue_id NUMBER := 2;       -- Art Gallery
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 2: Event with minimal budget');
    
    -- Setup: Set minimal event budget
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Completed',
        EVENT_BUDGET = 10  -- Minimal budget value
    WHERE EVENT_ID = v_event_id;
    
    -- Ensure venue has capacity
    UPDATE EVENT_ADMIN.VENUE
    SET VENUE_CAPACITY = 200
    WHERE VENUE_ID = v_venue_id;
    
    -- Create schedule
    MERGE INTO EVENT_ADMIN.EVENT_SCHEDULE es
    USING (SELECT v_event_id AS event_id, v_venue_id AS venue_id FROM dual) src
    ON (es.EVENT_EVENT_ID = src.event_id AND es.VENUE_VENUE_ID = src.venue_id 
        AND TRUNC(es.EVENT_SCHEDULE_DATE) = TRUNC(v_schedule_date))
    WHEN MATCHED THEN
        UPDATE SET START_TIME = v_schedule_date + INTERVAL '9' HOUR,
                   END_TIME = v_schedule_date + INTERVAL '17' HOUR
    WHEN NOT MATCHED THEN
        INSERT (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID)
        VALUES (EVENT_ADMIN.EVENT_SCHEDULE_SEQ.NEXTVAL, v_schedule_date, 
                v_schedule_date + INTERVAL '9' HOUR, v_schedule_date + INTERVAL '17' HOUR, 
                v_venue_id, v_event_id);
    
    -- Clean existing registrations
    DELETE FROM EVENT_ADMIN.PAYMENT 
    WHERE REGISTRATION_REGISTRATION_ID IN (
        SELECT REGISTRATION_ID FROM EVENT_ADMIN.REGISTRATION 
        WHERE EVENT_EVENT_ID = v_event_id AND ATTENDEE_ATTENDEE_ID = v_attendee_id
    );
    
    DELETE FROM EVENT_ADMIN.REGISTRATION
    WHERE EVENT_EVENT_ID = v_event_id AND ATTENDEE_ATTENDEE_ID = v_attendee_id;
    
    COMMIT;
    
    -- Test the procedure
    register_for_event(
        p_event_id => v_event_id,
        p_attendee_id => v_attendee_id,
        p_quantity => v_quantity,
        p_schedule_date => v_schedule_date,
        p_payment_method => 'Credit Card'
    );
    
    -- Verify results
    DECLARE
        v_ticket_price NUMBER;
    BEGIN
        SELECT R.TICKET_PRICE INTO v_ticket_price
        FROM EVENT_ADMIN.REGISTRATION R
        WHERE R.EVENT_EVENT_ID = v_event_id AND R.ATTENDEE_ATTENDEE_ID = v_attendee_id;
        
        DBMS_OUTPUT.PUT_LINE('Ticket price for minimal budget event: $' || v_ticket_price);
        DBMS_OUTPUT.PUT_LINE('Expected ticket price: $' || ROUND(10/200, 2) || ' (Budget $10 / 200 capacity)');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No registration found.');
    END;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
END;
/

-- TEST CASE 3: Large budget with small venue capacity (high ticket price)
DECLARE
    v_event_id NUMBER := 3;       -- Music Festival
    v_attendee_id NUMBER := 3;    -- An existing attendee
    v_quantity NUMBER := 1;       -- Just one seat
    v_schedule_date DATE := SYSDATE + 40;  -- Future date
    v_venue_id NUMBER := 8;       -- Workshop Center (small capacity)
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 3: Large budget with small venue capacity');
    
    -- Setup: Set large event budget and small venue capacity
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Completed',
        EVENT_BUDGET = 50000  -- Large budget
    WHERE EVENT_ID = v_event_id;
    
    -- Set venue to small capacity
    UPDATE EVENT_ADMIN.VENUE
    SET VENUE_CAPACITY = 100  -- Small capacity
    WHERE VENUE_ID = v_venue_id;
    
    -- Create schedule
    MERGE INTO EVENT_ADMIN.EVENT_SCHEDULE es
    USING (SELECT v_event_id AS event_id, v_venue_id AS venue_id FROM dual) src
    ON (es.EVENT_EVENT_ID = src.event_id AND es.VENUE_VENUE_ID = src.venue_id 
        AND TRUNC(es.EVENT_SCHEDULE_DATE) = TRUNC(v_schedule_date))
    WHEN MATCHED THEN
        UPDATE SET START_TIME = v_schedule_date + INTERVAL '9' HOUR,
                   END_TIME = v_schedule_date + INTERVAL '17' HOUR
    WHEN NOT MATCHED THEN
        INSERT (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID)
        VALUES (EVENT_ADMIN.EVENT_SCHEDULE_SEQ.NEXTVAL, v_schedule_date, 
                v_schedule_date + INTERVAL '9' HOUR, v_schedule_date + INTERVAL '17' HOUR, 
                v_venue_id, v_event_id);
    
    -- Clean existing registrations
    DELETE FROM EVENT_ADMIN.PAYMENT 
    WHERE REGISTRATION_REGISTRATION_ID IN (
        SELECT REGISTRATION_ID FROM EVENT_ADMIN.REGISTRATION 
        WHERE EVENT_EVENT_ID = v_event_id AND ATTENDEE_ATTENDEE_ID = v_attendee_id
    );
    
    DELETE FROM EVENT_ADMIN.REGISTRATION
    WHERE EVENT_EVENT_ID = v_event_id AND ATTENDEE_ATTENDEE_ID = v_attendee_id;
    
    COMMIT;
    
    -- Test the procedure
    register_for_event(
        p_event_id => v_event_id,
        p_attendee_id => v_attendee_id,
        p_quantity => v_quantity,
        p_schedule_date => v_schedule_date,
        p_payment_method => 'Credit Card'
    );
    
    -- Verify results
    DECLARE
        v_ticket_price NUMBER;
    BEGIN
        SELECT R.TICKET_PRICE INTO v_ticket_price
        FROM EVENT_ADMIN.REGISTRATION R
        WHERE R.EVENT_EVENT_ID = v_event_id AND R.ATTENDEE_ATTENDEE_ID = v_attendee_id;
        
        DBMS_OUTPUT.PUT_LINE('Ticket price for high-budget small-venue event: $' || v_ticket_price);
        DBMS_OUTPUT.PUT_LINE('Expected ticket price: $' || ROUND(50000/100, 2) || ' (Budget $50,000 / 100 capacity)');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No registration found.');
    END;
    
    -- Restore original venue capacity
    UPDATE EVENT_ADMIN.VENUE
    SET VENUE_CAPACITY = 100  -- Restore to original
    WHERE VENUE_ID = v_venue_id;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        -- Restore original venue capacity
        UPDATE EVENT_ADMIN.VENUE
        SET VENUE_CAPACITY = 100  -- Restore to original
        WHERE VENUE_ID = v_venue_id;
        ROLLBACK;
END;
/

-- TEST CASE 4: Register for the maximum available seats
DECLARE
    v_event_id NUMBER := 4;       -- Food Fair
    v_attendee_id NUMBER := 4;    -- An existing attendee
    v_venue_id NUMBER := 4;       -- Food Court
    v_venue_capacity NUMBER;
    v_schedule_date DATE := SYSDATE + 45;  -- Future date
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 4: Register for the maximum available seats');
    
    -- Setup: Set event status and get venue capacity
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Completed',
        EVENT_BUDGET = 6000  -- Budget
    WHERE EVENT_ID = v_event_id;
    
    -- Get venue capacity
    SELECT VENUE_CAPACITY INTO v_venue_capacity
    FROM EVENT_ADMIN.VENUE
    WHERE VENUE_ID = v_venue_id;
    
    DBMS_OUTPUT.PUT_LINE('Venue capacity: ' || v_venue_capacity);
    
    -- Create schedule
    MERGE INTO EVENT_ADMIN.EVENT_SCHEDULE es
    USING (SELECT v_event_id AS event_id, v_venue_id AS venue_id FROM dual) src
    ON (es.EVENT_EVENT_ID = src.event_id AND es.VENUE_VENUE_ID = src.venue_id 
        AND TRUNC(es.EVENT_SCHEDULE_DATE) = TRUNC(v_schedule_date))
    WHEN MATCHED THEN
        UPDATE SET START_TIME = v_schedule_date + INTERVAL '9' HOUR,
                   END_TIME = v_schedule_date + INTERVAL '17' HOUR
    WHEN NOT MATCHED THEN
        INSERT (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID)
        VALUES (EVENT_ADMIN.EVENT_SCHEDULE_SEQ.NEXTVAL, v_schedule_date, 
                v_schedule_date + INTERVAL '9' HOUR, v_schedule_date + INTERVAL '17' HOUR, 
                v_venue_id, v_event_id);
    
    -- Clean existing registrations for this event
    DELETE FROM EVENT_ADMIN.PAYMENT 
    WHERE REGISTRATION_REGISTRATION_ID IN (
        SELECT REGISTRATION_ID FROM EVENT_ADMIN.REGISTRATION 
        WHERE EVENT_EVENT_ID = v_event_id
    );
    
    DELETE FROM EVENT_ADMIN.REGISTRATION
    WHERE EVENT_EVENT_ID = v_event_id;
    
    COMMIT;
    
    -- Test the procedure with maximum available seats
    register_for_event(
        p_event_id => v_event_id,
        p_attendee_id => v_attendee_id,
        p_quantity => v_venue_capacity,  -- Maximum capacity
        p_schedule_date => v_schedule_date,
        p_payment_method => 'Bank Transfer'
    );
    
    -- Verify results
    DECLARE
        v_registered_quantity NUMBER;
        v_available_seats NUMBER;
    BEGIN
        SELECT QUANTITY INTO v_registered_quantity
        FROM EVENT_ADMIN.REGISTRATION
        WHERE EVENT_EVENT_ID = v_event_id AND ATTENDEE_ATTENDEE_ID = v_attendee_id;
        
        v_available_seats := get_available_seats(v_event_id, v_schedule_date);
        
        DBMS_OUTPUT.PUT_LINE('Registered quantity: ' || v_registered_quantity);
        DBMS_OUTPUT.PUT_LINE('Remaining seats: ' || v_available_seats);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No registration found.');
    END;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
END;
/

-- TEST CASE 5: Trying to register more seats than available
DECLARE
    v_event_id NUMBER := 5;       -- Sports Day
    v_attendee_id NUMBER := 5;    -- An existing attendee
    v_attendee_id2 NUMBER := 6;   -- Another attendee
    v_venue_id NUMBER := 5;       -- Sports Complex
    v_venue_capacity NUMBER;
    v_schedule_date DATE := SYSDATE + 50;  -- Future date
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 5: Trying to register more seats than available');
    
    -- Setup
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Completed',
        EVENT_BUDGET = 8000  -- Budget
    WHERE EVENT_ID = v_event_id;
    
    -- Get venue capacity
    SELECT VENUE_CAPACITY INTO v_venue_capacity
    FROM EVENT_ADMIN.VENUE
    WHERE VENUE_ID = v_venue_id;
    
    -- Create schedule
    MERGE INTO EVENT_ADMIN.EVENT_SCHEDULE es
    USING (SELECT v_event_id AS event_id, v_venue_id AS venue_id FROM dual) src
    ON (es.EVENT_EVENT_ID = src.event_id AND es.VENUE_VENUE_ID = src.venue_id 
        AND TRUNC(es.EVENT_SCHEDULE_DATE) = TRUNC(v_schedule_date))
    WHEN MATCHED THEN
        UPDATE SET START_TIME = v_schedule_date + INTERVAL '9' HOUR,
                   END_TIME = v_schedule_date + INTERVAL '17' HOUR
    WHEN NOT MATCHED THEN
        INSERT (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID)
        VALUES (EVENT_ADMIN.EVENT_SCHEDULE_SEQ.NEXTVAL, v_schedule_date, 
                v_schedule_date + INTERVAL '9' HOUR, v_schedule_date + INTERVAL '17' HOUR, 
                v_venue_id, v_event_id);
    
    -- Clean existing registrations for this event
    DELETE FROM EVENT_ADMIN.PAYMENT 
    WHERE REGISTRATION_REGISTRATION_ID IN (
        SELECT REGISTRATION_ID FROM EVENT_ADMIN.REGISTRATION 
        WHERE EVENT_EVENT_ID = v_event_id
    );
    
    DELETE FROM EVENT_ADMIN.REGISTRATION
    WHERE EVENT_EVENT_ID = v_event_id;
    
    -- First, register most of the seats with one attendee
    register_for_event(
        p_event_id => v_event_id,
        p_attendee_id => v_attendee_id,
        p_quantity => v_venue_capacity - 5,  -- Leave just 5 seats
        p_schedule_date => v_schedule_date,
        p_payment_method => 'Credit Card'
    );
    
    COMMIT;
    
    -- Check available seats
    DECLARE
        v_available NUMBER;
    BEGIN
        v_available := get_available_seats(v_event_id, v_schedule_date);
        DBMS_OUTPUT.PUT_LINE('Available seats after first registration: ' || v_available);
    END;
    
    -- Now try to register more than available
    DBMS_OUTPUT.PUT_LINE('Attempting to register 10 seats when only 5 are available:');
    register_for_event(
        p_event_id => v_event_id,
        p_attendee_id => v_attendee_id2,
        p_quantity => 10,  -- More than available
        p_schedule_date => v_schedule_date,
        p_payment_method => 'Credit Card'
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST CASE 6: Test with invalid parameters
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 6a: NULL event_id');
    BEGIN
        register_for_event(
            p_event_id => NULL,
            p_attendee_id => 1,
            p_quantity => 2,
            p_schedule_date => SYSDATE + 30,
            p_payment_method => 'Credit Card'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('TEST CASE 6b: NULL attendee_id');
    BEGIN
        register_for_event(
            p_event_id => 1,
            p_attendee_id => NULL,
            p_quantity => 2,
            p_schedule_date => SYSDATE + 30,
            p_payment_method => 'Credit Card'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('TEST CASE 6c: NULL quantity');
    BEGIN
        register_for_event(
            p_event_id => 1,
            p_attendee_id => 1,
            p_quantity => NULL,
            p_schedule_date => SYSDATE + 30,
            p_payment_method => 'Credit Card'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('TEST CASE 6d: Zero quantity');
    BEGIN
        register_for_event(
            p_event_id => 1,
            p_attendee_id => 1,
            p_quantity => 0,
            p_schedule_date => SYSDATE + 30,
            p_payment_method => 'Credit Card'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('TEST CASE 6e: Negative quantity');
    BEGIN
        register_for_event(
            p_event_id => 1,
            p_attendee_id => 1,
            p_quantity => -5,
            p_schedule_date => SYSDATE + 30,
            p_payment_method => 'Credit Card'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('TEST CASE 6f: NULL schedule_date');
    BEGIN
        register_for_event(
            p_event_id => 1,
            p_attendee_id => 1,
            p_quantity => 2,
            p_schedule_date => NULL,
            p_payment_method => 'Credit Card'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('TEST CASE 6g: NULL payment_method');
    BEGIN
        register_for_event(
            p_event_id => 1,
            p_attendee_id => 1,
            p_quantity => 2,
            p_schedule_date => SYSDATE + 30,
            p_payment_method => NULL
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
END;
/

-- TEST CASE 7: Non-existent event and attendee
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 7a: Non-existent event');
    BEGIN
        register_for_event(
            p_event_id => 9999,  -- Non-existent event
            p_attendee_id => 1,
            p_quantity => 2,
            p_schedule_date => SYSDATE + 30,
            p_payment_method => 'Credit Card'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
    
    DBMS_OUTPUT.PUT_LINE('TEST CASE 7b: Non-existent attendee');
    BEGIN
        register_for_event(
            p_event_id => 1,
            p_attendee_id => 9999,  -- Non-existent attendee
            p_quantity => 2,
            p_schedule_date => SYSDATE + 30,
            p_payment_method => 'Credit Card'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
END;
/

-- TEST CASE 8: Event with wrong status
DECLARE
    v_event_id NUMBER := 6;      -- Business Summit
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 8: Event with wrong status');
    
    -- Set event to a status other than 'Completed'
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Pending'
    WHERE EVENT_ID = v_event_id;
    COMMIT;
    
    -- Try to register
    register_for_event(
        p_event_id => v_event_id,
        p_attendee_id => 1,
        p_quantity => 2,
        p_schedule_date => SYSDATE + 30,
        p_payment_method => 'Credit Card'
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST CASE 9: Date with no scheduled event
DECLARE
    v_event_id NUMBER := 7;       -- Charity Run
    v_attendee_id NUMBER := 7;    -- An existing attendee
    v_schedule_date DATE := SYSDATE + 70;  -- Date with no schedule
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 9: Date with no scheduled event');
    
    -- Set event to Completed status
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Completed'
    WHERE EVENT_ID = v_event_id;
    
    -- Make sure there's no schedule for this date
    DELETE FROM EVENT_ADMIN.EVENT_SCHEDULE
    WHERE EVENT_EVENT_ID = v_event_id 
    AND TRUNC(EVENT_SCHEDULE_DATE) = TRUNC(v_schedule_date);
    COMMIT;
    
    -- Try to register
    register_for_event(
        p_event_id => v_event_id,
        p_attendee_id => v_attendee_id,
        p_quantity => 2,
        p_schedule_date => v_schedule_date,
        p_payment_method => 'Credit Card'
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST CASE 10: Attempt to register twice for the same event
DECLARE
    v_event_id NUMBER := 8;       -- Workshop Series
    v_attendee_id NUMBER := 8;    -- An existing attendee
    v_venue_id NUMBER := 8;       -- Workshop Center
    v_schedule_date DATE := SYSDATE + 80;  -- Future date
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 10: Attempt to register twice for the same event');
    
    -- Setup
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Completed',
        EVENT_BUDGET = 2000
    WHERE EVENT_ID = v_event_id;
    
    -- Create schedule
    MERGE INTO EVENT_ADMIN.EVENT_SCHEDULE es
    USING (SELECT v_event_id AS event_id, v_venue_id AS venue_id FROM dual) src
    ON (es.EVENT_EVENT_ID = src.event_id AND es.VENUE_VENUE_ID = src.venue_id 
        AND TRUNC(es.EVENT_SCHEDULE_DATE) = TRUNC(v_schedule_date))
    WHEN MATCHED THEN
        UPDATE SET START_TIME = v_schedule_date + INTERVAL '9' HOUR,
                   END_TIME = v_schedule_date + INTERVAL '17' HOUR
    WHEN NOT MATCHED THEN
        INSERT (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID)
        VALUES (EVENT_ADMIN.EVENT_SCHEDULE_SEQ.NEXTVAL, v_schedule_date, 
                v_schedule_date + INTERVAL '9' HOUR, v_schedule_date + INTERVAL '17' HOUR, 
                v_venue_id, v_event_id);
    
    -- Clear previous registrations
    DELETE FROM EVENT_ADMIN.PAYMENT 
    WHERE REGISTRATION_REGISTRATION_ID IN (
        SELECT REGISTRATION_ID FROM EVENT_ADMIN.REGISTRATION 
        WHERE EVENT_EVENT_ID = v_event_id AND ATTENDEE_ATTENDEE_ID = v_attendee_id
    );
    
    DELETE FROM EVENT_ADMIN.REGISTRATION
    WHERE EVENT_EVENT_ID = v_event_id AND ATTENDEE_ATTENDEE_ID = v_attendee_id;
    
    COMMIT;
    
    -- First registration (should succeed)
    BEGIN
        register_for_event(
            p_event_id => v_event_id,
            p_attendee_id => v_attendee_id,
            p_quantity => 2,
            p_schedule_date => v_schedule_date,
            p_payment_method => 'Credit Card'
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Unexpected error in first registration: ' || SQLERRM);
    END;
    
    -- Second registration (should fail)
    DBMS_OUTPUT.PUT_LINE('Attempting second registration for the same event:');
    register_for_event(
        p_event_id => v_event_id,
        p_attendee_id => v_attendee_id,
        p_quantity => 1,
        p_schedule_date => v_schedule_date,
        p_payment_method => 'Credit Card'
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- TEST CASE 11: Different payment methods
DECLARE
    v_event_id NUMBER := 9;       -- Networking Event
    v_attendee_id NUMBER := 9;    -- An existing attendee
    v_venue_id NUMBER := 9;       -- Networking Lounge
    v_schedule_date DATE := SYSDATE + 90;  -- Future date
    TYPE payment_methods_array IS TABLE OF VARCHAR2(100);
    v_methods payment_methods_array := payment_methods_array('Credit Card', 'Debit Card', 'PayPal', 'Bank Transfer', 'Cash');
BEGIN
    DBMS_OUTPUT.PUT_LINE('TEST CASE 11: Different payment methods');
    
    -- Setup
    UPDATE EVENT_ADMIN.EVENT
    SET STATUS = 'Completed',
        EVENT_BUDGET = 1000
    WHERE EVENT_ID = v_event_id;
    
    -- Create schedule
    MERGE INTO EVENT_ADMIN.EVENT_SCHEDULE es
    USING (SELECT v_event_id AS event_id, v_venue_id AS venue_id FROM dual) src
    ON (es.EVENT_EVENT_ID = src.event_id AND es.VENUE_VENUE_ID = src.venue_id 
        AND TRUNC(es.EVENT_SCHEDULE_DATE) = TRUNC(v_schedule_date))
    WHEN MATCHED THEN
        UPDATE SET START_TIME = v_schedule_date + INTERVAL '9' HOUR,
                   END_TIME = v_schedule_date + INTERVAL '17' HOUR
    WHEN NOT MATCHED THEN
        INSERT (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID)
        VALUES (EVENT_ADMIN.EVENT_SCHEDULE_SEQ.NEXTVAL, v_schedule_date, 
                v_schedule_date + INTERVAL '9' HOUR, v_schedule_date + INTERVAL '17' HOUR, 
                v_venue_id, v_event_id);
    
    -- Clear previous registrations
    DELETE FROM EVENT_ADMIN.PAYMENT 
    WHERE REGISTRATION_REGISTRATION_ID IN (
        SELECT REGISTRATION_ID FROM EVENT_ADMIN.REGISTRATION 
        WHERE EVENT_EVENT_ID = v_event_id
    );
    
    DELETE FROM EVENT_ADMIN.REGISTRATION
    WHERE EVENT_EVENT_ID = v_event_id;
    
    COMMIT;
    
    -- Try each payment method with a different attendee
    FOR i IN 1..v_methods.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Testing with payment method: ' || v_methods(i));
        BEGIN
            register_for_event(
                p_event_id => v_event_id,
                p_attendee_id => v_attendee_id + i - 1,  -- Different attendees
                p_quantity => 1,
                p_schedule_date => v_schedule_date,
                p_payment_method => v_methods(i)
            );
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error with ' || v_methods(i) || ': ' || SQLERRM);
        END;
    END LOOP;
    
    -- Verify results
    DECLARE
        v_method VARCHAR2(100);
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM EVENT_ADMIN.PAYMENT P
        JOIN EVENT_ADMIN.REGISTRATION R ON P.REGISTRATION_REGISTRATION_ID = R.REGISTRATION_ID
        WHERE R.EVENT_EVENT_ID = v_event_id;
        
        DBMS_OUTPUT.PUT_LINE('Total successful registrations: ' || v_count);
        
        -- Show each payment method used
        FOR payment_rec IN (
            SELECT P.PAYMENT_METHOD
            FROM EVENT_ADMIN.PAYMENT P
            JOIN EVENT_ADMIN.REGISTRATION R ON P.REGISTRATION_REGISTRATION_ID = R.REGISTRATION_ID
            WHERE R.EVENT_EVENT_ID = v_event_id
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('Used payment method: ' || payment_rec.PAYMENT_METHOD);
        END LOOP;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No registrations found.');
    END;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
END;
/
