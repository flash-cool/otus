DO $$
DECLARE
    a integer[2]; -- размер игнорируется
BEGIN
    a := ARRAY[10,20,30];
    RAISE NOTICE '%', a;
    -- по умолчанию элементы нумеруются с единицы
    RAISE NOTICE 'a[1] = %, a[2] = %, a[3] = %', a[1], a[2], a[3];
    -- срез массива
    RAISE NOTICE 'Срез [2:3] = %', a[2:3];
    -- присваиваем значения срезу массива
    a[2:3] := ARRAY[222,333];
    -- выводим весь массив
    RAISE NOTICE '%', a;
END;
$$ LANGUAGE plpgsql;

NOTICE:  {10,20,30}
NOTICE:  a[1] = 10, a[2] = 20, a[3] = 30
NOTICE:  Срез [2:3] = {20,30}
NOTICE:  {10,222,333}
do

-- Одномерный массив можно заполнять и поэлементно — при необходимости он автоматически расширяется. 
-- Если пропустить какие-то элементы, они получают неопределенные значения. Что будет выведено?

DO $$
DECLARE
    a integer[];
BEGIN
    a[2] := 10;
    a[3] := 20;
    a[6] := 30;
    RAISE NOTICE '%', a;
END;
$$ LANGUAGE plpgsql;

NOTICE:  [2:6]={10,20,NULL,NULL,30}
do

-- Поскольку нумерация началась не с единицы, перед самим массивом дополнительно выводится диапазон номеров элементов.

-- Мы можем определить составной тип и создать массив из элементов этого типа:

CREATE TYPE currency AS (amount numeric, code text);

DO $$
DECLARE
    c currency[];  -- массив из элементов составного типа
BEGIN
  -- присваиваем значения отдельным элементам
    c[1].amount := 10;  c[1].code := 'RUB';
    c[2].amount := 50;  c[2].code := 'KZT';
    RAISE NOTICE '%', c;
END
$$ LANGUAGE plpgsql;

NOTICE:  {"(10,RUB)","(50,KZT)"}
do

-- Еще один способ получить массив — создать его из подзапроса:

DO $$
DECLARE
    a integer[];
BEGIN
    a := ARRAY( SELECT n FROM generate_series(1,3) n );
    RAISE NOTICE '%', a;
END
$$ LANGUAGE plpgsql;
NOTICE:  {1,2,3}
DO

-- Можно и наоборот, массив преобразовать в таблицу:

SELECT unnest( ARRAY[1,2,3] );
 unnest 
--------
      1
      2
      3
(3 rows)

-- Интересно, что выражение IN со списком значений преобразуется в поиск по массиву:

EXPLAIN ANALYZE
SELECT * FROM generate_series(1,10) g(id) WHERE id IN (1,2,3);
                 QUERY PLAN                  
---------------------------------------------
 Function Scan on generate_series g
   Filter: (id = ANY ('{1,2,3}'::integer[]))
(2 rows)

-- Двумерный массив — прямоугольная матрица, память под которую выделяется при инициализации. Литерал выглядит как массив массивов, имеющих одинаковое число элементов. Здесь мы использовали другой способ инициализации — с помощью символьной строки.

-- После инициализации многомерный массив уже нельзя расширить.

DO $$
DECLARE
    a integer[][] := '{
        { 10, 20, 30},
        {100,200,300}
    }';
BEGIN
    RAISE NOTICE 'Двумерный массив : %', a;
    RAISE NOTICE 'Неограниченный срез массива [2:] = %', a[2:];
    -- присваиваем значения этому срезу
    a[2:] := ARRAY[ARRAY[111, 222, 333]];
    -- снова выводим весь массив
    RAISE NOTICE '%', a;
    -- расширять нельзя ни по какому измерению
    a[4][4] := 1;
END
$$ LANGUAGE plpgsql;
NOTICE:  Двумерный массив : {{10,20,30},{100,200,300}}
NOTICE:  Неограниченный срез массива [2:] = {{100,200,300}}
NOTICE:  {{10,20,30},{111,222,333}}
ERROR:  array subscript out of range
CONTEXT:  PL/pgSQL function inline_code_block line 15 at assignment


-- Массивы и циклы
-- Обычный цикл по индексам элементов
--	array_lower
--	array_upper
-- Цикл FOREACH по элементам массива
--проще, но индексы элементов недоступны

-- Для итерации по элементам массива вполне можно использовать обычный целочисленный цикл FOR, используя функции, возвращающие минимальный и максимальный индексы массива.Однако есть и специализированный вариант цикла: FOREACH. В таком варианте переменная цикла пробегает не индексы элементов, а сами элементы. Поэтому переменная должна иметь тот же тип, что и элементы массива (как обычно, если элементами являются записи, то одну переменную составного типа можно заменить несколькими скалярными переменными).Тот же цикл с фразой SLICE позволяет итерировать срезы массива. Например, для двумерного массива одномерными срезами будут его строки.https://postgrespro.ru/docs/postgresql/16/plpgsql-control-structures#PLPGSQL-FOREACH-ARRAY

-- Массивы и циклы
-- Цикл можно организовать, итерируя индексы элементов массива. Второй параметр функций array_lower и array_upper — номер размерности (единица для одномерных массивов).

DO $$
DECLARE
    a integer[] := ARRAY[10,20,30];
BEGIN
    FOR i IN array_lower(a,1)..array_upper(a,1) 
    LOOP 
        RAISE NOTICE 'a[%] = %', i, a[i];
    END LOOP;
END
$$ LANGUAGE plpgsql;
NOTICE:  a[1] = 10
NOTICE:  a[2] = 20
NOTICE:  a[3] = 30
do

-- Если индексы не нужны, то проще итерировать сами элементы:

DO $$
DECLARE
    a integer[] := ARRAY[10,20,30];
    x integer;
BEGIN
    FOREACH x IN ARRAY a 
    LOOP 
        RAISE NOTICE '%', x;
    END LOOP;
END
$$ LANGUAGE plpgsql;
NOTICE:  10
NOTICE:  20
NOTICE:  30
do

-- Итерация индексов в двумерном массиве:

DO $$
DECLARE
    -- можно и без двойных квадратных скобок
    a integer[] := ARRAY[
        ARRAY[ 10, 20, 30],
        ARRAY[100,200,300]
    ];
BEGIN
    FOR i IN array_lower(a,1)..array_upper(a,1) LOOP -- по строкам
        FOR j IN array_lower(a,2)..array_upper(a,2) LOOP -- по столбцам
            RAISE NOTICE 'a[%][%] = %', i, j, a[i][j];
        END LOOP;
    END LOOP;
END
$$ LANGUAGE plpgsql;
NOTICE:  a[1][1] = 10
NOTICE:  a[1][2] = 20
NOTICE:  a[1][3] = 30
NOTICE:  a[2][1] = 100
NOTICE:  a[2][2] = 200
NOTICE:  a[2][3] = 300
do

-- Итерация элементов двумерного массива не требует вложенного цикла:

DO $$
DECLARE
    a integer[] := ARRAY[
        ARRAY[ 10, 20, 30],
        ARRAY[100,200,300]
    ];
    x integer;
BEGIN
    FOREACH x IN ARRAY a 
    LOOP 
        RAISE NOTICE '%', x;
    END LOOP;
END
$$ LANGUAGE plpgsql;
NOTICE:  10
NOTICE:  20
NOTICE:  30
NOTICE:  100
NOTICE:  200
NOTICE:  300
do

-- Существует также возможность выполнять в подобном цикле итерацию по срезам, а не по отдельным элементам. Значение SLICE в такой конструкции должно быть целым числом, не превышающим размерность массива, а переменная, куда читаются срезы, сама должна быть массивом. В примере — цикл по одномерным срезам:

DO $$
DECLARE
    a integer[] := ARRAY[
        ARRAY[ 10, 20, 30],
        ARRAY[100,200,300]
    ];
    x integer[];
BEGIN
    FOREACH x SLICE 1 IN ARRAY a LOOP 
        RAISE NOTICE '%', x;
    END LOOP;
END
$$ LANGUAGE plpgsql;
NOTICE:  {10,20,30}
NOTICE:  {100,200,300}
DO


-- Массивы и подпрограммы
-- Подпрограммы с переменным числом параметров
-- все необязательные параметры должны иметь одинаковый тип
-- передаются в подпрограмму в виде массива
-- последний параметр-массив объявляется как variadic
-- Полиморфные подпрограммы
-- работают со значениями разных типов;
-- тип конкретизируется во время выполнения
-- дополнительные полиморфные псевдотипы anyarray, anynonarray, 
-- anycompatiblearray и anycompatiblenonarrray
-- могут иметь переменное число параметров

-- Массивы позволяют создавать подпрограммы (функции или процедуры) с переменным числом параметров.В отличие от параметров со значениями по умолчанию, которые при объявлении подпрограммы надо явно перечислить, необязательных параметров может быть сколько угодно и все они передаются подпрограмме в виде массива. Но, как следствие, все они должны иметь один и тот же (или совместимый, в случае использования anycompatible/anycompatiblearray) тип.При объявлении подпрограммы последним указывается один параметр, помеченный как VARIADIC, имеющий тип массива.https://postgrespro.ru/docs/postgresql/16/xfunc-sql#XFUNC-SQL-VARIADIC-FUNCTIONSМы уже говорили про полиморфные подпрограммы, которые могут работать с параметрами разных типов. При объявлении подпрограммы указывается специальный полиморфный псевдотип, а конкретный тип уточняется во время выполнения по фактическому типу переданных параметров.Для массивов есть отдельные полиморфные типы anyarray, anycompatiblearray (и anynonarray, anycompatiblenonarrray для не-массивов).Эти типы можно использовать совместно с передачей переменного числа аргументов при объявлении VARIADIC-параметра.https://postgrespro.ru/docs/postgresql/16/xfunc-sql#XFUNC-SQL-POLYMORPHIC-FUNCTIONS

-- Массивы и подпрограммы
-- В теме «SQL. Процедуры» мы рассматривали перегрузку и полиморфизм и создали функцию maximum, которая находила максимальное из трех чисел. Обобщим ее на произвольное число аргументов. Для этого объявим один VARIADIC-параметр:

CREATE FUNCTION maximum(VARIADIC a integer[]) RETURNS integer
AS $$
DECLARE
    x integer;
    maxsofar integer;
BEGIN
    FOREACH x IN ARRAY a LOOP
        IF x IS NOT NULL AND (maxsofar IS NULL OR x > maxsofar) THEN
            maxsofar := x;
        END IF;
    END LOOP;
    RETURN maxsofar;
END
$$ IMMUTABLE LANGUAGE plpgsql;

-- Пробуем:

SELECT maximum(12, 65, 47);
 maximum 
---------
      65
(1 row)

SELECT maximum(12, 65, 47, null, 87, 24);
 maximum 
---------
      87
(1 row)

SELECT maximum(null, null);
 maximum 
---------
        
(1 row)

-- Для полноты картины и эта функция может быть сделана полиморфной, чтобы принимать любой тип данных (для которого, конечно, должны быть определены операции сравнения).

DROP FUNCTION maximum(integer[]);

-- Полиморфные типы anycompatiblearray и anycompatible (а также anyarray и anyelement) всегда согласованы между собой: anycompatiblearray = anycompatible[], anyarray = anyelement[];
-- Нам нужна переменная, имеющая тип элемента массива. Но объявить ее как anycompatible нельзя — она должна иметь реальный тип. Здесь помогает конструкция %TYPE.

CREATE FUNCTION maximum(VARIADIC a anycompatiblearray, maxsofar OUT anycompatible)
AS $$
DECLARE
    x maxsofar%TYPE;
BEGIN
    FOREACH x IN ARRAY a LOOP
        IF x IS NOT NULL AND (maxsofar IS NULL OR x > maxsofar) THEN
            maxsofar := x;
        END IF;
    END LOOP;
END
$$ IMMUTABLE LANGUAGE plpgsql;


-- Проверим:

SELECT maximum(12, 65, 47);
 maximum 
---------
      65
(1 row)

SELECT maximum(12.1, 65.3, 47.6);
 maximum 
---------
    65.3
(1 row)

SELECT maximum(12, 65.3, 15e2, 3.14);
 maximum 
---------
    1500
(1 row)

-- Вот теперь у нас получился практически полный аналог выражения greatest!

-- Классический реляционный подход предполагает, что в таблице хранятся атомарные значения (первая нормальная форма). Язык SQL не имеет средств для «заглядывания внутрь» сложносоставных значений.Поэтому обычный подход состоит в создании отдельной таблицы, связанной с основной отношением «многие ко многим».Тем не менее, мы можем создать таблицу со столбцом типа массива. PostgreSQL имеет богатый набор функций для работы с массивами,а поиск элемента в массиве может быть ускорен специальными индексами (такие индексы рассматриваются в курсе DEV2).Такой подход бывает удобен: получается компактное представление, не требующее соединений. В частности, массивы активно используются в системном каталоге PostgreSQL.Какое решение выбрать? Зависит от того, какие ставятся задачи, какие требуются операции. Рассмотрим пример.

-- Массив или таблица?
-- Представим себе, что мы проектируем базу данных для ведения блога. В блоге есть сообщения, и нам хотелось бы сопоставлять им теги.

--Традиционный подход состоит в том, что для тегов надо создать отдельную таблицу, например, так:

CREATE TABLE posts(
    post_id integer PRIMARY KEY,
    message text
);

CREATE TABLE tags(
    tag_id integer PRIMARY KEY,
    name text
);

-- Связываем сообщения и теги отношением многие ко многим через еще одну таблицу:

CREATE TABLE posts_tags(
    post_id integer REFERENCES posts(post_id),
    tag_id integer REFERENCES tags(tag_id)
);

-- Наполним таблицы тестовыми данными:

INSERT INTO posts(post_id,message) VALUES
    (1, 'Перечитывал пейджер, много думал.'),
    (2, 'Это было уже весной и я отнес елку обратно.');

INSERT INTO tags(tag_id,name) VALUES
    (1, 'былое и думы'), (2, 'технологии'), (3, 'семья');

INSERT INTO posts_tags(post_id,tag_id) VALUES
    (1,1), (1,2), (2,1), (2,3);

-- Теперь мы можем вывести сообщения и теги:

SELECT p.message, t.name as tags
FROM posts p
     JOIN posts_tags pt ON pt.post_id = p.post_id
     JOIN tags t ON t.tag_id = pt.tag_id
ORDER BY p.post_id, t.name;

                   message                   |     name     
---------------------------------------------+--------------
 Перечитывал пейджер, много думал.           | былое и думы
 Перечитывал пейджер, много думал.           | технологии
 Это было уже весной и я отнес елку обратно. | былое и думы
 Это было уже весной и я отнес елку обратно. | семья
(4 rows)

-- Или чуть иначе — возможно удобнее получить массив тегов. Для этого используем агрегирующую функцию:

SELECT p.message, array_agg(t.name ORDER BY t.name) tags
FROM posts p
     JOIN posts_tags pt ON pt.post_id = p.post_id
     JOIN tags t ON t.tag_id = pt.tag_id
GROUP BY p.post_id
ORDER BY p.post_id;
                   message                   |            tags             
---------------------------------------------+-----------------------------
 Перечитывал пейджер, много думал.           | {"былое и думы",технологии}
 Это было уже весной и я отнес елку обратно. | {"былое и думы",семья}
(2 rows)

-- Можем найти все сообщения с определенным тегом:

SELECT p.message
FROM posts p
     JOIN posts_tags pt ON pt.post_id = p.post_id
     JOIN tags t ON t.tag_id = pt.tag_id
WHERE t.name = 'былое и думы'
ORDER BY p.post_id;
                   message                   
---------------------------------------------
 Перечитывал пейджер, много думал.
 Это было уже весной и я отнес елку обратно.
(2 rows)

-- Может потребоваться найти все уникальные теги — это совсем просто:

SELECT t.name
FROM tags t
ORDER BY t.name;
     name     
--------------
 былое и думы
 семья
 технологии
(3 rows)

-- Теперь попробуем подойти к задаче по-другому. Пусть теги будут представлены текстовым массивом прямо внутри таблицы сообщений.

DROP TABLE posts_tags;

DROP TABLE tags;

ALTER TABLE posts ADD COLUMN tags text[];

-- Теперь у нас нет идентификаторов тегов, но они нам не очень и нужны.

UPDATE posts SET tags = '{"былое и думы","технологии"}'
WHERE post_id = 1;

UPDATE posts SET tags = '{"былое и думы","семья"}'
WHERE post_id = 2;

-- Вывод всех сообщений упростился:

SELECT p.message, p.tags
FROM posts p
ORDER BY p.post_id;
                   message                   |            tags             
---------------------------------------------+-----------------------------
 Перечитывал пейджер, много думал.           | {"былое и думы",технологии}
 Это было уже весной и я отнес елку обратно. | {"былое и думы",семья}
(2 rows)

-- Сообщения с определенным тегом тоже легко найти (используем оператор пересечения &&).

-- Эта операция может быть ускорена с помощью индекса GIN, и для такого запроса не придется перебирать всю таблицу сообщений.

SELECT p.message
FROM posts p
WHERE p.tags && '{"былое и думы"}'
ORDER BY p.post_id;
                   message                   
---------------------------------------------
 Перечитывал пейджер, много думал.
 Это было уже весной и я отнес елку обратно.
(2 rows)

-- А вот получить список тегов довольно сложно. Это требует разворачивания всех массивов тегов в большую таблицу и поиск уникальных значений — тяжелая операция.

SELECT distinct unnest(p.tags) AS name
FROM posts p;
     name     
--------------
 технологии
 былое и думы
 семья
(3 rows)

-- Тут хорошо видно, что имеет место дублирование данных.
-- Итак, оба подхода вполне могут применяться.
-- В простых случаях массивы выглядят проще и работают хорошо.
-- В более сложных сценариях (представьте, что вместе с именем тега мы хотим хранить дату его создания; или требуется проверка ограничений целостности) классический вариант становится более привлекательным.

-- Итоги
-- Массив состоит из пронумерованных элементов одного и того же типа данных
-- Столбец с массивом как альтернатива отдельной таблице: удобные операции и индексная поддержка
-- Позволяет создавать функции с переменным числом параметров


:var можно было в dbeaver
или ${var}
попробуйте например
select :var

/*
Формат JSON:
JavaScript Object Notation
	простой язык разметки, стандарт 1999 года
	появился в JavaScript, но распространен повсеместно
Структура
	объекты (пары «ключ: значение»), массивы значений
	значения текстовые, числовые, даты, логические
Инструментарий PostgreSQL: 
	язык запросов JSONPath,
	неполная пока поддержка стандарта SQL/JSON,
	индексирование
*/


/*
Имеются два типа данных для представления документов JSON: json и jsonb.
Первый появился раньше и, по сути, просто хранит документ в виде текстовой строки 
(при этом, конечно, проверяется, что строка является корректным документом JSON). 
Но при любом обращении к части документа JSON, его приходится заново разбирать. 
Это вызывает большие накладные расходы. Кроме того, для формата json не реализован язык 
JSONPath и не работает индексирование GIN. Поэтому json применяется редко. Обычно используется т
ип jsonb (b — binary). Этот формат сохраняет однажды разобранную иерархию элементов, 
что позволяет эффективно работать с документом. Следует учитывать, что исходный вид документа 
при этом не сохраняется: нарушается порядок следования элементов, пропадают отступы и дублирующиеся ключи.
https://postgrespro.ru/docs/postgresql/14/datatype-json#DATATYPE-JSONPATH
*/


-- JSON: типы данных json и jsonb
-- Документ, описывающий компоненты компьютера, может выглядеть в JSON так:

-- psql:

-- :var можно было в dbeaver
-- или ${var}
-- попробуйте например
-- select :var

select $js$
{ "motherboard": {
    "cpu": "Intel® Core™ i7-7567U",
    "ram": [
      { "type": "dimm",
        "size_gb": 32,
        "model": "Crucial DDR4-2400 SODIMM"
      }
    ]
  },
  "disks": [
    { "type": "ssd",
      "size_gb": 512,
      "model": "Intel 760p Series"
    },
    { "type": "hdd",
      "size_gb": 3000,
      "model": "Toshiba Canvio"
    }
  ]
}
$js$ as json \gset

-- Формат json хранит документ как обычный текст:
select :'json'::json;


/*
В jsonb документ разбирается и записывается во внутреннем формате, 
сохраняющем структуру разбора. Из-за этого при выводе документ 
составляется заново в эквивалентном, но ином виде:
*/
select :'json'::jsonb;


-- Чтобы вывести документ в человекочитаемом виде, можно использовать специальную функцию:
select jsonb_pretty(:'json'::jsonb);


-- Дальше мы будем работать с типом jsonb, который предоставляет больше возможностей.

-- JSON: выражения JSONPath и другие средства

-- Для получения части JSON-документа стандарт SQL:2016 определил язык запросов JSONPath. Вот некоторые примеры.
-- Так же, как и XPath, JSONPath позволяет спускаться по дереву элементов. Часть документа, соответствующая пути от корня:
select jsonb_pretty(jsonb_path_query(:'json', '$.motherboard.ram'));

-- Элементы массива указываются в квадратных скобках:
select jsonb_pretty(jsonb_path_query(:'json', '$.disks[0]'));

-- Можно получить и все элементы сразу:
select jsonb_pretty(jsonb_path_query(:'json', '$.disks[*]'));

-- Условия фильтрации записываются в скобках после вопросительного знака. Символ @ обозначает текущий путь.

-- Найдем диски, объем памяти которых начинается от 1000 гигабайт:
select jsonb_pretty(jsonb_path_query(:'json', '$.disks ? (@.size_gb > 1000)'));

-- Условия являются частью пути, который можно продолжить дальше. Выберем только модель:
explain analyze
select jsonb_pretty(jsonb_path_query(:'json', '$.disks ? (@.size_gb > 1000).model'));

-- В пути может быть и несколько условий:
select jsonb_pretty(
	jsonb_path_query(
						:'json',
						'$.disks ? (@.size_gb > 128).model ? (@ starts with "Intel")'
					)
);

-- Кроме средств JSONPath, можно применять и «традиционную» стрелочную нотацию.

-- Переходим к ключу motherboard, затем к ключу ram, затем берем первый (нулевой) элемент массива:
select jsonb_pretty( (:'json'::jsonb)->'motherboard'->'ram'->0 );
       

-- Двойная стрелка возвращает не jsonb, а текстовое представление: (Необходимые фильтрации в таком случае придется выполнять уже на уровне SQL.)
select (:'json'::jsonb)->'motherboard'->'ram'->0->'model';


/*
JSON: преобразование в реляционный вид и обратно
Стандарт определяет функцию jsontable, но она пока не реализована в PostgreSQL. 
Разумеется, можно выйти из положения и теми средствами, которые существуют. 
Сначала выделим все диски:
*/

truncate table disks;

create table if not exists disks (
	drive_type text, 
	name text, 
	capacity int8
);


with dsk(d) as (
	select jsonb_path_query(:'json', '$.disks[*]')
)
select d from dsk;


-- На основе этого запроса несложно сделать вставку в таблицу:
insert into disks(drive_type, name, capacity)
with dsk(d) as (
    select jsonb_path_query(:'json', '$.disks[*]')
)
select d->>'type', d->>'model', (d->>'size_gb')::integer from dsk;

select * from disks;


-- Для обратного преобразования удобно воспользоваться функцией row_to_json:
select row_to_json(disks) from disks;


-- Соединить строки в общий JSON-массив можно, например, так:
select json_agg(disks) from disks;


/* GIN - индексы
Идея метода доступа GIN (general inverted index) основана на том, что для сложносоставных значений 
имеет смысл индексировать элементы значений, а не все значение целиком.Представьте предметный указатель 
в конце книги. Страницы книги — сложносоставные значения (текст), а указатель позволяет ответить 
на вопрос «на каких страницах встречается такой-то термин?».Для хранения элементов в GIN используется 
обычное B-дерево, поэтому элементы должны принадлежать к сортируемому типу данных. Основные отличия 
от B-дерева состоят в следующем:- Когда нужно проиндексировать новое значение, это значение разбивается 
на элементы и индексируются сразу все элементы. Поэтому в индекс добавляется не один элемент, а сразу 
несколько (обычно много).- Каждый элемент индекса ссылается на множество табличных строк.- Хотя элементы 
и организованы в B-дерево, классы операторов GIN не поддерживают операции сравнения «больше», «меньше».
Таким образом, GIN оптимизирован для других условий использования, нежели B-дерево. (Но имеется расширение 
btree_gin, реализующее классы операторов GIN для обычных типов данных.)

https://postgrespro.ru/docs/postgresql/14/gin
https://postgrespro.ru/docs/postgresql/14/datatype-json#JSON-INDEXING
*/


-- Метод доступа GIN для индексирования JSON
-- Пусть теперь таблица с дисками будет содержать JSON-документы.

drop table disks;

create table disks(
	id integer primary key generated always as identity,
    disk jsonb
);


-- Заполним ее разными моделями, от 10 до 1000 Гб:
insert into disks(disk)
with rnd(r) as (
    select (10+random()*990)::integer from generate_series(1,100000)
),
dsk(type, model, capacity, plates) as (
    select 'hdd', 'NoName '||r||' GB', r, (1 + random()*9)::integer
    from rnd
)
select row_to_json(dsk) from dsk;

analyze disks;

-- Вот что получилось:
select * from disks limit 3;


-- Сколько всего моделей имеют емкость 10 Гб и сколько времени займет поиск?
-- Оператор @? проверяет, есть ли в документе JSON заданный путь.

select count(*) from disks where disk @? '$ ? (@.capacity == 10)';


-- Как выполняется этот запрос?
explain analyze
select count(*) from disks where disk @? '$ ? (@.capacity == 10)'; -- Конечно, используется полное сканирование таблицы — у нас нет подходящего индекса. Execution Time: 38.843 ms


-- Документы JSONB можно индексировать с помощью метода GIN. Для этого есть два доступных класса операторов:
select opcname, opcdefault
from pg_opclass
where opcmethod = (select oid from pg_am where amname = 'gin')
and opcintype = 'jsonb'::regtype; 


/*
Класс по умолчанию, jsonb_ops, более универсален, но менее эффективен. 
Этот класс операторов помещает в индекс все ключи и значения. 
Из-за этого поиск получается неточным: значение 10 может быть найдено не 
только в контексте емкости (ключ capacity), но и как число пластин (ключ plates). 
Зато такой индекс поддерживает и другие операции с JSONB.
*/

-- Попробуем.
create index disks_json_idx on disks using gin(disk);


-- Доступ, тем не менее, ускоряется. Execution Time: 9.442 ms
explain analyze
select count(*) from disks where disk @? '$ ? (@.capacity == 10)';


/*
Другой класс операторов, jsonb_path_ops, помещает в индекс значения вместе с путем, 
который к ним ведет. За счет этого поиск становится более точным, хотя поддерживаются не все операции.
*/

-- Проверим и этот способ:
drop index disks_json_path_idx

create index disks_json_path_idx on disks using gin(disk jsonb_path_ops);

explain analyze
select count(*) from disks where disk @? '$ ? (@.capacity == 10)'; -- Так гораздо лучше. Execution Time: 0.243 ms



-- Еще один вариант — построить индекс на основе B-дерева по выражению. Вот так:
create index disks_btree_idx on disks( (disk->>'capacity') );

explain analyze
select count(*) from disks where disk->>'capacity' = '10'; -- Но такой способ, конечно, менее универсален — под каждый запрос потребуется создавать отдельный индекс.



-- Сравним размер индексов (для сравнения выводится и размер таблицы):
select indexname,
    pg_size_pretty(pg_total_relation_size(indexname::regclass))
from pg_indexes
where tablename = 'disks'
union all
select 'disks', pg_size_pretty(pg_table_size('disks'::regclass));



select pg_typeof(json_build_object('name', 'Иван', 'surname', 'Петров', 'age', 47)), json_build_object('name', 'Иван', 'surname', 'Петров', 'age', 47);

select pg_typeof('{"name": "Иван", "surname": "Петров", "age": 47}'::jsonb);

select '{"name": "Иван", "surname": "Петров", "age": 47}'::jsonb -> 'age' as age; -- Таким образом можем обратиться к определенному ключу и получить его значение

select '{"name": "Иван", "surname": "Петров", "age": 47}'::jsonb ->> 'age' as age; -- приводим к тестовому представлению


drop table table_json;

create table if not exists table_json (
	id int2,
	name varchar(30),
	age int2
);

insert into table_json (id, name, age) values (1, 'Иван', 30), (2, 'Петр', 28), (3, 'Александр', null);
select * from table_json;

select jsonb_agg(json_build_object('name', name, 'age', age)) as people from table_json;


alter table table_json add json_data jsonb;

update table_json o set json_data = (select to_jsonb(e.*) from (select i.id, i.name, i.age from table_json i where i.id = o.id) e);

select * from table_json;