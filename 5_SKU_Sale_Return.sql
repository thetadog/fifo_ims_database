USE ims_SKU;

-- issue a sale return for a previous sale
# item will be assigned cost on fifo order
DROP PROCEDURE IF EXISTS insert_sale_return;
DELIMITER //
CREATE PROCEDURE insert_sale_return(IN input_sale_id INT,
                                    IN input_item_id INT,
                                    IN input_quantity INT)
BEGIN
    DECLARE message VARCHAR(255);
    DECLARE sold_quantity INT;
    DECLARE stack_quantity INT;
    DECLARE stack_sku INT;
    DECLARE stack_remain INT;
    DECLARE stack_sale_price DECIMAL(8, 2);
    DECLARE sql_error INT DEFAULT FALSE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        SET sql_error = TRUE;

    IF input_sale_id NOT IN (SELECT sale_id FROM sale) OR input_item_id NOT IN (SELECT item_id FROM item)
    THEN
        SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'Invalid input. A return must have a corresponding sale and item';
    END IF;

    DROP TEMPORARY TABLE IF EXISTS sale_fifo_stack;
    CREATE TEMPORARY TABLE IF NOT EXISTS sale_fifo_stack
    SELECT S.sku_id, S.order_quantity, S.unit_cost, shs.sale_quantity, shs.unit_sale_price
    FROM sale
             JOIN sale_has_sku shs on sale.sale_id = shs.sale_id
             JOIN sku S on shs.sku_id = S.sku_id
             JOIN supply_order so on S.order_id = so.order_id
    WHERE sale.sale_id = input_sale_id
      AND S.item_id = input_item_id
    ORDER BY so.delivery_date DESC; # most recent cost assigned when the sale was made

    SET sold_quantity = (SELECT SUM(sale_quantity) FROM sale_fifo_stack);
    SET sold_quantity = IF(sold_quantity IS NULL, 0, sold_quantity);

    IF sold_quantity = 0 OR input_quantity > sold_quantity THEN
        SELECT CONCAT('Return quantity shall not exceed sale quantity for the item id=', input_item_id, '. Sold ',
                      sold_quantity, ' but returning ', input_quantity)
        INTO message;
        SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = message;
    END IF;

    SET stack_quantity = input_quantity;

#     START TRANSACTION;
    WHILE stack_quantity > 0 DO
    SELECT sku_id,
           sale_quantity,
           unit_sale_price
    INTO stack_sku, stack_remain,stack_sale_price
    FROM sale_fifo_stack
    LIMIT 1;

    IF stack_quantity > stack_remain THEN
        INSERT INTO sale_has_sku VALUES (input_sale_id, stack_sku, 0 - stack_remain, stack_sale_price);
        SET stack_quantity = stack_quantity - stack_remain;
    ELSE
        INSERT INTO sale_has_sku VALUES (input_sale_id, stack_sku, 0 - stack_quantity, stack_sale_price);
        SET stack_quantity = 0;
    END IF;

    DELETE FROM sale_fifo_stack LIMIT 1;
    END WHILE;

    IF sql_error = FALSE THEN
        COMMIT;
        SELECT 'Sale_Return succeed!' AS TRANSACTION_SUCCESS;
    ELSE
        ROLLBACK;
        SELECT 'Sale_Return failed!' AS TRANSACTION_FAILURE;
    END IF;

END//
DELIMITER ;

select *
from sku
         join supply_order so on sku.order_id = so.order_id;

select *
from sale_has_sku
         join sale s on sale_has_sku.sale_id = s.sale_id;

# TESTING
# RETURN 30 APPLES
# CALL insert_sale_return(2, 1, 30);
# SALE 15 APPLES AFTER RETURN
# CALL insert_into_sale(1, now(), 1, null, @sale_id);
# CALL insert_into_sale_has_sku(@sale_id, 1, 15, 0.45);
# Rerun 2_SKU_Mock_Data_Init.sql after testing.
