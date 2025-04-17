SET SERVEROUTPUT ON;
DECLARE
  seq_exists NUMBER;
BEGIN

  -- Check and create ATTENDEE_ID_SEQ
  SELECT COUNT(*) INTO seq_exists FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'ATTENDEE_ID_SEQ';
  IF seq_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE ATTENDEE_ID_SEQ
                      START WITH 11
                      INCREMENT BY 1
                      NOCACHE
                      NOCYCLE';
    DBMS_OUTPUT.PUT_LINE('ATTENDEE_ID_SEQ created successfully.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('ATTENDEE_ID_SEQ already exists. Skipping creation.');
  END IF;

  -- Check and create ORGANIZER_ID_SEQ
  SELECT COUNT(*) INTO seq_exists FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'ORGANIZER_ID_SEQ';
  IF seq_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE ORGANIZER_ID_SEQ
                      START WITH 11
                      INCREMENT BY 1
                      NOCACHE
                      NOCYCLE';
    DBMS_OUTPUT.PUT_LINE('ORGANIZER_ID_SEQ created successfully.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('ORGANIZER_ID_SEQ already exists. Skipping creation.');
  END IF;

  -- Check and create SPONSOR_ID_SEQ
  SELECT COUNT(*) INTO seq_exists FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'SPONSOR_ID_SEQ';
  IF seq_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE SPONSOR_ID_SEQ
                      START WITH 11
                      INCREMENT BY 1
                      NOCACHE
                      NOCYCLE';
    DBMS_OUTPUT.PUT_LINE('SPONSOR_ID_SEQ created successfully.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('SPONSOR_ID_SEQ already exists. Skipping creation.');
  END IF;

  -- Check and create VENUE_ID_SEQ
  SELECT COUNT(*) INTO seq_exists FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'VENUE_ID_SEQ';
  IF seq_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE VENUE_ID_SEQ
                      START WITH 11
                      INCREMENT BY 1
                      NOCACHE
                      NOCYCLE';
    DBMS_OUTPUT.PUT_LINE('VENUE_ID_SEQ created successfully.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('VENUE_ID_SEQ already exists. Skipping creation.');
  END IF;

END;
/

-- Create EVENT_ID_SEQ sequence with error handling
DECLARE
  seq_exists NUMBER;
BEGIN
  -- Check if EVENT_ID_SEQ exists
  SELECT COUNT(*) INTO seq_exists
  FROM USER_SEQUENCES
  WHERE SEQUENCE_NAME = 'EVENT_ID_SEQ';
  
  IF seq_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE EVENT_ADMIN.EVENT_ID_SEQ
                      START WITH 1001
                      INCREMENT BY 1
                      NOCACHE
                      NOCYCLE';
    DBMS_OUTPUT.PUT_LINE('EVENT_ID_SEQ created successfully.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('EVENT_ID_SEQ already exists. Skipping creation.');
  END IF;
END;
/


-- First create the REGISTRATION_SEQ if it doesn't exist
DECLARE
  seq_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO seq_exists FROM USER_SEQUENCES 
  WHERE SEQUENCE_NAME = 'REGISTRATION_SEQ';
  IF seq_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE EVENT_ADMIN.REGISTRATION_SEQ 
                      START WITH 1001 
                      INCREMENT BY 1 
                      NOCACHE 
                      NOCYCLE';
    DBMS_OUTPUT.PUT_LINE('REGISTRATION_SEQ created successfully.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('REGISTRATION_SEQ already exists.');
  END IF;
END;
/


-- First create the PAYMENT_ID_SEQ if it doesn't exist
DECLARE
  seq_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO seq_exists FROM USER_SEQUENCES 
  WHERE SEQUENCE_NAME = 'PAYMENT_ID_SEQ';
  IF seq_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE EVENT_ADMIN.PAYMENT_ID_SEQ 
                      START WITH 1001 
                      INCREMENT BY 1 
                      NOCACHE 
                      NOCYCLE';
    DBMS_OUTPUT.PUT_LINE('PAYMENT_ID_SEQ created successfully.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('PAYMENT_ID_SEQ already exists.');
  END IF;
END;
/

-- Query to check and create EVENT_SCHEDULE_SEQ
DECLARE
  seq_exists NUMBER;
BEGIN
  -- Check if EVENT_SCHEDULE_SEQ exists
  SELECT COUNT(*) INTO seq_exists 
  FROM USER_SEQUENCES 
  WHERE SEQUENCE_NAME = 'EVENT_SCHEDULE_SEQ';
  IF seq_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE EVENT_ADMIN.EVENT_SCHEDULE_SEQ 
                      START WITH 1001 
                      INCREMENT BY 1 
                      NOCACHE 
                      NOCYCLE';
    DBMS_OUTPUT.PUT_LINE('EVENT_SCHEDULE_SEQ created successfully.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('EVENT_SCHEDULE_SEQ already exists. Skipping creation.');
  END IF;
END;
/


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


