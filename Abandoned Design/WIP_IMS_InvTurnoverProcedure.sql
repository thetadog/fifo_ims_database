USE ims;

# WIP
# WIP
# WIP
# DO NOT USE!
# DO NOT USE!
# DO NOT USE!

-- COGS
DROP PROCEDURE IF EXISTS MONTHLY_COGS_BY_ITEM_AND_STORE;
DELIMITER //
CREATE PROCEDURE MONTHLY_COGS_BY_ITEM_AND_STORE(IN input_store_id INT,
                                                IN input_item_id INT,
                                                IN input_month INT)
BEGIN
    DECLARE start_inv DECIMAL(8, 2) DEFAULT 0;
    DECLARE end_inv DECIMAL(8, 2) DEFAULT 0;
    DECLARE purchase DECIMAL(8, 2) DEFAULT 0;

    IF input_month IS NULL OR input_month NOT BETWEEN 1 AND 12 THEN SET input_month = 1;
    END IF;
    IF input_store_id IS NULL THEN SET input_store_id = 1;
    END IF;
    IF input_item_id IS NULL THEN SET input_item_id = 1;
    END IF;

    select *
    from sale_has_item shi
             join sale s on shi.sale_id = s.sale_id
             join retail_store rs on s.store_id = rs.store_id
    where rs.store_id = 1 and shi.item_id = 1 and sale_date < 20190701
    ;



END //
DELIMITER ;

DROP PROCEDURE IF EXISTS MONTHLY_AVE_INV_BY_ITEM_AND_STORE;
DELIMITER //
CREATE PROCEDURE MONTHLY_AVE_INV_BY_ITEM_AND_STORE
BEGIN

END //
DELIMITER ;


-- COGS REAL-TIME
DROP FUNCTION IF EXISTS COGS_real_time;
DELIMITER //
CREATE FUNCTION COGS_real_time(input_store_address VARCHAR(30), input_item_name VARCHAR(30), sale_quantity INT)
    RETURNS DECIMAL(8, 2)
    READS SQL DATA
BEGIN
    DECLARE cost DECIMAL(8, 2) DEFAULT 0;
    DECLARE stack_quantity INT;
    DECLARE stack_cost DECIMAL(8, 2);

    CREATE TEMPORARY TABLE fifo_stack
    SELECT ohi.unit_cost                                                      AS uc,
           SUM(DISTINCT ohi.order_quantity) - SUM(DISTINCT shi.sale_quantity) AS in_stock
    FROM item
             JOIN order_has_item ohi ON item.item_id = ohi.item_id
             JOIN supply_order so ON ohi.order_id = so.order_id
             JOIN retail_store rs ON so.store_id = rs.store_id
             LEFT JOIN sale s ON rs.store_id = s.store_id
             JOIN sale_has_item shi ON item.item_id = shi.item_id
    WHERE rs.store_address = 'wanda street'-- input_store_address
      AND item.item_name = 'apple'-- input_item_name
      AND so.delivery_date IS NOT NULL
    GROUP BY so.order_id, so.delivery_date, ohi.unit_cost
    ORDER BY so.delivery_date, so.order_id;

    WHILE sale_quantity > 0 DO
    SELECT uc, in_stock INTO stack_cost, stack_quantity FROM fifo_stack LIMIT 1;
    IF sale_quantity > stack_quantity THEN
        SET sale_quantity = sale_quantity - stack_quantity;
        SET cost = cost + stack_quantity * stack_cost;
        DELETE FROM fifo_stack LIMIT 1;
    ELSE
        SET cost = cost + sale_quantity * stack_cost;
        SET sale_quantity = 0;
    END IF;
    END WHILE;

    DROP TEMPORARY TABLE IF EXISTS fifo_stack;
    RETURN cost;
END
//
DELIMITER ;

select COGS_real_time('wanda street', 'apple', 50);
