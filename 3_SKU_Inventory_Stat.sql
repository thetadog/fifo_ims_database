USE ims_SKU;

-- display inventory remain by item and store and cat
# this procedure generates QUANTITY, NOT $ AMOUNT
DROP PROCEDURE IF EXISTS get_inventory_status_by_item;
DELIMITER //
CREATE PROCEDURE get_inventory_status_by_item(IN input_store_id INT,
                                              IN input_item_id INT,
                                              IN input_cat_id INT)
BEGIN
    SELECT supply.store_id,
           supply.store_address,
           supply.item_id,
           supply.item_name,
           supply.cat_id,
           supply.cat_name,
           supply.bought                                       AS bought,
           IF(sale.sold IS NULL, 0, sale.sold)                 AS sold,
           supply.bought - IF(sale.sold IS NULL, 0, sale.sold) AS remain
    FROM (SELECT rs.store_id,
                 rs.store_address,
                 i.item_id,
                 i.item_name,
                 ic.cat_id,
                 ic.cat_name,
                 SUM(sku.order_quantity) AS bought
          FROM retail_store rs
                   JOIN supply_order so ON rs.store_id = so.store_id
                   JOIN sku on sku.order_id = so.order_id
                   JOIN item i on sku.item_id = i.item_id
                   JOIN item_category ic on i.cat_id = ic.cat_id
          WHERE so.delivery_date IS NOT NULL
          GROUP BY rs.store_id, rs.store_address, i.item_id, i.item_name) AS supply
             LEFT JOIN
         (SELECT i.item_id, s.store_id, SUM(shs.sale_quantity) as sold
          FROM item i
                   JOIN sku ON i.item_id = sku.item_id
                   JOIN sale_has_sku shs ON sku.sku_id = shs.sku_id
                   JOIN sale s on shs.sale_id = s.sale_id
          GROUP BY i.item_id, s.store_id) AS sale
         ON (supply.item_id = sale.item_id AND supply.store_id = sale.store_id)
    WHERE 1 = 1
      AND (
        CASE # set condition for store_id
            WHEN input_store_id IS NOT NULL THEN supply.store_id = input_store_id
            ELSE 1 = 1
            END)
      AND (
        CASE # set condition for item_id
            WHEN input_item_id IS NOT NULL THEN supply.item_id = input_item_id
            ELSE 1 = 1
            END)
      AND (
        CASE # set condition for cat_id
            WHEN input_cat_id IS NOT NULL THEN supply.cat_id = input_cat_id
            ELSE 1 = 1
            END)
    ORDER BY supply.store_id, supply.item_id, supply.cat_id;
END//
DELIMITER ;

CALL get_inventory_status_by_item(null, null, null);
# store_id, item_id, cat_id

-- return quantity remain for every sku (NOT item)
# a potential helper method used for fifo
# default order by delivery date
# non-delivered sku are not included
DROP PROCEDURE IF EXISTS get_inventory_status_by_sku;
DELIMITER //
CREATE PROCEDURE get_inventory_status_by_sku(IN input_store_id INT,
                                             IN input_item_id INT)
BEGIN
    SELECT bought.sku_id,
           bought.store_id,
           bought.store_address,
           bought.item_id,
           bought.item_name,
           bought.unit_cost,
           bought.order_quantity,
           bought.order_quantity - IF(sold.num IS NULL, 0, sold.num) AS remain
    FROM (SELECT sku.sku_id,
                 sku.order_quantity,
                 sku.unit_cost,
                 rs.store_id,
                 rs.store_address,
                 i.item_id,
                 i.item_name
          FROM retail_store rs
                   JOIN supply_order so ON rs.store_id = so.store_id
                   JOIN sku ON so.order_id = sku.order_id
                   JOIN item i ON sku.item_id = i.item_id
          WHERE so.delivery_date IS NOT NULL
         ) AS bought
             LEFT JOIN
         (SELECT sku.sku_id, SUM(shs.sale_quantity) AS num
          FROM sku
                   JOIN sale_has_sku shs ON sku.sku_id = shs.sku_id
          GROUP BY sku.sku_id
         ) AS sold ON (bought.sku_id = sold.sku_id)
    WHERE 1 = 1
      AND (
        CASE # set condition for store_id
            WHEN input_store_id IS NOT NULL THEN bought.store_id = input_store_id
            ELSE 1 = 1
            END)
      AND (
        CASE # set condition for item_id
            WHEN input_item_id IS NOT NULL THEN bought.item_id = input_item_id
            ELSE 1 = 1
            END)
    ORDER BY bought.store_id, bought.item_id, remain;
END//
DELIMITER ;

CALL get_inventory_status_by_sku(null, null);

DROP PROCEDURE IF EXISTS get_remaining_inventory_by_age_of_inv;
DELIMITER //
CREATE PROCEDURE get_remaining_inventory_by_age_of_inv(IN input_store_id INT,
                                                       IN input_item_id INT)
BEGIN
    SELECT bought.sku_id,
           bought.store_id,
           bought.store_address,
           bought.item_id,
           bought.item_name,
           bought.unit_cost,
           bought.order_quantity,
           bought.order_quantity - IF(sold.num IS NULL, 0, sold.num) AS remain,
           DATEDIFF(NOW(), delivery_date)                            AS age_of_inv
    FROM (SELECT sku.sku_id,
                 sku.order_quantity,
                 sku.unit_cost,
                 rs.store_id,
                 rs.store_address,
                 i.item_id,
                 i.item_name,
                 so.delivery_date
          FROM retail_store rs
                   JOIN supply_order so ON rs.store_id = so.store_id
                   JOIN sku ON so.order_id = sku.order_id
                   JOIN item i ON sku.item_id = i.item_id
          WHERE so.delivery_date IS NOT NULL
         ) AS bought
             LEFT JOIN
         (SELECT sku.sku_id, SUM(shs.sale_quantity) AS num
          FROM sku
                   JOIN sale_has_sku shs ON sku.sku_id = shs.sku_id
          GROUP BY sku.sku_id
         ) AS sold ON (bought.sku_id = sold.sku_id)
    WHERE 1 = 1
      AND (
        CASE # set condition for store_id
            WHEN input_store_id IS NOT NULL THEN bought.store_id = input_store_id
            ELSE 1 = 1
            END)
      AND (
        CASE # set condition for item_id
            WHEN input_item_id IS NOT NULL THEN bought.item_id = input_item_id
            ELSE 1 = 1
            END)
    HAVING remain > 0
    ORDER BY age_of_inv DESC, bought.store_id, bought.item_id, remain;
END//
DELIMITER ;

CALL get_remaining_inventory_by_age_of_inv(null, null);