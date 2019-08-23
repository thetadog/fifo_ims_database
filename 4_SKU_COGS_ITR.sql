USE ims_SKU;

-- display cogs for each sale (and shs) by store and item
# each sale can have multiple shs and thus different cogs even for the same item
DROP PROCEDURE IF EXISTS get_cogs_by_sale;
DELIMITER //
CREATE PROCEDURE get_cogs_by_sale(IN input_store_id INT,
                                  IN input_item_id INT)
BEGIN
    SELECT s.sale_id,
           rs.store_id,
           rs.store_address,
           i.item_id,
           i.item_name,
           shs.sale_quantity,
           sku.unit_cost,
           shs.sale_quantity * sku.unit_cost AS cogs,
           # yearweek has no usage in this query as every sale has its own date
           # but could prove beneficial if sum by week is needed in future
           YEARWEEK(sale_date)               AS year_week
    FROM retail_store rs
             JOIN supply_order so ON rs.store_id = so.store_id
             JOIN sku ON so.order_id = sku.order_id
             JOIN item i on sku.item_id = i.item_id
             JOIN sale_has_sku shs ON sku.sku_id = shs.sku_id
             JOIN sale s on shs.sale_id = s.sale_id
    WHERE 1 = 1
      AND (
        CASE # set condition for store_id
            WHEN input_store_id IS NOT NULL THEN rs.store_id = input_store_id
            ELSE 1 = 1
            END)
      AND (
        CASE # set condition for item_id
            WHEN input_item_id IS NOT NULL THEN i.item_id = input_item_id
            ELSE 1 = 1
            END)
    ORDER BY rs.store_id, i.item_id, sale_date, sale_id, shs.sale_quantity;
END//
DELIMITER ;

CALL get_cogs_by_sale(null, null);

DROP PROCEDURE IF EXISTS get_weekly_cogs_by_item;
DELIMITER //
CREATE PROCEDURE get_weekly_cogs_by_item(IN input_store_id INT,
                                         IN input_item_id INT,
                                         IN input_start_date DATE,
                                         IN input_end_date DATE)
BEGIN
    SELECT rs.store_id,
           i.item_id,
           SUM(shs.sale_quantity)                                                   AS sale_quantity,
           SUM(shs.sale_quantity * sku.unit_cost)                                   AS cogs,
           IF(input_start_date <= input_end_date, YEARWEEK(input_start_date), NULL) AS FROM_WEEK,
           IF(input_start_date <= input_end_date, YEARWEEK(input_end_date), NULL)   AS TO_WEEK
    FROM retail_store rs
             JOIN supply_order so ON rs.store_id = so.store_id
             JOIN sku ON so.order_id = sku.order_id
             JOIN item i on sku.item_id = i.item_id
             JOIN sale_has_sku shs ON sku.sku_id = shs.sku_id
             JOIN sale s on shs.sale_id = s.sale_id
    WHERE 1 = 1
      AND (
        CASE # set condition for store_id
            WHEN input_store_id IS NOT NULL THEN rs.store_id = input_store_id
            ELSE 1 = 1
            END)
      AND (
        CASE # set condition for item_id
            WHEN input_item_id IS NOT NULL THEN i.item_id = input_item_id
            ELSE 1 = 1
            END)
      AND (
        CASE # set condition for week range
            WHEN input_start_date IS NOT NULL AND input_end_date IS NOT NULL AND
                 input_start_date <= input_end_date THEN
                YEARWEEK(s.sale_date) BETWEEN YEARWEEK(input_start_date) AND YEARWEEK(input_end_date)
            ELSE 1 = 1
            END)
    GROUP BY rs.store_id, sku.item_id, FROM_WEEK, TO_WEEK
    ORDER BY rs.store_id, sku.item_id;
END//
DELIMITER ;

CALL get_weekly_cogs_by_item(null, null, null, null);
CALL get_weekly_cogs_by_item(null, null, 20190701, 20190730);

-- get average inventory quantity and value by item and store
# since this is calculated weekly, if an item is bought and sold in the same week,
# the return value will always be 0 and will be ignored in Java.
DROP PROCEDURE IF EXISTS get_avg_hist_inv_by_item;
DELIMITER //
CREATE PROCEDURE get_avg_hist_inv_by_item(IN input_store_id INT,
                                          IN input_item_id INT,
                                          IN input_start_date DATE,
                                          IN input_end_date DATE)
BEGIN
    SELECT store_id,
           item_id,
           ROUND(AVG(inv_remain), 2)                                                AS avg_remain,
           ROUND(AVG(inv_value), 2)                                                 AS avg_value,
           IF(input_start_date <= input_end_date, YEARWEEK(input_start_date), NULL) AS FROM_WEEK,
           IF(input_start_date <= input_end_date, YEARWEEK(input_end_date), NULL)   AS TO_WEEK
    FROM hist_inv
    WHERE 1 = 1
      AND (
        CASE # set condition for store_id
            WHEN input_store_id IS NOT NULL THEN hist_inv.store_id = input_store_id
            ELSE 1 = 1
            END)
      AND (
        CASE # set condition for item_id
            WHEN input_item_id IS NOT NULL THEN hist_inv.item_id = input_item_id
            ELSE 1 = 1
            END)
      AND (
        CASE # set condition for week range
            WHEN input_start_date IS NOT NULL AND input_end_date IS NOT NULL AND
                 input_start_date <= input_end_date THEN
                year_week BETWEEN YEARWEEK(input_start_date) AND YEARWEEK(input_end_date)
            ELSE 1 = 1
            END)
    GROUP BY store_id, item_id, FROM_WEEK, TO_WEEK
    ORDER BY store_id, item_id;
END//
DELIMITER ;

# store_id, item_id, start_date, end_date
CALL get_avg_hist_inv_by_item(null, null, null, null);
CALL get_avg_hist_inv_by_item(1, null, 20190621, 20190620);

DROP PROCEDURE IF EXISTS get_lead_time_by_item;
DELIMITER //
CREATE PROCEDURE get_lead_time_by_item(IN input_vendor_id INT,
                                       IN input_item_id INT)
BEGIN
    SELECT v.ven_id,
           v.ven_name,
           i.item_id,
           i.item_name,
           ROUND(AVG(DATEDIFF(so.delivery_date, so.order_date)), 0) AS avg_lead_date
    FROM item i
             JOIN sku ON i.item_id = sku.item_id
             JOIN supply_order so ON sku.order_id = so.order_id
             JOIN vendor v ON so.ven_id = v.ven_id
    WHERE so.delivery_date IS NOT NULL
      AND (
        CASE
            WHEN input_vendor_id IS NOT NULL THEN v.ven_id = input_vendor_id
            ELSE 1 = 1
            END)
      AND (
        CASE
            WHEN input_item_id IS NOT NULL THEN i.item_id = input_item_id
            ELSE 1 = 1
            END)
    GROUP BY v.ven_id, v.ven_name, i.item_id, i.item_name;
END//
DELIMITER ;

CALL get_lead_time_by_item(null, null); # vendor_id, item_id


DROP PROCEDURE IF EXISTS get_itr_by_item_for_past_num_week;
DELIMITER //
CREATE PROCEDURE get_itr_by_item_for_past_num_week(IN input_store_id INT,
                                                   IN input_item_id INT,
                                                   IN input_week_num INT)
BEGIN
    DECLARE rollback_week INT;
    SET rollback_week = input_week_num - 1;

    SELECT cogs.store_id,
           cogs.store_address,
           cogs.item_id,
           cogs.item_name,
           cogs.sale_quantity,
           avg_inv.avg_remain,
           cogs.cogs,
           avg_inv.avg_value,
           ROUND(cogs.sale_quantity / avg_inv.avg_remain, 2) AS quantity_itr,
           ROUND(cogs.cogs / avg_inv.avg_value, 2)           AS cogs_itr,
           YEARWEEK(NOW()) - rollback_week                   AS FROM_WEEK,
           YEARWEEK(NOW())                                   AS TO_WEEK
    FROM (
             SELECT rs.store_id,
                    rs.store_address,
                    i.item_id,
                    i.item_name,
                    SUM(shs.sale_quantity)                 AS sale_quantity,
                    SUM(shs.sale_quantity * sku.unit_cost) AS cogs
             FROM retail_store rs
                      JOIN supply_order so ON rs.store_id = so.store_id
                      JOIN sku ON so.order_id = sku.order_id
                      JOIN item i on sku.item_id = i.item_id
                      JOIN sale_has_sku shs ON sku.sku_id = shs.sku_id
                      JOIN sale s on shs.sale_id = s.sale_id
             WHERE YEARWEEK(sale_date) BETWEEN YEARWEEK(NOW()) - rollback_week AND YEARWEEK(NOW())
               AND (
                 CASE # set condition for store_id
                     WHEN input_store_id IS NOT NULL THEN rs.store_id = input_store_id
                     ELSE 1 = 1
                     END)
               AND (
                 CASE # set condition for item_id
                     WHEN input_item_id IS NOT NULL THEN i.item_id = input_item_id
                     ELSE 1 = 1
                     END)
             GROUP BY rs.store_id, sku.item_id
             ORDER BY rs.store_id, sku.item_id) AS cogs
             JOIN (
        SELECT store_id,
               item_id,
               ROUND(AVG(inv_remain), 2) AS avg_remain,
               ROUND(AVG(inv_value), 2)  AS avg_value
        FROM hist_inv
        WHERE year_week BETWEEN YEARWEEK(NOW()) - rollback_week AND YEARWEEK(NOW())
          AND (
            CASE # set condition for store_id
                WHEN input_store_id IS NOT NULL THEN hist_inv.store_id = input_store_id
                ELSE 1 = 1
                END)
          AND (
            CASE # set condition for item_id
                WHEN input_item_id IS NOT NULL THEN hist_inv.item_id = input_item_id
                ELSE 1 = 1
                END)
        GROUP BY store_id, item_id
        ORDER BY store_id, item_id) AS avg_inv
                  ON (cogs.store_id = avg_inv.store_id AND cogs.item_id = avg_inv.item_id);

END//
DELIMITER ;

# store_id, item_id, num_of_week
CALL get_itr_by_item_for_past_num_week(null, null, 4);
