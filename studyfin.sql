-- ("5"), Semester 2, 2025
-- [Daniel Hay]
-- [Danie.hay@studnet.uts.edu.au]
-- [25128974]
-- 
-- StudyFin Student Accommodation Platform
-- This database manages student accommodation listings and rental applications.
-- It connects landlords who list properties with students seeking accommodation
-- near their universities. The system tracks property details, user information,
-- and rental applications.
-- 
-- Inspired by: https://studyfin.co/rent

-- DROP existing tables (allows script to run multiple times)
DROP TABLE IF EXISTS accommodation_applications CASCADE;
DROP TABLE IF EXISTS accommodation_listings CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Users table (landlords and students)
CREATE TABLE users (
    id SERIAL,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    user_type TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_pkey PRIMARY KEY (id),
    CONSTRAINT users_email_unique UNIQUE (email),
    CONSTRAINT valid_user_type CHECK (user_type IN ('landlord', 'student')),
    CONSTRAINT valid_email CHECK (email LIKE '%@%')
);

-- Accommodation listings table
CREATE TABLE accommodation_listings (
    id SERIAL,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT NOT NULL,
    price NUMERIC NOT NULL,
    currency TEXT NOT NULL DEFAULT 'AUD',
    bedrooms INTEGER NOT NULL,
    bathrooms NUMERIC NOT NULL,
    property_type TEXT NOT NULL,
    nearest_institution TEXT,
    user_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT accommodation_listings_pkey PRIMARY KEY (id),
    CONSTRAINT accommodation_listings_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES users(id) 
        ON DELETE CASCADE,
    CONSTRAINT valid_price CHECK (price >= 0),
    CONSTRAINT valid_bedrooms CHECK (bedrooms >= 0),
    CONSTRAINT valid_bathrooms CHECK (bathrooms >= 0),
    CONSTRAINT valid_currency CHECK (currency IN ('AUD', 'USD', 'EUR'))
);

-- Accommodation applications table (creates M:N relationship)
CREATE TABLE accommodation_applications (
    id SERIAL,
    property_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    email TEXT NOT NULL,
    additional_notes TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT accommodation_applications_pkey PRIMARY KEY (id),
    CONSTRAINT accommodation_applications_property_id_fkey 
        FOREIGN KEY (property_id) REFERENCES accommodation_listings(id) 
        ON DELETE CASCADE,
    CONSTRAINT accommodation_applications_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES users(id) 
        ON DELETE RESTRICT,
    CONSTRAINT valid_status CHECK (status IN ('pending', 'approved', 'rejected')),
    CONSTRAINT valid_application_email CHECK (email LIKE '%@%')
);

-- Insert sample data for users (landlords and students)
INSERT INTO users (name, email, phone, user_type) VALUES
('John Smith', 'john.smith@gmail.com', '0412345678', 'landlord'),
('Sarah Johnson', 'sarah.j@gmail.com', '0423456789', 'landlord'),
('Mike Chen', 'mike.chen@student.uts.edu.au', '0434567890', 'student'),
('Emma Wilson', 'emma.w@student.uts.edu.au', '0445678901', 'student'),
('David Lee', 'david.lee@student.unsw.edu.au', '0456789012', 'student');

-- Insert sample accommodation listings
INSERT INTO accommodation_listings 
(title, description, location, price, currency, bedrooms, bathrooms, property_type, nearest_institution, user_id) VALUES
('Cozy Studio Near UTS', 'Modern studio apartment with great city views', 'Ultimo, NSW', 450, 'AUD', 1, 1, 'Studio', 'UTS', 1),
('Shared House in Newtown', 'Spacious room in friendly share house', 'Newtown, NSW', 280, 'AUD', 1, 1, 'Shared House', 'UNSW', 1),
('2BR Apartment CBD', 'Fully furnished 2 bedroom in heart of Sydney', 'Sydney CBD, NSW', 800, 'AUD', 2, 1, 'Apartment', 'UTS', 2),
('Student Room Kensington', 'Perfect for UNSW students, walk to campus', 'Kensington, NSW', 320, 'AUD', 1, 1, 'Shared House', 'UNSW', 2),
('Luxury Studio Pyrmont', 'Brand new building with gym and pool', 'Pyrmont, NSW', 550, 'AUD', 1, 1, 'Studio', 'UTS', 1);
('Budget Room Ultimo', 'Ultimo, NSW', 300, 1, 1, 'Shared House', 'UTS', 1);

-- Insert sample accommodation applications
INSERT INTO accommodation_applications 
(property_id, user_id, first_name, last_name, phone_number, email, additional_notes, status) VALUES
(1, 3, 'Mike', 'Chen', '0434567890', 'mike.chen@student.uts.edu.au', 'I am a first year engineering student at UTS', 'approved'),
(1, 4, 'Emma', 'Wilson', '0445678901', 'emma.w@student.uts.edu.au', 'Looking for accommodation starting March', 'pending'),
(2, 5, 'David', 'Lee', '0456789012', 'david.lee@student.unsw.edu.au', 'Quiet and responsible tenant', 'approved'),
(3, 3, 'Mike', 'Chen', '0434567890', 'mike.chen@student.uts.edu.au', 'Would like to view this property', 'rejected'),
(4, 5, 'David', 'Lee', '0456789012', 'david.lee@student.unsw.edu.au', 'Very close to my university', 'pending'),
(5, 4, 'Emma', 'Wilson', '0445678901', 'emma.w@student.uts.edu.au', 'Can move in immediately', 'pending');

-- Query 1: Simple query of a single table
-- Find all accommodation listings under $350 per week
SELECT title, location, price, bedrooms
FROM accommodation_listings
WHERE price < 350
ORDER BY price;

-- Query 2: Natural join query
-- Show all applications with property and applicant details
SELECT a.first_name, a.last_name, a.status, l.title, l.location, l.price
FROM accommodation_applications a
NATURAL JOIN accommodation_listings l;

-- Query 3: Cross product equivalent to natural join above
-- Same result using WHERE clause instead of NATURAL JOIN
SELECT a.first_name, a.last_name, a.status, l.title, l.location, l.price
FROM accommodation_applications a, accommodation_listings l
WHERE a.property_id = l.id;

-- Query 4: Group by query with HAVING
-- Count applications per property, show only properties with 2+ applications
SELECT l.title, l.location, COUNT(a.id) as application_count
FROM accommodation_listings l
JOIN accommodation_applications a ON l.id = a.property_id
GROUP BY l.id, l.title, l.location
HAVING COUNT(a.id) >= 2
ORDER BY application_count DESC;

-- Query 5: Subquery
-- Find students who have applied to properties more expensive than $400
SELECT DISTINCT u.name, u.email
FROM users u
WHERE u.id IN (
    SELECT a.user_id
    FROM accommodation_applications a
    JOIN accommodation_listings l ON a.property_id = l.id
    WHERE l.price > 400
)
AND u.user_type = 'student';

-- Query 6: Self join / Cross product that cannot use NATURAL JOIN
-- Find pairs of properties in the same location but different prices
SELECT l1.title as property1, l1.price as price1, 
       l2.title as property2, l2.price as price2, 
       l1.location
FROM accommodation_listings l1, accommodation_listings l2
WHERE l1.location = l2.location 
AND l1.id < l2.id
AND l1.price < l2.price
ORDER BY l1.location;
