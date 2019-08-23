USE ims_SKU;

-- return a list of sales with specified customer name and sale date
DROP PROCEDURE IF EXISTS get_sales_by_cus_name;
DELIMITER //
CREATE PROCEDURE get_sales_by_cus_name(IN input_cus_name VARCHAR(30),
                                       IN input_sale_date DATE)
BEGIN
    SELECT c.cus_id, c.cus_name, s.sale_id, s.sale_date
    FROM customer c
             JOIN sale s on c.cus_id = s.cus_id
    WHERE 1 = 1
      AND (
        CASE
            WHEN input_cus_name IS NOT NULL THEN cus_name = input_cus_name
            ELSE 1 = 1
            END)
      AND (
        CASE
            WHEN input_sale_date IS NOT NULL THEN s.sale_date = input_sale_date
            ELSE 1 = 1
            END);
END//
DELIMITER ;

-- return a list of orders with specified vendor name (not null) and order date
DROP PROCEDURE IF EXISTS get_orders_by_ven_name;
DELIMITER //
CREATE PROCEDURE get_orders_by_ven_name(IN input_ven_name VARCHAR(30),
                                        IN input_order_date DATE)
BEGIN

    IF input_ven_name IS NULL THEN
        SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = 'Input Vendor ID Must Not Be NULL.';
    END IF;

    SELECT v.ven_id, v.ven_name, so.order_id, so.order_date, so.delivery_date
    FROM vendor v
             JOIN supply_order so on v.ven_id = so.ven_id
    WHERE v.ven_name = input_ven_name
      AND (
        CASE
            WHEN input_order_date IS NOT NULL THEN so.order_date = input_order_date
            ELSE 1 = 1
            END);
END//
DELIMITER ;

# (customer_name, sale_date)
CALL get_sales_by_cus_name('rod johnson', null);
CALL get_sales_by_cus_name(null, '20190711');

# (vendor_name NOT NULL, order_date) NOT delivery_date
# CALL get_orders_by_ven_name(null, null); # THIS WILL FAIL
CALL get_orders_by_ven_name('Ward, Shields and Oberbrunner', null);
CALL get_orders_by_ven_name('Olson, Mayert and Kessler', '20190626');
