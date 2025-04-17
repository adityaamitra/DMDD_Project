# Event Management System - Database Project

## Overview

This project implements a comprehensive event management system database with role-based access control. The system enables various users (admins, organizers, sponsors, attendees, and venue managers) to interact with the database based on their specific roles and permissions.

## Project Structure

The repository is organized into the following key components:

- **SETUP**: Contains scripts for creating user accounts and roles
- **Tables**: Contains SQL scripts for creating database tables
- **Permissions**: Contains scripts for granting appropriate permissions to users
- **Dummy_input_data**: Contains scripts for populating tables with sample data
- **Views**: Contains SQL views for common data access patterns
- **FUNCTIONS**: Contains database functions for specific operations
- **STORED_PROCEDURES**: Contains stored procedures for complex operations
- **TRIGGERS**: Contains database triggers for data integrity and automation
- **SEQUENCES**: Contains sequences for all necessary tables
- **REPORTS**: Contains Analytical Reports

## Prerequisites

- Oracle Database (compatible with Oracle SQL syntax)
- Oracle SQL Developer or similar database management tool
- Administrative access to create users and manage permissions

## Installation and Setup

### Step 1: User Creation

1. Connect to your Oracle database as the ADMIN user
2. Navigate to the **SETUP** folder in the project
3. Execute the `UserCreation.sql` script using the ADMIN account

This will create the following user accounts:
- EVENT_ADMIN (administrator role)
- EVENT_ORGANIZER
- EVENT_SPONSOR
- EVENT_ATTENDEE
- EVENT_VIEWER
- VENUE_MANAGER

### Step 2: Database Schema Creation

1. Connect to your Oracle database as the EVENT_ADMIN user
2. Navigate to the **Tables** folder
3. Execute the `Table_Creation.sql` script

This will create all the necessary tables for the event management system.

### Step 3: Grant Permissions

1. Remain connected as the EVENT_ADMIN user
2. Navigate to the **Permissions** folder
3. Execute the `Permission_granted.sql` script

This will grant the appropriate permissions to all user roles.

### Step 4: Create Sequences

1. Remain connected as the EVENT_ADMIN user
2. Navigate to **Sequences** folder
3. Execute the `EVENT_ADMIN-Sequences.sql` script

### Step 5: Implement Functions

1. Remain connected as the EVENT_ADMIN user
2. Navigate to the **FUNCTIONS** folder
3. Execute all SQL scripts in this folder

This will create specialized functions such as:
- User contact validation
- Seat availability checking

### Step 6: Implement Triggers

1. Remain connected as the EVENT_ADMIN user
2. Navigate to the **TRIGGERS** folder
3. Execute `EVENT_ADMIN-insert_user_type.sql` script

This will implement triggers for data integrity and automated operations.

### Step 7: Implement Stored Procedures

1. Remain connected as the EVENT_ADMIN user
2. Navigate to the **STORED_PROCEDURES** folder
3. Execute the following scripts in order:
   - `EVENT ADMIN - User Operations.sql`
   - `ORGANIZER-Create Event.sql`
   - `ORGANIZER-Event Request.sql`
   - `ORGANIZER-Update Event.sql`
   - `VENUE_MANAGER-Create_Venue.sql`
   - `VENUE_MANAGER-Event Requests.sql`
   - `EVENT_SPONSOR-Add_Sponsorship.sql`
   - `EVENT_ATTENDEE-Register for Events.sql`
   - `EVENT_ATTENDEE-Update_Registration.sql`
   - `EVENT_ATTENDEE-add_feedback.sql`

### Step 8: Populate with Sample Data

1. Remain connected as the EVENT_ADMIN user
2. Navigate to the **Dummy_input_data** folder
3. Execute the `input_data.sql` script

This will populate the database with sample data for testing purposes.

### Step 9: Create Views

1. Remain connected as the EVENT_ADMIN user
2. Navigate to the **Views** folder
3. Execute the `Views.sql` script

This will create the following views:
- REPORT_EVENT_PROFIT_LOSS
- REPORT_ORGANIZER_PERFORMANCE
- VIEW_SPONSOR_ANALYSIS
- VIEW_ATTENDEE_EVENT_HISTORY
- VIEW_VENUE_ANALYSIS

### Step 10: Create Reports

Execute the following report scripts:
- `REPORT_1_Revenue.sql`
- `REPORT_2_FEEDBACK.sql`
- `REPORT_3_SPONSOR.sql`
- `REPORT_4_ATTENDEE.sql`
- `REPORT_5_VENUE.sql`
