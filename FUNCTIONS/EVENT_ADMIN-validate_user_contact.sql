CREATE OR REPLACE FUNCTION validate_user_contact(
    PHONE_NUMBER  IN NUMBER,
    EMAIL         IN VARCHAR2
) RETURN NUMBER
IS
    phone_regex VARCHAR2(100) := '^[0-9]{10}$';
    email_regex VARCHAR2(100) := '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';
BEGIN
    -- Handle NULL inputs
    IF PHONE_NUMBER IS NULL OR EMAIL IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Convert phone number to string and validate
    IF NOT REGEXP_LIKE(TO_CHAR(PHONE_NUMBER), phone_regex) THEN
        RETURN 0;
    ELSIF NOT REGEXP_LIKE(EMAIL, email_regex) THEN
        RETURN 0;
    ELSE
        RETURN 1;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- Test SQL statements for the updated function

-- Test 1: Valid phone and email
SELECT validate_user_contact(1234567890, 'test@example.com') AS result FROM dual;

-- Test 2: NULL phone
SELECT validate_user_contact(NULL, 'test@example.com') AS result FROM dual;

-- Test 3: NULL email
SELECT validate_user_contact(1234567890, NULL) AS result FROM dual;

-- Test 4: Phone with too few digits
SELECT validate_user_contact(123456789, 'test@example.com') AS result FROM dual;

-- Test 5: Phone with too many digits
SELECT validate_user_contact(12345678901, 'test@example.com') AS result FROM dual;

-- Test 6: Invalid email (no @ symbol)
SELECT validate_user_contact(1234567890, 'invalid_email') AS result FROM dual;

-- Test 7: Invalid email (no domain)
SELECT validate_user_contact(1234567890, 'test@') AS result FROM dual;

-- Test 8: Invalid email (no TLD)
SELECT validate_user_contact(1234567890, 'test@domain') AS result FROM dual;

-- Test 9: Leading zeros in phone (will be stored as 123456789, which is invalid)
SELECT validate_user_contact(0123456789, 'test@example.com') AS result FROM dual;

-- Test 10: Email with longer TLD (> 4 chars, invalid with current regex)
SELECT validate_user_contact(1234567890, 'test@example.technology') AS result FROM dual;

-- Test 11: Complex but valid email with current regex
SELECT validate_user_contact(1234567890, 'user.name+tag@example.co.uk') AS result FROM dual;