SET SERVEROUTPUT ON;

CREATE OR REPLACE TRIGGER after_insert_event_users
AFTER INSERT ON EVENT_USERS
FOR EACH ROW
BEGIN
    -- Insert into appropriate table based on USER_TYPE
    CASE :NEW.USER_TYPE
        WHEN 'Attendee' THEN
            INSERT INTO ATTENDEE (
                ATTENDEE_ID,
                FIRST_NAME,
                LAST_NAME,
                USER_USER_ID
            ) VALUES (
                ATTENDEE_ID_SEQ.NEXTVAL,
                :NEW.FIRST_NAME,
                :NEW.LAST_NAME,
                :NEW.USER_ID
            );
            
        WHEN 'Organizer' THEN
            INSERT INTO ORGANIZER (
                ORGANIZER_ID,
                USER_USER_ID,
                COMPANY_NAME
            ) VALUES (
                ORGANIZER_ID_SEQ.NEXTVAL,
                :NEW.USER_ID,
                NULL  -- Default null for COMPANY_NAME, to be updated later
            );
            
        WHEN 'Sponsor' THEN
            INSERT INTO SPONSOR (
                SPONSOR_ID,
                SPONSOR_NAME,
                AMOUNT_SPONSORED,
                EVENT_EVENT_ID,
                USER_USER_ID
            ) VALUES (
                SPONSOR_ID_SEQ.NEXTVAL,
                NULL,  -- Default null for SPONSOR_NAME, to be updated later
                NULL,  -- Default null for AMOUNT_SPONSORED, to be updated later
                NULL,  -- Default null for EVENT_EVENT_ID, to be updated later
                :NEW.USER_ID
            );
            
        WHEN 'Venue_Manager' THEN
            INSERT INTO VENUE (
                VENUE_ID,
                VENUE_NAME,
                VENUE_CAPACITY,
                USER_USER_ID
            ) VALUES (
                VENUE_ID_SEQ.NEXTVAL,
                NULL,  -- Default null for VENUE_NAME, to be updated later
                NULL,  -- Default null for VENUE_CAPACITY, to be updated later
                :NEW.USER_ID
            );
            
        ELSE
            -- Invalid user type - raise an error
            RAISE_APPLICATION_ERROR(-20001, 'Invalid USER_TYPE: ' || :NEW.USER_TYPE);
    END CASE;
    
    -- Log the action
    DBMS_OUTPUT.PUT_LINE('User ' || :NEW.USER_ID || ' of type ' || :NEW.USER_TYPE || ' added to respective table.');
END;
/



-- To check if trigger works 

SELECT USER_ID FROM EVENT_USERS ORDER BY USER_ID DESC;
SET SERVEROUTPUT ON;
INSERT INTO EVENT_USERS (USER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, USER_PASSWORD, USER_TYPE)
VALUES (1017, 'Michael', 'Scott', 'michael.scott@example.com', 5556667777, 'attendeePass123', 'Attendee');
COMMIT;

SELECT ATTENDEE_ID, FIRST_NAME, LAST_NAME, USER_USER_ID
FROM ATTENDEE
WHERE FIRST_NAME = 'Michael' 
  AND LAST_NAME  = 'Scott';


