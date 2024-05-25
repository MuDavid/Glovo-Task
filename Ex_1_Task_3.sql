WITH
    CityGroup AS (
        SELECT DISTINCT
            city,
            CASE
                WHEN city = 'Barcelona' THEN 'Group1'
                WHEN city = 'Madrid' THEN 'Group2'
                WHEN city IN ('Valencia', 'Murcia') THEN 'Group3'
                ELSE 'Group4'
            END AS city_group
        FROM
            Orders
    ),
    LastWeekOrders AS (
        SELECT
            c.city_group,
            COUNT(*) AS last_week_orders
        FROM
            Orders o
            JOIN CityGroup c ON o.city = c.city
        WHERE
            DATE_PART ('week', o.order_date) = DATE_PART ('week', CURRENT_DATE - INTERVAL '1 week')
            AND DATE_PART ('year', o.order_date) = DATE_PART ('year', CURRENT_DATE)
        GROUP BY
            c.city_group
    ),
    WeekOverWeekOrders AS (
        SELECT
            c.city_group,
            COUNT(*) AS last_week_orders,
            LAG (COUNT(*)) OVER (
                PARTITION BY
                    c.city_group
                ORDER BY
                    DATE_PART ('week', o.order_date)
            ) AS prev_week_orders
        FROM
            Orders o
            JOIN CityGroup c ON o.city = c.city
        WHERE
            DATE_PART ('week', o.order_date) IN (
                DATE_PART ('week', CURRENT_DATE),
                DATE_PART ('week', CURRENT_DATE - INTERVAL '1 week')
            )
            AND DATE_PART ('year', o.order_date) = DATE_PART ('year', CURRENT_DATE)
        GROUP BY
            c.city_group,
            DATE_PART ('week', o.order_date)
    ),
    LastWeekRegistrations AS (
        SELECT
            c.city_group,
            COUNT(*) AS last_week_registrations
        FROM
            Users u
            JOIN CityGroup c ON u.city = c.city
        WHERE
            DATE_PART ('week', u.registration_date) = DATE_PART ('week', CURRENT_DATE - INTERVAL '1 week')
            AND DATE_PART ('year', u.registration_date) = DATE_PART ('year', CURRENT_DATE)
        GROUP BY
            c.city_group
    ),
    AvgFoodOrdersPerUserLastMonth AS (
        SELECT
            c.city_group,
            AVG(
                CASE
                    WHEN o.category = 'FOOD' THEN 1
                    ELSE 0
                END
            ) AS avg_food_orders_per_user_last_month
        FROM
            Orders o
            JOIN CityGroup c ON o.city = c.city
        WHERE
            o.order_date >= DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month')
            AND o.order_date < DATE_TRUNC ('month', CURRENT_DATE)
        GROUP BY
            c.city_group
    ),
    LastMonthOldActiveUsers AS (
        SELECT
            c.city_group,
            COUNT(DISTINCT u.id) AS last_month_old_active_users
        FROM
            Users u
            JOIN Orders o ON u.id = o.user_id
            JOIN CityGroup c ON u.city = c.city
        WHERE
            o.order_date >= DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month')
            AND o.order_date < DATE_TRUNC ('month', CURRENT_DATE)
            AND u.first_order_date < DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month')
        GROUP BY
            c.city_group
    )
SELECT
    COALESCE(LastWeekOrders.city_group, 'Group1') AS city_group,
    COALESCE(LastWeekOrders.last_week_orders, 0) AS last_week_orders,
    COALESCE(WeekOverWeekOrders.prev_week_orders, 0) AS prev_week_orders,
    COALESCE(LastWeekRegistrations.last_week_registrations, 0) AS last_week_registrations,
    COALESCE(
        AvgFoodOrdersPerUserLastMonth.avg_food_orders_per_user_last_month,
        0
    ) AS avg_food_orders_per_user_last_month,
    COALESCE(
        LastMonthOldActiveUsers.last_month_old_active_users,
        0
    ) AS last_month_old_active_users
FROM
    LastWeekOrders
    FULL JOIN WeekOverWeekOrders ON LastWeekOrders.city_group = WeekOverWeekOrders.city_group
    FULL JOIN LastWeekRegistrations ON LastWeekOrders.city_group = LastWeekRegistrations.city_group
    FULL JOIN AvgFoodOrdersPerUserLastMonth ON LastWeekOrders.city_group = AvgFoodOrdersPerUserLastMonth.city_group
    FULL JOIN LastMonthOldActiveUsers ON LastWeekOrders.city_group = LastMonthOldActiveUsers.city_group
ORDER BY
    LastWeekOrders.city_group;