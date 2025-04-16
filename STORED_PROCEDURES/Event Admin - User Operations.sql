-- Create sequences for the USER and ADDRESS tables
SET SERVEROUTPUT ON;
DECLARE
  seq_exists NUMBER;
BEGIN
  -- Check if USER_ID_SEQ exists
  SELECT COUNT(*) INTO seq_exists FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'USER_ID_SEQ';
  IF seq_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE USER_ID_SEQ 
                      START WITH 1001 
                      INCREMENT BY 1 
                      NOCACHE 
                      NOCYCLE';
    DBMS_OUTPUT.PUT_LINE('USER_ID_SEQ created successfully.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('USER_ID_SEQ already exists. Skipping creation.');
  END IF;

  -- Check if ADDRESS_ID_SEQ exists
  SELECT COUNT(*) INTO seq_exists FROM USER_SEQUENCES WHERE SEQUENCE_NAME = 'ADDRESS_ID_SEQ';
  IF seq_exists = 0 THEN
    EXECUTE IMMEDIATE 'CREATE SEQUENCE ADDRESS_ID_SEQ 
                      START WITH 1001 
                      INCREMENT BY 1 
                      NOCACHE 
                      NOCYCLE';
    DBMS_OUTPUT.PUT_LINE('ADDRESS_ID_SEQ created successfully.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('ADDRESS_ID_SEQ already exists. Skipping creation.');
  END IF;
END;
/

-- Procedure for address creation
CREATE OR REPLACE PROCEDURE add_user_address(
    p_user_id IN NUMBER,
    p_street_address IN VARCHAR2,
    p_city IN VARCHAR2,
    p_state IN VARCHAR2,
    p_country IN VARCHAR2,
    p_zip_code IN NUMBER
)
AS
BEGIN
    -- Insert into USER_ADDRESS table
    INSERT INTO USER_ADDRESS(ADDRESS_ID, USER_USER_ID, STREET_ADDRESS, CITY, STATE, COUNTRY, ZIP_CODE)
    VALUES (ADDRESS_ID_SEQ.NEXTVAL, p_user_id, p_street_address, p_city, p_state, p_country, p_zip_code);
    
    -- No COMMIT here to allow the calling procedure to handle transaction control
EXCEPTION
    WHEN OTHERS THEN
        -- Raise the error to the caller
        RAISE;
END add_user_address;
/

-- Procedure for user creation with extended parameters
CREATE OR REPLACE PROCEDURE add_user_with_address(
    p_first_name IN VARCHAR2,
    p_last_name IN VARCHAR2,
    p_email IN VARCHAR2,
    p_phone_number IN NUMBER,
    p_user_password IN VARCHAR2,
    p_user_type IN VARCHAR2,
    p_street_address IN VARCHAR2,
    p_city IN VARCHAR2,
    p_state IN VARCHAR2,
    p_country IN VARCHAR2,
    p_zip_code IN NUMBER,
    -- Additional parameters for type-specific tables
    p_company_name IN VARCHAR2 DEFAULT NULL,
    p_sponsor_name IN VARCHAR2 DEFAULT NULL,
    p_amount_sponsored IN NUMBER DEFAULT NULL,
    p_venue_name IN VARCHAR2 DEFAULT NULL,
    p_venue_capacity IN NUMBER DEFAULT NULL
)
AS
    v_user_id NUMBER;
    invalid_user_type EXCEPTION;
    email_exists EXCEPTION;
    phone_exists EXCEPTION;
    invalid_contact EXCEPTION;
    missing_required_info EXCEPTION;
    v_count NUMBER;
    v_is_valid NUMBER;
BEGIN
    -- Validate contact information using the validate_user_contact function
    v_is_valid := validate_user_contact(p_phone_number, p_email);
    IF v_is_valid = 0 THEN
        RAISE invalid_contact;
    END IF;
    
    -- Validate user_type
    IF p_user_type NOT IN ('Attendee', 'Organizer', 'Sponsor', 'Venue_Manager') THEN
        RAISE invalid_user_type;
    END IF;
    
    -- Check for required type-specific information
    IF p_user_type = 'Organizer' AND p_company_name IS NULL THEN
        RAISE missing_required_info;
    ELSIF p_user_type = 'Sponsor' AND p_sponsor_name IS NULL THEN
        RAISE missing_required_info;
    ELSIF p_user_type = 'Venue_Manager' AND (p_venue_name IS NULL OR p_venue_capacity IS NULL) THEN
        RAISE missing_required_info;
    END IF;
    
    -- Check if email already exists
    SELECT COUNT(*) INTO v_count FROM EVENT_USERS WHERE EMAIL = p_email;
    IF v_count > 0 THEN
        RAISE email_exists;
    END IF;
    
    -- Check if phone number already exists
    SELECT COUNT(*) INTO v_count FROM EVENT_USERS WHERE PHONE_NUMBER = p_phone_number;
    IF v_count > 0 THEN
        RAISE phone_exists;
    END IF;
    
    -- Disable the trigger temporarily to handle the insert ourselves
    EXECUTE IMMEDIATE 'ALTER TRIGGER after_insert_event_users DISABLE';
    
    -- Insert into USER table
    INSERT INTO EVENT_USERS(USER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, USER_PASSWORD, USER_TYPE)
    VALUES (USER_ID_SEQ.NEXTVAL, p_first_name, p_last_name, p_email, p_phone_number, p_user_password, p_user_type)
    RETURNING USER_ID INTO v_user_id;
    
    -- Insert into type-specific table based on user_type
    CASE p_user_type
        WHEN 'Attendee' THEN
            INSERT INTO ATTENDEE (
                ATTENDEE_ID,
                FIRST_NAME,
                LAST_NAME,
                USER_USER_ID
            ) VALUES (
                ATTENDEE_ID_SEQ.NEXTVAL,
                p_first_name,
                p_last_name,
                v_user_id
            );
            
        WHEN 'Organizer' THEN
            INSERT INTO ORGANIZER (
                ORGANIZER_ID,
                USER_USER_ID,
                COMPANY_NAME
            ) VALUES (
                ORGANIZER_ID_SEQ.NEXTVAL,
                v_user_id,
                p_company_name
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
                p_sponsor_name,
                NVL(p_amount_sponsored, 0),
                NULL,  -- EVENT_EVENT_ID to be updated later
                v_user_id
            );
            
        WHEN 'Venue_Manager' THEN
            INSERT INTO VENUE (
                VENUE_ID,
                VENUE_NAME,
                VENUE_CAPACITY,
                USER_USER_ID
            ) VALUES (
                VENUE_ID_SEQ.NEXTVAL,
                p_venue_name,
                p_venue_capacity,
                v_user_id
            );
    END CASE;
    
    -- Call the address procedure with the newly generated user_id
    add_user_address(
        v_user_id,
        p_street_address,
        p_city,
        p_state,
        p_country,
        p_zip_code
    );
    
    -- Re-enable the trigger
    EXECUTE IMMEDIATE 'ALTER TRIGGER after_insert_event_users ENABLE';
    
    -- Commit the transaction after all operations are complete
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('User created successfully with ID: ' || v_user_id);
    
EXCEPTION
    WHEN invalid_contact THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid phone number or email format');
        ROLLBACK;
    WHEN invalid_user_type THEN
        DBMS_OUTPUT.PUT_LINE('Error: USER_TYPE must be Attendee, Organizer, Sponsor, or Venue_Manager');
        ROLLBACK;
    WHEN missing_required_info THEN
        DBMS_OUTPUT.PUT_LINE('Error: Missing required information for user type ' || p_user_type);
        ROLLBACK;
    WHEN email_exists THEN
        DBMS_OUTPUT.PUT_LINE('Error: User with email ' || p_email || ' already exists');
        ROLLBACK;
    WHEN phone_exists THEN
        DBMS_OUTPUT.PUT_LINE('Error: User with phone number ' || p_phone_number || ' already exists');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        -- Make sure to re-enable the trigger even if there's an error
        EXECUTE IMMEDIATE 'ALTER TRIGGER after_insert_event_users ENABLE';
        ROLLBACK;
END add_user_with_address;
/

-- Procedure for updating user information
CREATE OR REPLACE PROCEDURE update_user(
    p_user_id IN NUMBER,
    p_first_name IN VARCHAR2 DEFAULT NULL,
    p_last_name IN VARCHAR2 DEFAULT NULL,
    p_email IN VARCHAR2 DEFAULT NULL,
    p_phone_number IN NUMBER DEFAULT NULL,
    p_user_password IN VARCHAR2 DEFAULT NULL,
    p_user_type IN VARCHAR2 DEFAULT NULL
)
AS
    v_count NUMBER;
    email_exists EXCEPTION;
    phone_exists EXCEPTION;
    invalid_user_type EXCEPTION;
    user_not_found EXCEPTION;
    invalid_contact EXCEPTION;
    v_current_email VARCHAR2(250);
    v_current_phone NUMBER;
    v_current_type VARCHAR2(15);
    v_is_valid NUMBER;
BEGIN
    -- Check if user exists
    SELECT COUNT(*) INTO v_count FROM EVENT_USERS WHERE USER_ID = p_user_id;
    IF v_count = 0 THEN
        RAISE user_not_found;
    END IF;
    
    -- Get current values for comparison
    SELECT EMAIL, PHONE_NUMBER, USER_TYPE 
    INTO v_current_email, v_current_phone, v_current_type
    FROM EVENT_USERS
    WHERE USER_ID = p_user_id;
    
    -- Validate contact information if either is being updated
    IF p_email IS NOT NULL OR p_phone_number IS NOT NULL THEN
        v_is_valid := validate_user_contact(
            CASE WHEN p_phone_number IS NOT NULL THEN p_phone_number ELSE v_current_phone END,
            CASE WHEN p_email IS NOT NULL THEN p_email ELSE v_current_email END
        );
        
        IF v_is_valid = 0 THEN
            RAISE invalid_contact;
        END IF;
    END IF;
    
    -- Check if new email exists (if it's being updated)
    IF p_email IS NOT NULL AND p_email != v_current_email THEN
        SELECT COUNT(*) INTO v_count FROM EVENT_USERS 
        WHERE EMAIL = p_email AND USER_ID != p_user_id;
        IF v_count > 0 THEN
            RAISE email_exists;
        END IF;
    END IF;
    
    -- Check if new phone number exists (if it's being updated)
    IF p_phone_number IS NOT NULL AND p_phone_number != v_current_phone THEN
        SELECT COUNT(*) INTO v_count FROM EVENT_USERS 
        WHERE PHONE_NUMBER = p_phone_number AND USER_ID != p_user_id;
        IF v_count > 0 THEN
            RAISE phone_exists;
        END IF;
    END IF;
    
    -- Validate user_type if it's being updated
    IF p_user_type IS NOT NULL AND p_user_type != v_current_type THEN
        IF p_user_type NOT IN ('Attendee', 'Organizer', 'Sponsor', 'Venue_Manager') THEN
            RAISE invalid_user_type;
        END IF;
    END IF;
    
    -- Update user information with conditional updates for each field
    UPDATE EVENT_USERS
    SET FIRST_NAME = CASE WHEN p_first_name IS NOT NULL THEN p_first_name ELSE FIRST_NAME END,
        LAST_NAME = CASE WHEN p_last_name IS NOT NULL THEN p_last_name ELSE LAST_NAME END,
        EMAIL = CASE WHEN p_email IS NOT NULL THEN p_email ELSE EMAIL END,
        PHONE_NUMBER = CASE WHEN p_phone_number IS NOT NULL THEN p_phone_number ELSE PHONE_NUMBER END,
        USER_PASSWORD = CASE WHEN p_user_password IS NOT NULL THEN p_user_password ELSE USER_PASSWORD END,
        USER_TYPE = CASE WHEN p_user_type IS NOT NULL THEN p_user_type ELSE USER_TYPE END
    WHERE USER_ID = p_user_id;
    
    -- Commit the transaction
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('User with ID ' || p_user_id || ' updated successfully.');
    
EXCEPTION
    WHEN invalid_contact THEN
        DBMS_OUTPUT.PUT_LINE('Error: Invalid phone number or email format');
        ROLLBACK;
    WHEN user_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: User with ID ' || p_user_id || ' not found.');
        ROLLBACK;
    WHEN email_exists THEN
        DBMS_OUTPUT.PUT_LINE('Error: User with email ' || p_email || ' already exists.');
        ROLLBACK;
    WHEN phone_exists THEN
        DBMS_OUTPUT.PUT_LINE('Error: User with phone number ' || p_phone_number || ' already exists.');
        ROLLBACK;
    WHEN invalid_user_type THEN
        DBMS_OUTPUT.PUT_LINE('Error: USER_TYPE must be Attendee, Organizer, Sponsor, or Venue_Manager');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
END update_user;
/

-- Procedure for updating a user's address
CREATE OR REPLACE PROCEDURE update_user_address(
    p_address_id IN NUMBER,
    p_user_id IN NUMBER,
    p_street_address IN VARCHAR2 DEFAULT NULL,
    p_city IN VARCHAR2 DEFAULT NULL,
    p_state IN VARCHAR2 DEFAULT NULL,
    p_country IN VARCHAR2 DEFAULT NULL,
    p_zip_code IN NUMBER DEFAULT NULL
)
AS
    v_count NUMBER;
    address_not_found EXCEPTION;
    user_not_found EXCEPTION;
    address_not_owned_by_user EXCEPTION;
BEGIN
    -- Check if the user exists
    SELECT COUNT(*) INTO v_count FROM EVENT_USERS WHERE USER_ID = p_user_id;
    IF v_count = 0 THEN
        RAISE user_not_found;
    END IF;
    
    -- Check if the address exists
    SELECT COUNT(*) INTO v_count FROM USER_ADDRESS WHERE ADDRESS_ID = p_address_id;
    IF v_count = 0 THEN
        RAISE address_not_found;
    END IF;
    
    -- Check if the address belongs to the user
    SELECT COUNT(*) INTO v_count 
    FROM USER_ADDRESS 
    WHERE ADDRESS_ID = p_address_id AND USER_USER_ID = p_user_id;
    IF v_count = 0 THEN
        RAISE address_not_owned_by_user;
    END IF;
    
    -- Update address information with conditional updates for each field
    UPDATE USER_ADDRESS
    SET STREET_ADDRESS = CASE WHEN p_street_address IS NOT NULL THEN p_street_address ELSE STREET_ADDRESS END,
        CITY = CASE WHEN p_city IS NOT NULL THEN p_city ELSE CITY END,
        STATE = CASE WHEN p_state IS NOT NULL THEN p_state ELSE STATE END,
        COUNTRY = CASE WHEN p_country IS NOT NULL THEN p_country ELSE COUNTRY END,
        ZIP_CODE = CASE WHEN p_zip_code IS NOT NULL THEN p_zip_code ELSE ZIP_CODE END
    WHERE ADDRESS_ID = p_address_id;
    
    -- Commit the transaction
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Address with ID ' || p_address_id || ' for user ID ' || p_user_id || ' updated successfully.');
    
EXCEPTION
    WHEN user_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: User with ID ' || p_user_id || ' not found.');
        ROLLBACK;
    WHEN address_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: Address with ID ' || p_address_id || ' not found.');
        ROLLBACK;
    WHEN address_not_owned_by_user THEN
        DBMS_OUTPUT.PUT_LINE('Error: Address with ID ' || p_address_id || ' does not belong to user with ID ' || p_user_id || '.');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        ROLLBACK;
END update_user_address;
/

-- Test cases for checking if the procedures work correctly
-- Test Case 1: User creation - Valid inputs
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 1: User creation with valid inputs');
    add_user_with_address(
        'John', 'Doe', 'john.doe@example.com', 1234567890, 'Password123', 'Attendee',
        '123 Main St', 'New York', 'NY', 'USA', 10001
    );
END;
/

-- Test Case 2: User creation - Invalid phone (9 digits)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 2: User creation with invalid phone (9 digits)');
    add_user_with_address(
        'Jane', 'Smith', 'jane.smith@example.com', 123456789, 'Password123', 'Attendee',
        '456 Oak Ave', 'Los Angeles', 'CA', 'USA', 90001
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 3: User creation - Invalid email (no @ symbol)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 3: User creation with invalid email (no @ symbol)');
    add_user_with_address(
        'Bob', 'Brown', 'bob.brown.example.com', 9876543210, 'Password123', 'Attendee',
        '789 Pine St', 'Chicago', 'IL', 'USA', 60601
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 4: User creation - NULL phone
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 4: User creation with NULL phone');
    add_user_with_address(
        'Alice', 'Green', 'alice.green@example.com', NULL, 'Password123', 'Attendee',
        '321 Elm St', 'Boston', 'MA', 'USA', 02101
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 5: User creation - NULL email
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 5: User creation with NULL email');
    add_user_with_address(
        'Mark', 'White', NULL, 4567891230, 'Password123', 'Attendee',
        '654 Maple Ave', 'Miami', 'FL', 'USA', 33101
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 6: User creation - Invalid user type
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 6: User creation with invalid user type');
    add_user_with_address(
        'Chris', 'Black', 'chris.black@example.com', 7891234560, 'Password123', 'Guest',
        '987 Cedar Rd', 'Seattle', 'WA', 'USA', 98101
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 7: User creation - Duplicate email
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 7: User creation with duplicate email');
    -- First create a user (if not already created in Test Case 1)
    BEGIN
        add_user_with_address(
            'David', 'Lee', 'david.lee@example.com', 3216549870, 'Password123', 'Attendee',
            '741 Birch Ave', 'Dallas', 'TX', 'USA', 75201
        );
    EXCEPTION
        WHEN OTHERS THEN
            NULL; -- Ignore errors, in case user already exists
    END;
    
    -- Then try to create another with the same email
    add_user_with_address(
        'Emma', 'Clark', 'david.lee@example.com', 9876543210, 'Password456', 'Organizer',
        '852 Aspen Dr', 'Houston', 'TX', 'USA', 77001
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 8: User creation - Duplicate phone
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 8: User creation with duplicate phone');
    -- First create a user (if not already created)
    BEGIN
        add_user_with_address(
            'Frank', 'Wilson', 'frank.wilson@example.com', 1472583690, 'Password123', 'Sponsor',
            '963 Pine St', 'Phoenix', 'AZ', 'USA', 85001
        );
    EXCEPTION
        WHEN OTHERS THEN
            NULL; -- Ignore errors, in case user already exists
    END;
    
    -- Then try to create another with the same phone
    add_user_with_address(
        'Grace', 'Taylor', 'grace.taylor@example.com', 1472583690, 'Password456', 'Venue_Manager',
        '159 Oak St', 'San Diego', 'CA', 'USA', 92101
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 9: Create a user for update tests
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 9: Creating user for update tests');
    BEGIN
        add_user_with_address(
            'Update', 'Test', 'update.test@example.com', 9876543210, 'Password123', 'Attendee',
            '123 Update St', 'Chicago', 'IL', 'USA', 60601
        );
        DBMS_OUTPUT.PUT_LINE('Test user created successfully');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error creating test user (may already exist): ' || SQLERRM);
    END;
END;
/

-- Test Case 10: User update - Invalid phone (9 digits)
DECLARE
    v_user_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 10: User update with invalid phone (9 digits)');
    BEGIN
        SELECT USER_ID INTO v_user_id
        FROM EVENT_USERS
        WHERE EMAIL = 'update.test@example.com';
        
        update_user(
            p_user_id => v_user_id,
            p_phone_number => 123456789
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Test user not found');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
END;
/

-- Test Case 11: User update - Invalid email (no @ symbol)
DECLARE
    v_user_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 11: User update with invalid email (no @ symbol)');
    BEGIN
        SELECT USER_ID INTO v_user_id
        FROM EVENT_USERS
        WHERE EMAIL = 'update.test@example.com';
        
        update_user(
            p_user_id => v_user_id,
            p_email => 'invalid.email'
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Test user not found');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
END;
/

-- Test Case 12: User update - Non-existent user ID
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 12: User update with non-existent user ID');
    update_user(
        p_user_id => 999999,
        p_first_name => 'Nonexistent'
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
END;
/

-- Test Case 13: Create another user for duplicate tests
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 13: Creating second user for duplicate tests');
    BEGIN
        add_user_with_address(
            'Duplicate', 'Test', 'duplicate.test@example.com', 1122334455, 'Password123', 'Attendee',
            '123 Duplicate St', 'Seattle', 'WA', 'USA', 98101
        );
        DBMS_OUTPUT.PUT_LINE('Second test user created successfully');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error creating second test user (may already exist): ' || SQLERRM);
    END;
END;
/

-- Test Case 14: User update - Email already exists
DECLARE
    v_user_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 14: User update with email that already exists');
    BEGIN
        SELECT USER_ID INTO v_user_id
        FROM EVENT_USERS
        WHERE EMAIL = 'update.test@example.com';
        
        update_user(
            p_user_id => v_user_id,
            p_email => 'duplicate.test@example.com'
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Test user not found');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
END;
/

-- Test Case 15: User update - Phone already exists
DECLARE
    v_user_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 15: User update with phone that already exists');
    BEGIN
        SELECT USER_ID INTO v_user_id
        FROM EVENT_USERS
        WHERE EMAIL = 'update.test@example.com';
        
        update_user(
            p_user_id => v_user_id,
            p_phone_number => 1122334455
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Test user not found');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
END;
/

-- Test Case 16: User update - Invalid user type
DECLARE
    v_user_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 16: User update with invalid user type');
    BEGIN
        SELECT USER_ID INTO v_user_id
        FROM EVENT_USERS
        WHERE EMAIL = 'update.test@example.com';
        
        update_user(
            p_user_id => v_user_id,
            p_user_type => 'Guest'
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Test user not found');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
END;
/

-- Test Case 17: User update - Valid update (all fields)
DECLARE
    v_user_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 17: Valid user update (all fields)');
    BEGIN
        SELECT USER_ID INTO v_user_id
        FROM EVENT_USERS
        WHERE EMAIL = 'update.test@example.com';
        
        update_user(
            p_user_id => v_user_id,
            p_first_name => 'Updated',
            p_last_name => 'User',
            p_email => 'updated.user@example.com',
            p_phone_number => 5556667777,
            p_user_password => 'NewPassword789',
            p_user_type => 'Organizer'
        );
        
        -- Verify the update
        FOR rec IN (SELECT FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, USER_TYPE
                    FROM EVENT_USERS 
                    WHERE USER_ID = v_user_id) 
        LOOP
            DBMS_OUTPUT.PUT_LINE('Updated user info:');
            DBMS_OUTPUT.PUT_LINE('Name: ' || rec.FIRST_NAME || ' ' || rec.LAST_NAME);
            DBMS_OUTPUT.PUT_LINE('Email: ' || rec.EMAIL);
            DBMS_OUTPUT.PUT_LINE('Phone: ' || rec.PHONE_NUMBER);
            DBMS_OUTPUT.PUT_LINE('Type: ' || rec.USER_TYPE);
        END LOOP;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Test user not found');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
    END;
END;
/

-- Test Case 18: Address update - Non-existent address
DECLARE
    v_user_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 18: Address update with non-existent address ID');
    BEGIN
        SELECT USER_ID INTO v_user_id
        FROM EVENT_USERS
        WHERE EMAIL = 'updated.user@example.com';
        
        update_user_address(
            p_address_id => 999999,
            p_user_id => v_user_id,
            p_street_address => '456 Nonexistent St'
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Test user not found');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
END;
/

-- Test Case 19: Address update - Non-existent user
DECLARE
    v_address_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 19: Address update with non-existent user');
    BEGIN
        SELECT ADDRESS_ID INTO v_address_id
        FROM USER_ADDRESS
        WHERE ROWNUM = 1;
        
        update_user_address(
            p_address_id => v_address_id,
            p_user_id => 999999,
            p_street_address => '456 Invalid User St'
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No addresses found in the database');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
END;
/

-- Test Case 20: Address update - Address not owned by user
DECLARE
    v_user_id1 NUMBER;
    v_user_id2 NUMBER;
    v_address_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 20: Address update with address not owned by user');
    BEGIN
        -- Get user 1 and their address
        SELECT USER_ID INTO v_user_id1
        FROM EVENT_USERS
        WHERE EMAIL = 'updated.user@example.com';
        
        SELECT ADDRESS_ID INTO v_address_id
        FROM USER_ADDRESS
        WHERE USER_USER_ID = v_user_id1 AND ROWNUM = 1;
        
        -- Get user 2
        SELECT USER_ID INTO v_user_id2
        FROM EVENT_USERS
        WHERE EMAIL = 'duplicate.test@example.com';
        
        -- Try to update user1's address using user2's ID
        update_user_address(
            p_address_id => v_address_id,
            p_user_id => v_user_id2,
            p_street_address => '789 Wrong Owner St'
        );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Test users or address not found');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;
END;
/

-- Test Case 21: Address update - Valid update
DECLARE
    v_user_id NUMBER;
    v_address_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 21: Valid address update');
    BEGIN
        SELECT USER_ID INTO v_user_id
        FROM EVENT_USERS
        WHERE EMAIL = 'updated.user@example.com';
        
        SELECT ADDRESS_ID INTO v_address_id
        FROM USER_ADDRESS
        WHERE USER_USER_ID = v_user_id AND ROWNUM = 1;
        
        update_user_address(
            p_address_id => v_address_id,
            p_user_id => v_user_id,
            p_street_address => '123 New Address',
            p_city => 'New City',
            p_state => 'NC',
            p_country => 'USA',
            p_zip_code => 20001
        );
        
        -- Verify the update
        FOR rec IN (SELECT STREET_ADDRESS, CITY, STATE, COUNTRY, ZIP_CODE
                    FROM USER_ADDRESS 
                    WHERE ADDRESS_ID = v_address_id) 
        LOOP
            DBMS_OUTPUT.PUT_LINE('Updated address info:');
            DBMS_OUTPUT.PUT_LINE('Street: ' || rec.STREET_ADDRESS);
            DBMS_OUTPUT.PUT_LINE('City: ' || rec.CITY);
            DBMS_OUTPUT.PUT_LINE('State: ' || rec.STATE);
            DBMS_OUTPUT.PUT_LINE('Country: ' || rec.COUNTRY);
            DBMS_OUTPUT.PUT_LINE('Zip: ' || rec.ZIP_CODE);
        END LOOP;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Test user or address not found');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
    END;
END;
/