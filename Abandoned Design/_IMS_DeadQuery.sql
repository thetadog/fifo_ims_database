
/*
THIS PART HAS BEEN ABANDONED!
THIS PART HAS BEEN ABANDONED!
THIS PART HAS BEEN ABANDONED!
THIS PART HAS BEEN ABANDONED!
THIS PART HAS BEEN ABANDONED!
THIS PART HAS BEEN ABANDONED!
THIS PART HAS BEEN ABANDONED!
DON NOT USE!


-- DESIGN 2
DROP TRIGGER IF EXISTS insert_sale_check;
DROP TRIGGER IF EXISTS insert_sale_update;
DELIMITER //

CREATE TRIGGER insert_sale_check
    BEFORE INSERT
    ON sale_has_item
    FOR EACH ROW
BEGIN
    IF NEW.sale_quantity > (SELECT inv_stock FROM store_has_item WHERE store_has_item.item_id = NEW.item_id) THEN
        SIGNAL SQLSTATE 'HY000'
            SET MESSAGE_TEXT = 'Not enough item in stock. Insertion failed.';
    END IF;
END;

CREATE TRIGGER insert_sale_update
    AFTER INSERT
    ON sale_has_item
    FOR EACH ROW
BEGIN
    UPDATE store_has_item
    SET inv_stock = inv_stock - NEW.sale_quantity
    WHERE store_has_item.item_id = NEW.item_id
      AND store_has_item.store_id = (SELECT store_id FROM sale WHERE sale.sale_id = NEW.sale_id);
END;

DELIMITER ;

DROP TRIGGER IF EXISTS insert_order;
DELIMITER //

CREATE TRIGGER insert_order
    AFTER UPDATE
    ON supply_order
    FOR EACH ROW
BEGIN
    DECLARE order_has_item_cursor CURSOR FOR
        SELECT item_id, order_quantity FROM order_has_item WHERE order_has_item.order_id = NEW.order_id;
    DECLARE iid INT;
    DECLARE quant INT;
    DECLARE row_not_found TINYINT DEFAULT FALSE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET row_not_found = TRUE;

    IF OLD.delivery_date IS NULL AND NEW.delivery_date IS NOT NULL THEN
        OPEN order_has_item_cursor;
        FETCH order_has_item_cursor INTO iid, quant;
        WHILE row_not_found = FALSE DO
        IF (SELECT inv_stock
            FROM store_has_item
            WHERE store_has_item.item_id = iid
              AND store_has_item.store_id = NEW.store_id) IS NULL THEN
            INSERT INTO store_has_item VALUES (NEW.store_id, iid, quant);
        ELSE
            UPDATE store_has_item
            SET inv_stock = inv_stock + quant
            WHERE store_has_item.store_id = NEW.store_id
              AND store_has_item.item_id = iid;
        END IF;
        END WHILE;
    END IF;

END;

DELIMITER ;
 */


/*
-- SALE INSERTION TRIGGER 2
DROP TRIGGER IF EXISTS update_oder_remain_for_sale_insert;
DELIMITER //
CREATE TRIGGER update_oder_remain_for_sale_insert
    AFTER INSERT
    ON sale_has_item
    FOR EACH ROW
BEGIN
    DECLARE s_id INT;
    DECLARE o_id INT;
    DECLARE sale_quantity INT;
    DECLARE stack_quantity INT;

    SET sale_quantity = NEW.sale_quantity;

    SELECT s.store_id
    INTO s_id
    FROM sale_has_item shi
             JOIN sale s on shi.sale_id = s.sale_id
    WHERE s.sale_id = NEW.sale_id
      AND shi.item_id = NEW.item_id;

    DROP TEMPORARY TABLE IF EXISTS fifo_stack;
    CREATE TEMPORARY TABLE IF NOT EXISTS fifo_stack
    SELECT so.order_id AS order_id, ohi.item_id, so.delivery_date, ohi.remain_quantity AS remain
    FROM order_has_item ohi
             JOIN supply_order so ON ohi.order_id = so.order_id
    WHERE ohi.item_id = NEW.item_id
      AND so.store_id = s_id
      AND so.delivery_date IS NOT NULL
      AND ohi.remain_quantity > 0
    ORDER BY so.delivery_date;

    WHILE sale_quantity > 0 DO
    SELECT order_id, remain INTO o_id, stack_quantity FROM fifo_stack LIMIT 1;
    IF sale_quantity > stack_quantity THEN
        UPDATE order_has_item
        SET remain_quantity = 0
        WHERE order_id = o_id
          AND item_id = NEW.item_id;
        SET sale_quantity = sale_quantity - stack_quantity;
        DELETE FROM fifo_stack LIMIT 1;
    ELSE
        UPDATE order_has_item ohi
        SET ohi.remain_quantity = ohi.remain_quantity - sale_quantity
        WHERE ohi.order_id = o_id
          AND ohi.item_id = NEW.item_id;
        SET sale_quantity = 0;
    END IF;
    END WHILE;

    DROP TEMPORARY TABLE IF EXISTS fifo_stack;
END//
DELIMITER ;
*/