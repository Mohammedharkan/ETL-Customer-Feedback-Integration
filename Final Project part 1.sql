-- Step 3: Creating the Database and Tables in MySQL

CREATE DATABASE IF NOT EXISTS etl_final_project;

USE etl_final_project;

DROP TABLE IF EXISTS Reviews;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Customers;

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    region VARCHAR(100)
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(100),
    price DECIMAL(10,2)
);

CREATE TABLE Reviews (
    review_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    review_date DATE,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comments TEXT,

    CONSTRAINT fk_reviews_customers
        FOREIGN KEY (customer_id)
        REFERENCES Customers(customer_id),

    CONSTRAINT fk_reviews_products
        FOREIGN KEY (product_id)
        REFERENCES Products(product_id)
);






-- Step 4: Inserting Sample Data into the Tables

USE etl_final_project;

INSERT INTO Customers (customer_id, name, email, region)
VALUES
(1, 'John Doe', 'john.doe@example.com', 'North'),
(2, 'Jane Smith', 'jane.smith@example.com', 'East'),
(3, 'Emily Davis', 'emily.davis@example.com', 'South');

INSERT INTO Products (product_id, name, category, price)
VALUES
(101, 'Wireless Mouse', 'Electronics', 25.99),
(102, 'Bluetooth Headphones', 'Electronics', 59.99),
(103, 'Office Chair', 'Furniture', 149.99);

-- Add a general feedback product for reviews that do not include product_id
INSERT IGNORE INTO Products (product_id, name, category, price)
VALUES (999, 'General Customer Feedback', 'General Feedback', 0.00);


INSERT INTO Reviews (customer_id, product_id, review_date, rating, comments)
VALUES
(1, 101, '2024-01-01', 5, 'Great product!'),
(2, 102, '2024-01-02', 4, 'Good quality.'),
(3, 103, '2024-01-03', 3, 'Average quality.');


-- Verify Inserted Data

SELECT * FROM Customers;

SELECT * FROM Products;

SELECT * FROM Reviews;




-- Step 5: Importing CSV Data into MySQL

USE etl_final_project;

DROP TABLE IF EXISTS customer_survey_staging;

CREATE TABLE customer_survey_staging (
    customer_id INT,
    name VARCHAR(100),
    email VARCHAR(150),
    region VARCHAR(100),
    rating INT,
    comments TEXT,
    review_date DATE
);

DESCRIBE customer_survey_staging;




-- Load CSV File into Staging Table

LOAD DATA LOCAL INFILE 'C:/Users/moham/Documents/Introduction to Extract-Transform-Load Assignments/Final Project Part 1/customer_survey.csv'
INTO TABLE customer_survey_staging
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM customer_survey_staging;





-- Step 6 Part1: Moving CSV Data into Final Tables

INSERT IGNORE INTO Customers (customer_id, name, email, region)
SELECT
    customer_id,
    name,
    email,
    region
FROM customer_survey_staging;


SELECT * FROM Customers;

-- Step 6 Part 2: Move CSV review data into the final Reviews table
INSERT INTO Reviews (customer_id, product_id, review_date, rating, comments)
SELECT
    customer_id,
    999 AS product_id,
    review_date,
    rating,
    comments
FROM customer_survey_staging;



SELECT * FROM Reviews;


SELECT * FROM Customers;


-- Step 6 Part 3: Data Cleaning Using SQL UPDATE

SET SQL_SAFE_UPDATES = 0;

-- Remove extra spaces from review comments
UPDATE Reviews
SET comments = TRIM(comments);

-- Replace missing review dates with the current date
UPDATE Reviews
SET review_date = CURDATE()
WHERE review_date IS NULL;

SET SQL_SAFE_UPDATES = 1;

SELECT * FROM Reviews;



-- Step 9: Creating SQL Views and Joins

CREATE OR REPLACE VIEW customer_product_reviews AS
SELECT
    r.review_id,
    c.customer_id,
    c.name AS customer_name,
    c.email,
    c.region,
    p.product_id,
    p.name AS product_name,
    p.category,
    p.price,
    r.review_date,
    r.rating,
    r.comments
FROM Reviews r
LEFT JOIN Customers c
    ON r.customer_id = c.customer_id
LEFT JOIN Products p
    ON r.product_id = p.product_id;
    
    
    
SELECT * FROM customer_product_reviews;





-- Step 10: SQL Analysis Queries

SELECT
    p.product_id,
    p.name AS product_name,
    AVG(r.rating) AS average_rating,
    COUNT(r.review_id) AS total_reviews
FROM Products p
LEFT JOIN Reviews r
    ON p.product_id = r.product_id
GROUP BY
    p.product_id,
    p.name
ORDER BY
    average_rating DESC;
    
    
    
    
-- Step 11: Creating an Index for Query Optimization

CREATE INDEX idx_reviews_product
ON Reviews(product_id);


CREATE INDEX idx_reviews_customer
ON Reviews(customer_id);

CREATE INDEX idx_reviews_date
ON Reviews(review_date);

SHOW INDEX FROM Reviews;



USE etl_final_project;

SHOW TABLES;


USE etl_final_project;

-- Staging table for JSON web feedback
CREATE TABLE IF NOT EXISTS web_feedback_staging (
    feedback_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    rating INT,
    comments TEXT,
    review_date DATE
);

-- Staging table for XML external reviews
CREATE TABLE IF NOT EXISTS external_reviews_staging (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    rating INT,
    comments TEXT,
    review_date DATE
);

-- Error log table for parsing issues
CREATE TABLE IF NOT EXISTS parsing_error_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    source_file VARCHAR(100),
    row_identifier VARCHAR(100),
    error_description TEXT,
    log_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SHOW TABLES;

USE etl_final_project;

SELECT *
FROM products
WHERE product_id = 999;



USE etl_final_project;

SELECT *
FROM customer_survey_staging;



-- Check for missing values in CSV survey data

SELECT *
FROM customer_survey_staging
WHERE
    name IS NULL
    OR email IS NULL
    OR region IS NULL
    OR rating IS NULL
    OR comments IS NULL
    OR review_date IS NULL;
    


-- Validate rating values in CSV survey data

SELECT *
FROM customer_survey_staging
WHERE rating < 1
   OR rating > 5;
   
   

-- Check for duplicate records in CSV survey data

SELECT
    customer_id,
    comments,
    COUNT(*) AS duplicate_count
FROM customer_survey_staging
GROUP BY customer_id, comments
HAVING COUNT(*) > 1;





-- Insert validated CSV survey data into Reviews table

INSERT INTO reviews (
    customer_id,
    product_id,
    rating,
    comments,
    review_date
)
SELECT
    customer_id,
    999,
    rating,
    comments,
    review_date
FROM customer_survey_staging;

SELECT *
FROM reviews;



-- Temporarily disable safe update mode

SET SQL_SAFE_UPDATES = 0;

DELETE r1
FROM reviews r1
INNER JOIN reviews r2
ON r1.customer_id = r2.customer_id
AND r1.comments = r2.comments
AND r1.review_date = r2.review_date
AND r1.review_id > r2.review_id;

SET SQL_SAFE_UPDATES = 1;




-- Verify JSON staging table structure

DESCRIBE web_feedback_staging;



-- Verify inserted JSON records in staging table

SELECT *
FROM web_feedback_staging;