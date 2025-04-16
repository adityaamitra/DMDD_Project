CREATE OR REPLACE PROCEDURE add_sponsorship(
    p_event_id IN NUMBER,
    p_user_id IN NUMBER,
    p_sponsor_name IN VARCHAR2,
    p_amount IN NUMBER
)
AS
    v_event_status VARCHAR2(20);
    v_user_exists NUMBER;
    v_sponsor_id NUMBER;
    v_event_budget NUMBER;
BEGIN
    -- Validate sponsor name
    IF TRIM(p_sponsor_name) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20100, 'Sponsor name cannot be empty.');
    END IF;

    -- Validate amount
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20101, 'Sponsorship amount must be greater than zero.');
    END IF;

    -- Check if event exists, status is Completed, and get budget
    SELECT STATUS, EVENT_BUDGET
    INTO v_event_status, v_event_budget
    FROM EVENT_ADMIN.EVENT
    WHERE EVENT_ID = p_event_id;

    IF UPPER(v_event_status) != 'COMPLETED' THEN
        RAISE_APPLICATION_ERROR(-20102, 'Sponsorship is allowed only for completed events.');
    END IF;

    -- Validate that sponsorship does not exceed budget
    IF p_amount > v_event_budget THEN
        RAISE_APPLICATION_ERROR(-20105, 'Sponsorship amount exceeds event budget of ' || v_event_budget || '.');
    END IF;

    -- Check if sponsor (user) exists
    SELECT COUNT(*) INTO v_user_exists
    FROM EVENT_ADMIN.EVENT_USERS
    WHERE USER_ID = p_user_id;

    IF v_user_exists = 0 THEN
        RAISE_APPLICATION_ERROR(-20103, 'User ID (sponsor) does not exist.');
    END IF;

    -- Generate new SPONSOR_ID
    SELECT NVL(MAX(SPONSOR_ID), 0) + 1 INTO v_sponsor_id FROM EVENT_ADMIN.SPONSOR;

    -- Insert sponsorship record
    INSERT INTO EVENT_ADMIN.SPONSOR (
        SPONSOR_ID,
        SPONSOR_NAME,
        AMOUNT_SPONSORED,
        EVENT_EVENT_ID,
        USER_USER_ID
    ) VALUES (
        v_sponsor_id,
        TRIM(p_sponsor_name),
        p_amount,
        p_event_id,
        p_user_id
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('✅ Sponsorship added successfully. Sponsor ID: ' || v_sponsor_id);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20104, 'Event with ID ' || p_event_id || ' not found.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Unexpected error: ' || SQLERRM);
END add_sponsorship;
/


SET SERVEROUTPUT ON;
-- Test Case 1: Valid sponsorship (should succeed)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 1: Valid Sponsorship');
    add_sponsorship(
        p_event_id =>5,  -- Replace with CONFIRMED event ID
        p_user_id => 5,     -- Replace with existing sponsor user ID
        p_sponsor_name => 'Tech Corp',
        p_amount => 3000
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Failed');
END;
/

-- Test Case 2: Invalid (non-existent) user ID
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 2: Invalid User ID');
    add_sponsorship(
        p_event_id => 5,  -- Must be confirmed
        p_user_id => 9999,  -- Non-existent user
        p_sponsor_name => 'Ghost Sponsor',
        p_amount => 3000
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Passed');
END;
/

-- Test Case 3: Sponsoring an unconfirmed event
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 3: Unconfirmed Event');
    add_sponsorship(
        p_event_id => 1011,  -- Replace with a Pending/Draft event ID
        p_user_id => 5,
        p_sponsor_name => 'Unconfirmed Event Sponsor',
        p_amount => 2000
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Passed');
END;
/

-- Test Case 4: Null sponsor name
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 4: NULL Sponsor Name');
    add_sponsorship(
        p_event_id =>5,
        p_user_id => 5,
        p_sponsor_name => NULL,
        p_amount => 1500
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Passed');
END;
/

-- Test Case 5: Empty sponsor name (spaces only)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 5: Empty Sponsor Name');
    add_sponsorship(
        p_event_id => 5,
        p_user_id => 5,
        p_sponsor_name => '   ',
        p_amount => 1500
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Passed');
END;
/

-- Test Case 6: Negative amount
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 6: Negative Sponsorship Amount');
    add_sponsorship(
        p_event_id => 5,
        p_user_id => 5,
        p_sponsor_name => 'Negative Sponsor',
        p_amount => -500
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Passed');
END;
/

-- Test Case 7: Zero amount
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 7: Zero Sponsorship Amount');
    add_sponsorship(
        p_event_id => 5,
        p_user_id => 5,
        p_sponsor_name => 'Zero Sponsor',
        p_amount => 0
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Passed');
END;
/

-- Test Case 8: Valid second sponsor for same event
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 8: Another Sponsor, Same Event');
    add_sponsorship(
        p_event_id =>5,
        p_user_id => 6,  -- another existing user
        p_sponsor_name => 'Supportive Co.',
        p_amount => 3000
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Failed');
END;
/

-- Test Case 9: Same sponsor for different event
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 9: Same Sponsor, Different Event');
    add_sponsorship(
        p_event_id => 5,  -- another CONFIRMED event
        p_user_id => 5,
        p_sponsor_name => 'Tech Corp',
        p_amount => 3000
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Failed');
END;
/
-- Test Case 10: Valid Sponsorship (amount < budget, event is completed)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 10: Valid Sponsorship (within budget)');
    add_sponsorship(
        p_event_id => 5,  -- COMPLETED event with budget >= 5000
        p_user_id => 5,     -- Valid user
        p_sponsor_name => 'Oracle Corp',
        p_amount => 2000
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Failed');
END;
/

-- Test Case 11: Sponsorship exceeds event budget
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 11: Sponsorship amount exceeds event budget');
    add_sponsorship(
        p_event_id => 5,           -- Event ID with budget 3000
        p_user_id => 5,            -- Existing sponsor user
        p_sponsor_name => 'Over Budget Sponsor',
        p_amount => 5000           -- Exceeds budget
    );
EXCEPTION
    WHEN OTHERS THEN
        IF INSTR(SQLERRM, 'ORA-20105') > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Passed');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Failed');
        END IF;
END;
/




-- Test Case 12: Sponsorship with amount exactly equal to event budget
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 12: Sponsorship equals event budget');
    add_sponsorship(
        p_event_id =>5,  -- Event with budget exactly 3000
        p_user_id => 6,
        p_sponsor_name => 'Exact Budget Sponsor',
        p_amount => 3000
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Failed');
END;
/



