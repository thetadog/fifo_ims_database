USE ims_SKU;

DROP FUNCTION IF EXISTS get_avg_daily_sale_by_item;
DELIMITER //
CREATE FUNCTION get_avg_daily_sale_by_item(input_store_id INT,
                                           input_item_id INT)
    RETURNS DECIMAL(8, 2)
    READS SQL DATA
BEGIN
    DECLARE daily_avg_sale DECIMAL(8, 2);

    IF input_store_id IS NULL OR input_item_id IS NULL THEN
        RETURN 0;
    END IF;

    # the max of this period can only be 365 days (1 year)
    SELECT (SELECT SUM(sale_quantity) as quant
            FROM sku
                     JOIN sale_has_sku ON sku.sku_id = sale_has_sku.sku_id
                     JOIN sale ON sale_has_sku.sale_id = sale.sale_id
            WHERE DATEDIFF(NOW(), sale_date) < 365
              AND sku.item_id = input_item_id
              AND sale.store_id = input_store_id)
               /
           (SELECT DATEDIFF(NOW(), MIN(so.delivery_date)) AS days
            FROM sku
                     JOIN supply_order so on sku.order_id = so.order_id
            WHERE so.delivery_date IS NOT NULL
              AND DATEDIFF(NOW(), so.delivery_date) < 365
              AND so.store_id = input_store_id
              AND sku.item_id = input_item_id)
    INTO daily_avg_sale;

    IF daily_avg_sale IS NULL THEN
        RETURN 0;
    ELSE
        RETURN daily_avg_sale;
    END IF;
END//
DELIMITER ;


DROP FUNCTION IF EXISTS get_avg_lead_time_by_item;
DELIMITER //
CREATE FUNCTION get_avg_lead_time_by_item(input_store_id INT, input_item_id INT)
    RETURNS DECIMAL(8, 2)
    READS SQL DATA
BEGIN
    DECLARE avg_lead_time DECIMAL(8, 2);

    IF input_store_id IS NULL OR input_item_id IS NULL THEN
        RETURN 0;
    END IF;

    SELECT AVG(lt)
    INTO avg_lead_time
    FROM (
             SELECT DISTINCT sku.order_id, DATEDIFF(so.delivery_date, so.order_date) AS lt
             FROM supply_order so
                      JOIN sku ON so.order_id = sku.order_id
             WHERE so.delivery_date IS NOT NULL
               AND DATEDIFF(NOW(), so.delivery_date) < 365
               AND so.store_id = input_store_id
               AND sku.item_id = input_item_id) AS lt_table;

    IF avg_lead_time IS NULL THEN
        RETURN 0;
    ELSE
        RETURN avg_lead_time;
    END IF;
END//
DELIMITER ;


DROP FUNCTION IF EXISTS get_rop_by_item;
DELIMITER //
CREATE FUNCTION get_rop_by_item(input_store_id INT, input_item_id INT)
    RETURNS DECIMAL(8, 2)
    READS SQL DATA
BEGIN
    DECLARE gop DECIMAL(8, 2);
    IF input_item_id IS NULL THEN
        RETURN 0;
    END IF;

    SET gop = get_avg_daily_sale_by_item(input_store_id, input_item_id) *
              get_avg_lead_time_by_item(input_store_id, input_item_id);

    IF gop IS NULL THEN
        RETURN 0;
    ELSE
        RETURN gop;
    END IF;
END//
DELIMITER ;

SELECT get_avg_daily_sale_by_item(2, 2);
SELECT get_avg_lead_time_by_item(2, 2);
SELECT get_rop_by_item(1, 1); # store_id, item_id

DROP TRIGGER IF EXISTS verify_reminder_for_order_delivery;
DELIMITER //
CREATE TRIGGER verify_reminder_for_order_delivery
    AFTER UPDATE
    ON supply_order
    FOR EACH ROW
BEGIN
    DECLARE cur_item_id INT;

    IF NEW.delivery_date IS NOT NULL AND OLD.delivery_date IS NULL THEN
        CREATE TEMPORARY TABLE IF NOT EXISTS item_in_so
        SELECT DISTINCT item_id
        FROM supply_order so
                 JOIN sku ON so.order_id = sku.order_id
        WHERE so.order_id = NEW.order_id;

        # loop through whole sku.item_id in this sale
        WHILE (SELECT item_id FROM item_in_so LIMIT 1) IS NOT NULL DO
        SELECT item_id INTO cur_item_id FROM item_in_so LIMIT 1;
        IF get_item_stock_at_store(cur_item_id, NEW.store_id)
            > get_rop_by_item(NEW.store_id, cur_item_id) THEN
            DELETE
            FROM inv_reminder
            WHERE inv_reminder.item_id = cur_item_id
              AND inv_reminder.store_id = NEW.store_id;
        END IF;

        DELETE FROM item_in_so LIMIT 1;
        END WHILE;

        DROP TEMPORARY TABLE IF EXISTS item_in_so;
    END IF;
END//
DELIMITER ;

DROP TRIGGER IF EXISTS verify_reminder_for_shs_insertion;
DELIMITER //
CREATE TRIGGER verify_reminder_for_shs_insertion
    AFTER INSERT
    ON sale_has_sku
    FOR EACH ROW
BEGIN
    DECLARE cur_store_id INT;
    DECLARE cur_item_id INT;
    DECLARE msg VARCHAR(255);

    SELECT store_id
    INTO cur_store_id
    FROM sale
    WHERE sale.sale_id = NEW.sale_id;

    SELECT item_id
    INTO cur_item_id
    FROM sku
    WHERE sku.sku_id = NEW.sku_id;

    IF get_item_stock_at_store(cur_item_id, cur_store_id)
        <= get_rop_by_item(cur_store_id, cur_item_id) THEN
        SELECT CONCAT('Store id=', cur_store_id, ' needs to replenish Item id=', cur_item_id,
                      '. Reorder Point ', get_rop_by_item(cur_store_id, cur_item_id),
                      ' > Current Stock ', get_item_stock_at_store(cur_item_id, cur_store_id))
        INTO msg;

        IF (SELECT message
            FROM inv_reminder
            WHERE store_id = cur_store_id
              AND item_id = cur_item_id) IS NULL THEN

            INSERT INTO inv_reminder VALUES (cur_store_id, cur_item_id, msg);

        ELSE
            UPDATE inv_reminder
            SET message = msg
            WHERE store_id = cur_store_id
              AND item_id = cur_item_id;

        END IF;

    ELSE # delete for negative sale (sale return)
        DELETE
        FROM inv_reminder
        WHERE inv_reminder.store_id = cur_store_id
          AND inv_reminder.item_id = cur_item_id;
    END IF;
END//
DELIMITER ;