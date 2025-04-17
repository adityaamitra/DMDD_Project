
-- Helper function to get available seats for an event on a specific date
CREATE OR REPLACE FUNCTION get_available_seats(
    p_event_id IN NUMBER,
    p_schedule_date IN DATE
) RETURN NUMBER
AS
    v_venue_capacity NUMBER;
    v_sold_seats NUMBER;
    v_available_seats NUMBER;
BEGIN
    -- Get venue capacity
    BEGIN
        SELECT V.VENUE_CAPACITY INTO v_venue_capacity
        FROM EVENT_ADMIN.VENUE V
        JOIN EVENT_ADMIN.EVENT_SCHEDULE ES ON V.VENUE_ID = ES.VENUE_VENUE_ID
        WHERE ES.EVENT_EVENT_ID = p_event_id
        AND TRUNC(ES.EVENT_SCHEDULE_DATE) = TRUNC(p_schedule_date)
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN -1; -- Indicate error
    END;
    
    -- Get total sold seats for confirmed registrations
    BEGIN
        SELECT NVL(SUM(R.QUANTITY), 0) INTO v_sold_seats
        FROM EVENT_ADMIN.REGISTRATION R
        WHERE R.EVENT_EVENT_ID = p_event_id
        AND R.STATUS = 'Confirmed';
    EXCEPTION
        WHEN OTHERS THEN
            RETURN -1; -- Indicate error
    END;
    
    -- Calculate available seats
    v_available_seats := v_venue_capacity - v_sold_seats;
    
    RETURN GREATEST(v_available_seats, 0);
END get_available_seats;
/

-- Function to check if a registration exists
CREATE OR REPLACE FUNCTION registration_exists(
    p_registration_id IN NUMBER
) RETURN BOOLEAN
AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM EVENT_ADMIN.REGISTRATION
    WHERE REGISTRATION_ID = p_registration_id;
    
    RETURN (v_count > 0);
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END registration_exists;
/

-- Function to get the status of a registration
CREATE OR REPLACE FUNCTION get_registration_status(
    p_registration_id IN NUMBER
) RETURN VARCHAR2
AS
    v_status VARCHAR2(20);
BEGIN
    SELECT STATUS INTO v_status
    FROM EVENT_ADMIN.REGISTRATION
    WHERE REGISTRATION_ID = p_registration_id;
    
    RETURN v_status;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END get_registration_status;
/

-- Function to count payment records for a registration
CREATE OR REPLACE FUNCTION count_payment_records(
    p_registration_id IN NUMBER
) RETURN NUMBER
AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM EVENT_ADMIN.PAYMENT
    WHERE REGISTRATION_REGISTRATION_ID = p_registration_id;
    
    RETURN v_count;
EXCEPTION
    WHEN OTHERS THEN
        RETURN -1;
END count_payment_records;
/

-- Function to get the latest payment ID for a registration
CREATE OR REPLACE FUNCTION get_latest_payment_id(
    p_registration_id IN NUMBER
) RETURN NUMBER
AS
    v_payment_id NUMBER;
BEGIN
    SELECT PAYMENT_ID INTO v_payment_id
    FROM (
        SELECT PAYMENT_ID
        FROM EVENT_ADMIN.PAYMENT
        WHERE REGISTRATION_REGISTRATION_ID = p_registration_id
        ORDER BY PAYMENT_DATE DESC
    )
    WHERE ROWNUM = 1;
    
    RETURN v_payment_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END get_latest_payment_id;
/

-- Function to get payment status
CREATE OR REPLACE FUNCTION get_payment_status(
    p_payment_id IN NUMBER
) RETURN VARCHAR2
AS
    v_status VARCHAR2(50);
BEGIN
    SELECT PAYMENT_STATUS INTO v_status
    FROM EVENT_ADMIN.PAYMENT
    WHERE PAYMENT_ID = p_payment_id;
    
    RETURN v_status;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END get_payment_status;
/


--procedure 

CREATE OR REPLACE PROCEDURE update_registration(
    p_registration_id IN NUMBER,
    p_action IN VARCHAR2,  -- 'UPDATE' or 'CANCEL'
    p_new_quantity IN NUMBER DEFAULT NULL,
    p_refund_method IN VARCHAR2 DEFAULT NULL
)
AS
    v_registration_exists NUMBER;
    v_event_id NUMBER;
    v_attendee_id NUMBER;
    v_current_quantity NUMBER;
    v_event_name VARCHAR2(100);
    v_event_status VARCHAR2(50);
    v_ticket_price NUMBER;
    v_registration_status VARCHAR2(20);
    v_available_seats NUMBER;
    v_payment_id NUMBER;
    v_payment_status VARCHAR2(50);
    v_payment_amount NUMBER;
    v_payment_method VARCHAR2(100);
    v_refund_amount NUMBER := 0;
    v_additional_payment NUMBER := 0;
    v_schedule_date DATE;
    v_event_date TIMESTAMP;
    v_venue_id NUMBER;
    v_venue_capacity NUMBER;
    
    -- Custom exceptions
    registration_not_found EXCEPTION;
    invalid_action EXCEPTION;
    invalid_parameters EXCEPTION;
    registration_already_cancelled EXCEPTION;
    insufficient_seats EXCEPTION;
    invalid_quantity EXCEPTION;
    event_too_close EXCEPTION;
    event_already_occurred EXCEPTION;
    no_payment_found EXCEPTION;
BEGIN
    -- Input validation
    IF p_registration_id IS NULL THEN
        RAISE invalid_parameters;
    END IF;
    
    IF p_action IS NULL OR p_action NOT IN ('UPDATE', 'CANCEL') THEN
        RAISE invalid_action;
    END IF;
    
    IF p_action = 'UPDATE' AND p_new_quantity IS NULL THEN
        RAISE invalid_parameters;
    END IF;
    
    IF p_action = 'UPDATE' AND p_new_quantity <= 0 THEN
        RAISE invalid_quantity;
    END IF;
    
    -- Check if registration exists and get related data
    BEGIN
        SELECT 
            COUNT(*), 
            MAX(R.EVENT_EVENT_ID), 
            MAX(R.ATTENDEE_ATTENDEE_ID),
            MAX(R.QUANTITY),
            MAX(R.STATUS),
            MAX(R.TICKET_PRICE),
            MAX(E.EVENT_NAME),
            MAX(E.STATUS)
        INTO 
            v_registration_exists, 
            v_event_id, 
            v_attendee_id,
            v_current_quantity,
            v_registration_status,
            v_ticket_price,
            v_event_name,
            v_event_status
        FROM 
            EVENT_ADMIN.REGISTRATION R
            JOIN EVENT_ADMIN.EVENT E ON R.EVENT_EVENT_ID = E.EVENT_ID
        WHERE 
            R.REGISTRATION_ID = p_registration_id;
            
        IF v_registration_exists = 0 THEN
            RAISE registration_not_found;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE registration_not_found;
    END;
    
    -- Check if registration is already cancelled - do this early
    IF v_registration_status = 'Cancelled' THEN
        RAISE registration_already_cancelled;
    END IF;
    
    -- Get payment information - use the most recent payment record with Completed status
    BEGIN
        SELECT 
            PAYMENT_ID, 
            PAYMENT_STATUS, 
            AMOUNT, 
            PAYMENT_METHOD
        INTO 
            v_payment_id, 
            v_payment_status, 
            v_payment_amount, 
            v_payment_method
        FROM (
            SELECT 
                PAYMENT_ID, 
                PAYMENT_STATUS, 
                AMOUNT, 
                PAYMENT_METHOD
            FROM 
                EVENT_ADMIN.PAYMENT
            WHERE 
                REGISTRATION_REGISTRATION_ID = p_registration_id
                AND PAYMENT_STATUS = 'Completed'
            ORDER BY 
                PAYMENT_DATE DESC
        ) WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE no_payment_found;
    END;
    
    -- Get event schedule date - be careful with multiple records
    BEGIN
        SELECT 
            TRUNC(ES.EVENT_SCHEDULE_DATE),
            ES.START_TIME
        INTO 
            v_schedule_date,
            v_event_date
        FROM (
            SELECT 
                EVENT_SCHEDULE_DATE,
                START_TIME
            FROM 
                EVENT_ADMIN.EVENT_SCHEDULE
            WHERE 
                EVENT_EVENT_ID = v_event_id
            ORDER BY 
                EVENT_SCHEDULE_DATE ASC
        ) ES
        WHERE ROWNUM = 1;
            
        -- Check if event has already occurred
        IF v_event_date <= SYSTIMESTAMP THEN
            RAISE event_already_occurred;
        END IF;
        
        -- Check if event is too close (within 24 hours)
        IF v_event_date <= SYSTIMESTAMP + INTERVAL '1' DAY THEN
            RAISE event_too_close;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'No schedule found for this event.');
    END;
    
    -- Process UPDATE action
    IF p_action = 'UPDATE' THEN
        -- Check seat availability if increasing quantity
        IF p_new_quantity > v_current_quantity THEN
            -- Get venue capacity safely
            BEGIN
                SELECT V.VENUE_ID, V.VENUE_CAPACITY 
                INTO v_venue_id, v_venue_capacity
                FROM (
                    SELECT 
                        V.VENUE_ID, V.VENUE_CAPACITY
                    FROM 
                        EVENT_ADMIN.VENUE V
                        JOIN EVENT_ADMIN.EVENT_SCHEDULE ES ON V.VENUE_ID = ES.VENUE_VENUE_ID
                    WHERE 
                        ES.EVENT_EVENT_ID = v_event_id
                        AND TRUNC(ES.EVENT_SCHEDULE_DATE) = TRUNC(v_schedule_date)
                    ORDER BY 
                        ES.EVENT_SCHEDULE_DATE ASC
                ) V
                WHERE ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20003, 'No venue found for this event on the specified date.');
                WHEN TOO_MANY_ROWS THEN
                    RAISE_APPLICATION_ERROR(-20004, 'Multiple venues found for this event.');
            END;
            
            v_available_seats := get_available_seats(v_event_id, v_schedule_date);
            
            IF v_available_seats = -1 THEN
                RAISE_APPLICATION_ERROR(-20001, 'Error checking seat availability');
            END IF;
            
            -- Check if enough additional seats are available
            IF (p_new_quantity - v_current_quantity) > v_available_seats THEN
                RAISE insufficient_seats;
            END IF;
            
            -- Calculate additional payment required
            v_additional_payment := (p_new_quantity - v_current_quantity) * v_ticket_price;
        ELSIF p_new_quantity < v_current_quantity THEN
            -- Calculate refund amount for reduced quantity
            v_refund_amount := (v_current_quantity - p_new_quantity) * v_ticket_price;
        END IF;
        
        -- Update the registration record
        UPDATE EVENT_ADMIN.REGISTRATION
        SET QUANTITY = p_new_quantity
        WHERE REGISTRATION_ID = p_registration_id;
        
        -- Process additional payment if needed
        IF v_additional_payment > 0 THEN
            -- In a real system, this would integrate with a payment gateway
            -- For this demo, we'll simulate payment processing
            DECLARE
                v_new_payment_id NUMBER;
            BEGIN
                INSERT INTO EVENT_ADMIN.PAYMENT(
                    PAYMENT_ID,
                    REGISTRATION_REGISTRATION_ID,
                    AMOUNT,
                    PAYMENT_METHOD,
                    PAYMENT_STATUS,
                    PAYMENT_DATE
                ) VALUES (
                    EVENT_ADMIN.PAYMENT_ID_SEQ.NEXTVAL,
                    p_registration_id,
                    v_additional_payment,
                    v_payment_method, -- Use the same payment method as original
                    'Completed',
                    SYSDATE
                ) RETURNING PAYMENT_ID INTO v_new_payment_id;
                
                DBMS_OUTPUT.PUT_LINE('Additional payment processed successfully.');
                DBMS_OUTPUT.PUT_LINE('Payment ID: ' || v_new_payment_id);
                DBMS_OUTPUT.PUT_LINE('Amount: $' || v_additional_payment);
            END;
        -- Process refund if needed
        ELSIF v_refund_amount > 0 THEN
            -- Update the payment record with Refunded status
            DECLARE
                v_refund_method VARCHAR2(100);
            BEGIN
                -- Use provided refund method or original payment method
                v_refund_method := NVL(p_refund_method, v_payment_method);
                
                -- Update the payment record with Refunded status
                UPDATE EVENT_ADMIN.PAYMENT
                SET PAYMENT_STATUS = 'Refunded',
                    PAYMENT_METHOD = v_refund_method,
                    PAYMENT_DATE = SYSDATE
                WHERE PAYMENT_ID = v_payment_id;
                
                DBMS_OUTPUT.PUT_LINE('Refund processed successfully.');
                DBMS_OUTPUT.PUT_LINE('Refund amount: $' || v_refund_amount);
            END;
        END IF;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Registration updated successfully.');
        DBMS_OUTPUT.PUT_LINE('Event: "' || v_event_name || '" (ID: ' || v_event_id || ')');
        DBMS_OUTPUT.PUT_LINE('Registration ID: ' || p_registration_id);
        DBMS_OUTPUT.PUT_LINE('Previous quantity: ' || v_current_quantity);
        DBMS_OUTPUT.PUT_LINE('New quantity: ' || p_new_quantity);
    
    -- Process CANCEL action
    ELSIF p_action = 'CANCEL' THEN
        -- Calculate full refund amount
        v_refund_amount := v_current_quantity * v_ticket_price;
        
        -- Update registration status to Cancelled
        UPDATE EVENT_ADMIN.REGISTRATION
        SET STATUS = 'Cancelled'
        WHERE REGISTRATION_ID = p_registration_id;
        
        -- Update payment status to Refunded
        DECLARE
            v_refund_method VARCHAR2(100);
        BEGIN
            -- Use provided refund method or original payment method
            v_refund_method := NVL(p_refund_method, v_payment_method);
            
            -- Update the payment record with Refunded status instead of inserting a new row
            UPDATE EVENT_ADMIN.PAYMENT
            SET PAYMENT_STATUS = 'Refunded',
                PAYMENT_METHOD = v_refund_method,
                PAYMENT_DATE = SYSDATE
            WHERE PAYMENT_ID = v_payment_id;
            
            DBMS_OUTPUT.PUT_LINE('Refund processed successfully.');
            DBMS_OUTPUT.PUT_LINE('Refund amount: $' || v_refund_amount);
        END;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Registration cancelled successfully.');
        DBMS_OUTPUT.PUT_LINE('Event: "' || v_event_name || '" (ID: ' || v_event_id || ')');
        DBMS_OUTPUT.PUT_LINE('Registration ID: ' || p_registration_id);
        DBMS_OUTPUT.PUT_LINE('Cancelled quantity: ' || v_current_quantity);
    END IF;
    
EXCEPTION
    WHEN invalid_parameters THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid parameters provided.');
        ROLLBACK;
    WHEN invalid_action THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid action. Action must be either "UPDATE" or "CANCEL".');
        ROLLBACK;
    WHEN registration_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: Registration with ID ' || p_registration_id || ' not found.');
        ROLLBACK;
    WHEN invalid_quantity THEN
        DBMS_OUTPUT.PUT_LINE('Error: New quantity must be greater than zero.');
        ROLLBACK;
    WHEN registration_already_cancelled THEN
        DBMS_OUTPUT.PUT_LINE('Error: This registration is already cancelled.');
        ROLLBACK;
    WHEN insufficient_seats THEN
        DBMS_OUTPUT.PUT_LINE('Error: Not enough available seats for the quantity increase. Available: ' || v_available_seats);
        ROLLBACK;
    WHEN event_too_close THEN
        DBMS_OUTPUT.PUT_LINE('Error: Cannot modify registration within 24 hours of the event.');
        ROLLBACK;
    WHEN event_already_occurred THEN
        DBMS_OUTPUT.PUT_LINE('Error: Cannot modify registration for an event that has already occurred.');
        ROLLBACK;
    WHEN no_payment_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: No payment record found for this registration.');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM || ' - Error code: ' || SQLCODE);
        ROLLBACK;
END update_registration;
/



-- Test suite for update_registration procedure
SET SERVEROUTPUT ON SIZE UNLIMITED;

-- Clear any existing test registrations to avoid conflicts
DECLARE
    CURSOR c_test_registrations IS
        SELECT REGISTRATION_ID
        FROM EVENT_ADMIN.REGISTRATION
        WHERE REGISTRATION_ID > 1000; -- Assuming IDs > 1000 are test data
    
    CURSOR c_test_payments IS
        SELECT PAYMENT_ID
        FROM EVENT_ADMIN.PAYMENT
        WHERE PAYMENT_ID > 1000; -- Assuming IDs > 1000 are test data
BEGIN
    FOR rec IN c_test_payments LOOP
        DELETE FROM EVENT_ADMIN.PAYMENT WHERE PAYMENT_ID = rec.PAYMENT_ID;
    END LOOP;
    
    FOR rec IN c_test_registrations LOOP
        DELETE FROM EVENT_ADMIN.REGISTRATION WHERE REGISTRATION_ID = rec.REGISTRATION_ID;
    END LOOP;
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error cleaning up test data: ' || SQLERRM);
        ROLLBACK;
END;
/

-- Main test execution procedure
DECLARE
    -- Test variables
    v_test_counter NUMBER := 0;
    v_passed_counter NUMBER := 0;
    v_failed_counter NUMBER := 0;
    
    -- Test data variables
    v_registration_id NUMBER;
    v_payment_id NUMBER;
    v_event_id NUMBER;
    v_attendee_id NUMBER;
    
    -- Helper procedure to display test result
    PROCEDURE display_test_result(
        p_test_name VARCHAR2, 
        p_status VARCHAR2, 
        p_message VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Test #' || v_test_counter || ': ' || p_test_name || ' - ' || p_status);
        IF p_message IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('   ' || p_message);
        END IF;
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END;
    
    -- Helper procedure to set up a test registration
    PROCEDURE setup_test_registration(
        p_quantity IN NUMBER,
        p_days_ahead IN NUMBER
    ) IS
        v_schedule_date DATE;
        v_venue_id NUMBER;
    BEGIN
        -- Find existing event and attendee
        BEGIN
            SELECT MIN(EVENT_ID), MIN(ATTENDEE_ID) 
            INTO v_event_id, v_attendee_id
            FROM EVENT_ADMIN.EVENT, EVENT_ADMIN.ATTENDEE
            WHERE ROWNUM = 1;
            
            IF v_event_id IS NULL OR v_attendee_id IS NULL THEN
                RAISE_APPLICATION_ERROR(-20100, 'No events or attendees found in the database.');
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20100, 'No events or attendees found in the database.');
        END;
        
        -- Set up schedule date
        v_schedule_date := SYSDATE + p_days_ahead;
        
        -- Ensure the event has a venue and schedule
        BEGIN
            SELECT MIN(VENUE_ID) INTO v_venue_id
            FROM EVENT_ADMIN.VENUE
            WHERE ROWNUM = 1;
            
            -- Create or update the event schedule
            MERGE INTO EVENT_ADMIN.EVENT_SCHEDULE es
            USING (SELECT v_event_id as event_id, v_venue_id as venue_id FROM dual) src
            ON (es.EVENT_EVENT_ID = src.event_id 
                AND es.VENUE_VENUE_ID = src.venue_id 
                AND TRUNC(es.EVENT_SCHEDULE_DATE) = TRUNC(v_schedule_date))
            WHEN MATCHED THEN
                UPDATE SET START_TIME = v_schedule_date + INTERVAL '9' HOUR,
                           END_TIME = v_schedule_date + INTERVAL '17' HOUR
            WHEN NOT MATCHED THEN
                INSERT (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID)
                VALUES (
                    NVL((SELECT MAX(SCHEDULE_ID) FROM EVENT_ADMIN.EVENT_SCHEDULE), 0) + 1,
                    v_schedule_date,
                    v_schedule_date + INTERVAL '9' HOUR,
                    v_schedule_date + INTERVAL '17' HOUR,
                    v_venue_id,
                    v_event_id
                );
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error setting up schedule: ' || SQLERRM);
                RAISE;
        END;
        
        -- Create test registration
        INSERT INTO EVENT_ADMIN.REGISTRATION (
            REGISTRATION_ID,
            EVENT_EVENT_ID,
            ATTENDEE_ATTENDEE_ID,
            REGISTRATION_DATE,
            STATUS,
            TICKET_PRICE,
            QUANTITY
        ) VALUES (
            1001, -- Test ID
            v_event_id,
            v_attendee_id,
            SYSDATE,
            'Confirmed',
            100, -- $100 per ticket
            p_quantity
        ) RETURNING REGISTRATION_ID INTO v_registration_id;
        
        -- Create payment record
        INSERT INTO EVENT_ADMIN.PAYMENT (
            PAYMENT_ID,
            REGISTRATION_REGISTRATION_ID,
            AMOUNT,
            PAYMENT_METHOD,
            PAYMENT_STATUS,
            PAYMENT_DATE
        ) VALUES (
            1001, -- Test ID
            v_registration_id,
            100 * p_quantity, -- $100 * quantity
            'Credit Card',
            'Completed',
            SYSDATE
        ) RETURNING PAYMENT_ID INTO v_payment_id;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Test registration created:');
        DBMS_OUTPUT.PUT_LINE('Registration ID: ' || v_registration_id);
        DBMS_OUTPUT.PUT_LINE('Payment ID: ' || v_payment_id);
        DBMS_OUTPUT.PUT_LINE('Event ID: ' || v_event_id);
        DBMS_OUTPUT.PUT_LINE('Attendee ID: ' || v_attendee_id);
        DBMS_OUTPUT.PUT_LINE('Quantity: ' || p_quantity);
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error setting up test registration: ' || SQLERRM);
            RAISE;
    END;
    
    -- Helper procedure to clean up test data
    PROCEDURE cleanup_test_data IS
    BEGIN
        -- Delete payment records
        DELETE FROM EVENT_ADMIN.PAYMENT 
        WHERE PAYMENT_ID = v_payment_id;
        
        -- Delete registration
        DELETE FROM EVENT_ADMIN.REGISTRATION
        WHERE REGISTRATION_ID = v_registration_id;
        
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error cleaning up test data: ' || SQLERRM);
            ROLLBACK;
    END;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('STARTING TEST SUITE FOR UPDATE_REGISTRATION PROCEDURE');
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    -- TEST CASE 1: Basic Cancellation
    v_test_counter := v_test_counter + 1;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('TEST CASE 1: Basic Cancellation');
        
        -- Setup test data with 3 tickets and 30 days ahead
        setup_test_registration(3, 30);
        
        -- Get payment count before
        DECLARE
            v_payment_count_before NUMBER;
            v_payment_count_after NUMBER;
        BEGIN
            v_payment_count_before := count_payment_records(v_registration_id);
            
            -- Cancel registration
            UPDATE_REGISTRATION(
                p_registration_id => v_registration_id,
                p_action => 'CANCEL'
            );
            
            -- Verify results
            v_payment_count_after := count_payment_records(v_registration_id);
            
            IF v_payment_count_after = v_payment_count_before THEN
                -- Check payment status
                IF get_payment_status(v_payment_id) = 'Refunded' THEN
                    -- Check registration status
                    IF get_registration_status(v_registration_id) = 'Cancelled' THEN
                        v_passed_counter := v_passed_counter + 1;
                        display_test_result('Basic Cancellation', 'PASSED', 
                            'Registration cancelled, payment status updated to Refunded');
                    ELSE
                        v_failed_counter := v_failed_counter + 1;
                        display_test_result('Basic Cancellation', 'FAILED', 
                            'Registration status not changed to Cancelled');
                    END IF;
                ELSE
                    v_failed_counter := v_failed_counter + 1;
                    display_test_result('Basic Cancellation', 'FAILED', 
                        'Payment status not updated to Refunded');
                END IF;
            ELSE
                v_failed_counter := v_failed_counter + 1;
                display_test_result('Basic Cancellation', 'FAILED', 
                    'Payment count changed from ' || v_payment_count_before || 
                    ' to ' || v_payment_count_after);
            END IF;
        END;
        
        -- Clean up
        cleanup_test_data;
    EXCEPTION
        WHEN OTHERS THEN
            v_failed_counter := v_failed_counter + 1;
            display_test_result('Basic Cancellation', 'FAILED', 'Unexpected error: ' || SQLERRM);
            cleanup_test_data;
    END;
    
    -- TEST CASE 2: Decrease Quantity
    v_test_counter := v_test_counter + 1;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('TEST CASE 2: Decrease Quantity');
        
        -- Setup test data with 5 tickets
        setup_test_registration(5, 30);
        
        -- Get payment count before
        DECLARE
            v_payment_count_before NUMBER;
            v_payment_count_after NUMBER;
            v_original_quantity NUMBER := 5;
            v_new_quantity NUMBER := 3;
        BEGIN
            v_payment_count_before := count_payment_records(v_registration_id);
            
            -- Update registration to decrease quantity
            UPDATE_REGISTRATION(
                p_registration_id => v_registration_id,
                p_action => 'UPDATE',
                p_new_quantity => v_new_quantity
            );
            
            -- Verify results
            v_payment_count_after := count_payment_records(v_registration_id);
            
            IF v_payment_count_after = v_payment_count_before THEN
                -- Check payment status
                IF get_payment_status(v_payment_id) = 'Refunded' THEN
                    -- Check registration quantity
                    DECLARE
                        v_current_quantity NUMBER;
                    BEGIN
                        SELECT QUANTITY INTO v_current_quantity
                        FROM EVENT_ADMIN.REGISTRATION
                        WHERE REGISTRATION_ID = v_registration_id;
                        
                        IF v_current_quantity = v_new_quantity THEN
                            v_passed_counter := v_passed_counter + 1;
                            display_test_result('Decrease Quantity', 'PASSED', 
                                'Quantity updated from ' || v_original_quantity || 
                                ' to ' || v_new_quantity);
                        ELSE
                            v_failed_counter := v_failed_counter + 1;
                            display_test_result('Decrease Quantity', 'FAILED', 
                                'Quantity not updated correctly. Expected: ' || 
                                v_new_quantity || ', Actual: ' || v_current_quantity);
                        END IF;
                    EXCEPTION
                        WHEN OTHERS THEN
                            v_failed_counter := v_failed_counter + 1;
                            display_test_result('Decrease Quantity', 'FAILED', 
                                'Error checking registration quantity: ' || SQLERRM);
                    END;
                ELSE
                    v_failed_counter := v_failed_counter + 1;
                    display_test_result('Decrease Quantity', 'FAILED', 
                        'Payment status not updated to Refunded');
                END IF;
            ELSE
                v_failed_counter := v_failed_counter + 1;
                display_test_result('Decrease Quantity', 'FAILED', 
                    'Payment count changed from ' || v_payment_count_before || 
                    ' to ' || v_payment_count_after);
            END IF;
        END;
        
        -- Clean up
        cleanup_test_data;
    EXCEPTION
        WHEN OTHERS THEN
            v_failed_counter := v_failed_counter + 1;
            display_test_result('Decrease Quantity', 'FAILED', 'Unexpected error: ' || SQLERRM);
            cleanup_test_data;
    END;
    
    -- TEST CASE 3: Event too close (within 24 hours)
    v_test_counter := v_test_counter + 1;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('TEST CASE 3: Event too close');
        
        -- Setup test data with event happening in 12 hours
        setup_test_registration(3, 0.5);
        
        -- Try to cancel registration (should fail)
        BEGIN
            UPDATE_REGISTRATION(
                p_registration_id => v_registration_id,
                p_action => 'CANCEL'
            );
            
            v_failed_counter := v_failed_counter + 1;
            display_test_result('Event too close', 'FAILED', 
                'Should not allow cancellation within 24 hours of event');
        EXCEPTION
            WHEN OTHERS THEN
                -- Verify appropriate error message
                IF INSTR(SQLERRM, 'within 24 hours') > 0 THEN
                    v_passed_counter := v_passed_counter + 1;
                    display_test_result('Event too close', 'PASSED', 
                        'Correctly rejected modification within 24 hours of event');
                ELSE
                    v_failed_counter := v_failed_counter + 1;
                    display_test_result('Event too close', 'FAILED', 
                        'Unexpected error: ' || SQLERRM);
                END IF;
        END;
        
        -- Clean up
        cleanup_test_data;
    EXCEPTION
        WHEN OTHERS THEN
            v_failed_counter := v_failed_counter + 1;
            display_test_result('Event too close', 'FAILED', 'Unexpected error: ' || SQLERRM);
            cleanup_test_data;
    END;
    
    -- TEST CASE 4: Invalid registration ID
    v_test_counter := v_test_counter + 1;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('TEST CASE 4: Invalid registration ID');
        
        -- Try to cancel a non-existent registration
        BEGIN
            UPDATE_REGISTRATION(
                p_registration_id => 999999, -- Non-existent ID
                p_action => 'CANCEL'
            );
            
            v_failed_counter := v_failed_counter + 1;
            display_test_result('Invalid registration ID', 'FAILED', 
                'Should not allow cancellation of non-existent registration');
        EXCEPTION
            WHEN OTHERS THEN
                -- Verify appropriate error message
                IF INSTR(SQLERRM, 'not found') > 0 THEN
                    v_passed_counter := v_passed_counter + 1;
                    display_test_result('Invalid registration ID', 'PASSED', 
                        'Correctly rejected non-existent registration');
                ELSE
                    v_failed_counter := v_failed_counter + 1;
                    display_test_result('Invalid registration ID', 'FAILED', 
                        'Unexpected error: ' || SQLERRM);
                END IF;
        END;
    EXCEPTION
        WHEN OTHERS THEN
            v_failed_counter := v_failed_counter + 1;
            display_test_result('Invalid registration ID', 'FAILED', 'Unexpected error: ' || SQLERRM);
    END;
    
    -- TEST CASE 5: Invalid action
    v_test_counter := v_test_counter + 1;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('TEST CASE 5: Invalid action');
        
        -- Setup test data
        setup_test_registration(3, 30);
        
        -- Try to use an invalid action
        BEGIN
            UPDATE_REGISTRATION(
                p_registration_id => v_registration_id,
                p_action => 'MODIFY' -- Invalid action
            );
            
            v_failed_counter := v_failed_counter + 1;
            display_test_result('Invalid action', 'FAILED', 
                'Should not allow invalid action');
        EXCEPTION
            WHEN OTHERS THEN
                -- Verify appropriate error message
                IF INSTR(SQLERRM, 'Invalid action') > 0 THEN
                    v_passed_counter := v_passed_counter + 1;
                    display_test_result('Invalid action', 'PASSED', 
                        'Correctly rejected invalid action');
                ELSE
                    v_failed_counter := v_failed_counter + 1;
                    display_test_result('Invalid action', 'FAILED', 
                        'Unexpected error: ' || SQLERRM);
                END IF;
        END;
        
        -- Clean up
        cleanup_test_data;
    EXCEPTION
        WHEN OTHERS THEN
            v_failed_counter := v_failed_counter + 1;
            display_test_result('Invalid action', 'FAILED', 'Unexpected error: ' || SQLERRM);
            cleanup_test_data;
    END;
    
    -- TEST CASE 6: Already cancelled registration
    v_test_counter := v_test_counter + 1;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('TEST CASE 6: Already cancelled registration');
        
        -- Setup test data
        setup_test_registration(3, 30);
        
        -- First cancel the registration
        UPDATE_REGISTRATION(
            p_registration_id => v_registration_id,
            p_action => 'CANCEL'
        );
        
        -- Now try to cancel it again (should fail)
        BEGIN
            UPDATE_REGISTRATION(
                p_registration_id => v_registration_id,
                p_action => 'CANCEL'
            );
            
            v_failed_counter := v_failed_counter + 1;
            display_test_result('Already cancelled registration', 'FAILED', 
                'Should not allow cancellation of already cancelled registration');
        EXCEPTION
            WHEN OTHERS THEN
                -- Verify appropriate error message
                IF INSTR(SQLERRM, 'already cancelled') > 0 THEN
                    v_passed_counter := v_passed_counter + 1;
                    display_test_result('Already cancelled registration', 'PASSED', 
                        'Correctly rejected cancellation of already cancelled registration');
                ELSE
                    v_failed_counter := v_failed_counter + 1;
                    display_test_result('Already cancelled registration', 'FAILED', 
                        'Unexpected error: ' || SQLERRM);
                END IF;
        END;
        
        -- Clean up
        cleanup_test_data;
    EXCEPTION
        WHEN OTHERS THEN
            v_failed_counter := v_failed_counter + 1;
            display_test_result('Already cancelled registration', 'FAILED', 'Unexpected error: ' || SQLERRM);
            cleanup_test_data;
    END;
    
    -- TEST CASE 7: Null quantity for UPDATE action
    v_test_counter := v_test_counter + 1;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('TEST CASE 7: Null quantity for UPDATE action');
        
        -- Setup test data
        setup_test_registration(3, 30);
        
        -- Try to update with NULL quantity (should fail)
        BEGIN
            UPDATE_REGISTRATION(
                p_registration_id => v_registration_id,
                p_action => 'UPDATE',
                p_new_quantity => NULL
            );
            
            v_failed_counter := v_failed_counter + 1;
            display_test_result('Null quantity for UPDATE action', 'FAILED', 
                'Should not allow NULL quantity for UPDATE action');
        EXCEPTION
            WHEN OTHERS THEN
                -- Verify appropriate error message
                IF INSTR(SQLERRM, 'Invalid parameters') > 0 THEN
                    v_passed_counter := v_passed_counter + 1;
                    display_test_result('Null quantity for UPDATE action', 'PASSED', 
                        'Correctly rejected NULL quantity for UPDATE action');
                ELSE
                    v_failed_counter := v_failed_counter + 1;
                    display_test_result('Null quantity for UPDATE action', 'FAILED', 
                        'Unexpected error: ' || SQLERRM);
                END IF;
        END;
        
        -- Clean up
        cleanup_test_data;
    EXCEPTION
        WHEN OTHERS THEN
            v_failed_counter := v_failed_counter + 1;
            display_test_result('Null quantity for UPDATE action', 'FAILED', 'Unexpected error: ' || SQLERRM);
            cleanup_test_data;
    END;
    
    -- TEST CASE 8: Zero quantity for UPDATE action
    v_test_counter := v_test_counter + 1;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('TEST CASE 8: Zero quantity for UPDATE action');
        
        -- Setup test data
        setup_test_registration(3, 30);
        
        -- Try to update with zero quantity (should fail)
        BEGIN
            UPDATE_REGISTRATION(
                p_registration_id => v_registration_id,
                p_action => 'UPDATE',
                p_new_quantity => 0
            );
            
            v_failed_counter := v_failed_counter + 1;
            display_test_result('Zero quantity for UPDATE action', 'FAILED', 
                'Should not allow zero quantity for UPDATE action');
        EXCEPTION
            WHEN OTHERS THEN
                -- Verify appropriate error message
                IF INSTR(SQLERRM, 'must be greater than zero') > 0 THEN
                    v_passed_counter := v_passed_counter + 1;
                    display_test_result('Zero quantity for UPDATE action', 'PASSED', 
                        'Correctly rejected zero quantity for UPDATE action');
                ELSE
                    v_failed_counter := v_failed_counter + 1;
                    display_test_result('Zero quantity for UPDATE action', 'FAILED', 
                        'Unexpected error: ' || SQLERRM);
                END IF;
        END;
        
        -- Clean up
        cleanup_test_data;
    EXCEPTION
        WHEN OTHERS THEN
            v_failed_counter := v_failed_counter + 1;
            display_test_result('Zero quantity for UPDATE action', 'FAILED', 'Unexpected error: ' || SQLERRM);
            cleanup_test_data;
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error in test suite: ' || SQLERRM);
        ROLLBACK;
END;
/