USE ims;

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE item_category;
INSERT INTO item_category
VALUES (1, 'fruit', 'this is a fruit'),
       (2, 'phone', 'this is a phone'),
       (3, 'laptop', 'this is a laptop'),
       (4, 'car', 'this is a car');

TRUNCATE TABLE item;
INSERT INTO item
VALUES (1, 1, 'apple', 0.5),
       (2, 1, 'dragon fruit', 1.0),
       (3, 2, 'iphone x', 1000),
       (4, 3, 'xps 15', 1500),
       (5, 3, 'macbook air', 1100);

TRUNCATE TABLE vendor;
INSERT INTO vendor
VALUES (1, 'Ward, Shields and Oberbrunner', '5894 Hoeger Pines Suite 241', 'AZ', '19556', NULL),
       (2, 'Olson, Mayert and Kessler', '938 Jast Brook Apt. 535', 'IL', '55080',
        'sales phones and laptop'),
       (3, 'Collins-Purdy', '01070 Alaina Key', 'MT', '63790',
        'only sales iphone x');

TRUNCATE TABLE vendor_has_item;
INSERT INTO vendor_has_item
VALUES (1, 1),
       (1, 2),
       (1, 5),
       (2, 1),
       (2, 2),
       (2, 3),
       (2, 4),
       (2, 5),
       (3, 3);

TRUNCATE TABLE retail_store;
INSERT INTO retail_store
VALUES (1, 'Wanda Street', 'MA', '02555'),
       (2, 'Vision Street', 'MA', '02156'),
       (3, 'Thanos Street', 'MA', '02133');

TRUNCATE TABLE supply_order;
# THIS INSERTION IS FOR DEMO ONLY!!!
# THE USER SHALL NOT SET delivery_date!!!
INSERT INTO supply_order
VALUES (1, 1, 1, '2019-05-26', '2019-06-07'),
       (2, 1, 1, '2019-06-06', '2019-06-10'),
       (3, 2, 2, '2019-06-23', '2019-07-02'),
       (4, 2, 1, '2019-06-26', '2019-07-08'),
       (5, 1, 2, '2019-07-05', '2019-07-29');
# USE CALL INSERT_INTO_SUPPLY_ORDER(order_id, ven_id, store_id, order_date) FOR JAVA INSTEAD!
CALL INSERT_INTO_SUPPLY_ORDER(6, 2, 2, '2019-07-18');

TRUNCATE TABLE order_has_item;
# THIS INSERTION IS FOR DEMO ONLY!!!
# THE USER SHALL NOT SET remain_quantity!!!
INSERT INTO order_has_item
VALUES (1, 1, 50, 50, 0.2),
       (1, 2, 50, 50, 1.1),
       (2, 1, 100, 100, 0.15),
       (2, 2, 70, 70, 1.05),
       (3, 3, 10, 10, 800),
       (4, 5, 5, 5, 1200),
       (5, 1, 200, 200, 0.15);
# USE CALL INSERT_INTO_ORDER_HAS_ITEM (order_id, item_id, order_quantity, unit_cost) FOR JAVA INSTEAD!
CALL INSERT_INTO_ORDER_HAS_ITEM(6, 5, 20, 1100);

TRUNCATE TABLE customer;
INSERT INTO customer
VALUES (1, 'Rod Johnson'),
       (2, 'Meta Jenkins'),
       (3, 'Mr. Paris Miller MD'),
       (4, 'Martina Orn'),
       (5, 'Brisa Hane');

TRUNCATE TABLE sale;
INSERT INTO sale
VALUES (1, 1, 1, '2019-06-09 12:23:11'),
       (2, 1, 1, '2019-06-09 12:33:01'),
       (3, 1, 2, '2019-06-09 19:03:39'),
       (4, 1, 4, '2019-07-11 10:38:10');

TRUNCATE TABLE sale_has_item;
# sale_has_item table can only be inserted by calling INSERT_INTO_SALE_HAS_ITEM!!!
# CALL INSERT_INTO_SALE_HAS_ITEM(sale_id, item_id, sale_quantity, unit_sale_price);
CALL INSERT_INTO_SALE_HAS_ITEM(1, 1, 20, 0.3);
CALL INSERT_INTO_SALE_HAS_ITEM(2, 1, 10, 0.3);
CALL INSERT_INTO_SALE_HAS_ITEM(2, 2, 5, 2.0);
CALL INSERT_INTO_SALE_HAS_ITEM(3, 2, 10, 1.8);
CALL INSERT_INTO_SALE_HAS_ITEM(4, 1, 20, 0.4);
CALL INSERT_INTO_SALE_HAS_ITEM(4, 5, 1, 1499);

# INSERT INTO sale_has_item
# VALUES (1, 1, 20, 0.3),
#        (2, 1, 10, 0.3),
#        (2, 2, 5, 2.0),
#        (3, 2, 10, 1.8),
#        (4, 1, 20, 0.4),
#        (4, 5, 1, 1499);

SET FOREIGN_KEY_CHECKS = 1;

CALL INV_STATUS(NULL,NULL,NULL);