-- Question 1
SELECT article, unit_price
FROM fact_tables.bakery_sales
WHERE unit_price = (SELECT MAX(unit_price) FROM fact_tables.bakery_sales)
OR unit_price = (SELECT MIN(unit_price) FROM fact_tables.bakery_sales
                                        WHERE unit_price >0);

-- Question 2
WITH second_most_sale_item AS (
    SELECT article,
           SUM(quantity) AS total_sales,
           dense_rank() over (ORDER BY sum(quantity) DESC) AS rank
    FROM fact_tables.bakery_sales
    GROUP BY article
    )
SELECT *
FROM second_most_sale_item
WHERE rank = 2;

-- Question 3
WITH quantity_list AS (
    SELECT article,
           SUM(quantity) AS quantity_sum,
           dense_rank() OVER (PARTITION BY DATE_PART('MONTH', sale_date)
               ORDER BY SUM(quantity) DESC) AS quantity_rank,
           DATE_PART('MONTH', sale_date) AS month,
           SUM(quantity*unit_price) AS sales
    FROM fact_tables.bakery_sales
    WHERE sale_date BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY article, month
)
SELECT *
FROM quantity_list
WHERE quantity_rank <= 3;

-- Question 4
SELECT ticket_number, COUNT(article) AS number_of_articles
FROM fact_tables.bakery_sales
WHERE sale_date BETWEEN '2022-08-01' AND '2022-08-31'
GROUP BY ticket_number
HAVING COUNT(article) >= 5
ORDER BY ticket_number;

-- Question 5
SELECT SUM(quantity*unit_price)/31 AS average_sales_per_day
FROM fact_tables.bakery_sales
WHERE sale_date BETWEEN '2022-08-01' AND '2022-08-31';

-- Question 6
SELECT extract(dow from sale_date) AS day_of_week, SUM(quantity*unit_price) AS sales
FROM fact_tables.bakery_sales
GROUP BY day_of_week
ORDER BY sales DESC
LIMIT 1;

-- Question 7
WITH  traditional_Baguette AS(
    SELECT article,
           extract(HOUR FROM sale_time) AS hour,
           sum(quantity*unit_price) AS sales
    FROM fact_tables.bakery_sales
    WHERE article = 'TRADITIONAL BAGUETTE'
    GROUP BY hour, article
    ORDER BY sales DESC
    LIMIT 1
)
SELECT article,
    concat('Most sales happen between ', hour, ' and ', hour+1) AS hour_range,
    sales
FROM traditional_Baguette;

-- Question 8
WITH quantity_list AS(
    SELECT article,
           extract(YEAR FROM sale_date) AS year,
           extract(MONTH FROM sale_date) AS month,
           SUM(quantity*unit_price) AS sales,
           rank() OVER (PARTITION BY extract(YEAR FROM sale_date),
               extract(MONTH FROM sale_date)
               ORDER BY extract(YEAR FROM sale_date),
                   extract(MONTH FROM sale_date),
                   SUM(quantity*unit_price) ASC) AS quantity_rank
    FROM fact_tables.bakery_sales
    GROUP BY year,month,article
)
SELECT *
FROM quantity_list
WHERE quantity_rank = 1;

-- Question 9
WITH January AS(
    SELECT article, sum(quantity*unit_price) AS sales
    FROM fact_tables.bakery_sales
    WHERE sale_date BETWEEN '2022-01-01' AND '2022-01-31'
    GROUP BY article
)
SELECT article, (sales/(SELECT SUM(sales) FROM January)*100) AS percentage_of_sales
FROM January;

-- Question 10
with total AS (
    select extract(MONTH FROM sale_date) AS month,
           SUM(quantity) AS total_quantity
    FROM fact_tables.bakery_sales
    WHERE sale_date >= '2022-01-01'
    GROUP BY month
), banette AS(
    SELECT extract(MONTH FROM sale_date) AS month,
           SUM(quantity) AS total_banette
    FROM fact_tables.bakery_sales
    WHERE article = 'BANETTE'
    AND sale_date >= '2022-01-01'
    GROUP BY month
)
SELECT total.month, (100.00*banette.total_banette/total.total_quantity)
    AS order_rate_percentage
FROM total
INNER JOIN banette
ON total.month = banette.month;