# Триггеры, поддержка заполнения витрин 
_____

- Цели
  - Создать триггер для поддержки витрины в актуальном состоянии.
  
1.***Создаем и заполняем таблицу товары.***
```sql
postgres=# CREATE TABLE goods
(
    goods_id    integer PRIMARY KEY,
    good_name   varchar(63) NOT NULL,
    good_price  numeric(12, 2) NOT NULL CHECK (good_price > 0.0)
);
CREATE TABLE

postgres=# INSERT INTO goods (goods_id, good_name, good_price)
VALUES  (1, 'Спички хозайственные', .50),
                (2, 'Автомобиль Ferrari FXX K', 185000000.01);
INSERT 0 2

postgres=# select * from goods;
 goods_id |        good_name         |  good_price
----------+--------------------------+--------------
        1 | Спички хозайственные     |         0.50
        2 | Автомобиль Ferrari FXX K | 185000000.01
(2 rows)
```
2.***Создаем и заполняем таблицу продажи.***
```sql
postgres=# CREATE TABLE sales
(
    sales_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    good_id     integer REFERENCES goods (goods_id),
    sales_time  timestamp with time zone DEFAULT now(),
    sales_qty   integer CHECK (sales_qty > 0)
);

INSERT INTO sales (good_id, sales_qty) VALUES (1, 10), (1, 1), (1, 120), (2, 1);
CREATE TABLE
INSERT 0 4

postgres=# select * from sales;
 sales_id | good_id |          sales_time           | sales_qty
----------+---------+-------------------------------+-----------
        1 |       1 | 2024-03-01 04:38:30.770634-09 |        10
        2 |       1 | 2024-03-01 04:38:30.770634-09 |         1
        3 |       1 | 2024-03-01 04:38:30.770634-09 |       120
        4 |       2 | 2024-03-01 04:38:30.770634-09 |         1
(4 rows)
```
3.***Получаем отчет.***
```sql
postgres=# SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
        good_name         |     sum
--------------------------+--------------
 Автомобиль Ferrari FXX K | 185000000.01
 Спички хозайственные     |        65.50
(2 rows)
```
4.***Принято решение денормализовать БД, создать таблицу.***
```sql
postgres=# CREATE TABLE good_sum_mart
(
        good_name   varchar(63) NOT NULL,
        sum_sale        numeric(16, 2)NOT NULL
);
CREATE TABLE
```
>Передсозданием тригеров заполняем таблицу витрин

```sql
postgres=# INSERT INTO good_sum_mart SELECT G.good_name, sum(G.good_price * S.sales_qty) AS sum_sale
  FROM goods G
  INNER JOIN sales S ON S.good_id = G.goods_id
  GROUP BY G.good_name;
  
postgres=# select * from good_sum_mart;

good_name               |sum_sale    |
------------------------+------------+
Автомобиль Ferrari FXX K|185000000.01|
Спички хозайственные    |      105.50| 
```
5.***Создать триггер на таблице продаж, для поддержки данных в витрине в актуальном состоянии (вычисляющий при каждой продаже сумму и записывающий её в витрину)***
>При добавлении следует добавление текущей стоимости записи, либо добавление новой записи в таблицу со значением записи

```sql
postgres=# CREATE or replace function pr_ins_sales()
RETURNS trigger
AS
$TRIG_FUNC$
DECLARE
s_name varchar(63);
s_price numeric(12,2);
BEGIN
SELECT G.good_name, G.good_price*NEW.sales_qty INTO s_name, s_price FROM goods G where G.goods_id = NEW.good_id;
IF EXISTS(select from good_sum_mart T where T.good_name = s_name)
THEN UPDATE good_sum_mart T SET sum_sale = sum_sale + s_price where T.good_name = s_name;
ELSE INSERT INTO good_sum_mart (good_name, sum_sale) values(s_name, s_price);
END IF;
RETURN NEW;
END;
$TRIG_FUNC$
LANGUAGE plpgsql;

postgres=# CREATE TRIGGER tr_ins_sales
AFTER INSERT
ON sales
FOR EACH ROW
EXECUTE PROCEDURE pr_ins_sales();
```
>При удалении следует вычитание текущей стоимости записи с последующим удалением строк, у которых стоимость меньше либо равна 0.

```sql
postgres=# CREATE or replace function pr_del_sales()
RETURNS trigger
AS
$TRIG_FUNC$
DECLARE
s_name varchar(63);
s_price numeric(12,2);
BEGIN
SELECT G.good_name, G.good_price*OLD.sales_qty INTO s_name, s_price FROM goods G where G.goods_id = OLD.good_id;
IF EXISTS(select from good_sum_mart T where T.good_name = s_name)
THEN 
UPDATE good_sum_mart T SET sum_sale = sum_sale - s_price where T.good_name = s_name;
DELETE FROM good_sum_mart T where T.good_name = s_name and (sum_sale < 0 or sum_sale = 0);
END IF;
RETURN NEW;
END;
$TRIG_FUNC$
LANGUAGE plpgsql;

postgres=# CREATE TRIGGER tr_del_sales
AFTER DELETE
ON sales
FOR EACH ROW
EXECUTE PROCEDURE pr_del_sales();
```
>При обновлении следуют обе процедуры описанные выше.

```sql
postgres=# CREATE or replace function pr_up_sales()
RETURNS trigger
AS
$TRIG_FUNC$
DECLARE
s_name_old varchar(63);
s_price_old numeric(12,2);
s_name_new varchar(63);
s_price_new numeric(12,2);
BEGIN
SELECT G.good_name, G.good_price*OLD.sales_qty INTO s_name_old, s_price_old FROM goods G where G.goods_id = OLD.good_id;
SELECT G.good_name, G.good_price*NEW.sales_qty INTO s_name_new, s_price_new FROM goods G where G.goods_id = NEW.good_id;
IF EXISTS(select from good_sum_mart T where T.good_name = s_name_new)
THEN UPDATE good_sum_mart T SET sum_sale = sum_sale + s_price_new where T.good_name = s_name_new;
ELSE INSERT INTO good_sum_mart (good_name, sum_sale) values(s_name_new, s_price_new);
END IF;
IF EXISTS(select from good_sum_mart T where T.good_name = s_name_old)
THEN 
UPDATE good_sum_mart T SET sum_sale = sum_sale - s_price_old where T.good_name = s_name_old;
DELETE FROM good_sum_mart T where T.good_name = s_name_old and (sum_sale < 0 or sum_sale = 0);
END IF;
RETURN NEW;
END;
$TRIG_FUNC$
LANGUAGE plpgsql;

postgres=# CREATE TRIGGER tr_up_sales
AFTER UPDATE
ON sales
FOR EACH ROW
EXECUTE PROCEDURE pr_up_sales();
```

```sql
select * from good_sum_mart;
select * from sales;
INSERT INTO sales (good_id, sales_qty) VALUES (1, 267);
update sales set sales_qty = 5 where sales_id = 15;
delete from sales where sales_id = 1;

select * from information_schema.triggers

DROP TRIGGER IF EXISTS tr_up_sales ON sales;

drop FUNCTION function pr_up_sales();
```
✨Magic ✨