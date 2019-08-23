USE ims;

DROP PROCEDURE IF EXISTS SALE_STATUS_BY_ITEM;
DELIMITER //
CREATE PROCEDURE SALE_STATUS_BY_ITEM(IN input_store_id INT,
                                     IN input_item_id INT,
                                     IN input_weekly BOOLEAN, -- if false(0) then display total sale by far
                                     IN input_order_by VARCHAR(30)) -- input_order_by MUST BE PRESET!
BEGIN
    DROP TEMPORARY TABLE IF EXISTS sale_status_temp_table;
    CREATE TEMPORARY TABLE IF NOT EXISTS sale_status_temp_table
    SELECT rs.store_id                                  AS rs_id,
           rs.store_address                             AS rs_name,
           i.item_id                                    AS i_id,
           i.item_name                                  AS i_name,
           s.sale_id                                    AS s_id,
           s.sale_date                                  AS s_date,
           SUM(shi.sale_quantity * shi.unit_sale_price) AS sale_amt
    FROM retail_store rs
             LEFT JOIN sale s ON rs.store_id = s.store_id
             LEFT JOIN sale_has_item shi ON s.sale_id = shi.sale_id
             LEFT JOIN item i ON shi.item_id = i.item_id
    GROUP BY rs_id, rs_name, s_id, s_date, i_id, i_name;

    DROP TEMPORARY TABLE IF EXISTS sale_by_item_temp_table;
    IF input_weekly = 1 THEN
        SET @sql = 'SELECT rs_id, rs_name, YEARWEEK(s_date) AS year_week, i_id, i_name, SUM(sale_amt) AS sale
                    FROM sale_status_temp_table WHERE 1 = 1';
    ELSE
        SET @sql = 'SELECT rs_id, rs_name, i_id, i_name, SUM(sale_amt) AS sale
                    FROM sale_status_temp_table WHERE 1 = 1';
    END IF;

    IF input_store_id IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND rs_id = "', input_store_id, '"');
    END IF;

    IF input_item_id IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND i_id = "', input_item_id, '"');
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
           ('rs_id', 'rs_name', 'year_week', 'year_week desc', 'i_id', 'i_name', 'sale', 'sale desc') THEN
            SET @sql = CONCAT(@sql, ' ORDER BY ', input_order_by);
        ELSEIF input_weekly = 0 AND input_order_by IN ('rs_id', 'rs_name', 'i_id', 'i_name', 'sale', 'sale desc') THEN
            SET @sql = CONCAT(@sql, ' ORDER BY ', input_order_by);
        ELSE
            SET @sql = CONCAT(@sql, ' ORDER BY rs_id, i_name, sale');
        END IF;
    ELSE
        SET @sql = CONCAT(@sql, ' ORDER BY rs_id, i_id, sale');
    END IF;

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

END//
DELIMITER ;


DROP PROCEDURE IF EXISTS SALE_STATUS_BY_CAT;
DELIMITER //
CREATE PROCEDURE SALE_STATUS_BY_CAT(IN input_store_id INT,
                                    IN input_cat_id INT,
                                    IN input_weekly BOOLEAN,
                                    IN input_order_by VARCHAR(30))
BEGIN
    DROP TEMPORARY TABLE IF EXISTS sale_status_temp_table;
    CREATE TEMPORARY TABLE IF NOT EXISTS sale_status_temp_table
    SELECT rs.store_id                                  AS rs_id,
           rs.store_address                             AS rs_name,
           ic.cat_id                                    AS ic_id,
           ic.cat_name                                  AS ic_name,
           s.sale_id                                    AS s_id,
           s.sale_date                                  AS s_date,
           SUM(shi.sale_quantity * shi.unit_sale_price) AS sale_amt
    FROM retail_store rs
             LEFT JOIN sale s on rs.store_id = s.store_id
             LEFT JOIN sale_has_item shi on s.sale_id = shi.sale_id
             LEFT JOIN item i on shi.item_id = i.item_id
             LEFT JOIN item_category ic on i.cat_id = ic.cat_id
    GROUP BY rs_id, rs_name, s_id, s_date, ic_id, ic_name;

    IF input_weekly = 1 THEN
        SET @sql = 'SELECT rs_id, rs_name, YEARWEEK(s_date) AS year_week, ic_id, ic_name, SUM(sale_amt) AS sale
        FROM sale_status_temp_table WHERE 1 = 1';
    ELSE
        SET @sql =
                'SELECT rs_id, rs_name, ic_id, ic_name, SUM(sale_amt) AS sale FROM sale_status_temp_table WHERE 1 = 1';
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
           ('rs_id', 'rs_name', 'year_week', 'year_week desc', 'ic_id', 'ic_name', 'sale', 'sale desc') THEN
            SET @sql = CONCAT(@sql, ' ORDER BY ', input_order_by);
        ELSEIF input_weekly = 0 AND input_order_by IN ('rs_id', 'rs_name', 'ic_id', 'ic_name', 'sale', 'sale desc') THEN
            SET @sql = CONCAT(@sql, ' ORDER BY ', input_order_by);
        ELSE
            SET @sql = CONCAT(@sql, ' ORDER BY rs_id, ic_id, sale');
        END IF;
    ELSE
        SET @sql = CONCAT(@sql, ' ORDER BY rs_id, ic_id, sale');
    END IF;

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;

# call INV_STATUS(null,null,null);
# call SALE_STATUS_BY_ITEM(null,null,null,null);
# call PROFIT_STATUS_BY_CAT(null,null,null,null);
# select *
# from order_has_item;
# update supply_order
# set delivery_date = now() where order_id = 6;