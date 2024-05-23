WITH
    CityGroup AS (
        SELECT
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
            city_group,
            COUNT(*) AS last_week_orders
        FROM
            CityGroup
        WHERE
            DATE_PART ('week', order_date) = DATE_PART ('week', CURRENT_DATE) - 1
            AND DATE_PART ('year', order_date) = DATE_PART ('year', CURRENT_DATE)
        GROUP BY
            city_group
    ),
    WeekOverWeekOrders AS (
        SELECT
            city_group,
            last_week_orders,
            LAG (last_week_orders) OVER (
                ORDER BY
                    city_group
            ) AS prev_week_orders
        FROM
            LastWeekOrders
    ),
    LastWeekRegistrations AS (
        SELECT
            city_group,
            COUNT(*) AS last_week_registrations
        FROM
            users
        WHERE
            DATE_PART ('week', registration_date) = DATE_PART ('week', CURRENT_DATE) - 1
            AND DATE_PART ('year', registration_date) = DATE_PART ('year', CURRENT_DATE)
        GROUP BY
            city_group
    ),
    AvgFoodOrdersPerUserLastMonth AS (
        SELECT
            city_group,
            AVG(
                CASE
                    WHEN category = 'FOOD' THEN 1
                    ELSE 0
                END
            ) AS avg_food_orders_per_user_last_month
        FROM
            Orders
        WHERE
            order_date >= DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month')
            AND order_date < DATE_TRUNC ('month', CURRENT_DATE)
        GROUP BY
            city_group
    ),
    LastMonthOldActiveUsers AS (
        SELECT
            city_group,
            COUNT(DISTINCT u.id) AS last_month_old_active_users
        FROM
            users u
            INNER JOIN Orders o ON u.id = o.user_id
        WHERE
            o.order_date >= DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month')
            AND o.order_date < DATE_TRUNC ('month', CURRENT_DATE)
            AND u.first_order_date < DATE_TRUNC ('month', CURRENT_DATE - INTERVAL '1 month')
        GROUP BY
            city_group
    )
SELECT
    COALESCE(
        LWO.city_group,
        WO.city_group,
        LWR.city_group,
        AFO.city_group,
        LMO.city_group
    ) AS city_group,
    COALESCE(WO.last_week_orders, 0) AS last_week_orders,
    COALESCE(WO.last_week_orders - WO.prev_week_orders, 0) AS week_over_week_orders,
    COALESCE(LWR.last_week_registrations, 0) AS last_week_registrations,
    COALESCE(AFO.avg_food_orders_per_user_last_month, 0) AS avg_food_orders_per_user_last_month,
    COALESCE(LMO.last_month_old_active_users, 0) AS last_month_old_active_users
FROM
    LastWeekOrders WO
    FULL JOIN WeekOverWeekOrders WOO ON WO.city_group = WOO.city_group
    FULL JOIN LastWeekRegistrations LWR ON WO.city_group = LWR.city_group
    FULL JOIN AvgFoodOrdersPerUserLastMonth AFO ON WO.city_group = AFO.city_group
    FULL JOIN LastMonthOldActiveUsers LMO ON WO.city_group = LMO.city_group
ORDER BY
    city_group;