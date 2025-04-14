-- Organizer with permissions on events, venues, and schedules

GRANT SELECT, INSERT, UPDATE, DELETE ON EVENT TO EVENT_ORGANIZER;
GRANT SELECT, INSERT, UPDATE, DELETE ON VENUE TO EVENT_ORGANIZER;
GRANT SELECT, INSERT, UPDATE, DELETE ON EVENT_SCHEDULE TO EVENT_ORGANIZER;

-- Sponsor with permissions on sponsor-related tables
GRANT SELECT, INSERT, UPDATE, DELETE ON SPONSOR TO EVENT_SPONSOR;

-- Attendee with permissions on registration, feedback, and payments
GRANT SELECT, INSERT, UPDATE, DELETE ON REGISTRATION TO EVENT_ATTENDEE;
GRANT SELECT, INSERT, UPDATE, DELETE ON EVENT_REVIEW TO EVENT_ATTENDEE;
GRANT SELECT, INSERT, UPDATE, DELETE ON PAYMENT TO EVENT_ATTENDEE;
GRANT SELECT, INSERT, UPDATE, DELETE ON ATTENDEE TO EVENT_ATTENDEE;

GRANT SELECT, INSERT, UPDATE, DELETE ON VENUE TO VENUE_MANAGER;
-- Viewer with read-only access
GRANT SELECT ON EVENT TO EVENT_VIEWER;
GRANT SELECT ON VENUE TO EVENT_VIEWER;
GRANT SELECT ON EVENT_SCHEDULE TO EVENT_VIEWER;
GRANT SELECT ON REGISTRATION TO EVENT_VIEWER;

-- Additional Grants for Foreign Key References
GRANT SELECT ON EVENT_USERS TO EVENT_ORGANIZER, EVENT_SPONSOR, EVENT_ATTENDEE;
GRANT SELECT ON EVENT TO EVENT_SPONSOR, EVENT_ATTENDEE;
GRANT SELECT ON VENUE TO EVENT_ATTENDEE, EVENT_SPONSOR;

-- Commit Changes
COMMIT;