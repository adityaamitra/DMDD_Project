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
