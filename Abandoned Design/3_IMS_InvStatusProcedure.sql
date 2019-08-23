USE ims;

# UPDATED design allow us to check the inventory by using remain_quantity in order_has_item
-- INVENTORY STATUS
## NEED MORE DESIGN INFO: ITEM CATEGORY FILTER

DROP PROCEDURE IF EXISTS INV_STATUS;
DELIMITER //
CREATE PROCEDURE INV_STATUS(IN input_store_id INT,
                                 IN input_cat_id INT,
                                 IN input_item_id INT)

BEGIN
    DROP TEMPORARY TABLE IF EXISTS inv_status_temp_table;
    CREATE TEMPORARY TABLE IF NOT EXISTS inv_status_temp_table
    SELECT supply.store_id                                         AS rs_id,
           supply.store_address                                    AS rs_name,
           supply.item_id                                          AS i_id,
           supply.item_name                                        AS i_name,
           supply.cat_id                                           AS ic_id,
           supply.cat_name                                         AS ic_name,
           IF(sale.sq IS NULL, supply.oq - 0, supply.oq - sale.sq) AS in_stock
    FROM (SELECT rs.store_id,
                 rs.store_address,
                 i.item_id,
                 i.item_name,
                 i.cat_id,
                 ic.cat_name,
                 SUM(ohi.order_quantity) AS oq
          FROM item_category ic
                   JOIN item i ON i.cat_id = ic.cat_id
                   JOIN order_has_item ohi ON ohi.item_id = i.item_id
                   JOIN supply_order so ON ohi.order_id = so.order_id
                   JOIN retail_store rs ON so.store_id = rs.store_id
          WHERE so.delivery_date IS NOT NULL
          GROUP BY i.item_id, so.store_id, i.item_name) AS supply
             LEFT JOIN
         (SELECT rs.store_id,
                 rs.store_address,
                 i.item_id,
                 i.item_name,
                 i.cat_id,
                 ic.cat_name,
                 SUM(shi.sale_quantity) AS sq
          FROM item_category ic
                   JOIN item i ON i.cat_id = ic.cat_id
                   JOIN sale_has_item shi ON shi.item_id = i.item_id
                   JOIN sale s ON shi.sale_id = s.sale_id
                   JOIN retail_store rs ON s.store_id = rs.store_id
          GROUP BY i.item_id, s.store_id, i.item_name) AS sale
         ON (supply.store_id = sale.store_id AND supply.item_id = sale.item_id);

    SET @sql = 'SELECT rs_id, rs_name, ic_id, ic_name, i_id, i_name, in_stock FROM inv_status_temp_table WHERE 1 = 1';
    IF input_store_id IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND rs_id = "', input_store_id, '"');
    END IF;
    IF input_cat_id IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND ic_id = "', input_cat_id, '"');
    END IF;
    IF input_item_id IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND i_id = "', input_item_id, '"');
    END IF;
    SET @sql = CONCAT(@sql, ' ORDER BY rs_id, ic_id, i_id');

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

END //
DELIMITER ;

call INV_STATUS(1, null,null);