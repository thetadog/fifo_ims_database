DROP DATABASE IF EXISTS ims;
CREATE DATABASE IF NOT EXISTS ims;
USE ims;


DROP TABLE IF EXISTS item_category;
CREATE TABLE IF NOT EXISTS item_category
(
    cat_id          INT PRIMARY KEY AUTO_INCREMENT,
    cat_name        VARCHAR(30),
    cat_description VARCHAR(255)
);


DROP TABLE IF EXISTS item;
CREATE TABLE IF NOT EXISTS item
(
    item_id         INT PRIMARY KEY AUTO_INCREMENT,
    cat_id          INT NOT NULL,
    item_name       VARCHAR(30),
    item_unit_price DECIMAL(8, 2),

    CONSTRAINT item_FK_cat FOREIGN KEY (cat_id) REFERENCES item_category (cat_id)
);

DROP TABLE IF EXISTS vendor;
CREATE TABLE IF NOT EXISTS vendor
(
    ven_id          INT PRIMARY KEY AUTO_INCREMENT,
    ven_name        VARCHAR(30),
    ven_address     VARCHAR(30),
    ven_state       CHAR(2),
    ven_zip         INT,
    ven_description VARCHAR(255)
);

DROP TABLE IF EXISTS vendor_has_item;
CREATE TABLE IF NOT EXISTS vendor_has_item
(
    ven_id  INT,
    item_id INT,

    PRIMARY KEY (ven_id, item_id),
    CONSTRAINT vi_fk_ven FOREIGN KEY (ven_id) REFERENCES vendor (ven_id),
    CONSTRAINT vi_fk_item FOREIGN KEY (item_id) REFERENCES item (item_id)
);


DROP TABLE IF EXISTS retail_store;
CREATE TABLE IF NOT EXISTS retail_store
(
    store_id      INT PRIMARY KEY AUTO_INCREMENT,
    store_address VARCHAR(255),
    store_state   CHAR(2),
    store_zip     INT
);


DROP TABLE IF EXISTS supply_order;
CREATE TABLE IF NOT EXISTS supply_order
(
    order_id      INT AUTO_INCREMENT UNIQUE,
    ven_id        INT,
    store_id      INT,
    order_date    DATE NOT NULL,
    delivery_date DATE DEFAULT NULL,

    PRIMARY KEY (order_id, ven_id, store_id),
    CONSTRAINT order_fk_ven FOREIGN KEY (ven_id) REFERENCES vendor (ven_id),
    CONSTRAINT order_fk_store FOREIGN KEY (store_id) REFERENCES retail_store (store_id)
);


DROP TABLE IF EXISTS order_has_item;
CREATE TABLE IF NOT EXISTS order_has_item
(
    order_id        INT,
    item_id         INT,
    order_quantity  INT NOT NULL,
    remain_quantity INT DEFAULT NULL,
    unit_cost       DECIMAL(8, 2),

    PRIMARY KEY (order_id, item_id),
    CONSTRAINT oi_fk_order FOREIGN KEY (order_id) REFERENCES supply_order (order_id),
    CONSTRAINT oi_fk_item FOREIGN KEY (item_id) REFERENCES item (item_id)
);


DROP TABLE IF EXISTS customer;
CREATE TABLE IF NOT EXISTS customer
(
    cus_id   INT PRIMARY KEY AUTO_INCREMENT,
    cus_name VARCHAR(30)
);


DROP TABLE IF EXISTS sale;
CREATE TABLE IF NOT EXISTS sale
(
    sale_id   INT AUTO_INCREMENT UNIQUE,
    store_id  INT,
    cus_id    INT,
    sale_date DATETIME NOT NULL,

    PRIMARY KEY (sale_id, store_id, cus_id),
    CONSTRAINT sale_fk_store FOREIGN KEY (store_id) REFERENCES retail_store (store_id),
    CONSTRAINT sale_fk_cus FOREIGN KEY (cus_id) REFERENCES customer (cus_id)
);


DROP TABLE IF EXISTS sale_has_item;
CREATE TABLE IF NOT EXISTS sale_has_item
(
    sale_id         INT,
    item_id         INT,
    sale_quantity   INT           NOT NULL,
    unit_sale_price DECIMAL(8, 2) NOT NULL,
    cogs            DECIMAL(8, 2) DEFAULT 0,

    PRIMARY KEY (sale_id, item_id),
    CONSTRAINT si_fk_sale FOREIGN KEY (sale_id) REFERENCES sale (sale_id),
    CONSTRAINT si_fk_item FOREIGN KEY (item_id) REFERENCES item (item_id)
);


DROP TRIGGER IF EXISTS VERIFY_VENDOR_FOR_ORDER_INSERTION;
DELIMITER //
CREATE TRIGGER VERIFY_VENDOR_FOR_ORDER_INSERTION
    BEFORE INSERT
    ON order_has_item
    FOR EACH ROW
BEGIN
    DECLARE message VARCHAR(255);
    DECLARE cur_ven_id INT;

    SELECT ven_id INTO cur_ven_id FROM supply_order WHERE order_id = NEW.order_id;

    IF (SELECT ven_id FROM vendor_has_item WHERE ven_id = cur_ven_id AND item_id = NEW.item_id) IS NULL THEN
        SELECT CONCAT('Vendor id=', cur_ven_id, ' is not selling Item id=', NEW.item_id,
                      '\nOrder can not be inserted. Update vendor_has_item table first.')
        INTO message;
        SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = message;
    END IF;
END//
DELIMITER ;


-- HELPER METHOD GET_STOCK: get stock for a given item in a given store
DROP FUNCTION IF EXISTS GET_STOCK;
DELIMITER //
CREATE FUNCTION GET_STOCK(input_item_id INT, input_store_id INT)
    RETURNS INT
    READS SQL DATA
BEGIN
    DECLARE stock INT;

    SELECT IF(sale.sq IS NULL, supply.oq - 0, supply.oq - sale.sq) AS in_stock
    INTO stock
    FROM (SELECT rs.store_id, i.item_id, i.cat_id, SUM(ohi.order_quantity) AS oq
          FROM item i
                   JOIN order_has_item ohi ON ohi.item_id = i.item_id
                   JOIN supply_order so ON ohi.order_id = so.order_id
                   JOIN retail_store rs ON so.store_id = rs.store_id
          WHERE so.delivery_date IS NOT NULL
          GROUP BY i.item_id, so.store_id, i.item_name) AS supply
             LEFT JOIN
         (SELECT rs.store_id, i.item_id, i.cat_id, SUM(shi.sale_quantity) AS sq
          FROM item i
                   JOIN sale_has_item shi ON shi.item_id = i.item_id
                   JOIN sale s ON shi.sale_id = s.sale_id
                   JOIN retail_store rs ON s.store_id = rs.store_id
          GROUP BY i.item_id, s.store_id, i.item_name) AS sale
         ON (supply.store_id = sale.store_id AND supply.item_id = sale.item_id)
    WHERE supply.store_id = input_store_id
      AND supply.item_id = input_item_id;
    RETURN stock;
END //
DELIMITER ;

-- SALE INSERTION TRIGGER
DROP TRIGGER IF EXISTS VERIFY_STOCK_FOR_SALE_INSERTION;
DELIMITER //
CREATE TRIGGER VERIFY_STOCK_FOR_SALE_INSERTION
    BEFORE INSERT
    ON sale_has_item
    FOR EACH ROW
BEGIN
    DECLARE message VARCHAR(255); -- The error message
    DECLARE cur_store_id INT;

    SELECT sale.store_id INTO cur_store_id FROM sale WHERE sale.sale_id = NEW.sale_id;

    IF GET_STOCK(NEW.item_id, cur_store_id) IS NULL OR NEW.sale_quantity > GET_STOCK(NEW.item_id, cur_store_id) THEN
        SELECT CONCAT('There are not enough Item id=', NEW.item_id, ' to sale in Store id=', cur_store_id,
                      '. Trying to sell ',
                      NEW.sale_quantity, ' but found only ',
                      IF(GET_STOCK(NEW.item_id, cur_store_id) IS NULL, 0, GET_STOCK(NEW.item_id, cur_store_id)))
        INTO message;
        SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = message;
    END IF;
END //
DELIMITER ;

# Insert into supply_order table procedure.
# Does not need delivery date as every order starts with a null delivery date.
# Delivery_date will be initialized by UPDATE_ORDER_FOR_DELIVERY procedure.
DROP PROCEDURE IF EXISTS INSERT_INTO_SUPPLY_ORDER;
DELIMITER //
CREATE PROCEDURE INSERT_INTO_SUPPLY_ORDER(IN input_order_id INT,
                                          IN input_ven_id INT,
                                          IN input_store_id INT,
                                          IN input_order_date DATE) # date can be ignored if set to NOW()
BEGIN
    INSERT INTO supply_order (order_id, ven_id, store_id, order_date)
    VALUES (input_order_id, input_ven_id, input_store_id, input_order_date);
END//
DELIMITER ;

# Insert into order_has_item table procedure.
# Does not need remain_quantity as every ohi starts with a null remain_quantity.
# Remain_quantity will be initialized by UPDATE_REMAIN_QUANTITY_FOR_DELIVERY procedure.
DROP PROCEDURE IF EXISTS INSERT_INTO_ORDER_HAS_ITEM;
DELIMITER //
CREATE PROCEDURE INSERT_INTO_ORDER_HAS_ITEM(IN input_order_id INT,
                                            IN input_item_id INT,
                                            IN input_order_quantity INT,
                                            IN input_unit_cost DECIMAL(8, 2))
BEGIN
    INSERT INTO order_has_item (order_id, item_id, order_quantity, unit_cost)
    VALUES (input_order_id, input_item_id, input_order_quantity, input_unit_cost);
END//
DELIMITER ;

# Insert into sale table procedure.
# Will create new customer if current customer id is not in customer table.
DROP PROCEDURE IF EXISTS INSERT_INTO_SALE;
DELIMITER //
CREATE PROCEDURE INSERT_INTO_SALE(IN input_sale_id INT,
                                  IN input_store_id INT,
                                  IN input_sale_date DATETIME, # can be ignored if set to NOW()
                                  IN input_cus_id INT,
                                  IN input_cus_name VARCHAR(30))
BEGIN
    IF input_cus_id IS NULL THEN
        INSERT INTO customer (cus_name) VALUES (input_cus_name);
    ELSEIF input_cus_id NOT IN (SELECT cus_id FROM customer) THEN
        INSERT INTO customer VALUES (input_cus_id, input_cus_name);
    END IF;
    INSERT INTO sale VALUES (input_sale_id, input_store_id, input_cus_id, input_sale_date);
END//
DELIMITER ;

# Use this procedure to insert values into sale_has_item table.
# COGS will be initialized as 0 at start and then calculated by this procedure.
# A trigger is not used since a trigger can not edit the table that triggers the trigger.
# Update remain_quantity in order_has_item table when a new SHI is added.
# Update cogs in SHI table when a new SHI is added.
DROP PROCEDURE IF EXISTS INSERT_INTO_SALE_HAS_ITEM;
DELIMITER //
CREATE PROCEDURE INSERT_INTO_SALE_HAS_ITEM(IN input_sale_id INT,
                                           IN input_item_id INT,
                                           IN input_sale_quantity INT,
                                           IN input_unit_sale_price DECIMAL(8, 2))
BEGIN
    DECLARE rs_id INT;
    DECLARE o_id INT;
    DECLARE stack_sale INT;
    DECLARE stack_remain INT;
    DECLARE stack_uc DECIMAL(8, 2);

    INSERT INTO sale_has_item VALUES (input_sale_id, input_item_id, input_sale_quantity, input_unit_sale_price, 0);

    SET stack_sale = input_sale_quantity;

    SELECT s.store_id
    INTO rs_id
    FROM sale_has_item shi
             JOIN sale s on shi.sale_id = s.sale_id
    WHERE s.sale_id = input_sale_id
      AND shi.item_id = input_item_id;

    DROP TEMPORARY TABLE IF EXISTS FIFO_STACK;
    CREATE TEMPORARY TABLE IF NOT EXISTS FIFO_STACK
    SELECT so.order_id AS order_id, ohi.item_id, ohi.unit_cost AS uc, so.delivery_date, ohi.remain_quantity AS remain
    FROM order_has_item ohi
             JOIN supply_order so ON ohi.order_id = so.order_id
    WHERE ohi.item_id = input_item_id
      AND so.store_id = rs_id
      AND so.delivery_date IS NOT NULL -- deal with non-delivered items; can be dropped if remain=NULL is default.
      AND ohi.remain_quantity > 0
    ORDER BY so.delivery_date;

    WHILE stack_sale > 0 DO
    SELECT order_id, uc, remain INTO o_id, stack_uc, stack_remain FROM FIFO_STACK LIMIT 1;

    IF stack_sale > stack_remain THEN
        # If sale is greater than current stack remain >> continue while, set remain quantity to 0.
        UPDATE order_has_item SET remain_quantity = 0 WHERE order_id = o_id AND item_id = input_item_id;

        # Update cogs with input sale id and item id.
        UPDATE sale_has_item shi
        SET cogs = cogs + stack_remain * stack_uc
        WHERE item_id = input_item_id
          AND sale_id = input_sale_id;

        # Update sale for next stack.
        SET stack_sale = stack_sale - stack_remain;

        DELETE FROM FIFO_STACK LIMIT 1;
    ELSE
        # If sale is smaller than current stack remain >> end while, set new stack remain.
        UPDATE order_has_item ohi
        SET ohi.remain_quantity = ohi.remain_quantity - stack_sale
        WHERE ohi.order_id = o_id
          AND ohi.item_id = input_item_id;

        # Update cogs with input sale id and item id.
        UPDATE sale_has_item shi
        SET cogs = cogs + stack_sale * stack_uc
        WHERE item_id = input_item_id
          AND sale_id = input_sale_id;

        SET stack_sale = 0;
    END IF;
    END WHILE;

    DROP TEMPORARY TABLE IF EXISTS FIFO_STACK;

END//
DELIMITER ;

# Set delivery date to now() when an order has been delivered.
DROP PROCEDURE IF EXISTS UPDATE_ORDER_FOR_DELIVERY;
DELIMITER //
CREATE PROCEDURE UPDATE_ORDER_FOR_DELIVERY(
    IN input_order_id INT
)
BEGIN
    IF (SELECT delivery_date FROM supply_order WHERE order_id = input_order_id) IS NULL THEN
        UPDATE supply_order o
        SET o.delivery_date = NOW()
        WHERE o.order_id = input_order_id;
    END IF;
END//
DELIMITER ;

# Set remain quantity to order quantity when the order has been delivered.
DROP TRIGGER IF EXISTS UPDATE_REMAIN_QUANTITY_FOR_DELIVERY;
DELIMITER //
CREATE TRIGGER UPDATE_REMAIN_QUANTITY_FOR_DELIVERY
    AFTER UPDATE
    ON supply_order
    FOR EACH ROW
BEGIN
    IF OLD.delivery_date IS NULL AND NEW.delivery_date IS NOT NULL THEN
        UPDATE order_has_item ohi
        SET ohi.remain_quantity = ohi.order_quantity
        WHERE ohi.order_id = NEW.order_id;
    END IF;
END//
DELIMITER ;

/*
 We do not deal with order that was delivered but forgot to insert into the DB.
 DB will treat this 'old' order as a new one and set its delivery date to now().
*/

/*
 Return 1 if vendor has specified item. return 0 if not
 INPUT SEQUENCE: ITEM ID, VENDOR ID
 */
DROP FUNCTION IF EXISTS CHECK_VHI_FOR_OHI_INSERTION;
DELIMITER //
CREATE FUNCTION CHECK_VHI_FOR_OHI_INSERTION(input_item_id INT, input_vendor_id INT)
    RETURNS BOOLEAN
    READS SQL DATA
BEGIN
    DECLARE sell_item BOOLEAN DEFAULT FALSE;

    IF input_item_id IN (SELECT item_id FROM vendor_has_item WHERE ven_id = input_vendor_id) THEN
        SET sell_item = TRUE;
    END IF;
    RETURN sell_item;
END//
DELIMITER ;

/*
 Return 1 if there is enough stock to sell. return 0 if not
 INPUT SEQUENCE: ITEM ID, STORE ID, SALE QUANTITY
 */
DROP FUNCTION IF EXISTS CHECK_STOCK_FOR_SHI_INSERTION;
DELIMITER //
CREATE FUNCTION CHECK_STOCK_FOR_SHI_INSERTION(input_item_id INT, input_store_id INT, input_sale_quantity INT)
    RETURNS BOOLEAN
    READS SQL DATA
BEGIN
    DECLARE has_enough_item BOOLEAN DEFAULT TRUE;
    DECLARE stock INT;
    SELECT GET_STOCK(input_item_id, input_store_id) INTO stock;

    IF stock IS NULL OR input_sale_quantity > stock THEN
        SET has_enough_item = FALSE;
    END IF;
    RETURN has_enough_item;
END//
DELIMITER ;