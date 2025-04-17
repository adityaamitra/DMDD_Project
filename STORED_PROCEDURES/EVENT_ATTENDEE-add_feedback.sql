CREATE OR REPLACE PROCEDURE ADD_FEEDBACK(
    p_registration_id IN NUMBER,
    p_event_id        IN NUMBER,
    p_review          IN VARCHAR2,
    p_rating          IN NUMBER
)
AS
    v_feedback_id         NUMBER;
    v_event_end_time      DATE;
    v_reg_status          VARCHAR2(20);
    v_existing_feedback   NUMBER;
BEGIN
    -- Validate rating
    IF p_rating < 1 OR p_rating > 5 THEN
        RAISE_APPLICATION_ERROR(-20201, 'Rating must be between 1 and 5.');
    END IF;

    -- Check if event has ended (use MAX to avoid ORA-01422)
    SELECT MAX(END_TIME) INTO v_event_end_time
    FROM EVENT_ADMIN.EVENT_SCHEDULE
    WHERE EVENT_EVENT_ID = p_event_id;

    IF v_event_end_time > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20202, 'Feedback allowed only after the event is completed.');
    END IF;

    -- Check registration status (ensure only one row)
    SELECT STATUS INTO v_reg_status
    FROM EVENT_ADMIN.REGISTRATION
    WHERE REGISTRATION_ID = p_registration_id AND EVENT_EVENT_ID = p_event_id
    AND ROWNUM = 1;

    IF UPPER(v_reg_status) != 'CONFIRMED' THEN
        RAISE_APPLICATION_ERROR(-20203, 'User registration must be confirmed.');
    END IF;

    -- Check if feedback already exists
    SELECT COUNT(*) INTO v_existing_feedback
    FROM EVENT_ADMIN.EVENT_REVIEW
    WHERE REGISTRATION_REGISTRATION_ID = p_registration_id AND EVENT_EVENT_ID = p_event_id;

    IF v_existing_feedback > 0 THEN
        RAISE_APPLICATION_ERROR(-20204, 'Feedback already submitted for this event registration.');
    END IF;

    -- Generate feedback ID
    SELECT NVL(MAX(FEEDBACK_ID), 0) + 1 INTO v_feedback_id FROM EVENT_ADMIN.EVENT_REVIEW;

    -- Insert feedback
    INSERT INTO EVENT_ADMIN.EVENT_REVIEW (
        FEEDBACK_ID,
        REGISTRATION_REGISTRATION_ID,
        EVENT_EVENT_ID,
        REVIEW,
        RATING
    ) VALUES (
        v_feedback_id,
        p_registration_id,
        p_event_id,
        TRIM(p_review),
        p_rating
    );

    COMMIT; 

    DBMS_OUTPUT.PUT_LINE('✅ Feedback submitted with ID: ' || v_feedback_id);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20205, 'Invalid registration or event ID.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20999, 'Unexpected error in ADD_FEEDBACK: ' || SQLERRM);
END ADD_FEEDBACK;
/
