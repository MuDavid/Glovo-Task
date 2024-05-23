WITH SignupWeek AS (
    SELECT
        id AS customer_id,
        registration_date,
        DATE_PART('week', registration_date) AS signup_week,
        DATE_PART('year', registration_date) AS signup_year
    FROM
        Customer
),
FirstOrderWeek AS (
    SELECT
        c.id AS customer_id,
        c.registration_date,
        o.activation_time,
        DATE_PART('week', c.registration_date) AS signup_week,
        DATE_PART('year', c.registration_date) AS signup_year,
        DATE_PART('week', o.activation_time) AS order_week,
        DATE_PART('year', o.activation_time) AS order_year
    FROM
        Customer c
    INNER JOIN
        Orders o ON c.first_order_id = o.id
)
SELECT
    sw.signup_year,
    
    COUNT(CASE WHEN fw.order_week = sw.signup_week + 1 THEN fw.customer_id END) AS week_1,
    COUNT(CASE WHEN fw.order_week = sw.signup_week + 2 THEN fw.customer_id END) AS week_2,
    COUNT(CASE WHEN fw.order_week = sw.signup_week + 3 THEN fw.customer_id END) AS week_3,
    
    
    (week_1+week_2+week_3) as  users_ordered_in_3weeks
FROM
    SignupWeek sw
LEFT JOIN
    FirstOrderWeek fw ON sw.customer_id = fw.customer_id
GROUP BY
    sw.signup_year 
ORDER BY
    sw.signup_year; 