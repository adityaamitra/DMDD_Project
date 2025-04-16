-- Function: get_available_seats
-- Description: Returns the number of available seats for a given event and schedule date

CREATE OR REPLACE FUNCTION get_available_seats(
    event_id_input NUMBER,
    event_schedule_date_input DATE
)
RETURN NUMBER
IS
    venue_capacity     NUMBER;
    total_quantity     NUMBER := 0;
    available_seats    NUMBER;
BEGIN
    -- Step 1: Fetch venue capacity for the given event and date
    BEGIN
        SELECT v.venue_capacity
        INTO venue_capacity
        FROM EVENT_ADMIN.VENUE v
        JOIN EVENT_ADMIN.EVENT_SCHEDULE es ON v.venue_id = es.venue_venue_id
        WHERE es.event_event_id = event_id_input
          AND TRUNC(es.event_schedule_date) = TRUNC(event_schedule_date_input);

        DBMS_OUTPUT.PUT_LINE('Venue capacity found: ' || venue_capacity);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No venue found for Event ID ' || event_id_input || ' on ' || event_schedule_date_input);
            RETURN -1;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error fetching venue capacity: ' || SQLERRM);
            RETURN -1;
    END;

    -- Step 2: Sum the quantity of tickets registered for the event on the same schedule date
    BEGIN
        SELECT NVL(SUM(r.quantity), 0)
        INTO total_quantity
        FROM EVENT_ADMIN.REGISTRATION r
        JOIN EVENT_ADMIN.EVENT_SCHEDULE es ON r.event_event_id = es.event_event_id
        WHERE es.event_event_id = event_id_input
          AND TRUNC(es.event_schedule_date) = TRUNC(event_schedule_date_input);

        DBMS_OUTPUT.PUT_LINE('Total registered quantity: ' || total_quantity);

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error fetching registration quantity: ' || SQLERRM);
            RETURN -1;
    END;

    -- Step 3: Calculate available seats
    available_seats := venue_capacity - total_quantity;
    IF available_seats < 0 THEN
        available_seats := 0;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Available seats: ' || available_seats);
    RETURN available_seats;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error in function: ' || SQLERRM);
        RETURN -1;
END;
/

-- Test Cases for get_available_seats function
SET SERVEROUTPUT ON;

-- Test Case 1: EVENT_ID = 3 on 2025-04-06 (existing event schedule)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 1 Result: ' || get_available_seats(3, TO_DATE('2025-04-06', 'YYYY-MM-DD')));
END;
/

-- Test Case 2: EVENT_ID = 4 on 2025-04-02 (existing event schedule)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 2 Result: ' || get_available_seats(4, TO_DATE('2025-04-02', 'YYYY-MM-DD')));
END;
/

-- Test Case 3: EVENT_ID = 6 on 2025-04-04 (existing event schedule)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 3 Result: ' || get_available_seats(6, TO_DATE('2025-04-04', 'YYYY-MM-DD')));
END;
/

-- Test Case 4: EVENT_ID = 7 on 2025-04-05 (existing event schedule)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 4 Result: ' || get_available_seats(7, TO_DATE('2025-04-05', 'YYYY-MM-DD')));
END;
/

-- Test Case 5: EVENT_ID = 1 on 2025-05-16 (existing event schedule)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 5 Result: ' || get_available_seats(1, TO_DATE('2025-05-16', 'YYYY-MM-DD')));
END;
/

-- Test Case 6: Invalid event ID (no match)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 6 Result: ' || get_available_seats(999, TO_DATE('2030-01-01', 'YYYY-MM-DD')));
END;
/
