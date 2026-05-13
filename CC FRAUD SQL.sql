# -- 1 CREATE DATABASE
CREATE DATABASE credit_card_fraud_detection;

USE credit_card_fraud_detection;

# -- 2 CREATE TABLE FRAUD_TRAIN 

CREATE TABLE fraud_train (
    dummy INT,
    trans_date_trans_time DATETIME,
    cc_num BIGINT,
    merchant VARCHAR(255),
    category VARCHAR(100),
    amt DECIMAL(10,2),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    gender VARCHAR(10),
    street VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code INT,
    lat DECIMAL(10,6),
    longi DECIMAL(10,6),
    city_pop INT,
    job VARCHAR(255),
    dob DATE,
    trans_num VARCHAR(255),
    unix_time BIGINT,
    merch_lat DECIMAL(10,6),
    merch_long DECIMAL(10,6),
    is_fraud INT
);

show tables;

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE '"C:\csv\fraudTrain.csv"'
INTO TABLE fraud_train
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT COUNT(*) FROM fraud_train;

SELECT * FROM fraud_train LIMIT 10;

# -- 3 CREATE TABLE FRAUD_TEST 

CREATE TABLE fraud_test (
    dummy INT,
    trans_date_trans_time DATETIME,
    cc_num BIGINT,
    merchant VARCHAR(255),
    category VARCHAR(100),
    amt DECIMAL(10,2),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    gender VARCHAR(10),
    street VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code INT,
    lat DECIMAL(10,6),
    longi DECIMAL(10,6),
    city_pop INT,
    job VARCHAR(255),
    dob DATE,
    trans_num VARCHAR(255),
    unix_time BIGINT,
    merch_lat DECIMAL(10,6),
    merch_long DECIMAL(10,6),
    is_fraud INT
);

show tables;

SELECT * FROM fraud_test LIMIT 10;

# -- 4 DATA CLEANING $ PREPROCESSING 
# ---- CHECK TOTAL RECORDS

SELECT COUNT(*) FROM fraud_train;
SELECT COUNT(*) FROM fraud_test;

# ---- CHECK NULL VALUES 
SELECT
COUNT(*) AS null_merchant
FROM fraud_train
WHERE merchant IS NULL;

# ---- REMOVE DUPLICATE TRANSACTION
SELECT trans_num, COUNT(*)
FROM fraud_train
GROUP BY trans_num
HAVING COUNT(*) > 1;

# -- 5 FEATURE ENGINEERING 
# ---- EXTRACT TRANSACTION HOUR 
ALTER TABLE fraud_train
ADD COLUMN transaction_hour INT;
SET SQL_SAFE_UPDATES = 0;

UPDATE fraud_train
SET transaction_hour = HOUR(trans_date_trans_time)
LIMIT 100000;

SELECT COUNT(*)
FROM fraud_train
WHERE transaction_hour IS NULL;

# ---- EXTRACT TRANSACTION DAY 
ALTER TABLE fraud_train
ADD COLUMN transaction_day VARCHAR(20);

UPDATE fraud_train
SET transaction_day = DAYNAME(trans_date_trans_time)
WHERE transaction_day IS NULL
LIMIT 100000;

SELECT COUNT(*)
FROM fraud_train
WHERE transaction_day IS NULL;

 # ---- CREATE AGE COLUMN 
 ALTER TABLE fraud_train
ADD COLUMN customer_age INT;

UPDATE fraud_train
SET customer_age = TIMESTAMPDIFF(YEAR, dob, CURDATE())
WHERE customer_age IS NULL
LIMIT 100000;

SELECT COUNT(*)
FROM fraud_train
WHERE customer_age IS NULL;

# -- 6 BUSINESS PROBLEMS & SQL ANALYSIS 
# ---- TOTAL TRANSACTIONS 
SELECT COUNT(*) AS total_transactions
FROM fraud_train;

# ---- TOTAL FRAUD TRANSACTIONS
SELECT COUNT(*) AS total_fraud_transactions
FROM fraud_train
WHERE is_fraud = 1;

#  ---- FRAUD TRANSACTIONS 
SELECT
ROUND(
SUM(is_fraud) * 100.0 / COUNT(*),2) AS fraud_percentage
FROM fraud_train;

# ---- TOP FRAUD MERCHANT CATEGORIES 
SELECT
category,
COUNT(*) AS fraud_cases
FROM fraud_train
WHERE is_fraud = 1
GROUP BY category
ORDER BY fraud_cases DESC;

 # ---- HIGHEST  FRAUD STATE
 SELECT
state,
COUNT(*) AS fraud_count
FROM fraud_train
WHERE is_fraud = 1
GROUP BY state
ORDER BY fraud_count DESC
LIMIT 10;

# ---- FRAUD BY GENDER 
SELECT
gender,
COUNT(*) AS fraud_count
FROM fraud_train
WHERE is_fraud = 1
GROUP BY gender;

# ---- FRAUD TRANSACTIONS BY HOUR 
SELECT
transaction_hour,
COUNT(*) AS fraud_cases
FROM fraud_train
WHERE is_fraud = 1
GROUP BY transaction_hour
ORDER BY fraud_cases DESC;

# ---- TOP HIGH-RISK MERCHANTS
SELECT
merchant,
COUNT(*) AS fraud_cases
FROM fraud_train
WHERE is_fraud = 1
GROUP BY merchant
ORDER BY fraud_cases DESC
LIMIT 15;

# ---- FRAUD TREND BY MONTH
SELECT
MONTH(trans_date_trans_time) AS month_number,
COUNT(*) AS fraud_cases
FROM fraud_train
WHERE is_fraud = 1
GROUP BY MONTH(trans_date_trans_time)
ORDER BY month_number;

# ---- TOP JOBS WITH FRAUD CASES
SELECT
job,
COUNT(*) AS fraud_cases
FROM fraud_train
WHERE is_fraud = 1
GROUP BY job
ORDER BY fraud_cases DESC
LIMIT 15;

# ---- WEEKEND AND WEEKDAY FRAUD 
SELECT
CASE
WHEN DAYOFWEEK(trans_date_trans_time) IN (1,7)
THEN 'Weekend'
ELSE 'Weekday'
END AS day_type,
COUNT(*) AS fraud_cases
FROM fraud_train
WHERE is_fraud = 1
GROUP BY day_type;

# ---- TOP 5 CUSTOMERS BY FRAUD FREQUENCY 
SELECT
cc_num,
COUNT(*) AS fraud_frequency
FROM fraud_train
WHERE is_fraud = 1
GROUP BY cc_num
ORDER BY fraud_frequency DESC
LIMIT 5;

# ---- FRAUD RATE BY CATEGORY
SELECT
category,
COUNT(*) AS total_transactions,
SUM(is_fraud) AS fraud_transactions,
ROUND(SUM(is_fraud)*100/COUNT(*),2) AS fraud_rate
FROM fraud_train
GROUP BY category
ORDER BY fraud_rate DESC;

# -- 7 ADVANCED SQL QUERIES 
# ---- WINDOW FUNCTION ANALYSIS 
SELECT
merchant,
category,
amt,
RANK() OVER(
PARTITION BY category
ORDER BY amt DESC
) AS amount_rank
FROM fraud_train;

# ---- CTe ANALYSIS
WITH fraud_summary AS (
SELECT
category,
COUNT(*) AS fraud_count
FROM fraud_train
WHERE is_fraud = 1
GROUP BY category
)
SELECT *
FROM fraud_summary
ORDER BY fraud_count DESC;