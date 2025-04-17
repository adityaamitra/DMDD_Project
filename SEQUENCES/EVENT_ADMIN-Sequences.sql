SET SERVEROUTPUT ON;
DECLARE
  seq_exists NUMBER;
BEGIN

  -- Query to check and create ATTENDEE_ID_SEQ
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

  -- Query to check and create ORGANIZER_ID_SEQ
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

  -- Query to check and create SPONSOR_ID_SEQ
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

  -- Query to check and create VENUE_ID_SEQ
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

-- Query to check and create EVENT_ID_SEQ sequence with error handling
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


 -- Query to check and create REGISTRATION_SEQ 
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


 -- Query to check and create PAYMENT_ID_SEQ 
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



-- Grant full USAGE of the sequence to a specific user
GRANT SELECT, ALTER ON EVENT_ADMIN.VENUE_ID_SEQ TO VENUE_MANAGER;
GRANT SELECT, ALTER ON EVENT_ID_SEQ TO EVENT_ORGANIZER;
GRANT SELECT, ALTER ON EVENT_SCHEDULE_SEQ TO EVENT_ORGANIZER;
GRANT SELECT, ALTER ON EVENT_SCHEDULE_SEQ TO VENUE_MANAGER;
GRANT SELECT, ALTER ON EVENT_SCHEDULE_SEQ TO EVENT_ATTENDEE;
GRANT SELECT, ALTER ON REGISTRATION_SEQ TO EVENT_ATTENDEE;
GRANT SELECT, ALTER ON PAYMENT_ID_SEQ TO EVENT_ATTENDEE;
GRANT SELECT, ALTER ON EVENT_ID_SEQ TO EVENT_ATTENDEE;