CREATE OR REPLACE VIEW SEAT_AVAILABILITY AS
SELECT V.VENUE_ID, V.VENUE_NAME, 
       V.VENUE_CAPACITY - NVL(SUM(R.QUANTITY), 0) AS SEATS_AVAILABLE
FROM VENUE V
LEFT JOIN EVENT_SCHEDULE ES ON V.VENUE_ID = ES.VENUE_VENUE_ID
LEFT JOIN REGISTRATION R ON ES.EVENT_EVENT_ID = R.EVENT_EVENT_ID
GROUP BY V.VENUE_ID, V.VENUE_NAME, V.VENUE_CAPACITY;


CREATE OR REPLACE VIEW EVENT_TICKET_SALES AS
SELECT E.EVENT_ID, E.EVENT_NAME, 
       NVL(SUM(R.TICKET_PRICE * R.QUANTITY), 0) AS TOTAL_TICKET_SALES
FROM EVENT E
LEFT JOIN REGISTRATION R ON E.EVENT_ID = R.EVENT_EVENT_ID
GROUP BY E.EVENT_ID, E.EVENT_NAME;


-- Revenue
CREATE OR REPLACE VIEW EVENT_ADMIN.REPORT_EVENT_PROFIT_LOSS AS
SELECT 
    E.EVENT_ID,
    E.EVENT_NAME,
    E.EVENT_TYPE,
    E.STATUS,
    ES.EVENT_SCHEDULE_DATE,
    O.ORGANIZER_ID,
    O.COMPANY_NAME,
    U.FIRST_NAME || ' ' || U.LAST_NAME AS ORGANIZER_NAME,
    V.VENUE_NAME,
    V.VENUE_CAPACITY,
    COUNT(DISTINCT R.REGISTRATION_ID) AS TOTAL_REGISTRATIONS,
    COUNT(DISTINCT CASE WHEN R.STATUS = 'Confirmed' THEN R.REGISTRATION_ID END) AS CONFIRMED_REGISTRATIONS,
    COUNT(DISTINCT CASE WHEN R.STATUS = 'Cancelled' THEN R.REGISTRATION_ID END) AS CANCELLED_REGISTRATIONS,
    
    -- Revenue calculations
    NVL(SUM(CASE WHEN R.STATUS = 'Confirmed' THEN R.TICKET_PRICE * R.QUANTITY ELSE 0 END), 0) AS TICKET_REVENUE,
    NVL(SUM(S.AMOUNT_SPONSORED), 0) AS SPONSORSHIP_REVENUE,
    NVL(SUM(CASE WHEN R.STATUS = 'Confirmed' THEN R.TICKET_PRICE * R.QUANTITY ELSE 0 END), 0) +
    NVL(SUM(S.AMOUNT_SPONSORED), 0) AS TOTAL_REVENUE,
    
    -- Cost and profit calculations
    E.EVENT_BUDGET AS PLANNED_COST,
    NVL(SUM(CASE WHEN R.STATUS = 'Confirmed' THEN R.TICKET_PRICE * R.QUANTITY ELSE 0 END), 0) +
    NVL(SUM(S.AMOUNT_SPONSORED), 0) - E.EVENT_BUDGET AS PROFIT_LOSS,
    
    -- Financial indicators
    CASE 
        WHEN (NVL(SUM(CASE WHEN R.STATUS = 'Confirmed' THEN R.TICKET_PRICE * R.QUANTITY ELSE 0 END), 0) +
             NVL(SUM(S.AMOUNT_SPONSORED), 0) - E.EVENT_BUDGET) > 0 
        THEN 'Profit' 
        ELSE 'Loss' 
    END AS FINANCIAL_STATUS,
    
    -- Financial ratios
    ROUND(
        (NVL(SUM(CASE WHEN R.STATUS = 'Confirmed' THEN R.TICKET_PRICE * R.QUANTITY ELSE 0 END), 0) +
         NVL(SUM(S.AMOUNT_SPONSORED), 0) - E.EVENT_BUDGET) / 
        NULLIF(E.EVENT_BUDGET, 0) * 100, 
        2
    ) AS PROFIT_MARGIN_PERCENTAGE,
    
    -- Revenue per attendee
    ROUND(
        NVL(SUM(CASE WHEN R.STATUS = 'Confirmed' THEN R.TICKET_PRICE * R.QUANTITY ELSE 0 END), 0) /
        NULLIF(COUNT(DISTINCT CASE WHEN R.STATUS = 'Confirmed' THEN R.REGISTRATION_ID END), 0),
        2
    ) AS REVENUE_PER_ATTENDEE,
    
    -- Capacity utilization
    ROUND(
        COUNT(DISTINCT CASE WHEN R.STATUS = 'Confirmed' THEN R.REGISTRATION_ID END) * 100.0 /
        NULLIF(V.VENUE_CAPACITY, 0),
        2
    ) AS CAPACITY_UTILIZATION_PERCENTAGE,
    
    -- Revenue breakdown
    ROUND(
        NVL(SUM(S.AMOUNT_SPONSORED), 0) * 100.0 /
        NULLIF(NVL(SUM(CASE WHEN R.STATUS = 'Confirmed' THEN R.TICKET_PRICE * R.QUANTITY ELSE 0 END), 0) +
               NVL(SUM(S.AMOUNT_SPONSORED), 0), 0),
        2
    ) AS SPONSORSHIP_REVENUE_PERCENTAGE,
    
    ROUND(
        NVL(SUM(CASE WHEN R.STATUS = 'Confirmed' THEN R.TICKET_PRICE * R.QUANTITY ELSE 0 END), 0) * 100.0 /
        NULLIF(NVL(SUM(CASE WHEN R.STATUS = 'Confirmed' THEN R.TICKET_PRICE * R.QUANTITY ELSE 0 END), 0) +
               NVL(SUM(S.AMOUNT_SPONSORED), 0), 0),
        2
    ) AS TICKET_REVENUE_PERCENTAGE,
    
    -- Break-even analysis
    ROUND(
        E.EVENT_BUDGET /
        NULLIF(AVG(CASE WHEN R.STATUS = 'Confirmed' THEN R.TICKET_PRICE ELSE NULL END), 0),
        0
    ) AS TICKETS_NEEDED_FOR_BREAKEVEN,
    
    -- Sponsor information
    COUNT(DISTINCT S.SPONSOR_ID) AS SPONSOR_COUNT,
    LISTAGG(DISTINCT S.SPONSOR_NAME, ', ') WITHIN GROUP (ORDER BY S.SPONSOR_NAME) AS SPONSORS
FROM 
    EVENT_ADMIN.EVENT E
JOIN 
    EVENT_ADMIN.ORGANIZER O ON E.ORGANIZER_ORGANIZER_ID = O.ORGANIZER_ID
JOIN 
    EVENT_ADMIN.EVENT_USERS U ON O.USER_USER_ID = U.USER_ID
LEFT JOIN 
    EVENT_ADMIN.EVENT_SCHEDULE ES ON E.EVENT_ID = ES.EVENT_EVENT_ID
LEFT JOIN 
    EVENT_ADMIN.VENUE V ON ES.VENUE_VENUE_ID = V.VENUE_ID
LEFT JOIN 
    EVENT_ADMIN.REGISTRATION R ON E.EVENT_ID = R.EVENT_EVENT_ID
LEFT JOIN 
    EVENT_ADMIN.SPONSOR S ON E.EVENT_ID = S.EVENT_EVENT_ID
GROUP BY 
    E.EVENT_ID,
    E.EVENT_NAME,
    E.EVENT_TYPE,
    E.STATUS,
    ES.EVENT_SCHEDULE_DATE,
    O.ORGANIZER_ID,
    O.COMPANY_NAME,
    U.FIRST_NAME || ' ' || U.LAST_NAME,
    V.VENUE_NAME,
    V.VENUE_CAPACITY,
    E.EVENT_BUDGET
ORDER BY 
    ES.EVENT_SCHEDULE_DATE DESC;



-- Grant permissions
GRANT SELECT ON EVENT_ADMIN.REPORT_EVENT_PROFIT_LOSS TO EVENT_ADMIN;
GRANT SELECT ON EVENT_ADMIN.REPORT_EVENT_PROFIT_LOSS TO EVENT_ORGANIZER;






--Feedback

CREATE OR REPLACE VIEW EVENT_ADMIN.REPORT_ORGANIZER_PERFORMANCE AS
WITH EVENT_METRICS AS (
    SELECT 
        O.ORGANIZER_ID,
        O.COMPANY_NAME,
        U.FIRST_NAME || ' ' || U.LAST_NAME AS ORGANIZER_NAME,
        E.EVENT_ID,
        E.EVENT_NAME,
        E.EVENT_BUDGET,
        NVL(SUM(CASE WHEN R.STATUS = 'Confirmed' THEN R.TICKET_PRICE * R.QUANTITY ELSE 0 END), 0) AS TICKET_REVENUE,
        NVL(SUM(S.AMOUNT_SPONSORED), 0) AS SPONSOR_REVENUE,
        ROUND(AVG(ER.RATING), 2) AS EVENT_RATING,
        COUNT(DISTINCT R.REGISTRATION_ID) AS EVENT_REGISTRATIONS
    FROM 
        EVENT_ADMIN.ORGANIZER O
    JOIN 
        EVENT_ADMIN.EVENT_USERS U ON O.USER_USER_ID = U.USER_ID
    LEFT JOIN 
        EVENT_ADMIN.EVENT E ON O.ORGANIZER_ID = E.ORGANIZER_ORGANIZER_ID
    LEFT JOIN 
        EVENT_ADMIN.REGISTRATION R ON E.EVENT_ID = R.EVENT_EVENT_ID
    LEFT JOIN 
        EVENT_ADMIN.EVENT_REVIEW ER ON R.REGISTRATION_ID = ER.REGISTRATION_REGISTRATION_ID
    LEFT JOIN 
        EVENT_ADMIN.SPONSOR S ON E.EVENT_ID = S.EVENT_EVENT_ID
    GROUP BY 
        O.ORGANIZER_ID,
        O.COMPANY_NAME,
        U.FIRST_NAME || ' ' || U.LAST_NAME,
        E.EVENT_ID,
        E.EVENT_NAME,
        E.EVENT_BUDGET
)
SELECT
    ORGANIZER_ID,
    COMPANY_NAME,
    ORGANIZER_NAME,
    COUNT(EVENT_ID) AS TOTAL_EVENTS,
    ROUND(AVG(EVENT_RATING), 2) AS AVERAGE_RATING,
    SUM(TICKET_REVENUE + SPONSOR_REVENUE - EVENT_BUDGET) AS TOTAL_PROFIT_LOSS,
    CASE 
        WHEN SUM(TICKET_REVENUE + SPONSOR_REVENUE - EVENT_BUDGET) > 0 
        THEN 'Overall Profit' 
        ELSE 'Overall Loss' 
    END AS FINANCIAL_STATUS,
    LISTAGG(EVENT_NAME || ' (' || 
            CASE 
                WHEN (TICKET_REVENUE + SPONSOR_REVENUE - EVENT_BUDGET) > 0
                THEN 'Profit: $' || TO_CHAR(TICKET_REVENUE + SPONSOR_REVENUE - EVENT_BUDGET)
                ELSE 'Loss: -$' || TO_CHAR(ABS(TICKET_REVENUE + SPONSOR_REVENUE - EVENT_BUDGET))
            END || 
            ', Rating: ' || COALESCE(TO_CHAR(EVENT_RATING), 'N/A') || 
            ')', ', ') 
    WITHIN GROUP (ORDER BY EVENT_NAME) AS EVENTS_WITH_PERFORMANCE,
    COUNT(CASE WHEN (TICKET_REVENUE + SPONSOR_REVENUE - EVENT_BUDGET) > 0 THEN 1 END) AS PROFITABLE_EVENTS_COUNT,
    COUNT(CASE WHEN (TICKET_REVENUE + SPONSOR_REVENUE - EVENT_BUDGET) <= 0 THEN 1 END) AS LOSS_MAKING_EVENTS_COUNT,
    ROUND(AVG(TICKET_REVENUE + SPONSOR_REVENUE - EVENT_BUDGET), 2) AS AVERAGE_PROFIT_LOSS_PER_EVENT,
    COUNT(CASE WHEN EVENT_RATING >= 4 THEN 1 END) AS HIGH_RATED_EVENTS_COUNT,
    COUNT(CASE WHEN EVENT_RATING < 3 AND EVENT_RATING > 0 THEN 1 END) AS LOW_RATED_EVENTS_COUNT
FROM 
    EVENT_METRICS
GROUP BY
    ORGANIZER_ID,
    COMPANY_NAME,
    ORGANIZER_NAME
ORDER BY 
    AVERAGE_RATING DESC,
    TOTAL_PROFIT_LOSS DESC;


-- Grant permissions
GRANT SELECT ON EVENT_ADMIN.REPORT_ORGANIZER_PERFORMANCE TO EVENT_ADMIN;
GRANT SELECT ON EVENT_ADMIN.REPORT_ORGANIZER_PERFORMANCE TO EVENT_ORGANIZER;


--Sponsorship analysis:
-- Run as: EVENT_ADMIN
CREATE OR REPLACE VIEW EVENT_ADMIN.VIEW_SPONSOR_ANALYSIS AS
WITH SPONSOR_METRICS AS (
    SELECT 
        S.SPONSOR_ID,
        S.SPONSOR_NAME,
        U.FIRST_NAME || ' ' || U.LAST_NAME AS SPONSOR_CONTACT,
        U.EMAIL AS CONTACT_EMAIL,
        E.EVENT_ID,
        E.EVENT_NAME,
        E.EVENT_TYPE,
        E.STATUS AS EVENT_STATUS,
        ES.EVENT_SCHEDULE_DATE,
        V.VENUE_NAME,
        V.VENUE_CAPACITY,
        S.AMOUNT_SPONSORED,
        COUNT(DISTINCT R.REGISTRATION_ID) AS TOTAL_REGISTRATIONS,
        COUNT(DISTINCT CASE WHEN R.STATUS = 'Confirmed' THEN R.REGISTRATION_ID END) AS CONFIRMED_ATTENDEES,
        ROUND(AVG(NVL(ER.RATING, 0)), 2) AS EVENT_RATING,
        COUNT(DISTINCT ER.FEEDBACK_ID) AS FEEDBACK_COUNT
    FROM 
        EVENT_ADMIN.SPONSOR S
    JOIN 
        EVENT_ADMIN.EVENT_USERS U ON S.USER_USER_ID = U.USER_ID
    JOIN 
        EVENT_ADMIN.EVENT E ON S.EVENT_EVENT_ID = E.EVENT_ID
    LEFT JOIN 
        EVENT_ADMIN.EVENT_SCHEDULE ES ON E.EVENT_ID = ES.EVENT_EVENT_ID
    LEFT JOIN 
        EVENT_ADMIN.VENUE V ON ES.VENUE_VENUE_ID = V.VENUE_ID
    LEFT JOIN 
        EVENT_ADMIN.REGISTRATION R ON E.EVENT_ID = R.EVENT_EVENT_ID
    LEFT JOIN 
        EVENT_ADMIN.EVENT_REVIEW ER ON R.REGISTRATION_ID = ER.REGISTRATION_REGISTRATION_ID
    GROUP BY 
        S.SPONSOR_ID,
        S.SPONSOR_NAME,
        U.FIRST_NAME || ' ' || U.LAST_NAME,
        U.EMAIL,
        E.EVENT_ID,
        E.EVENT_NAME,
        E.EVENT_TYPE,
        E.STATUS,
        ES.EVENT_SCHEDULE_DATE,
        V.VENUE_NAME,
        V.VENUE_CAPACITY,
        S.AMOUNT_SPONSORED
)
SELECT
    SPONSOR_ID,
    SPONSOR_NAME,
    SPONSOR_CONTACT,
    CONTACT_EMAIL,
    COUNT(DISTINCT EVENT_ID) AS TOTAL_EVENTS_SPONSORED,
    SUM(AMOUNT_SPONSORED) AS TOTAL_SPONSORSHIP_AMOUNT,
    ROUND(AVG(AMOUNT_SPONSORED), 2) AS AVERAGE_SPONSORSHIP_AMOUNT,
    SUM(CONFIRMED_ATTENDEES) AS TOTAL_ATTENDEES_REACHED,
    ROUND(SUM(AMOUNT_SPONSORED) / NULLIF(SUM(CONFIRMED_ATTENDEES), 0), 2) AS COST_PER_ATTENDEE,
    
    -- Event rating metrics
    ROUND(AVG(EVENT_RATING), 2) AS AVERAGE_EVENT_RATING,
    COUNT(CASE WHEN EVENT_RATING >= 4 THEN 1 END) AS HIGH_RATED_EVENTS_COUNT,
    ROUND(
        COUNT(CASE WHEN EVENT_RATING >= 4 THEN 1 END) * 100.0 / 
        NULLIF(COUNT(DISTINCT CASE WHEN EVENT_RATING > 0 THEN EVENT_ID END), 0),
        2
    ) AS HIGH_RATED_EVENTS_PERCENTAGE,
    
    -- Event utilization metrics
    ROUND(
        SUM(CONFIRMED_ATTENDEES) * 100.0 / 
        NULLIF(SUM(VENUE_CAPACITY), 0),
        2
    ) AS AVERAGE_VENUE_UTILIZATION_PERCENTAGE,
    
    -- Event type breakdown
    LISTAGG(DISTINCT EVENT_TYPE, ', ') WITHIN GROUP (ORDER BY EVENT_TYPE) AS SPONSORED_EVENT_TYPES,
    
    -- Top event by attendance
    (
        SELECT EVENT_NAME || ' (' || CONFIRMED_ATTENDEES || ' attendees, $' || AMOUNT_SPONSORED || ' sponsored)'
        FROM SPONSOR_METRICS SM
        WHERE SM.SPONSOR_ID = SPONSOR_METRICS.SPONSOR_ID
        ORDER BY CONFIRMED_ATTENDEES DESC, EVENT_SCHEDULE_DATE DESC
        FETCH FIRST 1 ROW ONLY
    ) AS TOP_EVENT_BY_ATTENDANCE,
    
    -- Top event by rating
    (
        SELECT EVENT_NAME || ' (Rating: ' || EVENT_RATING || ', $' || AMOUNT_SPONSORED || ' sponsored)'
        FROM SPONSOR_METRICS SM
        WHERE SM.SPONSOR_ID = SPONSOR_METRICS.SPONSOR_ID AND EVENT_RATING > 0
        ORDER BY EVENT_RATING DESC, CONFIRMED_ATTENDEES DESC
        FETCH FIRST 1 ROW ONLY
    ) AS TOP_EVENT_BY_RATING,
    
    -- Events sponsored with details
    LISTAGG(
        EVENT_NAME || ' (' || 
        TO_CHAR(EVENT_SCHEDULE_DATE, 'YYYY-MM-DD') || ', ' ||
        CONFIRMED_ATTENDEES || ' attendees, ' ||
        '$' || AMOUNT_SPONSORED || ' sponsored, ' ||
        'Rating: ' || COALESCE(TO_CHAR(EVENT_RATING), 'N/A') ||
        ')', '; '
    ) WITHIN GROUP (ORDER BY EVENT_SCHEDULE_DATE DESC) AS SPONSORED_EVENTS_DETAILS,
    
    -- Sponsorship ROI metrics
    ROUND(SUM(FEEDBACK_COUNT) * 100.0 / NULLIF(SUM(CONFIRMED_ATTENDEES), 0), 2) AS FEEDBACK_RATE_PERCENTAGE,
    ROUND(SUM(AMOUNT_SPONSORED) / NULLIF(COUNT(DISTINCT EVENT_ID), 0), 2) AS AVERAGE_SPONSORSHIP_PER_EVENT
FROM 
    SPONSOR_METRICS
GROUP BY
    SPONSOR_ID,
    SPONSOR_NAME,
    SPONSOR_CONTACT,
    CONTACT_EMAIL
ORDER BY 
    TOTAL_SPONSORSHIP_AMOUNT DESC,
    TOTAL_EVENTS_SPONSORED DESC;



-- Grant permissions
GRANT SELECT ON EVENT_ADMIN.VIEW_SPONSOR_ANALYSIS TO EVENT_ADMIN;
GRANT SELECT ON EVENT_ADMIN.VIEW_SPONSOR_ANALYSIS TO EVENT_SPONSOR;



--Attendee
-- Run as: EVENT_ADMIN
CREATE OR REPLACE VIEW EVENT_ADMIN.VIEW_ATTENDEE_EVENT_HISTORY AS
WITH ATTENDEE_METRICS AS (
    SELECT 
        A.ATTENDEE_ID,
        A.FIRST_NAME,
        A.LAST_NAME,
        U.EMAIL,
        U.PHONE_NUMBER,
        R.REGISTRATION_ID,
        R.REGISTRATION_DATE,
        R.STATUS AS REGISTRATION_STATUS,
        R.TICKET_PRICE,
        R.QUANTITY,
        R.TICKET_PRICE * R.QUANTITY AS TOTAL_AMOUNT,
        E.EVENT_ID,
        E.EVENT_NAME,
        E.EVENT_TYPE,
        E.STATUS AS EVENT_STATUS,
        ES.EVENT_SCHEDULE_DATE,
        ES.START_TIME,
        ES.END_TIME,
        V.VENUE_NAME,
        V.VENUE_CAPACITY,
        O.COMPANY_NAME AS ORGANIZER_COMPANY,
        ER.RATING,
        ER.REVIEW,
        P.PAYMENT_ID,
        P.PAYMENT_METHOD,
        P.PAYMENT_STATUS,
        P.PAYMENT_DATE
    FROM 
        EVENT_ADMIN.ATTENDEE A
    JOIN 
        EVENT_ADMIN.EVENT_USERS U ON A.USER_USER_ID = U.USER_ID
    LEFT JOIN 
        EVENT_ADMIN.REGISTRATION R ON A.ATTENDEE_ID = R.ATTENDEE_ATTENDEE_ID
    LEFT JOIN 
        EVENT_ADMIN.EVENT E ON R.EVENT_EVENT_ID = E.EVENT_ID
    LEFT JOIN 
        EVENT_ADMIN.EVENT_SCHEDULE ES ON E.EVENT_ID = ES.EVENT_EVENT_ID
    LEFT JOIN 
        EVENT_ADMIN.VENUE V ON ES.VENUE_VENUE_ID = V.VENUE_ID
    LEFT JOIN 
        EVENT_ADMIN.ORGANIZER O ON E.ORGANIZER_ORGANIZER_ID = O.ORGANIZER_ID
    LEFT JOIN 
        EVENT_ADMIN.EVENT_REVIEW ER ON R.REGISTRATION_ID = ER.REGISTRATION_REGISTRATION_ID
    LEFT JOIN 
        EVENT_ADMIN.PAYMENT P ON R.REGISTRATION_ID = P.REGISTRATION_REGISTRATION_ID
)
SELECT
    ATTENDEE_ID,
    FIRST_NAME || ' ' || LAST_NAME AS ATTENDEE_NAME,
    EMAIL,
    PHONE_NUMBER,
    COUNT(DISTINCT REGISTRATION_ID) AS TOTAL_REGISTRATIONS,
    COUNT(DISTINCT CASE WHEN REGISTRATION_STATUS = 'Confirmed' THEN REGISTRATION_ID END) AS CONFIRMED_REGISTRATIONS,
    COUNT(DISTINCT CASE WHEN REGISTRATION_STATUS = 'Cancelled' THEN REGISTRATION_ID END) AS CANCELLED_REGISTRATIONS,
    COUNT(DISTINCT EVENT_ID) AS UNIQUE_EVENTS_ATTENDED,
    
    -- Financial metrics
    SUM(TOTAL_AMOUNT) AS TOTAL_SPENT,
    ROUND(AVG(TICKET_PRICE), 2) AS AVERAGE_TICKET_PRICE,
    MAX(TICKET_PRICE) AS HIGHEST_TICKET_PRICE,
    MIN(CASE WHEN REGISTRATION_STATUS = 'Confirmed' THEN TICKET_PRICE END) AS LOWEST_TICKET_PRICE,
    
    -- Event type preferences
    LISTAGG(DISTINCT EVENT_TYPE, ', ') WITHIN GROUP (ORDER BY EVENT_TYPE) AS EVENT_TYPES_ATTENDED,
    (
        SELECT EVENT_TYPE
        FROM (
            SELECT EVENT_TYPE, COUNT(*) AS TYPE_COUNT
            FROM ATTENDEE_METRICS AM
            WHERE AM.ATTENDEE_ID = ATTENDEE_METRICS.ATTENDEE_ID
            AND REGISTRATION_STATUS = 'Confirmed'
            GROUP BY EVENT_TYPE
            ORDER BY TYPE_COUNT DESC
        )
        WHERE ROWNUM = 1
    ) AS MOST_ATTENDED_EVENT_TYPE,
    
    -- Rating metrics
    ROUND(AVG(RATING), 2) AS AVERAGE_RATING_GIVEN,
    COUNT(DISTINCT CASE WHEN RATING IS NOT NULL THEN REGISTRATION_ID END) AS REVIEWS_SUBMITTED,
    
    -- Venue preferences
    LISTAGG(DISTINCT VENUE_NAME, ', ') WITHIN GROUP (ORDER BY VENUE_NAME) AS VENUES_VISITED,
    
    -- Recent activity
    (
        SELECT EVENT_NAME || ' (' || TO_CHAR(EVENT_SCHEDULE_DATE, 'YYYY-MM-DD') || ')'
        FROM ATTENDEE_METRICS AM
        WHERE AM.ATTENDEE_ID = ATTENDEE_METRICS.ATTENDEE_ID
        AND REGISTRATION_STATUS = 'Confirmed'
        ORDER BY EVENT_SCHEDULE_DATE DESC
        FETCH FIRST 1 ROW ONLY
    ) AS MOST_RECENT_EVENT,
    
    -- Upcoming events
    (
        SELECT COUNT(*)
        FROM ATTENDEE_METRICS AM
        WHERE AM.ATTENDEE_ID = ATTENDEE_METRICS.ATTENDEE_ID
        AND REGISTRATION_STATUS = 'Confirmed'
        AND EVENT_SCHEDULE_DATE > SYSDATE
    ) AS UPCOMING_EVENTS_COUNT,
    
    -- Detailed event history
    LISTAGG(
        EVENT_NAME || ' (' || 
        EVENT_TYPE || ', ' ||
        TO_CHAR(EVENT_SCHEDULE_DATE, 'YYYY-MM-DD') || ', ' ||
        VENUE_NAME || ', ' ||
        '$' || TOTAL_AMOUNT || ', ' ||
        REGISTRATION_STATUS ||
        CASE WHEN RATING IS NOT NULL THEN ', Rating: ' || RATING ELSE '' END ||
        ')', '; '
    ) WITHIN GROUP (ORDER BY EVENT_SCHEDULE_DATE DESC) AS EVENT_HISTORY,
    
    -- Payment method preferences
    LISTAGG(DISTINCT PAYMENT_METHOD, ', ') WITHIN GROUP (ORDER BY PAYMENT_METHOD) AS PAYMENT_METHODS_USED,
    (
        SELECT PAYMENT_METHOD
        FROM (
            SELECT PAYMENT_METHOD, COUNT(*) AS METHOD_COUNT
            FROM ATTENDEE_METRICS AM
            WHERE AM.ATTENDEE_ID = ATTENDEE_METRICS.ATTENDEE_ID
            AND PAYMENT_METHOD IS NOT NULL
            GROUP BY PAYMENT_METHOD
            ORDER BY METHOD_COUNT DESC
        )
        WHERE ROWNUM = 1
    ) AS PREFERRED_PAYMENT_METHOD,
    
    -- Spending trend
    CASE 
        WHEN COUNT(DISTINCT REGISTRATION_ID) > 1 AND 
             MAX(CASE WHEN REGISTRATION_STATUS = 'Confirmed' THEN TICKET_PRICE END) > 
             MIN(CASE WHEN REGISTRATION_STATUS = 'Confirmed' THEN TICKET_PRICE END)
        THEN 'Increasing'
        WHEN COUNT(DISTINCT REGISTRATION_ID) > 1 AND 
             MAX(CASE WHEN REGISTRATION_STATUS = 'Confirmed' THEN TICKET_PRICE END) < 
             MIN(CASE WHEN REGISTRATION_STATUS = 'Confirmed' THEN TICKET_PRICE END)
        THEN 'Decreasing'
        ELSE 'Stable'
    END AS TICKET_PRICE_TREND
FROM 
    ATTENDEE_METRICS
GROUP BY
    ATTENDEE_ID,
    FIRST_NAME,
    LAST_NAME,
    EMAIL,
    PHONE_NUMBER
ORDER BY 
    TOTAL_SPENT DESC;



-- Grant permissions
GRANT SELECT ON EVENT_ADMIN.VIEW_ATTENDEE_EVENT_HISTORY TO EVENT_ADMIN;
GRANT SELECT ON EVENT_ADMIN.VIEW_ATTENDEE_EVENT_HISTORY TO EVENT_ATTENDEE;




--Venue analysis
-- Run as: EVENT_ADMIN
CREATE OR REPLACE VIEW EVENT_ADMIN.VIEW_VENUE_ANALYSIS AS
WITH VENUE_METRICS AS (
    SELECT 
        V.VENUE_ID,
        V.VENUE_NAME,
        V.VENUE_CAPACITY,
        U.FIRST_NAME || ' ' || U.LAST_NAME AS VENUE_MANAGER,
        U.EMAIL AS MANAGER_EMAIL,
        ES.SCHEDULE_ID,
        ES.EVENT_SCHEDULE_DATE,
        ES.START_TIME,
        ES.END_TIME,
        E.EVENT_ID,
        E.EVENT_NAME,
        E.EVENT_TYPE,
        E.STATUS AS EVENT_STATUS,
        E.EVENT_BUDGET,
        O.ORGANIZER_ID,
        O.COMPANY_NAME AS ORGANIZER_COMPANY,
        COUNT(DISTINCT R.REGISTRATION_ID) AS EVENT_REGISTRATIONS,
        COUNT(DISTINCT CASE WHEN R.STATUS = 'Confirmed' THEN R.REGISTRATION_ID END) AS CONFIRMED_ATTENDEES,
        NVL(SUM(CASE WHEN R.STATUS = 'Confirmed' THEN R.TICKET_PRICE * R.QUANTITY ELSE 0 END), 0) AS TICKET_REVENUE,
        NVL(SUM(S.AMOUNT_SPONSORED), 0) AS SPONSORSHIP_AMOUNT,
        ROUND(AVG(ER.RATING), 2) AS EVENT_RATING
    FROM 
        EVENT_ADMIN.VENUE V
    JOIN 
        EVENT_ADMIN.EVENT_USERS U ON V.USER_USER_ID = U.USER_ID
    LEFT JOIN 
        EVENT_ADMIN.EVENT_SCHEDULE ES ON V.VENUE_ID = ES.VENUE_VENUE_ID
    LEFT JOIN 
        EVENT_ADMIN.EVENT E ON ES.EVENT_EVENT_ID = E.EVENT_ID
    LEFT JOIN 
        EVENT_ADMIN.ORGANIZER O ON E.ORGANIZER_ORGANIZER_ID = O.ORGANIZER_ID
    LEFT JOIN 
        EVENT_ADMIN.REGISTRATION R ON E.EVENT_ID = R.EVENT_EVENT_ID
    LEFT JOIN 
        EVENT_ADMIN.EVENT_REVIEW ER ON R.REGISTRATION_ID = ER.REGISTRATION_REGISTRATION_ID
    LEFT JOIN 
        EVENT_ADMIN.SPONSOR S ON E.EVENT_ID = S.EVENT_EVENT_ID
    GROUP BY 
        V.VENUE_ID,
        V.VENUE_NAME,
        V.VENUE_CAPACITY,
        U.FIRST_NAME || ' ' || U.LAST_NAME,
        U.EMAIL,
        ES.SCHEDULE_ID,
        ES.EVENT_SCHEDULE_DATE,
        ES.START_TIME,
        ES.END_TIME,
        E.EVENT_ID,
        E.EVENT_NAME,
        E.EVENT_TYPE,
        E.STATUS,
        E.EVENT_BUDGET,
        O.ORGANIZER_ID,
        O.COMPANY_NAME
)
SELECT
    VENUE_ID,
    VENUE_NAME,
    VENUE_CAPACITY,
    VENUE_MANAGER,
    MANAGER_EMAIL,
    COUNT(DISTINCT SCHEDULE_ID) AS TOTAL_EVENTS_HOSTED,
    COUNT(DISTINCT EVENT_ID) AS UNIQUE_EVENTS,
    COUNT(DISTINCT CASE WHEN EVENT_SCHEDULE_DATE > SYSDATE THEN SCHEDULE_ID END) AS UPCOMING_EVENTS,
    
    -- Venue utilization metrics
    ROUND(AVG(CONFIRMED_ATTENDEES), 0) AS AVERAGE_ATTENDEES_PER_EVENT,
    ROUND(MAX(CONFIRMED_ATTENDEES), 0) AS MAX_ATTENDEES,
    ROUND(AVG(CONFIRMED_ATTENDEES) * 100 / NULLIF(VENUE_CAPACITY, 0), 2) AS AVERAGE_CAPACITY_UTILIZATION,
    ROUND(MAX(CONFIRMED_ATTENDEES) * 100 / NULLIF(VENUE_CAPACITY, 0), 2) AS MAX_CAPACITY_UTILIZATION,
    
    -- Event diversity metrics
    COUNT(DISTINCT EVENT_TYPE) AS EVENT_TYPE_DIVERSITY,
    LISTAGG(DISTINCT EVENT_TYPE, ', ') WITHIN GROUP (ORDER BY EVENT_TYPE) AS EVENT_TYPES_HOSTED,
    (
        SELECT EVENT_TYPE
        FROM (
            SELECT EVENT_TYPE, COUNT(*) AS TYPE_COUNT
            FROM VENUE_METRICS VM
            WHERE VM.VENUE_ID = VENUE_METRICS.VENUE_ID
            GROUP BY EVENT_TYPE
            ORDER BY TYPE_COUNT DESC
        )
        WHERE ROWNUM = 1
    ) AS MOST_COMMON_EVENT_TYPE,
    
    -- Organizer metrics
    COUNT(DISTINCT ORGANIZER_ID) AS UNIQUE_ORGANIZERS,
    LISTAGG(DISTINCT ORGANIZER_COMPANY, ', ') WITHIN GROUP (ORDER BY ORGANIZER_COMPANY) AS ORGANIZER_COMPANIES,
    
    -- Attendee metrics
    SUM(CONFIRMED_ATTENDEES) AS TOTAL_ATTENDEES,
    SUM(EVENT_REGISTRATIONS) AS TOTAL_REGISTRATIONS,
    
    -- Revenue metrics
    SUM(TICKET_REVENUE) AS TOTAL_TICKET_REVENUE,
    SUM(SPONSORSHIP_AMOUNT) AS TOTAL_SPONSORSHIP_AMOUNT,
    SUM(TICKET_REVENUE + SPONSORSHIP_AMOUNT) AS TOTAL_REVENUE,
    ROUND(AVG(TICKET_REVENUE), 2) AS AVERAGE_TICKET_REVENUE_PER_EVENT,
    
    -- Rating metrics
    ROUND(AVG(EVENT_RATING), 2) AS AVERAGE_EVENT_RATING,
    COUNT(DISTINCT CASE WHEN EVENT_RATING >= 4 THEN EVENT_ID END) AS HIGH_RATED_EVENTS_COUNT,
    ROUND(
        COUNT(DISTINCT CASE WHEN EVENT_RATING >= 4 THEN EVENT_ID END) * 100.0 / 
        NULLIF(COUNT(DISTINCT CASE WHEN EVENT_RATING > 0 THEN EVENT_ID END), 0),
        2
    ) AS HIGH_RATED_EVENTS_PERCENTAGE,
    
    -- Time utilization metrics
    COUNT(DISTINCT TO_CHAR(EVENT_SCHEDULE_DATE, 'YYYY-MM')) AS MONTHS_UTILIZED,
    ROUND(COUNT(DISTINCT SCHEDULE_ID) / 
          NULLIF(MONTHS_BETWEEN(MAX(EVENT_SCHEDULE_DATE), MIN(EVENT_SCHEDULE_DATE)) + 1, 0), 2) AS EVENTS_PER_MONTH,
    
    -- Seasonal analysis
    LISTAGG(DISTINCT TO_CHAR(EVENT_SCHEDULE_DATE, 'MON'), ', ') 
        WITHIN GROUP (ORDER BY TO_CHAR(EVENT_SCHEDULE_DATE, 'MM')) AS ACTIVE_MONTHS,
    
    -- Most successful events
    (
        SELECT EVENT_NAME || ' (' || EVENT_TYPE || ', ' || 
               TO_CHAR(EVENT_SCHEDULE_DATE, 'YYYY-MM-DD') || ', ' || 
               CONFIRMED_ATTENDEES || ' attendees, ' ||
               'Rating: ' || EVENT_RATING || ')'
        FROM VENUE_METRICS VM
        WHERE VM.VENUE_ID = VENUE_METRICS.VENUE_ID
        AND EVENT_RATING IS NOT NULL
        ORDER BY EVENT_RATING DESC, CONFIRMED_ATTENDEES DESC
        FETCH FIRST 1 ROW ONLY
    ) AS TOP_RATED_EVENT,
    
    (
        SELECT EVENT_NAME || ' (' || EVENT_TYPE || ', ' || 
               TO_CHAR(EVENT_SCHEDULE_DATE, 'YYYY-MM-DD') || ', ' || 
               CONFIRMED_ATTENDEES || ' attendees, ' ||
               '$' || TICKET_REVENUE || ' revenue)'
        FROM VENUE_METRICS VM
        WHERE VM.VENUE_ID = VENUE_METRICS.VENUE_ID
        ORDER BY TICKET_REVENUE DESC
        FETCH FIRST 1 ROW ONLY
    ) AS HIGHEST_REVENUE_EVENT,
    
    (
        SELECT EVENT_NAME || ' (' || EVENT_TYPE || ', ' || 
               TO_CHAR(EVENT_SCHEDULE_DATE, 'YYYY-MM-DD') || ', ' || 
               CONFIRMED_ATTENDEES || ' attendees, ' ||
               ROUND(CONFIRMED_ATTENDEES * 100 / NULLIF(VENUE_CAPACITY, 0), 0) || '% capacity)'
        FROM VENUE_METRICS VM
        WHERE VM.VENUE_ID = VENUE_METRICS.VENUE_ID
        ORDER BY CONFIRMED_ATTENDEES DESC
        FETCH FIRST 1 ROW ONLY
    ) AS HIGHEST_ATTENDANCE_EVENT,
    
    -- Recent events
    (
        SELECT COUNT(*)
        FROM VENUE_METRICS VM
        WHERE VM.VENUE_ID = VENUE_METRICS.VENUE_ID
        AND EVENT_SCHEDULE_DATE BETWEEN SYSDATE - 30 AND SYSDATE
    ) AS EVENTS_LAST_30_DAYS
FROM 
    VENUE_METRICS
GROUP BY
    VENUE_ID,
    VENUE_NAME,
    VENUE_CAPACITY,
    VENUE_MANAGER,
    MANAGER_EMAIL
ORDER BY 
    TOTAL_EVENTS_HOSTED DESC,
    AVERAGE_CAPACITY_UTILIZATION DESC;



-- Grant permissions
GRANT SELECT ON EVENT_ADMIN.VIEW_VENUE_ANALYSIS TO EVENT_ADMIN;
GRANT SELECT ON EVENT_ADMIN.VIEW_VENUE_ANALYSIS TO VENUE_MANAGER;