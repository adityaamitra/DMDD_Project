
-- Insert Data into EVENT_USERS Table
INSERT INTO EVENT_USERS (USER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, USER_PASSWORD, USER_TYPE) VALUES (1, 'Alice', 'Johnson', 'alice.j@example.com', '1234567890', 'password123', 'Attendee');
INSERT INTO EVENT_USERS (USER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, USER_PASSWORD, USER_TYPE) VALUES (2, 'Bob', 'Smith', 'bob.s@example.com', '2345678901', 'password123', 'Organizer');
INSERT INTO EVENT_USERS (USER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, USER_PASSWORD, USER_TYPE) VALUES (3, 'Charlie', 'Brown', 'charlie.b@example.com', '3456789012', 'password123', 'Attendee');
INSERT INTO EVENT_USERS (USER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, USER_PASSWORD, USER_TYPE) VALUES (4, 'Daisy', 'Miller', 'daisy.m@example.com', '4567890123', 'password123', 'Organizer');
INSERT INTO EVENT_USERS (USER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, USER_PASSWORD, USER_TYPE) VALUES (5, 'Eva', 'Davis', 'eva.d@example.com', '5678901234', 'password123', 'Attendee');
INSERT INTO EVENT_USERS (USER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, USER_PASSWORD, USER_TYPE) VALUES (6, 'Frank', 'Wilson', 'frank.w@example.com', '6789012345', 'password123', 'Organizer');
INSERT INTO EVENT_USERS (USER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, USER_PASSWORD, USER_TYPE) VALUES (7, 'Grace', 'Garcia', 'grace.g@example.com', '7890123456', 'password123', 'Attendee');
INSERT INTO EVENT_USERS (USER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, USER_PASSWORD, USER_TYPE) VALUES (8, 'Hannah', 'Martinez', 'hannah.m@example.com', '8901234567', 'password123', 'Organizer');
INSERT INTO EVENT_USERS (USER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, USER_PASSWORD, USER_TYPE) VALUES (9, 'Ian', 'Rodriguez', 'ian.r@example.com', '9012345678', 'password123', 'Attendee');
INSERT INTO EVENT_USERS (USER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, USER_PASSWORD, USER_TYPE) VALUES (10, 'Jack', 'Lopez', 'jack.l@example.com', '0123456789', 'password123', 'Organizer');

-- Insert Data into USER_ADDRESS Table
INSERT INTO USER_ADDRESS (ADDRESS_ID, USER_USER_ID, STREET_ADDRESS, CITY, STATE, COUNTRY, ZIP_CODE, ADDRESS_TYPE) VALUES (1, 1, '123 Elm St', 'Springfield', 'IL', 'USA', 62701, 'Home');
INSERT INTO USER_ADDRESS (ADDRESS_ID, USER_USER_ID, STREET_ADDRESS, CITY, STATE, COUNTRY, ZIP_CODE, ADDRESS_TYPE) VALUES (2, 2, '456 Oak St', 'Springfield', 'IL', 'USA', 62702, 'Office');
INSERT INTO USER_ADDRESS (ADDRESS_ID, USER_USER_ID, STREET_ADDRESS, CITY, STATE, COUNTRY, ZIP_CODE, ADDRESS_TYPE) VALUES (3, 3, '789 Pine St', 'Springfield', 'IL', 'USA', 62703, 'Home');
INSERT INTO USER_ADDRESS (ADDRESS_ID, USER_USER_ID, STREET_ADDRESS, CITY, STATE, COUNTRY, ZIP_CODE, ADDRESS_TYPE) VALUES (4, 4, '321 Maple St', 'Springfield', 'IL', 'USA', 62704, 'Home');
INSERT INTO USER_ADDRESS (ADDRESS_ID, USER_USER_ID, STREET_ADDRESS, CITY, STATE, COUNTRY, ZIP_CODE, ADDRESS_TYPE) VALUES (5, 5, '654 Cedar St', 'Springfield', 'IL', 'USA', 62705, 'Office');
INSERT INTO USER_ADDRESS (ADDRESS_ID, USER_USER_ID, STREET_ADDRESS, CITY, STATE, COUNTRY, ZIP_CODE, ADDRESS_TYPE) VALUES (6, 6, '987 Birch St', 'Springfield', 'IL', 'USA', 62706, 'Home');
INSERT INTO USER_ADDRESS (ADDRESS_ID, USER_USER_ID, STREET_ADDRESS, CITY, STATE, COUNTRY, ZIP_CODE, ADDRESS_TYPE) VALUES (7, 7, '159 Walnut St', 'Springfield', 'IL', 'USA', 62707, 'Office');
INSERT INTO USER_ADDRESS (ADDRESS_ID, USER_USER_ID, STREET_ADDRESS, CITY, STATE, COUNTRY, ZIP_CODE, ADDRESS_TYPE) VALUES (8, 8, '753 Chestnut St', 'Springfield', 'IL', 'USA', 62708, 'Home');
INSERT INTO USER_ADDRESS (ADDRESS_ID, USER_USER_ID, STREET_ADDRESS, CITY, STATE, COUNTRY, ZIP_CODE, ADDRESS_TYPE) VALUES (9, 9, '951 Ash St', 'Springfield', 'IL', 'USA', 62709, 'Home');
INSERT INTO USER_ADDRESS (ADDRESS_ID, USER_USER_ID, STREET_ADDRESS, CITY, STATE, COUNTRY, ZIP_CODE, ADDRESS_TYPE) VALUES (10, 10, '753 Fir St', 'Springfield', 'IL', 'USA', 62710, 'Office');
-- Insert Data into ATTENDEE Table
INSERT INTO ATTENDEE (ATTENDEE_ID, FIRST_NAME, LAST_NAME, USER_USER_ID) VALUES (1, 'Alice', 'Johnson', 1);
INSERT INTO ATTENDEE (ATTENDEE_ID, FIRST_NAME, LAST_NAME, USER_USER_ID) VALUES (2, 'Bob', 'Smith', 2);
INSERT INTO ATTENDEE (ATTENDEE_ID, FIRST_NAME, LAST_NAME, USER_USER_ID) VALUES (3, 'Charlie', 'Brown', 3);
INSERT INTO ATTENDEE (ATTENDEE_ID, FIRST_NAME, LAST_NAME, USER_USER_ID) VALUES (4, 'Daisy', 'Miller', 4);
INSERT INTO ATTENDEE (ATTENDEE_ID, FIRST_NAME, LAST_NAME, USER_USER_ID) VALUES (5, 'Eva', 'Davis', 5);
INSERT INTO ATTENDEE (ATTENDEE_ID, FIRST_NAME, LAST_NAME, USER_USER_ID) VALUES (6, 'Frank', 'Wilson', 6);
INSERT INTO ATTENDEE (ATTENDEE_ID, FIRST_NAME, LAST_NAME, USER_USER_ID) VALUES (7, 'Grace', 'Garcia', 7);
INSERT INTO ATTENDEE (ATTENDEE_ID, FIRST_NAME, LAST_NAME, USER_USER_ID) VALUES (8, 'Hannah', 'Martinez', 8);
INSERT INTO ATTENDEE (ATTENDEE_ID, FIRST_NAME, LAST_NAME, USER_USER_ID) VALUES (9, 'Ian', 'Rodriguez', 9);
INSERT INTO ATTENDEE (ATTENDEE_ID, FIRST_NAME, LAST_NAME, USER_USER_ID) VALUES (10, 'Jack', 'Lopez', 10);

-- Insert Data into ORGANIZER Table
INSERT INTO ORGANIZER (ORGANIZER_ID, USER_USER_ID, COMPANY_NAME) VALUES (1, 1, 'Tech Corp');
INSERT INTO ORGANIZER (ORGANIZER_ID, USER_USER_ID, COMPANY_NAME) VALUES (2, 2, 'Art World');
INSERT INTO ORGANIZER (ORGANIZER_ID, USER_USER_ID, COMPANY_NAME) VALUES (3, 3, 'Music Fest LLC');
INSERT INTO ORGANIZER (ORGANIZER_ID, USER_USER_ID, COMPANY_NAME) VALUES (4, 4, 'Foodies United');
INSERT INTO ORGANIZER (ORGANIZER_ID, USER_USER_ID, COMPANY_NAME) VALUES (5, 5, 'Sporty Co.');
INSERT INTO ORGANIZER (ORGANIZER_ID, USER_USER_ID, COMPANY_NAME) VALUES (6, 6, 'Business Connect');
INSERT INTO ORGANIZER (ORGANIZER_ID, USER_USER_ID, COMPANY_NAME) VALUES (7, 7, 'Charity Events Inc.');
INSERT INTO ORGANIZER (ORGANIZER_ID, USER_USER_ID, COMPANY_NAME) VALUES (8, 8, 'Workshop Academy');
INSERT INTO ORGANIZER (ORGANIZER_ID, USER_USER_ID, COMPANY_NAME) VALUES (9, 9, 'Networking Hub');
INSERT INTO ORGANIZER (ORGANIZER_ID, USER_USER_ID, COMPANY_NAME) VALUES (10, 10, 'Clean Up Crew');

-- Insert Data into EVENT Table
INSERT INTO EVENT (EVENT_ID, ORGANIZER_ORGANIZER_ID, EVENT_NAME, EVENT_DESCRIPTION, EVENT_TYPE, STATUS, EVENT_BUDGET) VALUES (1, 1, 'Tech Conference', 'A conference about the latest in tech', 'Conference', 'Scheduled', 10000.00);
INSERT INTO EVENT (EVENT_ID, ORGANIZER_ORGANIZER_ID, EVENT_NAME, EVENT_DESCRIPTION, EVENT_TYPE, STATUS, EVENT_BUDGET) VALUES (2, 2, 'Art Exhibition', 'An exhibition showcasing local artists', 'Exhibition', 'Scheduled', 5000.00);
INSERT INTO EVENT (EVENT_ID, ORGANIZER_ORGANIZER_ID, EVENT_NAME, EVENT_DESCRIPTION, EVENT_TYPE, STATUS, EVENT_BUDGET) VALUES (3, 3, 'Music Festival', 'A festival featuring various music artists', 'Festival', 'Scheduled', 20000.00);
INSERT INTO EVENT (EVENT_ID, ORGANIZER_ORGANIZER_ID, EVENT_NAME, EVENT_DESCRIPTION, EVENT_TYPE, STATUS, EVENT_BUDGET) VALUES (4, 4, 'Food Fair', 'A fair featuring food from around the world', 'Fair', 'Scheduled', 8000.00);
INSERT INTO EVENT (EVENT_ID, ORGANIZER_ORGANIZER_ID, EVENT_NAME, EVENT_DESCRIPTION, EVENT_TYPE, STATUS, EVENT_BUDGET) VALUES (5, 5, 'Sports Day', 'A day of sports activities and competitions', 'Sports', 'Scheduled', 3000.00);
INSERT INTO EVENT (EVENT_ID, ORGANIZER_ORGANIZER_ID, EVENT_NAME, EVENT_DESCRIPTION, EVENT_TYPE, STATUS, EVENT_BUDGET) VALUES (6, 6, 'Business Summit', 'A summit for business leaders', 'Summit', 'Scheduled', 15000.00);
INSERT INTO EVENT (EVENT_ID, ORGANIZER_ORGANIZER_ID, EVENT_NAME, EVENT_DESCRIPTION, EVENT_TYPE, STATUS, EVENT_BUDGET) VALUES (7, 7, 'Charity Run', 'A run to raise money for charity', 'Run', 'Scheduled', 2000.00);
INSERT INTO EVENT (EVENT_ID, ORGANIZER_ORGANIZER_ID, EVENT_NAME, EVENT_DESCRIPTION, EVENT_TYPE, STATUS, EVENT_BUDGET) VALUES (8, 8, 'Workshop Series', 'A series of educational workshops', 'Workshop', 'Scheduled', 7000.00);
INSERT INTO EVENT (EVENT_ID, ORGANIZER_ORGANIZER_ID, EVENT_NAME, EVENT_DESCRIPTION, EVENT_TYPE, STATUS, EVENT_BUDGET) VALUES (9, 9, 'Networking Event', 'An event to network with professionals', 'Networking', 'Scheduled', 4000.00);
INSERT INTO EVENT (EVENT_ID, ORGANIZER_ORGANIZER_ID, EVENT_NAME, EVENT_DESCRIPTION, EVENT_TYPE, STATUS, EVENT_BUDGET) VALUES (10, 10, 'Community Cleanup', 'A community event to clean up the local area', 'Community Service', 'Scheduled', 1000.00);


-- Insert Data into REGISTRATION Table
INSERT INTO REGISTRATION (REGISTRATION_ID, EVENT_EVENT_ID, ATTENDEE_ATTENDEE_ID, REGISTRATION_DATE, STATUS, TICKET_PRICE, QUANTITY) VALUES (1, 1, 1, TO_DATE('2025-03-01', 'YYYY-MM-DD'), 'Confirmed', 100.00, 1);
INSERT INTO REGISTRATION (REGISTRATION_ID, EVENT_EVENT_ID, ATTENDEE_ATTENDEE_ID, REGISTRATION_DATE, STATUS, TICKET_PRICE, QUANTITY) VALUES (2, 1, 2, TO_DATE('2025-03-02', 'YYYY-MM-DD'), 'Confirmed', 100.00, 1);
INSERT INTO REGISTRATION (REGISTRATION_ID, EVENT_EVENT_ID, ATTENDEE_ATTENDEE_ID, REGISTRATION_DATE, STATUS, TICKET_PRICE, QUANTITY) VALUES (3, 2, 3, TO_DATE('2025-03-03', 'YYYY-MM-DD'), 'Pending', 50.00, 2);
INSERT INTO REGISTRATION (REGISTRATION_ID, EVENT_EVENT_ID, ATTENDEE_ATTENDEE_ID, REGISTRATION_DATE, STATUS, TICKET_PRICE, QUANTITY) VALUES (4, 3, 4, TO_DATE('2025-03-04', 'YYYY-MM-DD'), 'Confirmed', 75.00, 1);
INSERT INTO REGISTRATION (REGISTRATION_ID, EVENT_EVENT_ID, ATTENDEE_ATTENDEE_ID, REGISTRATION_DATE, STATUS, TICKET_PRICE, QUANTITY) VALUES (5, 4, 5, TO_DATE('2025-03-05', 'YYYY-MM-DD'), 'Cancelled', 30.00, 1);
INSERT INTO REGISTRATION (REGISTRATION_ID, EVENT_EVENT_ID, ATTENDEE_ATTENDEE_ID, REGISTRATION_DATE, STATUS, TICKET_PRICE, QUANTITY) VALUES (6, 5, 6, TO_DATE('2025-03-06', 'YYYY-MM-DD'), 'Confirmed', 200.00, 1);
INSERT INTO REGISTRATION (REGISTRATION_ID, EVENT_EVENT_ID, ATTENDEE_ATTENDEE_ID, REGISTRATION_DATE, STATUS, TICKET_PRICE, QUANTITY) VALUES (7, 6, 7, TO_DATE('2025-03-07', 'YYYY-MM-DD'), 'Pending', 60.00, 1);
INSERT INTO REGISTRATION (REGISTRATION_ID, EVENT_EVENT_ID, ATTENDEE_ATTENDEE_ID, REGISTRATION_DATE, STATUS, TICKET_PRICE, QUANTITY) VALUES (8, 7, 8, TO_DATE('2025-03-08', 'YYYY-MM-DD'), 'Confirmed', 90.00, 1);
INSERT INTO REGISTRATION (REGISTRATION_ID, EVENT_EVENT_ID, ATTENDEE_ATTENDEE_ID, REGISTRATION_DATE, STATUS, TICKET_PRICE, QUANTITY) VALUES (9, 8, 9, TO_DATE('2025-03-09', 'YYYY-MM-DD'), 'Pending', 120.00, 2);
INSERT INTO REGISTRATION (REGISTRATION_ID, EVENT_EVENT_ID, ATTENDEE_ATTENDEE_ID, REGISTRATION_DATE, STATUS, TICKET_PRICE, QUANTITY) VALUES (10, 9, 10, TO_DATE('2025-03-10', 'YYYY-MM-DD'), 'Confirmed', 150.00, 1);


-- Insert Data into EVENT_REVIEW Table
INSERT INTO EVENT_REVIEW (FEEDBACK_ID, REGISTRATION_REGISTRATION_ID, EVENT_EVENT_ID, REVIEW, RATING) VALUES (1, 1, 1, 'Great event, learned a lot!', 5);
INSERT INTO EVENT_REVIEW (FEEDBACK_ID, REGISTRATION_REGISTRATION_ID, EVENT_EVENT_ID, REVIEW, RATING) VALUES (2, 2, 1, 'Very informative.', 4);
INSERT INTO EVENT_REVIEW (FEEDBACK_ID, REGISTRATION_REGISTRATION_ID, EVENT_EVENT_ID, REVIEW, RATING) VALUES (3, 1, 2, 'Loved the art displayed.', 5);
INSERT INTO EVENT_REVIEW (FEEDBACK_ID, REGISTRATION_REGISTRATION_ID, EVENT_EVENT_ID, REVIEW, RATING) VALUES (4, 3, 3, 'Amazing performances!', 5);
INSERT INTO EVENT_REVIEW (FEEDBACK_ID, REGISTRATION_REGISTRATION_ID, EVENT_EVENT_ID, REVIEW, RATING) VALUES (5, 4, 4, 'Delicious food!', 4);
INSERT INTO EVENT_REVIEW (FEEDBACK_ID, REGISTRATION_REGISTRATION_ID, EVENT_EVENT_ID, REVIEW, RATING) VALUES (6, 5, 5, 'Fun day for the family.', 5);
INSERT INTO EVENT_REVIEW (FEEDBACK_ID, REGISTRATION_REGISTRATION_ID, EVENT_EVENT_ID, REVIEW, RATING) VALUES (7, 6, 6, 'Good networking opportunities.', 4);
INSERT INTO EVENT_REVIEW (FEEDBACK_ID, REGISTRATION_REGISTRATION_ID, EVENT_EVENT_ID, REVIEW, RATING) VALUES (8, 7, 7, 'Incredible cause!', 5);
INSERT INTO EVENT_REVIEW (FEEDBACK_ID, REGISTRATION_REGISTRATION_ID, EVENT_EVENT_ID, REVIEW, RATING) VALUES (9, 8, 8, 'Very helpful sessions.', 4);
INSERT INTO EVENT_REVIEW (FEEDBACK_ID, REGISTRATION_REGISTRATION_ID, EVENT_EVENT_ID, REVIEW, RATING) VALUES (10, 9, 9, 'Great connections made!', 5);

-- Insert Data into VENUE Table
INSERT INTO VENUE (VENUE_ID, VENUE_NAME, VENUE_CAPACITY, USER_USER_ID) VALUES (1, 'Grand Hall', 500, 1);
INSERT INTO VENUE (VENUE_ID, VENUE_NAME, VENUE_CAPACITY, USER_USER_ID) VALUES (2, 'Art Gallery', 200, 2);
INSERT INTO VENUE (VENUE_ID, VENUE_NAME, VENUE_CAPACITY, USER_USER_ID) VALUES (3, 'Music Arena', 1000, 3);
INSERT INTO VENUE (VENUE_ID, VENUE_NAME, VENUE_CAPACITY, USER_USER_ID) VALUES (4, 'Food Court', 300, 4);
INSERT INTO VENUE (VENUE_ID, VENUE_NAME, VENUE_CAPACITY, USER_USER_ID) VALUES (5, 'Sports Complex', 800, 5);
INSERT INTO VENUE (VENUE_ID, VENUE_NAME, VENUE_CAPACITY, USER_USER_ID) VALUES (6, 'Conference Room A', 150, 6);
INSERT INTO VENUE (VENUE_ID, VENUE_NAME, VENUE_CAPACITY, USER_USER_ID) VALUES (7, 'Charity Park', 250, 7);
INSERT INTO VENUE (VENUE_ID, VENUE_NAME, VENUE_CAPACITY, USER_USER_ID) VALUES (8, 'Workshop Center', 100, 8);
INSERT INTO VENUE (VENUE_ID, VENUE_NAME, VENUE_CAPACITY, USER_USER_ID) VALUES (9, 'Networking Lounge', 50, 9);
INSERT INTO VENUE (VENUE_ID, VENUE_NAME, VENUE_CAPACITY, USER_USER_ID) VALUES (10, 'Community Park', 300, 10);


-- Insert Data into EVENT_SCHEDULE Table
INSERT INTO EVENT_SCHEDULE (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID) VALUES (1, TO_TIMESTAMP('2025-03-30 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-03-30 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-03-30 17:00:00', 'YYYY-MM-DD HH24:MI:SS'), 1, 1);
INSERT INTO EVENT_SCHEDULE (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID) VALUES (2, TO_TIMESTAMP('2025-03-31 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-03-31 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-03-31 18:00:00', 'YYYY-MM-DD HH24:MI:SS'), 2, 2);
INSERT INTO EVENT_SCHEDULE (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID) VALUES (3, TO_TIMESTAMP('2025-04-01 11:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-01 11:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-01 20:00:00', 'YYYY-MM-DD HH24:MI:SS'), 3, 3);
INSERT INTO EVENT_SCHEDULE (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID) VALUES (4, TO_TIMESTAMP('2025-04-02 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-02 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-02 21:00:00', 'YYYY-MM-DD HH24:MI:SS'), 4, 4);
INSERT INTO EVENT_SCHEDULE (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID) VALUES (5, TO_TIMESTAMP('2025-04-03 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-03 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-03 17:00:00', 'YYYY-MM-DD HH24:MI:SS'), 5, 5);
INSERT INTO EVENT_SCHEDULE (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID) VALUES (6, TO_TIMESTAMP('2025-04-04 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-04 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-04 19:00:00', 'YYYY-MM-DD HH24:MI:SS'), 6, 6);
INSERT INTO EVENT_SCHEDULE (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID) VALUES (7, TO_TIMESTAMP('2025-04-05 11:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-05 11:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-05 20:00:00', 'YYYY-MM-DD HH24:MI:SS'), 7, 7);
INSERT INTO EVENT_SCHEDULE (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID) VALUES (8, TO_TIMESTAMP('2025-04-06 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-06 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-06 21:00:00', 'YYYY-MM-DD HH24:MI:SS'), 8, 8);
INSERT INTO EVENT_SCHEDULE (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID) VALUES (9, TO_TIMESTAMP('2025-04-07 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-07 09:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-07 17:00:00', 'YYYY-MM-DD HH24:MI:SS'), 9, 9);
INSERT INTO EVENT_SCHEDULE (SCHEDULE_ID, EVENT_SCHEDULE_DATE, START_TIME, END_TIME, VENUE_VENUE_ID, EVENT_EVENT_ID) VALUES (10, TO_TIMESTAMP('2025-04-08 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-08 10:00:00', 'YYYY-MM-DD HH24:MI:SS'), TO_TIMESTAMP('2025-04-08 19:00:00', 'YYYY-MM-DD HH24:MI:SS'), 10, 10);



-- Insert Data into PAYMENT Table
INSERT INTO PAYMENT (PAYMENT_ID, REGISTRATION_REGISTRATION_ID, AMOUNT, PAYMENT_METHOD, PAYMENT_STATUS, PAYMENT_DATE) VALUES (1, 1, 100.00, 'Credit Card', 'Completed', TO_DATE('2025-03-20', 'YYYY-MM-DD'));
INSERT INTO PAYMENT (PAYMENT_ID, REGISTRATION_REGISTRATION_ID, AMOUNT, PAYMENT_METHOD, PAYMENT_STATUS, PAYMENT_DATE) VALUES (2, 2, 50.00, 'Debit Card', 'Completed', TO_DATE('2025-03-21', 'YYYY-MM-DD'));
INSERT INTO PAYMENT (PAYMENT_ID, REGISTRATION_REGISTRATION_ID, AMOUNT, PAYMENT_METHOD, PAYMENT_STATUS, PAYMENT_DATE) VALUES (3, 3, 75.00, 'PayPal', 'Pending', TO_DATE('2025-03-22', 'YYYY-MM-DD'));
INSERT INTO PAYMENT (PAYMENT_ID, REGISTRATION_REGISTRATION_ID, AMOUNT, PAYMENT_METHOD, PAYMENT_STATUS, PAYMENT_DATE) VALUES (4, 4, 30.00, 'Credit Card', 'Completed', TO_DATE('2025-03-23', 'YYYY-MM-DD'));
INSERT INTO PAYMENT (PAYMENT_ID, REGISTRATION_REGISTRATION_ID, AMOUNT, PAYMENT_METHOD, PAYMENT_STATUS, PAYMENT_DATE) VALUES (5, 5, 200.00, 'Cash', 'Completed', TO_DATE('2025-03-24', 'YYYY-MM-DD'));
INSERT INTO PAYMENT (PAYMENT_ID, REGISTRATION_REGISTRATION_ID, AMOUNT, PAYMENT_METHOD, PAYMENT_STATUS, PAYMENT_DATE) VALUES (6, 6, 60.00, 'Credit Card', 'Completed', TO_DATE('2025-03-25', 'YYYY-MM-DD'));
INSERT INTO PAYMENT (PAYMENT_ID, REGISTRATION_REGISTRATION_ID, AMOUNT, PAYMENT_METHOD, PAYMENT_STATUS, PAYMENT_DATE) VALUES (7, 7, 90.00, 'Debit Card', 'Pending', TO_DATE('2025-03-26', 'YYYY-MM-DD'));
INSERT INTO PAYMENT (PAYMENT_ID, REGISTRATION_REGISTRATION_ID, AMOUNT, PAYMENT_METHOD, PAYMENT_STATUS, PAYMENT_DATE) VALUES (8, 8, 120.00, 'PayPal', 'Completed', TO_DATE('2025-03-27', 'YYYY-MM-DD'));
INSERT INTO PAYMENT (PAYMENT_ID, REGISTRATION_REGISTRATION_ID, AMOUNT, PAYMENT_METHOD, PAYMENT_STATUS, PAYMENT_DATE) VALUES (9, 9, 45.00, 'Credit Card', 'Pending', TO_DATE('2025-03-28', 'YYYY-MM-DD'));
INSERT INTO PAYMENT (PAYMENT_ID, REGISTRATION_REGISTRATION_ID, AMOUNT, PAYMENT_METHOD, PAYMENT_STATUS, PAYMENT_DATE) VALUES (10, 10, 150.00, 'Cash', 'Completed', TO_DATE('2025-03-29', 'YYYY-MM-DD'));

-- Insert Data into SPONSOR Table
INSERT INTO SPONSOR (SPONSOR_ID, SPONSOR_NAME, AMOUNT_SPONSORED, EVENT_EVENT_ID, USER_USER_ID) VALUES (1, 'Company A', 1000.00, 1, 1);
INSERT INTO SPONSOR (SPONSOR_ID, SPONSOR_NAME, AMOUNT_SPONSORED, EVENT_EVENT_ID, USER_USER_ID) VALUES (2, 'Company B', 2000.00, 2, 2);
INSERT INTO SPONSOR (SPONSOR_ID, SPONSOR_NAME, AMOUNT_SPONSORED, EVENT_EVENT_ID, USER_USER_ID) VALUES (3, 'Company C', 1500.00, 3, 3);
INSERT INTO SPONSOR (SPONSOR_ID, SPONSOR_NAME, AMOUNT_SPONSORED, EVENT_EVENT_ID, USER_USER_ID) VALUES (4, 'Company D', 2500.00, 4, 4);
INSERT INTO SPONSOR (SPONSOR_ID, SPONSOR_NAME, AMOUNT_SPONSORED, EVENT_EVENT_ID, USER_USER_ID) VALUES (5, 'Company E', 3000.00, 5, 5);
INSERT INTO SPONSOR (SPONSOR_ID, SPONSOR_NAME, AMOUNT_SPONSORED, EVENT_EVENT_ID, USER_USER_ID) VALUES (6, 'Company F', 1200.00, 6, 6);
INSERT INTO SPONSOR (SPONSOR_ID, SPONSOR_NAME, AMOUNT_SPONSORED, EVENT_EVENT_ID, USER_USER_ID) VALUES (7, 'Company G', 800.00, 7, 7);
INSERT INTO SPONSOR (SPONSOR_ID, SPONSOR_NAME, AMOUNT_SPONSORED, EVENT_EVENT_ID, USER_USER_ID) VALUES (8, 'Company H', 2200.00, 8, 8);
INSERT INTO SPONSOR (SPONSOR_ID, SPONSOR_NAME, AMOUNT_SPONSORED, EVENT_EVENT_ID, USER_USER_ID) VALUES (9, 'Company I', 1700.00, 9, 9);
INSERT INTO SPONSOR (SPONSOR_ID, SPONSOR_NAME, AMOUNT_SPONSORED, EVENT_EVENT_ID, USER_USER_ID) VALUES (10, 'Company J', 900.00, 10, 10);



commit;