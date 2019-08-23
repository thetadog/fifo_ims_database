USE ims_SKU;

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
# TODO: should use insert_into_supply_order(vendor_id, store_id, order_date)
INSERT INTO supply_order
VALUES (1, 1, 1, '2019-05-26', '2019-06-07'),
       (2, 1, 1, '2019-06-06', '2019-06-10'),
       (3, 2, 2, '2019-06-23', '2019-07-02'),
       (4, 2, 1, '2019-06-26', '2019-07-08'),
       (5, 1, 2, '2019-07-05', '2019-07-29');


TRUNCATE TABLE sku;
# TODO: should use insert_into_sku(order_id, item_id, order_quantity, unit_cost)
INSERT INTO sku # skuid, orderid, itemid
VALUES (1, 1, 1, 50, 0.2),
       (2, 1, 2, 50, 1.1),
       (3, 2, 1, 100, 0.15),
       (4, 2, 2, 70, 1.05),
       (5, 3, 3, 10, 800),
       (6, 4, 5, 5, 1200),
       (7, 5, 1, 200, 0.15);

TRUNCATE TABLE customer;
# USER SHALL NOT INSERT DIRECTLY TO customer!!!
# TODO: USE insert_into_sale(store_id, sale_date, customer_id, customer_name) INSTEAD!!!
INSERT INTO customer
VALUES (1, 'Rod Johnson'),
       (2, 'Meta Jenkins'),
       (3, 'Mr. Paris Miller MD'),
       (4, 'Martina Orn'),
       (5, 'Brisa Hane');

TRUNCATE TABLE sale;
# TODO: should use insert_into_sale(store_id, sale_date, customer_id, customer_name)
# customer id and customer_name can be null or non-exist in customer table
INSERT INTO sale
VALUES (1, 1, 1, '2019-06-11'),
       (2, 1, 1, '2019-06-11'),
       (3, 1, 2, '2019-06-11');

TRUNCATE TABLE sale_has_sku;
# TODO: MUST USE insert_into_sale_has_sku(sale_id, item_id, sale_quantity, unit_sale_price)
CALL insert_into_sale_has_sku(1, 1, 20, 0.3);
CALL insert_into_sale_has_sku(2, 1, 50, 0.35);
CALL insert_into_sale_has_sku(3, 1, 20, 0.3);

CALL save_inv_status_to_hist_inv(201923);
CALL save_inv_status_to_hist_inv(201924);
CALL save_inv_status_to_hist_inv(201925);
CALL save_inv_status_to_hist_inv(201926);
CALL save_inv_status_to_hist_inv(201927);
CALL save_inv_status_to_hist_inv(201928);

INSERT INTO sale
VALUES (4, 1, 4, '2019-07-25');

# THIS SHOULD FAIL; ROLLED BACK BY TRANSACTION
CALL insert_into_sale_has_sku(4, 4, 3, 900);

# THIS SHOULD SUCCEED
CALL insert_into_sale_has_sku(4, 1, 30, 0.4);

# Should be exactly the same as
# INSERT INTO sale_has_sku
# VALUES (1, 1, 20, 0.3),
#        (2, 1, 30, 0.35),
#        (2, 3, 20, 0.35),
#        (3, 3, 20, 0.3);
# (sale_id, sku_id, quantity, price)

CALL save_inv_status_to_hist_inv(201929);
CALL save_inv_status_to_hist_inv(201930);
CALL save_inv_status_to_hist_inv(201931);

SET FOREIGN_KEY_CHECKS = 1;