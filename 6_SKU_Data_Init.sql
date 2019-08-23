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
       (2, 1, 'dragon fruit', 2.0),
       (3, 2, 'iphone x', 1000),
       (4, 3, 'xps 15', 1500),
       (5, 3, 'macbook air', 1100),
       (6, 1, 'banana', 0.3),
       (7, 1, 'cherry', 6),
       (8, 2, 'pixel 3', 800),
       (9, 2, 'pixel 3a', 400),
       (10, 4, 'prius prime 2020', 27600);


TRUNCATE TABLE vendor;
INSERT INTO vendor
VALUES (1, 'Ward, Shields and Oberbrunner', '5894 Hoeger Pines Suite 241', 'AZ', '19556',
        'sales fruits and apple products'),
       (2, 'Olson, Mayert and Kessler', '938 Jast Brook Apt. 535', 'IL', '55080',
        'sales fruits and laptops'),
       (3, 'Collins-Purdy', '01070 Alaina Key', 'MT', '63790',
        'only sales phones and prius prime');

TRUNCATE TABLE vendor_has_item;
INSERT INTO vendor_has_item
VALUES (1, 1),
       (1, 2),
       (1, 3),
       (1, 5),
       (1, 6),
       (1, 7),
       (2, 1),
       (2, 2),
#        (2, 3),
       (2, 4),
       (2, 5),
       (2, 6),
       (2, 7),
       (3, 3),
       (3, 8),
       (3, 9),
       (3, 10);

TRUNCATE TABLE retail_store;
INSERT INTO retail_store
VALUES (1, 'Wanda Street', 'MA', '02555'),
       (2, 'Vision Street', 'MA', '02156'),
       (3, 'Thanos Street', 'MA', '02133');

TRUNCATE inv_reminder;

TRUNCATE TABLE supply_order;
# THIS INSERTION IS FOR DEMO ONLY!!!
# THE USER SHALL NOT SET delivery_date!!!
# 1st week
INSERT INTO supply_order
# order_id, ven_id, store_id, order_date, delivery_date (null at first)
VALUES
    # wanda gets apples/dragon/banana and iphone from v1
    (1, 1, 1, 20190701, 20190703),
    # wanda gets iphone from v1
    (3, 1, 1, 20190701, 20190704),
    # wanda gets apples from v2
    (4, 2, 1, 20190702, 20190704),
    # vision gets apple & dragon from v1
    (5, 1, 2, 20190701, 20190704),
    # thanos gets pixel 3 & 3a & iphone x from v3
    (6, 3, 3, 20190701, 20190706),
    # thanos gets iphone x from v1
    (7, 1, 3, 20190702, 20190706);

# 1st week
TRUNCATE TABLE sku;
CALL insert_into_sku(1, 1, 100, 0.3);
CALL insert_into_sku(1, 2, 50, 0.8);
CALL insert_into_sku(1, 6, 50, 0.1);
CALL insert_into_sku(3, 3, 20, 799);
CALL insert_into_sku(4, 1, 250, 0.25);
CALL insert_into_sku(5, 1, 200, 0.35);
CALL insert_into_sku(5, 2, 70, 0.85);
CALL insert_into_sku(6, 8, 20, 750);
CALL insert_into_sku(6, 9, 20, 350);
CALL insert_into_sku(6, 3, 50, 789);
CALL insert_into_sku(7, 3, 25, 819);

TRUNCATE TABLE customer;
# USER SHALL NOT INSERT DIRECTLY TO customer!!!
INSERT INTO customer
VALUES (1, 'Rod Johnson'),
       (2, 'Meta Jenkins'),
       (3, 'Mr. Paris Miller MD');

TRUNCATE TABLE sale;
# store_id, sale_date, cus_id, cus_name, OUT sale_id;
CALL insert_into_sale(1, 20190703, 1, null, @s1_id);
CALL insert_into_sale(1, 20190704, 1, null, @s2_id);
CALL insert_into_sale(3, 20190704, 3, null, @s3_id);
CALL insert_into_sale(1, 20190705, 2, null, @s4_id);
CALL insert_into_sale(2, 20190704, 4, 'Darth Sidious', @s5_id);
CALL insert_into_sale(2, 20190706, 5, 'Darth Vader', @s6_id);
CALL insert_into_sale(3, 20190706, null, 'Solo', @s7_id);


TRUNCATE TABLE sale_has_sku;
# sale_id, item_id, quantity, sale_price
CALL insert_into_sale_has_sku(@s1_id, 1, 40, 0.45);
CALL insert_into_sale_has_sku(@s1_id, 2, 20, 2.5);
CALL insert_into_sale_has_sku(@s1_id, 6, 10, 0.25);
CALL insert_into_sale_has_sku(@s2_id, 3, 1, 989);
CALL insert_into_sale_has_sku(@s3_id, 8, 2, 849);
CALL insert_into_sale_has_sku(@s4_id, 1, 100, 0.4);
CALL insert_into_sale_has_sku(@s4_id, 2, 30, 2.4);
CALL insert_into_sale_has_sku(@s5_id, 2, 70, 2.69);
CALL insert_into_sale_has_sku(@s6_id, 1, 200, 0.5);
CALL insert_into_sale_has_sku(@s7_id, 8, 2, 799);

TRUNCATE hist_inv;
CALL save_inv_status_to_hist_inv(YEARWEEK(20190707) - 1);

# 2nd week
INSERT INTO supply_order
# order_id, ven_id, store_id, order_date, delivery_date (null at first)
VALUES # wanda gets macbook airs from v1
       (2, 1, 1, 20190702, 20190707),
       # vision gets mba & xps 15 from v2
       (8, 2, 2, 20190704, 20190707),
       # vision gets mba from v1
       (9, 1, 2, 20190708, 20190710),
       # thanos gets p3 from v3
       (10, 3, 3, 20190710, 20190713),
       # wanda gets apple & dragon from v1
       (11, 1, 1, 20190706, 20190709),
       # vision gets apple & dragon from v1
       (12, 1, 2, 20190708, 20190711),
       # vision gets apple & dragon & banana from v2
       (13, 2, 2, 20190708, 20190712)
;

# order_id, item_id, quantity, cost
CALL insert_into_sku(2, 5, 10, 1199);
CALL insert_into_sku(8, 5, 10, 1149);
CALL insert_into_sku(8, 4, 5, 1449);
CALL insert_into_sku(9, 5, 15, 1100);
CALL insert_into_sku(10, 8, 10, 699);
CALL insert_into_sku(11, 1, 100, 0.15);
CALL insert_into_sku(11, 2, 50, 1.75);
CALL insert_into_sku(12, 1, 150, 0.19);
CALL insert_into_sku(12, 2, 50, 1.99);
CALL insert_into_sku(13, 1, 50, 0.15);
CALL insert_into_sku(13, 2, 70, 1.85);
CALL insert_into_sku(13, 6, 150, 0.12);

# store_id, sale_date, cus_id, cus_name, OUT sale_id
CALL insert_into_sale(1, 20190707, 2, null, @s1_id);
CALL insert_into_sale(1, 20190708, null, null, @s2_id);
CALL insert_into_sale(1, 20190708, 1, null, @s3_id);
CALL insert_into_sale(1, 20190710, 1, null, @s4_id);
CALL insert_into_sale(2, 20190709, 4, null, @s5_id);
CALL insert_into_sale(2, 20190710, 5, null, @s6_id);
CALL insert_into_sale(2, 20190713, 2, null, @s7_id);
CALL insert_into_sale(2, 20190713, null, null, @s8_id);
CALL insert_into_sale(3, 20190709, null, null, @s9_id);
CALL insert_into_sale(3, 20190712, 6, null, @s10_id);

# sale_id, item_id, quantity, sale_price
CALL insert_into_sale_has_sku(@s1_id, 1, 99, 0.45);
CALL insert_into_sale_has_sku(@s1_id, 2, 20, 1.5);
CALL insert_into_sale_has_sku(@s1_id, 3, 1, 980);
CALL insert_into_sale_has_sku(@s2_id, 1, 20, 0.49);
CALL insert_into_sale_has_sku(@s2_id, 5, 2, 1249);
CALL insert_into_sale_has_sku(@s3_id, 1, 66, 0.29);
CALL insert_into_sale_has_sku(@s3_id, 2, 30, 1.69);
CALL insert_into_sale_has_sku(@s4_id, 5, 1, 949);
CALL insert_into_sale_has_sku(@s5_id, 1, 199, 0.39);
CALL insert_sale_return(@s5_id, 1, 198);
CALL insert_into_sale_has_sku(@s6_id, 1, 20, 0.99);
CALL insert_into_sale_has_sku(@s6_id, 2, 20, 2.99);
CALL insert_into_sale_has_sku(@s7_id, 1, 10, 0.59);
CALL insert_into_sale_has_sku(@s7_id, 6, 15, 0.3);
CALL insert_into_sale_has_sku(@s8_id, 5, 1, 1199);
CALL insert_into_sale_has_sku(@s9_id, 8, 2, 899);
CALL insert_into_sale_has_sku(@s9_id, 9, 1, 499);
CALL insert_into_sale_has_sku(@s10_id, 3, 1, 899);
CALL insert_into_sale_has_sku(@s10_id, 9, 1, 499);

CALL save_inv_status_to_hist_inv(YEARWEEK(20190714) - 1);

# 3rd week
INSERT INTO supply_order
# order_id, ven_id, store_id, order_date, delivery_date (null at first)
VALUES # wanda gets dragon & xps 15 from v2
       (14, 2, 1, 20190712, 20190715),
       # wanda gets cherry from v1
       (15, 1, 1, 20190714, 20190716),
       # wanda gets cherry from v2
       (16, 2, 1, 20190715, 20190716),
       # vision gets apple from v1
       (17, 1, 2, 20190711, 20190714),
       # vision gets p3 & p3a from v3
       (18, 3, 2, 20190715, 20190719),
       # vision gets apple & banana from v1
       (19, 1, 2, 20190718, 20190720),
       # vision gets apple from v2
       (20, 2, 2, 20190719, 20190720),
       # wanda gets ipx & mba from v1
       (21, 1, 1, 20190717, 20190719),
       # wanda gets mba from v2
       (22, 2, 1, 20190718, 20190720),
       # thanos gets xps from v2
       (23, 2, 3, 20190713, 20190717),
       # thanos gets xps from v2
       (24, 2, 3, 20190715, 20190718),
       # thanos gets toyota from v3
       (25, 3, 3, 20190703, 20190719),
       # thanos gets mba from v1
       (26, 1, 2, 20190716, 20190720);

# order_id, item_id, quantity, cost
CALL insert_into_sku(14, 2, 40, 1.19);
CALL insert_into_sku(14, 4, 2, 1300);
CALL insert_into_sku(15, 7, 100, 3.99);
CALL insert_into_sku(16, 7, 200, 4.19);
CALL insert_into_sku(17, 1, 200, 0.39);
CALL insert_into_sku(18, 8, 5, 649);
CALL insert_into_sku(18, 9, 15, 339);
CALL insert_into_sku(19, 1, 80, 0.25);
CALL insert_into_sku(19, 6, 120, 0.12);
CALL insert_into_sku(20, 1, 100, 0.29);
CALL insert_into_sku(21, 3, 15, 829);
CALL insert_into_sku(21, 5, 5, 999);
CALL insert_into_sku(22, 5, 5, 950);
CALL insert_into_sku(23, 4, 5, 1199);
CALL insert_into_sku(24, 4, 5, 1149);
CALL insert_into_sku(25, 10, 1, 25800);
CALL insert_into_sku(26, 5, 7, 920);

# store_id, sale_date, cus_id, cus_name, OUT sale_id
CALL insert_into_sale(1, 20190714, null, 'Ahsoka', @s1_id);
CALL insert_into_sale(1, 20190715, 2, null, @s2_id);
CALL insert_into_sale(1, 20190715, 3, null, @s3_id);
CALL insert_into_sale(1, 20190716, null, null, @s4_id);
CALL insert_into_sale(1, 20190716, 1, null, @s5_id);
CALL insert_into_sale(1, 20190717, 2, null, @s6_id);
CALL insert_into_sale(1, 20190718, null, null, @s7_id);
CALL insert_into_sale(1, 20190720, null, null, @s8_id);
CALL insert_into_sale(1, 20190720, 1, null, @s9_id);
CALL insert_into_sale(2, 20190714, 4, null, @s10_id);
CALL insert_into_sale(2, 20190714, 6, null, @s11_id);
CALL insert_into_sale(2, 20190715, 5, null, @s12_id);
CALL insert_into_sale(2, 20190716, 10, null, @s13_id);
CALL insert_into_sale(2, 20190716, null, 'Jar-Jar', @s14_id);
CALL insert_into_sale(2, 20190717, 3, null, @s15_id);
CALL insert_into_sale(2, 20190719, null, 'Obi-Wan', @s16_id);
CALL insert_into_sale(2, 20190720, 4, null, @s17_id);
CALL insert_into_sale(2, 20190715, 10, null, @s18_id);
CALL insert_into_sale(3, 20190717, null, null, @s19_id);
CALL insert_into_sale(3, 20190717, 4, null, @s20_id);
CALL insert_into_sale(3, 20190719, 5, null, @s21_id);
CALL insert_into_sale(3, 20190720, 3, null, @s22_id);
CALL insert_into_sale(3, 20190720, null, null, @s23_id);

# sale_id, item_id, quantity, sale_price
CALL insert_into_sale_has_sku(@s1_id, 1, 40, 0.7);
CALL insert_into_sale_has_sku(@s1_id, 5, 1, 1099);
CALL insert_into_sale_has_sku(@s1_id, 3, 1, 949);
CALL insert_into_sale_has_sku(@s2_id, 7, 20, 6.99);
CALL insert_into_sale_has_sku(@s2_id, 6, 40, 0.29);
CALL insert_into_sale_has_sku(@s3_id, 1, 70, 0.65);
CALL insert_into_sale_has_sku(@s3_id, 2, 10, 2.65);
CALL insert_sale_return(@s3_id, 1, 50);
CALL insert_into_sale_has_sku(@s4_id, 3, 2, 979);
CALL insert_into_sale_has_sku(@s5_id, 4, 1, 1599);
CALL insert_into_sale_has_sku(@s5_id, 1, 40, 0.4);
CALL insert_sale_return(@s5_id, 4, 1);
CALL insert_sale_return(@s5_id, 1, 10);
CALL insert_into_sale_has_sku(@s6_id, 3, 1, 979);
CALL insert_into_sale_has_sku(@s6_id, 2, 10, 2.1);
CALL insert_into_sale_has_sku(@s7_id, 5, 1, 1199);
CALL insert_into_sale_has_sku(@s7_id, 3, 1, 979);
CALL insert_into_sale_has_sku(@s8_id, 3, 2, 969);
CALL insert_into_sale_has_sku(@s8_id, 2, 15, 1.88);
CALL insert_sale_return(@s8_id, 3, 1);
CALL insert_into_sale_has_sku(@s9_id, 4, 1, 1499);
CALL insert_into_sale_has_sku(@s10_id, 6, 100, 0.39);
CALL insert_sale_return(@s10_id, 6, 99);
CALL insert_into_sale_has_sku(@s11_id, 1, 130, 0.6);
CALL insert_into_sale_has_sku(@s11_id, 4, 1, 1699);
CALL insert_into_sale_has_sku(@s12_id, 5, 2, 1139);
CALL insert_into_sale_has_sku(@s12_id, 8, 1, 899);
CALL insert_into_sale_has_sku(@s13_id, 6, 66, 0.66);
CALL insert_into_sale_has_sku(@s14_id, 5, 2, 1349);
CALL insert_into_sale_has_sku(@s15_id, 4, 1, 1499);
CALL insert_into_sale_has_sku(@s16_id, 1, 200, 0.29);
CALL insert_into_sale_has_sku(@s16_id, 2, 79, 1.19);
CALL insert_into_sale_has_sku(@s17_id, 9, 3, 449);
CALL insert_into_sale_has_sku(@s18_id, 6, 40, 5.99);
CALL insert_into_sale_has_sku(@s19_id, 3, 10, 959);
CALL insert_into_sale_has_sku(@s20_id, 3, 40, 939);
CALL insert_into_sale_has_sku(@s20_id, 4, 5, 1450);
CALL insert_into_sale_has_sku(@s20_id, 10, 1, 34999);
CALL insert_sale_return(@s20_id, 3, 39);
CALL insert_sale_return(@s20_id, 4, 4);
CALL insert_sale_return(@s20_id, 10, 1);
CALL insert_into_sale_has_sku(@s21_id, 10, 1, 32999);
CALL insert_into_sale_has_sku(@s21_id, 3, 15, 929);
CALL insert_into_sale_has_sku(@s22_id, 3, 15, 929);
CALL insert_into_sale_has_sku(@s23_id, 3, 2, 999);
CALL insert_into_sale_has_sku(@s23_id, 4, 1, 1499);
CALL insert_sale_return(@s12_id, 5, 2);
CALL insert_sale_return(@s16_id, 2, 9);

CALL save_inv_status_to_hist_inv(YEARWEEK(20190721) - 1);

# 4th week
INSERT INTO supply_order
# order_id, ven_id, store_id, order_date, delivery_date (null at first)
VALUES (27, 1, 1, 20190720, 20190723),
       (28, 2, 1, 20190724, 20190726),
       (29, 2, 2, 20190719, 20190721),
       (30, 2, 2, 20190721, 20190724),
       (31, 3, 2, 20190722, 20190726),
       (32, 3, 3, 20190719, 20190723),
       (33, 2, 3, 20190724, 20190727);

# order_id, item_id, quantity, cost
CALL insert_into_sku(27, 1, 200, 0.23);
CALL insert_into_sku(27, 2, 70, 1.49);
CALL insert_into_sku(27, 6, 300, 0.14);
CALL insert_into_sku(27, 7, 120, 2.49);
CALL insert_into_sku(28, 1, 100, 0.29);
CALL insert_into_sku(28, 2, 120, 2.49);
CALL insert_into_sku(28, 4, 1, 1299);
CALL insert_into_sku(29, 4, 2, 1249);
CALL insert_into_sku(29, 7, 120, 3.49);
CALL insert_into_sku(30, 2, 20, 1.49);
CALL insert_into_sku(31, 8, 10, 750);
CALL insert_into_sku(32, 3, 10, 849);
CALL insert_into_sku(32, 9, 10, 329);
CALL insert_into_sku(33, 4, 4, 1100);

# store_id, sale_date, cus_id, cus_name, OUT sale_id
CALL insert_into_sale(1, 20190721, null, null, @s1_id);
CALL insert_into_sale(1, 20190723, 3, null, @s2_id);
CALL insert_into_sale(1, 20190724, 3, null, @s3_id);
CALL insert_into_sale(1, 20190727, 1, null, @s4_id);
CALL insert_into_sale(2, 20190722, 2, null, @s5_id);
CALL insert_into_sale(2, 20190724, 4, null, @s6_id);
CALL insert_into_sale(2, 20190724, null, null, @s7_id);
CALL insert_into_sale(3, 20190721, 10, null, @s8_id);
CALL insert_into_sale(3, 20190722, 6, null, @s9_id);
CALL insert_into_sale(3, 20190725, 6, null, @s10_id);
CALL insert_into_sale(3, 20190727, 5, null, @s11_id);
CALL insert_into_sale(1, 20190725, 10, null, @s12_id);
CALL insert_into_sale(1, 20190725, 14, null, @s13_id);
CALL insert_into_sale(2, 20190726, 15, null, @s14_id);
CALL insert_into_sale(3, 20190727, null, null, @s15_id);

# sale_id, item_id, quantity, sale_price
CALL insert_into_sale_has_sku(@s1_id, 1, 25, 0.45);
CALL insert_into_sale_has_sku(@s1_id, 2, 5, 3.2);
CALL insert_into_sale_has_sku(@s2_id, 1, 50, 0.3);
CALL insert_into_sale_has_sku(@s3_id, 2, 10, 2.3);
CALL insert_into_sale_has_sku(@s3_id, 4, 1, 1499);
CALL insert_into_sale_has_sku(@s3_id, 5, 1, 1299);
CALL insert_into_sale_has_sku(@s4_id, 2, 40, 2.49);
CALL insert_into_sale_has_sku(@s4_id, 6, 100, 0.29);
CALL insert_into_sale_has_sku(@s4_id, 7, 100, 5.29);
CALL insert_sale_return(@s3_id, 4, 1);
CALL insert_into_sale_has_sku(@s5_id, 1, 100, 0.3);
CALL insert_into_sale_has_sku(@s6_id, 1, 110, 0.28);
CALL insert_into_sale_has_sku(@s6_id, 2, 20, 2.19);
CALL insert_into_sale_has_sku(@s6_id, 4, 1, 1449);
CALL insert_into_sale_has_sku(@s6_id, 6, 60, 0.24);
CALL insert_sale_return(@s6_id, 1, 40);
CALL insert_into_sale_has_sku(@s7_id, 6, 20, 0.29);
CALL insert_into_sale_has_sku(@s8_id, 4, 1, 1399);
CALL insert_into_sale_has_sku(@s9_id, 8, 5, 799);
CALL insert_sale_return(@s8_id, 4, 1);
CALL insert_into_sale_has_sku(@s10_id, 8, 5, 799);
CALL insert_into_sale_has_sku(@s10_id, 9, 2, 359);
CALL insert_into_sale_has_sku(@s11_id, 3, 10, 899);
CALL insert_into_sale_has_sku(@s12_id, 1, 50, 0.4);
CALL insert_into_sale_has_sku(@s12_id, 5, 1, 1299);
CALL insert_into_sale_has_sku(@s12_id, 7, 40, 5.9);
CALL insert_sale_return(@s12_id, 7, 40);
CALL insert_into_sale_has_sku(@s13_id, 1, 40, 0.38);
CALL insert_into_sale_has_sku(@s14_id, 9, 2, 389);
CALL insert_into_sale_has_sku(@s14_id, 5, 2, 1159);
CALL insert_into_sale_has_sku(@s15_id, 4, 1, 1499);

CALL save_inv_status_to_hist_inv(YEARWEEK(20190728) - 1);

# 5th week
INSERT INTO supply_order
# order_id, ven_id, store_id, order_date, delivery_date (null at first)
VALUES (34, 3, 3, 20190716, 20190802),
       (35, 1, 1, 20190726, 20190728),
       (36, 1, 1, 20190729, 20190730),
       (37, 1, 1, 20190730, 20190802),
       (38, 1, 2, 20190728, 20190730),
       (39, 2, 2, 20190728, 20190731),
       (40, 1, 2, 20190730, 20190803),
       (41, 3, 2, 20190731, 20190803),
       (42, 1, 3, 20190727, 20190731),
       (43, 2, 3, 20190729, 20190802),
       (44, 3, 3, 20190730, 20190803);

# order_id, item_id, quantity, cost
CALL insert_into_sku(34, 10, 2, 26799);
CALL insert_into_sku(34, 8, 10, 749);
CALL insert_into_sku(35, 3, 10, 799);
CALL insert_into_sku(35, 1, 100, 0.25);
CALL insert_into_sku(36, 2, 50, 1.59);
CALL insert_into_sku(37, 3, 20, 819);
CALL insert_into_sku(37, 5, 10, 899);
CALL insert_into_sku(37, 6, 100, 0.1);
CALL insert_into_sku(38, 1, 200, 0.29);
CALL insert_into_sku(38, 2, 50, 1.4);
CALL insert_into_sku(38, 6, 100, 0.12);
CALL insert_into_sku(39, 4, 10, 1220);
CALL insert_into_sku(39, 5, 20, 970);
CALL insert_into_sku(40, 3, 40, 849);
CALL insert_into_sku(41, 9, 10, 339);
CALL insert_into_sku(42, 3, 20, 749);
CALL insert_into_sku(42, 5, 5, 1049);
CALL insert_into_sku(43, 5, 5, 1070);
CALL insert_into_sku(44, 3, 10, 799);


# store_id, sale_date, cus_id, cus_name, OUT sale_id
CALL insert_into_sale(1, 20190726, 1, null, @s1_id);
CALL insert_into_sale(1, 20190727, null, 'Tenno', @s2_id);
CALL insert_into_sale(1, 20190727, 2, null, @s3_id);
CALL insert_into_sale(1, 20190727, 10, null, @s4_id);
CALL insert_into_sale(2, 20190730, null, null, @s5_id);
CALL insert_into_sale(2, 20190730, 7, null, @s6_id);
CALL insert_into_sale(2, 20190731, null, 'Lotus', @s7_id);
CALL insert_into_sale(3, 20190729, 4, null, @s8_id);
CALL insert_into_sale(3, 20190731, 5, null, @s9_id);


# sale_id, item_id, quantity, sale_price
CALL insert_into_sale_has_sku(@s1_id, 1, 75, 0.65);
CALL insert_into_sale_has_sku(@s1_id, 2, 40, 2.94);
CALL insert_into_sale_has_sku(@s1_id, 6, 50, 0.22);
CALL insert_into_sale_has_sku(@s2_id, 1, 50, 0.63);
CALL insert_into_sale_has_sku(@s2_id, 6, 50, 0.23);
CALL insert_into_sale_has_sku(@s2_id, 7, 50, 5.42);
CALL insert_into_sale_has_sku(@s3_id, 3, 5, 999);
CALL insert_into_sale_has_sku(@s3_id, 5, 1, 1299);
CALL insert_into_sale_has_sku(@s4_id, 1, 40, 0.58);
CALL insert_into_sale_has_sku(@s4_id, 4, 1, 1379);
CALL insert_into_sale_has_sku(@s4_id, 5, 2, 1249);
CALL insert_sale_return(@s3_id, 3, 1);
CALL insert_sale_return(@s4_id, 5, 1);
CALL insert_into_sale_has_sku(@s5_id, 1, 40, 0.5);
CALL insert_into_sale_has_sku(@s5_id, 2, 20, 2.38);
CALL insert_into_sale_has_sku(@s5_id, 7, 40, 5.58);
CALL insert_into_sale_has_sku(@s5_id, 8, 1, 858);
CALL insert_into_sale_has_sku(@s6_id, 9, 1, 399);
CALL insert_into_sale_has_sku(@s7_id, 1, 20, 0.45);
CALL insert_into_sale_has_sku(@s7_id, 5, 5, 1229);
CALL insert_into_sale_has_sku(@s8_id, 10, 1, 36499);
CALL insert_sale_return(@s8_id, 5, 1);
CALL insert_into_sale_has_sku(@s9_id, 10, 1, 34700);

CALL save_inv_status_to_hist_inv(YEARWEEK(20190804) - 1);

# 6th week
INSERT INTO supply_order
# order_id, ven_id, store_id, order_date, delivery_date (null at first)
VALUES (45, 1, 1, 20190803, 20190806),
       (46, 2, 1, 20190801, 20190806),
       (47, 3, 2, 20190801, 20190805),
       (48, 2, 1, 20190807, NULL),
       (49, 3, 2, 20190807, NULL),
       (50, 3, 3, 20190806, NULL);

# order_id, item_id, quantity, cost
CALL insert_into_sku(45, 1, 50, 0.3);
CALL insert_into_sku(45, 2, 20, 1.73);
CALL insert_into_sku(45, 6, 150, 0.2);
CALL insert_into_sku(46, 1, 50, 0.34);
CALL insert_into_sku(46, 7, 50, 3.2);
CALL insert_into_sku(47, 8, 5, 600);
CALL insert_into_sku(48, 1, 150, 0.3);
CALL insert_into_sku(48, 6, 70, 0.2);
CALL insert_into_sku(49, 8, 10, 719);
CALL insert_into_sku(49, 9, 20, 320);
CALL insert_into_sku(50, 10, 3, 27999);
CALL insert_into_sku(50, 8, 10, 670);
CALL insert_into_sku(50, 9, 10, 329);

# store_id, sale_date, cus_id, cus_name, OUT sale_id
CALL insert_into_sale(1, 20190805, 5, null, @s1_id);
CALL insert_into_sale(1, 20190807, 14, null, @s2_id);
CALL insert_into_sale(1, 20190807, 8, null, @s3_id);
CALL insert_into_sale(2, 20190807, 10, null, @s4_id);
CALL insert_into_sale(3, 20190806, null, null, @s5_id);

# sale_id, item_id, quantity, sale_price
CALL insert_into_sale_has_sku(@s1_id, 1, 100, 0.7);
CALL insert_into_sale_has_sku(@s1_id, 2, 100, 3.3);
CALL insert_into_sale_has_sku(@s1_id, 5, 2, 1299);
CALL insert_into_sale_has_sku(@s2_id, 1, 100, 0.6);
CALL insert_into_sale_has_sku(@s2_id, 2, 60, 3.6);
CALL insert_into_sale_has_sku(@s2_id, 6, 190, 0.26);
CALL insert_into_sale_has_sku(@s2_id, 7, 240, 4.99);
CALL insert_into_sale_has_sku(@s4_id, 1, 140, 0.49);
CALL insert_into_sale_has_sku(@s4_id, 2, 40, 4.49);
CALL insert_into_sale_has_sku(@s5_id, 5, 8, 1299);
CALL insert_sale_return(@s5_id, 5, 2);

SET FOREIGN_KEY_CHECKS = 1;

SELECT *
FROM inv_reminder;
CALL get_weekly_sale_by_item(null, null);
CALL get_total_profit_by_item(null, null, null, null);