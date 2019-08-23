USE ims;

DROP PROCEDURE IF EXISTS PROFIT_STATUS_BY_ITEM;
DELIMITER //
CREATE PROCEDURE PROFIT_STATUS_BY_ITEM(IN input_store_id INT,
                                       IN input_item_id INT,
                                       IN input_weekly BOOLEAN, -- if false(0) then display total sale by far
                                       IN input_order_by VARCHAR(30)) -- input_order_by MUST BE PRESET!
BEGIN

    DROP TEMPORARY TABLE IF EXISTS profit_temp_table;
    CREATE TEMPORARY TABLE IF NOT EXISTS profit_temp_table
    SELECT rs.store_id                                             AS rs_id,
           rs.store_address                                        AS rs_name,
           i.item_id                                               AS i_id,
           i.item_name                                             AS i_name,
           s.sale_id                                               AS s_id,
           s.sale_date                                             AS s_date,
           SUM(shi.sale_quantity * shi.unit_sale_price - shi.cogs) AS profit
    FROM item i
             RIGHT JOIN sale_has_item shi ON i.item_id = shi.item_id
             RIGHT JOIN sale s ON shi.sale_id = s.sale_id
             RIGHT JOIN retail_store rs ON s.store_id = rs.store_id
    GROUP BY rs.store_id, rs.store_address, i.item_id, i.item_name, s.sale_id, s.sale_date;

    IF input_weekly = 1 THEN
        SET @sql = 'SELECT rs_id, rs_name, YEARWEEK(s_date) AS year_week, i_id, i_name, SUM(profit) AS profit
                    FROM profit_temp_table WHERE 1 = 1';
    ELSE
        SET @sql = 'SELECT rs_id, rs_name, i_id, i_name, SUM(profit) AS profit
                    FROM profit_temp_table WHERE 1 = 1';
    END IF;

    IF input_store_id IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND rs_id = "', input_store_id, '"');
    END IF;

    IF input_item_id IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND i_id= "', input_item_id, '"');
    END IF;

    IF input_weekly = 1 THEN
        SET @sql = CONCAT(@sql, ' GROUP BY rs_id, rs_name, year_week, i_id, i_name');
    ELSE
        SET @sql = CONCAT(@sql, ' GROUP BY rs_id, rs_name, i_id, i_name');
    END IF;

    IF input_order_by IS NOT NULL THEN
        IF input_weekly = 1 AND
            -- ORDER BY PRESET
           input_order_by IN
           ('rs_id', 'rs_name', 'year_week', 'year_week desc', 'i_id' 'i_name', 'profit', 'profit desc') THEN
            SET @sql = CONCAT(@sql, ' ORDER BY ', input_order_by);
        ELSEIF input_weekly = 0 AND
               input_order_by IN ('rs_id', 'rs_name', 'i_id', 'i_name', 'profit', 'profit desc') THEN
            SET @sql = CONCAT(@sql, ' ORDER BY ', input_order_by);
        ELSE
            SET @sql = CONCAT(@sql, ' ORDER BY rs_id, i_id, profit');
        END IF;
    ELSE
        SET @sql = CONCAT(@sql, ' ORDER BY rs_id, i_id, profit');
    END IF;

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

END//
DELIMITER ;


DROP PROCEDURE IF EXISTS PROFIT_STATUS_BY_CAT;
DELIMITER //
CREATE PROCEDURE PROFIT_STATUS_BY_CAT(IN input_store_id INT,
                                      IN input_cat_id INT,
                                      IN input_weekly BOOLEAN,
                                      IN input_order_by VARCHAR(30))
BEGIN
    DROP TEMPORARY TABLE IF EXISTS profit_temp_table;
    CREATE TEMPORARY TABLE IF NOT EXISTS profit_temp_table
    SELECT rs.store_id                                             AS rs_id,
           rs.store_address                                        AS rs_name,
           ic.cat_id                                               AS ic_id,
           ic.cat_name                                             AS ic_name,
           s.sale_id                                               AS s_id,
           s.sale_date                                             AS s_date,
           SUM(shi.sale_quantity * shi.unit_sale_price - shi.cogs) AS profit
    FROM item_category ic
             RIGHT JOIN item i ON ic.cat_id = i.cat_id
             RIGHT JOIN sale_has_item shi ON i.item_id = shi.item_id
             RIGHT JOIN sale s ON shi.sale_id = s.sale_id
             RIGHT JOIN retail_store rs ON s.store_id = rs.store_id
    GROUP BY rs.store_id, rs.store_address, ic.cat_id, ic.cat_name, s.sale_id, s.sale_date;

    IF input_weekly = 1 THEN
        SET @sql = 'SELECT rs_id, rs_name, YEARWEEK(s_date) AS year_week, ic_id, ic_name, SUM(profit) AS profit
                    FROM profit_temp_table WHERE 1 = 1';
    ELSE
        SET @sql = 'SELECT rs_id, rs_name, ic_id, ic_name, SUM(profit) AS profit
                    FROM profit_temp_table WHERE 1 = 1';
    END IF;

    IF input_store_id IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND rs_id = "', input_store_id, '"');
    END IF;

    IF input_cat_id IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND ic_id= "', input_cat_id, '"');
    END IF;

    IF input_weekly = 1 THEN
        SET @sql = CONCAT(@sql, ' GROUP BY rs_id, rs_name, year_week, ic_id, ic_name');
    ELSE
        SET @sql = CONCAT(@sql, ' GROUP BY rs_id, rs_name, ic_id, ic_name');
    END IF;

    IF input_order_by IS NOT NULL THEN
        IF input_weekly = 1 AND
            -- ORDER BY PRESET
           input_order_by IN
           ('rs_id', 'rs_name', 'year_week', 'year_week desc', 'ic_id' 'ic_name', 'profit', 'profit desc') THEN
            SET @sql = CONCAT(@sql, ' ORDER BY ', input_order_by);
        ELSEIF input_weekly = 0 AND
               input_order_by IN ('rs_id', 'rs_name', 'ic_id', 'ic_name', 'profit', 'profit desc') THEN
            SET @sql = CONCAT(@sql, ' ORDER BY ', input_order_by);
        ELSE
            SET @sql = CONCAT(@sql, ' ORDER BY rs_id, ic_id, profit');
        END IF;
    ELSE
        SET @sql = CONCAT(@sql, ' ORDER BY rs_id, ic_id, profit');
    END IF;

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;
