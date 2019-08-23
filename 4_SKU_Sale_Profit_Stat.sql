USE ims_SKU;

-- display weekly sale amount by item and store
# this procedure WILL NOT display store that hasn't made any sale
DROP PROCEDURE IF EXISTS get_weekly_sale_by_item;
DELIMITER //
CREATE PROCEDURE get_weekly_sale_by_item(IN input_store_id INT,
                                         IN input_item_id INT)
BEGIN
    SELECT rs.store_id,
           rs.store_address,
           i.item_id,
           i.item_name,
           YEARWEEK(sale.sale_date)                     AS year_week,
           SUM(shs.sale_quantity)                       AS sale_quantity,
           SUM(shs.sale_quantity * shs.unit_sale_price) AS sale_amt
    FROM retail_store rs
             JOIN supply_order so on rs.store_id = so.store_id
             JOIN sku S on so.order_id = S.order_id
             JOIN item i on S.item_id = i.item_id
             JOIN sale_has_sku shs on S.sku_id = shs.sku_id
             JOIN sale on shs.sale_id = sale.sale_id
    WHERE 1 = 1 # a delivery_date check is unnecessary since no sale can be inserted if not delivered
      AND (
        CASE
            WHEN input_store_id IS NOT NULL THEN rs.store_id = input_store_id
            ELSE 1 = 1
            END)
      AND (
        CASE
            WHEN input_item_id IS NOT NULL THEN i.item_id = input_item_id
            ELSE 1 = 1
            END)
    GROUP BY rs.store_id, rs.store_address, i.item_id, i.item_name, year_week
    ORDER BY year_week DESC, rs.store_id, i.item_id;
END//
DELIMITER ;

CALL get_weekly_sale_by_item(null, null);


-- display weekly profits by item and store
DROP PROCEDURE IF EXISTS get_weekly_profit_by_item;
DELIMITER //
CREATE PROCEDURE get_weekly_profit_by_item(IN input_store_id INT,
                                           IN input_item_id INT)
BEGIN
    SELECT rs.store_id,
           rs.store_address,
           i.item_id,
           i.item_name,
           SUM(shs.sale_quantity * (shs.unit_sale_price - S.unit_cost)) AS profit,
           YEARWEEK(sale.sale_date)                                     AS sale_week
    FROM retail_store rs
             JOIN supply_order so ON rs.store_id = so.store_id
             JOIN sku S on S.order_id = so.order_id
             JOIN item i on S.item_id = i.item_id
             JOIN sale_has_sku shs on S.sku_id = shs.sku_id
             JOIN sale on shs.sale_id = sale.sale_id
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
    GROUP BY rs.store_id, rs.store_address, i.item_id, i.item_name, sale_week
    ORDER BY sale_week DESC, rs.store_id, i.item_id, profit;
END//
DELIMITER ;

CALL get_weekly_profit_by_item(null, null);

-- get the total amount of sales by item & store
# a time range filter can be applied by setting start_date and end_date
DROP PROCEDURE IF EXISTS get_total_sale_by_item;
DELIMITER //
CREATE PROCEDURE get_total_sale_by_item(IN input_store_id INT,
                                        IN input_item_id INT,
                                        IN input_start_date DATE,
                                        IN input_end_date DATE)
BEGIN
    SELECT rs.store_id,
           rs.store_address,
           i.item_id,
           i.item_name,
           SUM(shs.sale_quantity)                                                   AS sale_quantity,
           SUM(shs.sale_quantity * shs.unit_sale_price)                             AS sale_amt,
           IF(input_start_date <= input_end_date, YEARWEEK(input_start_date), NULL) AS FROM_WEEK,
           IF(input_start_date <= input_end_date, YEARWEEK(input_end_date), NULL)   AS TO_WEEK
    FROM retail_store rs
             JOIN supply_order so on rs.store_id = so.store_id
             JOIN sku S on so.order_id = S.order_id
             JOIN item i on S.item_id = i.item_id
             JOIN sale_has_sku shs on S.sku_id = shs.sku_id
             JOIN sale on shs.sale_id = sale.sale_id
    WHERE 1 = 1 # a delivery_date check is unnecessary since no sale can be inserted if not delivered
      AND (
        CASE
            WHEN input_store_id IS NOT NULL THEN rs.store_id = input_store_id
            ELSE 1 = 1
            END)
      AND (
        CASE
            WHEN input_item_id IS NOT NULL THEN i.item_id = input_item_id
            ELSE 1 = 1
            END)
      AND (
        CASE # set condition for week range
            WHEN input_start_date IS NOT NULL AND input_end_date IS NOT NULL AND
                 input_start_date <= input_end_date THEN
                YEARWEEK(sale.sale_date) BETWEEN YEARWEEK(input_start_date) AND YEARWEEK(input_end_date)
            ELSE 1 = 1
            END)
    GROUP BY rs.store_id, rs.store_address, i.item_id, i.item_name, FROM_WEEK, TO_WEEK
    ORDER BY rs.store_id, i.item_id, sale_quantity, sale_amt;
END//
DELIMITER ;

call get_total_sale_by_item(null, null, null, null);

-- get the total profit by item & store
# a time range filter can be applied by setting start_date and end_date
DROP PROCEDURE IF EXISTS get_total_profit_by_item;
DELIMITER //
CREATE PROCEDURE get_total_profit_by_item(IN input_store_id INT,
                                          IN input_item_id INT,
                                          IN input_start_date DATE,
                                          IN input_end_date DATE)
BEGIN
    SELECT rs.store_id,
           rs.store_address,
           i.item_id,
           i.item_name,
           SUM(shs.sale_quantity * (shs.unit_sale_price - S.unit_cost))             AS profit,
           IF(input_start_date <= input_end_date, YEARWEEK(input_start_date), NULL) AS FROM_WEEK,
           IF(input_start_date <= input_end_date, YEARWEEK(input_end_date), NULL)   AS TO_WEEK
    FROM retail_store rs
             JOIN supply_order so ON rs.store_id = so.store_id
             JOIN sku S on S.order_id = so.order_id
             JOIN item i on S.item_id = i.item_id
             JOIN sale_has_sku shs on S.sku_id = shs.sku_id
             JOIN sale on shs.sale_id = sale.sale_id
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
                YEARWEEK(sale.sale_date) BETWEEN YEARWEEK(input_start_date) AND YEARWEEK(input_end_date)
            ELSE 1 = 1
            END)
    GROUP BY rs.store_id, rs.store_address, i.item_id, i.item_name
    ORDER BY rs.store_id, i.item_id, profit;
END//
DELIMITER ;

CALL get_total_profit_by_item(null, null, null, null);