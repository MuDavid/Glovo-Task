-- COURIER to PICKUP 
WITH
    combined AS (
        SELECT
            t1.id,
            t1.customer_id,
            t1.courier_id,
            t1.acceptance_latitude AS lat1,
            t1.acceptance_longitude AS lon1,
            t2.point_type,
            t2.latitude AS lat2,
            t2.longitude AS lon2
        FROM
            orders t1
            INNER JOIN order_points t2 ON t1.id = t2.order_id
    )
SELECT
    id,
    customer_id,
    courier_id,
    point_type,
    lat1,
    lon1,
    lat2,
    lon2,
    (
        6371 * acos(
            cos(radians (lat1)) * cos(radians (lat2)) * cos(radians (lon2) - radians (lon1)) + sin(radians (lat1)) * sin(radians (lat2))
        )
    ) AS distance_km
FROM
    Combined

-- PICKUP to DELIVERY     
where
    point_type = 'PICKUP';

WITH
    pickupdelivery AS (
        SELECT
            p.order_id,
            p.latitude AS pickup_lat,
            p.longitude AS pickup_lon,
            d.latitude AS delivery_lat,
            d.longitude AS delivery_lon
        FROM
            order_points p
            INNER JOIN order_points d ON p.order_id = d.order_id
        WHERE
            p.point_type = 'PICKUP'
            AND d.point_type = 'DELIVERY'
    )
SELECT
    order_id,
    pickup_lat,
    pickup_lon,
    delivery_lat,
    delivery_lon,
    (
        6371 * acos(
            cos(radians (pickup_lat)) * cos(radians (delivery_lat)) * cos(radians (delivery_lon) - radians (pickup_lon)) + sin(radians (pickup_lat)) * sin(radians (delivery_lat))
        )
    ) AS distance_km
FROM
    PickupDelivery;