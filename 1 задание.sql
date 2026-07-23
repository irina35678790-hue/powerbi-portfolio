UPDATE customer 
SET Gender = NULL 
WHERE Gender = '';
UPDATE customer 
SET Age = NULL 
WHERE Age = '';
ALTER TABLE customer 
MODIFY Age INT NULL;

SELECT * FROM customer;

CREATE TABLE Transactions (
    date_new DATE,
    Id_check INT,
    ID_client INT,
    Count_products DECIMAL(10, 3),
    Sum_payment DECIMAL(10, 2)
);

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/transactions.csv.csv'
INTO TABLE Transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT * FROM transactions;

## 1. Клиенты с непрерывной историей за год (12 месяцев без пропусков)
SELECT Id_client
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY Id_client
HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) = 12;

# Средний чек за период 01.06.2015 - 01.06.2016
SELECT AVG(Sum_payment) AS average_check
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01';

# Средняя сумма покупок за месяц
SELECT 
    DATE_FORMAT(date_new, '%m') AS month,
    SUM(Sum_payment) / COUNT(*) AS avg_monthly_payment
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY month
ORDER BY month;

#  Количество всех операций по клиенту за период
SELECT 
    Id_client,
    COUNT(*) AS total_transactions,
    SUM(Sum_payment) AS total_amount
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY Id_client
ORDER BY total_transactions DESC;

## 2. Средняя сумма чека в месяц
SELECT 
    DATE_FORMAT(date_new, '%m') AS month,
    AVG(Sum_payment) AS avg_check
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY month
ORDER BY month;

# Среднее количество операций в месяц
SELECT 
    DATE_FORMAT(date_new, '%m') AS month,
    COUNT(*) AS transactions,
    COUNT(DISTINCT Id_client) AS active_clients
FROM transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY month
ORDER BY month;

# Доля операций и суммы от годовых показателей
SELECT 
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(*) AS monthly_transactions,
    SUM(Sum_payment) AS monthly_sum,
    (COUNT(*) / total_transactions_year) * 100 AS transaction_share,
    (SUM(Sum_payment) / total_sum_year) * 100 AS sum_share
FROM transactions
CROSS JOIN (
    SELECT 
        COUNT(*) AS total_transactions_year,
        SUM(Sum_payment) AS total_sum_year
    FROM transactions
    WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
) AS totals
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY month, total_transactions_year, total_sum_year
ORDER BY month;

# Гендерное распределение в каждом месяце 
SELECT 
    month,
    Gender,
    transactions,
    total_sum,
    ROUND((transactions / total_month_transactions) * 100, 2) AS transaction_pct,
    ROUND((total_sum / total_month_sum) * 100, 2) AS sum_pct
FROM (
    SELECT 
        DATE_FORMAT(t.date_new, '%Y-%m') AS month,
        c.Gender,
        COUNT(*) AS transactions,
        SUM(t.Sum_payment) AS total_sum,
        SUM(COUNT(*)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) AS total_month_transactions,
        SUM(SUM(t.Sum_payment)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) AS total_month_sum
    FROM transactions t
    JOIN customer c ON t.Id_client = c.Id_client
    WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
    GROUP BY DATE_FORMAT(t.date_new, '%Y-%m'), c.Gender
) sub
ORDER BY month, Gender;

## 3. Возрастные группы за весь период
SELECT 
    CASE 
        WHEN Age < 10 THEN '0-9'
        WHEN Age < 20 THEN '10-19'
        WHEN Age < 30 THEN '20-29'
        WHEN Age < 40 THEN '30-39'
        WHEN Age < 50 THEN '40-49'
        WHEN Age < 60 THEN '50-59'
        WHEN Age < 70 THEN '60-69'
        WHEN Age < 80 THEN '70-79'
        WHEN Age < 90 THEN '80-89'
        ELSE '90+'
    END AS age_group,
    SUM(t.Sum_payment) AS total_sum,
    COUNT(*) AS total_transactions,
    ROUND(AVG(t.Sum_payment), 2) AS avg_check
FROM transactions t
JOIN customer c ON t.Id_client = c.Id_client
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY age_group
UNION ALL
SELECT 
    'NULL' AS age_group,
    SUM(t.Sum_payment) AS total_sum,
    COUNT(*) AS total_transactions,
    ROUND(AVG(t.Sum_payment), 2) AS avg_check
FROM transactions t
JOIN customer c ON t.Id_client = c.Id_client
WHERE c.Age IS NULL AND t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
ORDER BY FIELD(age_group, '0-9', '10-19', '20-29', '30-39', '40-49', '50-59', '60-69', '70-79', '80-89', '90+', 'NULL');

# Возрастные группы поквартально
SELECT 
    CASE 
        WHEN Age < 10 THEN '0-9'
        WHEN Age < 20 THEN '10-19'
        WHEN Age < 30 THEN '20-29'
        WHEN Age < 40 THEN '30-39'
        WHEN Age < 50 THEN '40-49'
        WHEN Age < 60 THEN '50-59'
        WHEN Age < 70 THEN '60-69'
        WHEN Age < 80 THEN '70-79'
        WHEN Age < 90 THEN '80-89'
        ELSE '90+'
    END AS age_group,
    CONCAT(YEAR(t.date_new), '-', QUARTER(t.date_new)) AS quarter,
    SUM(t.Sum_payment) AS total_sum,
    COUNT(*) AS total_transactions,
    ROUND(AVG(t.Sum_payment), 2) AS avg_check
FROM transactions t
JOIN customer c ON t.Id_client = c.Id_client
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY age_group, quarter
UNION ALL
SELECT 
    'NULL' AS age_group,
    CONCAT(YEAR(t.date_new), '-', QUARTER(t.date_new)) AS quarter,
    SUM(t.Sum_payment) AS total_sum,
    COUNT(*) AS total_transactions,
    ROUND(AVG(t.Sum_payment), 2) AS avg_check
FROM transactions t
JOIN customer c ON t.Id_client = c.Id_client
WHERE c.Age IS NULL AND t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY quarter
ORDER BY quarter, FIELD(age_group, '0-9', '10-19', '20-29', '30-39', '40-49', '50-59', '60-69', '70-79', '80-89', '90+', 'NULL');