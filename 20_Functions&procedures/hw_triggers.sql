-- ДЗ тема: триггеры, поддержка заполнения витрин

DROP SCHEMA IF EXISTS pract_functions CASCADE;
CREATE SCHEMA pract_functions;

SET search_path = pract_functions, publ

-- товары:
CREATE TABLE goods
(
    goods_id    integer PRIMARY KEY,
    good_name   varchar(63) NOT NULL,
    good_price  numeric(12, 2) NOT NULL CHECK (good_price > 0.0)
);
INSERT INTO goods (goods_id, good_name, good_price)
VALUES 	(1, 'Спички хозайственные', .50),
		(2, 'Автомобиль Ferrari FXX K', 185000000.01);

-- Продажи
CREATE TABLE sales
(
    sales_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    good_id     integer REFERENCES goods (goods_id),
    sales_time  timestamp with time zone DEFAULT now(),
    sales_qty   integer CHECK (sales_qty > 0)
);

INSERT INTO sales (good_id, sales_qty) VALUES (1, 10), (1, 1), (1, 120), (2, 1);

-- отчет:
SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;

-- с увеличением объёма данных отчет стал создаваться медленно
-- Принято решение денормализовать БД, создать таблицу
CREATE TABLE good_sum_mart
(
	good_name   varchar(63) NOT NULL,
	sum_sale	numeric(16, 2)NOT NULL
);

-- Создать триггер (на таблице sales) для поддержки.
-- Подсказка: не забыть, что кроме INSERT есть еще UPDATE и DELETE

-- Чем такая схема (витрина+триггер) предпочтительнее отчета, создаваемого "по требованию" (кроме производительности)?
-- Подсказка: В реальной жизни возможны изменения цен.

CREATE OR REPLACE FUNCTION good_sum_func() 
RETURNS TRIGGER 
AS 
$sale$
   BEGIN
      WITH ins_sum 
            AS  (
                INSERT INTO sales (sales_qty) VALUES (NEW.sales_qty)
				                ON CONFLICT (sales_qty)
                DO UPDATE SET sales_qty = EXCLUDED.sales_qty -- чтобы иметь возможность вернуть student_id
                RETURNING sales_sum),
			ins_id 
            AS  (
                INSERT INTO sales (good_id) VALUES (NEW.good_id)
				                ON CONFLICT (good_id)
                DO UPDATE SET good_id = EXCLUDED.good_id -- чтобы иметь возможность вернуть student_id
                RETURNING sales_id)
			INSERT INTO good_sum_mart (good_name, sum_sale)
            SELECT ins_id.sales_id, sum(goods.good_price * ins_sum.sales_sum)
            FROM ins_id, goods, ins_sum
			INNER JOIN sales ON sales.good_id =goods.goods_id;
      RETURN NEW;
   END;
$sale$ 
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION good_sum_func() 
RETURNS TRIGGER 
AS 
$sale$
   BEGIN
      INSERT INTO good_sum_mart(good_name, sum_sale) VALUES (new.good_id, new.sales_qty);
      RETURN NEW;
   END;
$sale$ 
LANGUAGE plpgsql;



select * from information_schema.triggers;