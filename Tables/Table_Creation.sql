BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE ATTENDEE CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE EVENT CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE EVENT_REVIEW CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE EVENT_SCHEDULE CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE ORGANIZER CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE PAYMENT CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE REGISTRATION CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE SPONSOR CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE EVENT_USERS CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE USER_ADDRESS CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE VENUE CASCADE CONSTRAINTS';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/


CREATE   TABLE ATTENDEE 
    ( 
     ATTENDEE_ID  NUMBER  NOT NULL , 
     FIRST_NAME   VARCHAR2 (20)  NOT NULL , 
     LAST_NAME    VARCHAR2 (20)  NOT NULL , 
     USER_USER_ID NUMBER  NOT NULL 
    ) 
;

ALTER TABLE ATTENDEE 
    ADD CONSTRAINT ATTENDEE_PK PRIMARY KEY ( ATTENDEE_ID ) ;

CREATE   TABLE EVENT 
    ( 
     EVENT_ID               NUMBER  NOT NULL , 
     ORGANIZER_ORGANIZER_ID NUMBER  NOT NULL , 
     EVENT_NAME             VARCHAR2 (100 CHAR)  NOT NULL , 
     EVENT_DESCRIPTION      VARCHAR2 (100 CHAR) , 
     EVENT_TYPE             VARCHAR2 (50 CHAR)  NOT NULL , 
     STATUS                 VARCHAR2 (50)  NOT NULL , 
     EVENT_BUDGET           NUMBER (10,2) 
    ) 
;

ALTER TABLE EVENT 
    ADD CONSTRAINT EVENT_PK PRIMARY KEY ( EVENT_ID ) ;

CREATE   TABLE EVENT_REVIEW 
    ( 
     FEEDBACK_ID                  NUMBER  NOT NULL , 
     REGISTRATION_REGISTRATION_ID NUMBER  NOT NULL , 
     EVENT_EVENT_ID               NUMBER  NOT NULL , 
     REVIEW                       VARCHAR2 (250 CHAR)  NOT NULL , 
     RATING                       NUMBER  NOT NULL 
    ) 
;

ALTER TABLE EVENT_REVIEW 
    ADD CONSTRAINT EVENT_REVIEW_PK PRIMARY KEY ( FEEDBACK_ID, REGISTRATION_REGISTRATION_ID ) ;

CREATE   TABLE EVENT_SCHEDULE 
    ( 
     SCHEDULE_ID         NUMBER  NOT NULL , 
     EVENT_SCHEDULE_DATE TIMESTAMP  NOT NULL , 
     START_TIME          TIMESTAMP  NOT NULL , 
     END_TIME            TIMESTAMP  NOT NULL , 
     VENUE_VENUE_ID      NUMBER  NOT NULL , 
     EVENT_EVENT_ID      NUMBER  NOT NULL 
    ) 
;

ALTER TABLE EVENT_SCHEDULE 
    ADD CONSTRAINT EVENT_SCHEDULE_PK PRIMARY KEY ( SCHEDULE_ID ) ;

CREATE   TABLE ORGANIZER 
    ( 
     ORGANIZER_ID NUMBER  NOT NULL , 
     USER_USER_ID NUMBER  NOT NULL , 
     COMPANY_NAME VARCHAR2 (100 CHAR)  NOT NULL 
    ) 
;

ALTER TABLE ORGANIZER 
    ADD CONSTRAINT ORGANIZER_PK PRIMARY KEY ( ORGANIZER_ID ) ;

CREATE   TABLE PAYMENT 
    ( 
     PAYMENT_ID                   NUMBER  NOT NULL , 
     REGISTRATION_REGISTRATION_ID NUMBER  NOT NULL , 
     AMOUNT                       NUMBER (10,2)  NOT NULL , 
     PAYMENT_METHOD               VARCHAR2 (100)  NOT NULL , 
     PAYMENT_STATUS               VARCHAR2 (50)  NOT NULL , 
     PAYMENT_DATE                 DATE  NOT NULL 
    ) 
;


ALTER TABLE PAYMENT 
    ADD CONSTRAINT PAYMENT_PK PRIMARY KEY ( PAYMENT_ID ) ;

CREATE   TABLE REGISTRATION 
    ( 
     REGISTRATION_ID      NUMBER  NOT NULL , 
     EVENT_EVENT_ID       NUMBER  NOT NULL , 
     ATTENDEE_ATTENDEE_ID NUMBER  NOT NULL , 
     REGISTRATION_DATE    DATE  NOT NULL , 
     STATUS               VARCHAR2 (20 CHAR)  NOT NULL , 
     TICKET_PRICE         NUMBER (10,2)  NOT NULL , 
     QUANTITY             NUMBER  NOT NULL 
    ) 
;

COMMENT ON COLUMN REGISTRATION.STATUS IS 'STATUS OF REGISTRATION EX: CONFIRMED, PENDING, CANCELLED' 
;

ALTER TABLE REGISTRATION 
    ADD CONSTRAINT REGISTRATION_PK PRIMARY KEY ( REGISTRATION_ID ) ;

CREATE   TABLE SPONSOR 
    ( 
     SPONSOR_ID       NUMBER  NOT NULL , 
     SPONSOR_NAME     VARCHAR2 (100 CHAR)  NOT NULL , 
     AMOUNT_SPONSORED NUMBER  NOT NULL , 
     EVENT_EVENT_ID   NUMBER  NOT NULL , 
     USER_USER_ID     NUMBER  NOT NULL 
    ) 
;

ALTER TABLE SPONSOR 
    ADD CONSTRAINT SPONSOR_PK PRIMARY KEY ( SPONSOR_ID, EVENT_EVENT_ID ) ;

CREATE   TABLE EVENT_USERS
    ( 
     USER_ID       NUMBER  NOT NULL , 
     FIRST_NAME    VARCHAR2 (50)  NOT NULL , 
     LAST_NAME     VARCHAR2 (50)  NOT NULL , 
     EMAIL         VARCHAR2 (250)  NOT NULL , 
     PHONE_NUMBER  NUMBER  NOT NULL , 
     USER_PASSWORD VARCHAR2 (250)  NOT NULL , 
     USER_TYPE     VARCHAR2 (15)  NOT NULL 
    ) 
;

ALTER TABLE EVENT_USERS 
    ADD CONSTRAINT USER_PK PRIMARY KEY ( USER_ID ) ;

CREATE   TABLE USER_ADDRESS 
    ( 
     ADDRESS_ID     NUMBER  NOT NULL , 
     USER_USER_ID   NUMBER  NOT NULL , 
     STREET_ADDRESS VARCHAR2 (250)  NOT NULL , 
     CITY           VARCHAR2 (100)  NOT NULL , 
     STATE          VARCHAR2 (100)  NOT NULL , 
     COUNTRY        VARCHAR2 (100)  NOT NULL , 
     ZIP_CODE       NUMBER  NOT NULL 
    
) 
;



ALTER TABLE USER_ADDRESS 
    ADD CONSTRAINT USER_ADDRESS_PK PRIMARY KEY ( ADDRESS_ID ) ;

CREATE   TABLE VENUE 
    ( 
     VENUE_ID       NUMBER  NOT NULL , 
     VENUE_NAME     VARCHAR2 (100 CHAR)  NOT NULL , 
     VENUE_CAPACITY NUMBER  NOT NULL , 
     USER_USER_ID   NUMBER  NOT NULL 
    ) 
;


ALTER TABLE VENUE 
    ADD CONSTRAINT VENUE_PK PRIMARY KEY ( VENUE_ID ) ;

ALTER TABLE ATTENDEE 
    ADD CONSTRAINT ATTENDEE_USER_FK FOREIGN KEY 
    ( 
     USER_USER_ID
    ) 
    REFERENCES EVENT_USERS 
    ( 
     USER_ID
    ) 
;

ALTER TABLE EVENT 
    ADD CONSTRAINT EVENT_ORGANIZER_FK FOREIGN KEY 
    ( 
     ORGANIZER_ORGANIZER_ID
    ) 
    REFERENCES ORGANIZER 
    ( 
     ORGANIZER_ID
    ) 
;

ALTER TABLE EVENT_REVIEW 
    ADD CONSTRAINT EVENT_REVIEW_EVENT_FK FOREIGN KEY 
    ( 
     EVENT_EVENT_ID
    ) 
    REFERENCES EVENT 
    ( 
     EVENT_ID
    ) 
;

ALTER TABLE EVENT_REVIEW 
    ADD CONSTRAINT EVENT_REVIEW_REGISTRATION_FK FOREIGN KEY 
    ( 
     REGISTRATION_REGISTRATION_ID
    ) 
    REFERENCES REGISTRATION 
    ( 
     REGISTRATION_ID
    ) 
;

ALTER TABLE EVENT_SCHEDULE 
    ADD CONSTRAINT EVENT_SCHEDULE_EVENT_FK FOREIGN KEY 
    ( 
     EVENT_EVENT_ID
    ) 
    REFERENCES EVENT 
    ( 
     EVENT_ID
    ) 
;

ALTER TABLE EVENT_SCHEDULE 
    ADD CONSTRAINT EVENT_SCHEDULE_VENUE_FK FOREIGN KEY 
    ( 
     VENUE_VENUE_ID
    ) 
    REFERENCES VENUE 
    ( 
     VENUE_ID
    ) 
;

ALTER TABLE ORGANIZER 
    ADD CONSTRAINT ORGANIZER_USER_FK FOREIGN KEY 
    ( 
     USER_USER_ID
    ) 
    REFERENCES EVENT_USERS 
    ( 
     USER_ID
    ) 
    ON DELETE CASCADE 
;

ALTER TABLE PAYMENT 
    ADD CONSTRAINT PAYMENT_REGISTRATION_FK FOREIGN KEY 
    ( 
     REGISTRATION_REGISTRATION_ID
    ) 
    REFERENCES REGISTRATION 
    ( 
     REGISTRATION_ID
    ) 
;

ALTER TABLE REGISTRATION 
    ADD CONSTRAINT REGISTRATION_ATTENDEE_FK FOREIGN KEY 
    ( 
     ATTENDEE_ATTENDEE_ID
    ) 
    REFERENCES ATTENDEE 
    ( 
     ATTENDEE_ID
    ) 
;

ALTER TABLE REGISTRATION 
    ADD CONSTRAINT REGISTRATION_EVENT_FK FOREIGN KEY 
    ( 
     EVENT_EVENT_ID
    ) 
    REFERENCES EVENT 
    ( 
     EVENT_ID
    ) 
;

ALTER TABLE SPONSOR 
    ADD CONSTRAINT SPONSOR_EVENT_FK FOREIGN KEY 
    ( 
     EVENT_EVENT_ID
    ) 
    REFERENCES EVENT 
    ( 
     EVENT_ID
    ) 
;

ALTER TABLE SPONSOR 
    ADD CONSTRAINT SPONSOR_USER_FK FOREIGN KEY 
    ( 
     USER_USER_ID
    ) 
    REFERENCES EVENT_USERS 
    ( 
     USER_ID
    ) 
;

ALTER TABLE USER_ADDRESS 
    ADD CONSTRAINT USER_ADDRESS_USER_FK FOREIGN KEY 
    ( 
     USER_USER_ID
    ) 
    REFERENCES EVENT_USERS 
    ( 
     USER_ID
    ) 
    ON DELETE CASCADE 
;

ALTER TABLE VENUE 
    ADD CONSTRAINT VENUE_USER_FK FOREIGN KEY 
    ( 
     USER_USER_ID
    ) 
    REFERENCES EVENT_USERS 
    ( 
     USER_ID
    ) 
;

PURGE RECYCLEBIN;
--Following Queries are to Add constraints
ALTER TABLE EVENT_USERS
ADD CONSTRAINT chk_user_email_not_blank CHECK (TRIM(EMAIL) IS NOT NULL AND EMAIL <> '');

ALTER TABLE EVENT_USERS
ADD CONSTRAINT chk_user_first_name_not_blank CHECK (TRIM(FIRST_NAME) IS NOT NULL AND FIRST_NAME <> '');

ALTER TABLE EVENT_USERS
ADD CONSTRAINT chk_user_last_name_not_blank CHECK (TRIM(LAST_NAME) IS NOT NULL AND LAST_NAME <> '');

ALTER TABLE EVENT_USERS
ADD CONSTRAINT chk_user_phone_number_not_null CHECK (PHONE_NUMBER IS NOT NULL);

ALTER TABLE EVENT_USERS
ADD CONSTRAINT chk_user_phone_number_numeric CHECK (REGEXP_LIKE(PHONE_NUMBER, '^[0-9]+$'));

ALTER TABLE EVENT_USERS
ADD CONSTRAINT chk_user_type CHECK (USER_TYPE IN ('Attendee', 'Organizer', 'Venue_Manager', 'Sponsor'));

ALTER TABLE EVENT
ADD CONSTRAINT chk_event_name_not_blank CHECK (TRIM(EVENT_NAME) IS NOT NULL AND EVENT_NAME <> '');

ALTER TABLE EVENT
ADD CONSTRAINT chk_event_status_valid CHECK (STATUS IN ('Scheduled', 'Completed', 'Cancelled'));

ALTER TABLE EVENT
ADD CONSTRAINT chk_event_budget_positive CHECK (EVENT_BUDGET IS NULL OR EVENT_BUDGET > 0);

ALTER TABLE REGISTRATION
ADD CONSTRAINT chk_registration_quantity_positive CHECK (QUANTITY > 0);

ALTER TABLE REGISTRATION
ADD CONSTRAINT chk_registration_ticket_price_positive CHECK (TICKET_PRICE > 0);

ALTER TABLE REGISTRATION
ADD CONSTRAINT chk_registration_status_valid CHECK (STATUS IN ('Confirmed', 'Pending', 'Cancelled'));
ALTER TABLE PAYMENT
ADD CONSTRAINT chk_payment_amount_positive CHECK (AMOUNT > 0);

ALTER TABLE PAYMENT
ADD CONSTRAINT chk_payment_status_valid CHECK (PAYMENT_STATUS IN ('Completed', 'Pending', 'Failed'));

ALTER TABLE EVENT_REVIEW
ADD CONSTRAINT chk_event_review_rating_range CHECK (RATING BETWEEN 1 AND 5);

ALTER TABLE EVENT_REVIEW
ADD CONSTRAINT chk_event_review_text_length CHECK (LENGTH(REVIEW) <= 250);

ALTER TABLE VENUE
ADD CONSTRAINT chk_venue_capacity_positive CHECK (VENUE_CAPACITY > 0);

ALTER TABLE VENUE
ADD CONSTRAINT chk_venue_name_not_blank CHECK (TRIM(VENUE_NAME) IS NOT NULL AND VENUE_NAME <> '');

ALTER TABLE SPONSOR
ADD CONSTRAINT chk_sponsor_amount_positive CHECK (AMOUNT_SPONSORED > 0);


ALTER TABLE EVENT_USERS
ADD CONSTRAINT unique_email UNIQUE (EMAIL);

ALTER TABLE EVENT_USERS
ADD CONSTRAINT unique_phone_number UNIQUE (PHONE_NUMBER);

ALTER TABLE USER_ADDRESS
ADD CONSTRAINT unique_user_address UNIQUE (USER_USER_ID);

ALTER TABLE VENUE
ADD CONSTRAINT unique_venue_name UNIQUE (VENUE_NAME);





Commit;



