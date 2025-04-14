Project Setup Instructions
Step 1: User Creation
1.	Open the Setup folder from the main branch.
2.	Run the UserCreation.sql file using the ADMIN user.
o	This will create the following users:
	EVENT_ADMIN
	EVENT_ORGANIZER
	EVENT_SPONSOR
	EVENT_ATTENDEE
	EVENT_VIEWER
	VENUE_MANAGER
o	The EVENT_ADMIN user will be granted admin rights.
Step 2: Table Creation
1.	Open the Table folder in the main branch.
2.	Run the Table_Creation.sql file using the EVENT_ADMIN user.
o	This will create all the necessary tables.
Step 3: Grant Permissions
1.	Open the Permission folder in the main branch.
2.	Run the Permission_granted.sql file using the EVENT_ADMIN user.
o	This will grant the required permissions.
Step 4: Insert Dummy Data
1.	Open the Dummy_input_data folder.
2.	Run the input_data.sql file using the EVENT_ADMIN user.
o	This will feed dummy data into all the tables.
Step 5: Create Views
1.	Open the Views folder from the main branch.
2.	Run the views.sql file.
o	This will create the following views:
	Seat Availability
	Total Ticket Sales
	Organizer Revenue
Step 6: Check Views
To check the views, run the following SQL queries:
SELECT * FROM SEAT_AVAILABILITY;
SELECT * FROM EVENT_TICKET_SALES;
SELECT * FROM ORGANIZER_REVENUE;
User Passwords
•	Passwords for each user are provided in the EVENT_ADMIN file.

 
Business Rules:

1.	An organizer can manage multiple events, but each event is managed by one organizer.
2.	Attendees can register for multiple events.
3.	Payments are linked to registrations, and a registration can have only one payment.
4.	Events can have multiple sponsors, but a sponsor can sponsor only events they are associated with.
5.	Event schedules are tied to venues, with one schedule per venue at a given time.
6.	Each registration can receive feedback once, and feedback is linked to the registration.
7.	Ticket prices are event-specific, and registration status must be maintained.
8.	Each user must have a email and phone number.

Normalization Process:
1st Normal Form (1NF)
•	Ensured all columns contain atomic data (no repeating groups).
•	Separate tables for entities like User, Organizer, Attendee, Venue, Event, Sponsor, Registration, Payment, Event Review, and Event Schedule.
2nd Normal Form (2NF)
•	Ensured no partial dependency by creating separate tables for dependent data.
•	Event Reviews are linked to both Registration and Event, removing redundancy.
•	Sponsor table has a composite primary key with Sponsor_ID and Event_ID to ensure proper relationships.
3rd Normal Form (3NF)
•	Removed transitive dependencies by creating new tables where necessary.
•	Address data is separated into its own table, linked to User by USER_ID.
•	Payment table stores payment information directly related to the registration, avoiding redundancy.
Boyce-Codd Normal Form (BCNF)
•	Ensured all determinants are candidate keys.
•	Any anomalies in the Sponsor and Event tables were resolved.
 
Validations and Constraints
User Constraints:
o	Email, First Name, and Last Name cannot be blank.
o	Phone Number must be NOT NULL and numeric.
o	User Type should be one of: 'Attendee', 'Organizer', ‘Venue_Manager’, or 'Sponsor'.
Event Constraints:
o	Event Name cannot be blank.
o	Status must be either 'Scheduled', 'Completed', or 'Cancelled'.
o	Event Budget must be greater than zero.
Registration Constraints:
o	Ticket Quantity cannot be zero or negative.
o	Ticket Price should be greater than zero.
o	Status should be one of: 'Confirmed', 'Pending', or 'Cancelled'.
Payment Constraints:
o	Payment Amount should be greater than zero.
o	Payment Status must be one of: 'Paid', 'Pending', or 'Failed'.
Event Review Constraints:
o	Ratings must be between 1 and 5.
o	Review text should not exceed 250 characters.
Venue Constraints:
o	Venue Capacity must be greater than zero.
o	Venue Name cannot be empty.
Sponsor Constraints:
o	Amount Sponsored must be a positive number.
General Rules:
o	Auto registration when a product's quantity on hand falls below the threshold value (for events with limited seats).
o	Discount is applied before tax calculation, not after.
o	No further discount or promotion on perishable or non-eligible event categories.


