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

-- Procedure for user creation that calls the address procedure
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
    p_zip_code IN NUMBER
)
AS
    v_user_id NUMBER;
    invalid_user_type EXCEPTION;
    email_exists EXCEPTION;
    phone_exists EXCEPTION;
    v_count NUMBER;
BEGIN
    -- Validate user_type
    IF p_user_type NOT IN ('Attendee', 'Organizer', 'Sponsor', 'Venue_Manager') THEN
        RAISE invalid_user_type;
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
    
    -- Insert into USER table
    INSERT INTO EVENT_USERS(USER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE_NUMBER, USER_PASSWORD, USER_TYPE)
    VALUES (USER_ID_SEQ.NEXTVAL, p_first_name, p_last_name, p_email, p_phone_number, p_user_password, p_user_type)
    RETURNING USER_ID INTO v_user_id;
    
    -- Call the address procedure with the newly generated user_id
    add_user_address(
        v_user_id,
        p_street_address,
        p_city,
        p_state,
        p_country,
        p_zip_code
    );
    
    -- Commit the transaction after both operations are complete
    COMMIT;
    
EXCEPTION
    WHEN invalid_user_type THEN
        DBMS_OUTPUT.PUT_LINE('Error: USER_TYPE must be Attendee, Organizer, Sponsor, or Venue_Manager');
        ROLLBACK;
    WHEN email_exists THEN
        DBMS_OUTPUT.PUT_LINE('Error: User with email ' || p_email || ' already exists');
        ROLLBACK;
    WHEN phone_exists THEN
        DBMS_OUTPUT.PUT_LINE('Error: User with phone number ' || p_phone_number || ' already exists');
        ROLLBACK;
    WHEN OTHERS THEN
        -- Rollback in case of any errors
        ROLLBACK;
        -- Raise the error to the caller
        RAISE;
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
    v_current_email VARCHAR2(250);
    v_current_phone NUMBER;
    v_current_type VARCHAR2(15);
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

-- Test Case 1: Valid user creation with address
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 1: Valid user creation with address');
    add_user_with_address(
        'John',                  -- First name
        'Doe',                   -- Last name
        'john.doe@example.com',  -- Email
        1234567890,              -- Phone number
        'Password123',           -- Password
        'Attendee',              -- User type (valid)
        '123 Main St',           -- Street address
        'New York',              -- City
        'NY',                    -- State
        'USA',                   -- Country
        10001                    -- Zip code
    );
    DBMS_OUTPUT.PUT_LINE('Test Case 1: Successfully created user and address');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Test Case 1 Error: ' || SQLERRM);
END;
/

-- Test Case 2: Test invalid user type
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 2: Testing invalid user type');
    
    add_user_with_address(
        'Jane',                  -- First name
        'Smith',                 -- Last name
        'jane.smith@example.com',-- Email
        9876543210,              -- Phone number
        'Password456',           -- Password
        'Invalid_Type',          -- User type (invalid)
        '456 Oak Ave',           -- Street address
        'Los Angeles',           -- City
        'CA',                    -- State
        'USA',                   -- Country
        90001                    -- Zip code
    );
    DBMS_OUTPUT.PUT_LINE('Test Case 2: User created - THIS SHOULD NOT DISPLAY');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Test Case 2: Error creating user with invalid type (expected): ' || SQLERRM);
END;
/

-- Test Case 3: Test email uniqueness
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 3: Testing email uniqueness');
    
    -- Try to create another user with the same email
    add_user_with_address(
        'Duplicate',             -- First name
        'Email',                 -- Last name
        'john.doe@example.com',  -- Email (duplicate)
        1117778888,              -- Phone number (unique)
        'Password456',           -- Password
        'Attendee',              -- User type
        '200 Different St',      -- Street address
        'Miami',                 -- City
        'FL',                    -- State
        'USA',                   -- Country
        33101                    -- Zip code
    );
    DBMS_OUTPUT.PUT_LINE('Test Case 3: User created - THIS SHOULD NOT DISPLAY');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Test Case 3: Error creating user with duplicate email (expected): ' || SQLERRM);
END;
/

-- Test Case 4: Test phone number uniqueness
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 4: Testing phone number uniqueness');
    
    -- Try to create another user with the same phone
    add_user_with_address(
        'Duplicate',                  -- First name
        'Phone',                      -- Last name
        'different.email@example.com',-- Email (unique)
        1234567890,                   -- Phone number (duplicate)
        'Password789',                -- Password
        'Attendee',                   -- User type
        '400 Different St',           -- Street address
        'Dallas',                     -- City
        'TX',                         -- State
        'USA',                        -- Country
        75201                         -- Zip code
    );
    DBMS_OUTPUT.PUT_LINE('Test Case 4: User created - THIS SHOULD NOT DISPLAY');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Test Case 4: Error creating user with duplicate phone (expected): ' || SQLERRM);
END;
/

-- Test Case 5: Update user with valid information
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 5: Update user with valid information');
    
    -- Get an existing user ID for testing
    DECLARE
        v_user_id NUMBER;
        v_email VARCHAR2(250);
    BEGIN
        -- Find a user to update
        BEGIN
            SELECT USER_ID, EMAIL INTO v_user_id, v_email
            FROM EVENT_USERS
            WHERE ROWNUM = 1;
            
            DBMS_OUTPUT.PUT_LINE('Test Case 5: Found user ID ' || v_user_id || ' with email ' || v_email);
            
            -- Update the user's name
            update_user(
                p_user_id => v_user_id,
                p_first_name => 'Updated',
                p_last_name => 'User'
            );
            
            DBMS_OUTPUT.PUT_LINE('Test Case 5: Successfully updated user name');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Test Case 5: No users found to update. Test skipped.');
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Test Case 5: Error: ' || SQLERRM);
        END;
    END;
END;
/

-- Test Case 6: Update address with valid information
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 6: Update address with valid information');
    
    DECLARE
        v_user_id NUMBER;
        v_address_id NUMBER;
    BEGIN
        -- Find a user and address for testing
        BEGIN
            SELECT UA.USER_USER_ID, UA.ADDRESS_ID 
            INTO v_user_id, v_address_id
            FROM USER_ADDRESS UA
            WHERE ROWNUM = 1;
            
            DBMS_OUTPUT.PUT_LINE('Test Case 6: Found user ID ' || v_user_id || ' with address ID ' || v_address_id);
            
            -- Update the address
            update_user_address(
                p_address_id => v_address_id,
                p_user_id => v_user_id,
                p_street_address => '123 Updated Street',
                p_city => 'New City'
            );
            
            DBMS_OUTPUT.PUT_LINE('Test Case 6: Successfully updated address');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Test Case 6: No addresses found to update. Test skipped.');
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Test Case 6: Error: ' || SQLERRM);
        END;
    END;
END;
/

-- Test Case 7: Update with invalid user ID
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 7: Update with invalid user ID');
    
    DECLARE
        v_address_id NUMBER;
    BEGIN
        -- Find an address for testing
        BEGIN
            SELECT ADDRESS_ID INTO v_address_id
            FROM USER_ADDRESS
            WHERE ROWNUM = 1;
            
            DBMS_OUTPUT.PUT_LINE('Test Case 7: Found address ID ' || v_address_id);
            
            -- Try to update with invalid user ID
            update_user_address(
                p_address_id => v_address_id,
                p_user_id => 999999,  -- Non-existent user ID
                p_street_address => '456 Invalid User Street'
            );
            
            DBMS_OUTPUT.PUT_LINE('Test Case 7: Update completed - THIS SHOULD NOT DISPLAY');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Test Case 7: No addresses found to test. Test skipped.');
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Test Case 7: Error: ' || SQLERRM);
        END;
    END;
END;
/

-- Test Case 8: Update non-existent address
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 8: Update non-existent address');
    
    DECLARE
        v_user_id NUMBER;
    BEGIN
        -- Find a user for testing
        BEGIN
            SELECT USER_ID INTO v_user_id
            FROM EVENT_USERS
            WHERE ROWNUM = 1;
            
            DBMS_OUTPUT.PUT_LINE('Test Case 8: Found user ID ' || v_user_id);
            
            -- Try to update non-existent address
            update_user_address(
                p_address_id => 999999,  -- Non-existent address ID
                p_user_id => v_user_id,
                p_street_address => '789 Nonexistent Address'
            );
            
            DBMS_OUTPUT.PUT_LINE('Test Case 8: Update completed - THIS SHOULD NOT DISPLAY');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Test Case 8: No users found to test. Test skipped.');
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Test Case 8: Error: ' || SQLERRM);
        END;
    END;
END;
/

-- Test Case 9: Update address that doesn't belong to user
BEGIN
    DBMS_OUTPUT.PUT_LINE('Test Case 9: Update address that doesn''t belong to user');
    
    DECLARE
        v_user_id1 NUMBER;
        v_user_id2 NUMBER;
        v_address_id NUMBER;
    BEGIN
        -- Find two different users and an address belonging to the first user
        BEGIN
            -- First, get a user with an address
            SELECT UA.USER_USER_ID, UA.ADDRESS_ID 
            INTO v_user_id1, v_address_id
            FROM USER_ADDRESS UA
            WHERE ROWNUM = 1;
            
            -- Then, get a different user
            SELECT USER_ID INTO v_user_id2
            FROM EVENT_USERS
            WHERE USER_ID != v_user_id1 AND ROWNUM = 1;
            
            DBMS_OUTPUT.PUT_LINE('Test Case 9: Found user1 ID ' || v_user_id1 || 
                               ', user2 ID ' || v_user_id2 || 
                               ', address ID ' || v_address_id);
            
            -- Try to update user1's address using user2's ID
            update_user_address(
                p_address_id => v_address_id,
                p_user_id => v_user_id2,
                p_street_address => '999 Wrong Owner Street'
            );
            
            DBMS_OUTPUT.PUT_LINE('Test Case 9: Update completed - THIS SHOULD NOT DISPLAY');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Test Case 9: Not enough users/addresses found to test. Test skipped.');
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Test Case 9: Error: ' || SQLERRM);
        END;
    END;
END;
/