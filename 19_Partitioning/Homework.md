# Секционирование таблицы 
_____

- Цели
  - Научиться секционировать таблицы.
  
1.***Секционировать большую таблицу из демо базы flights.***
```sql
demo=# \dt+
                                                List of relations
  Schema  |      Name       | Type  |  Owner   | Persistence | Access method |  Size  |        Description
----------+-----------------+-------+----------+-------------+---------------+--------+---------------------------
 bookings | aircrafts_data  | table | postgres | permanent   | heap          | 16 kB  | Aircrafts (internal data)
 bookings | airports_data   | table | postgres | permanent   | heap          | 56 kB  | Airports (internal data)
 bookings | boarding_passes | table | postgres | permanent   | heap          | 455 MB | Boarding passes
 bookings | bookings        | table | postgres | permanent   | heap          | 105 MB | Bookings
 bookings | flights         | table | postgres | permanent   | heap          | 21 MB  | Flights
 bookings | seats           | table | postgres | permanent   | heap          | 96 kB  | Seats
 bookings | ticket_flights  | table | postgres | permanent   | heap          | 547 MB | Flight segment
 bookings | tickets         | table | postgres | permanent   | heap          | 386 MB | Tickets
(8 rows)
```
2.***Для секционирования выбрал таблицу ticket_flights по списку.***
```sql
demo=# SELECT distinct fare_conditions from bookings.ticket_flights ;

fare_conditions|
---------------+
Business       |
Comfort        |
Economy        |
```
3.***Создаём секционированую таблицу из структуры таблицы ticket_flights***
```sql
demo=# CREATE TABLE ticket_flights_part (like ticket_flights) PARTITION BY LIST (fare_conditions);
```
4.***Создаём партиции для нашей таблицы***
```sql
demo=# CREATE TABLE ticket_flights_part_bus PARTITION OF ticket_flights_part FOR VALUES IN ('Business');

demo=# CREATE TABLE ticket_flights_part_com PARTITION OF ticket_flights_part FOR VALUES IN ('Comfort');

demo=# CREATE TABLE ticket_flights_part_eco PARTITION OF ticket_flights_part FOR VALUES IN ('Economy');
```
5.***Заполняем наши партиции данными***
```sql
demo=# insert into ticket_flights_part_bus
select * from ticket_flights where fare_conditions = 'Business';

demo=# insert into ticket_flights_part_com
select * from ticket_flights where fare_conditions = 'Comfort';

demo=# insert into ticket_flights_part_eco
select * from ticket_flights where fare_conditions = 'Economy';

demo=# insert into ticket_flights_part select * from ticket_flights;
```
6.***Посмотрим данные в наших партициях***
```sql
demo=# SELECT * from bookings.ticket_flights_part_bus limit 20;

ticket_no    |flight_id|fare_conditions|amount   |
-------------+---------+---------------+---------+
0005432674657|   113434|Business       |115000.00|
0005433653959|   179102|Business       | 90500.00|
0005432675047|   113381|Business       |115000.00|
0005434861318|    65405|Business       | 49700.00|
0005433652534|    28030|Business       | 90500.00|
0005434869323|    94907|Business       | 49700.00|
0005432675561|   113624|Business       |115000.00|
0005435816532|     8417|Business       |199800.00|
0005433653454|    28069|Business       | 90500.00|
0005435831363|   117376|Business       |199300.00|
0005433654330|    28028|Business       | 90500.00|
0005432850536|   118565|Business       |101000.00|
0005433652447|   179167|Business       | 90500.00|
0005433654161|   179106|Business       | 90500.00|
0005433652598|   179076|Business       | 90500.00|
0005434876888|    65479|Business       | 49700.00|
0005433652849|   179090|Business       | 90500.00|
0005433654540|   179071|Business       | 90500.00|
0005433653107|   179063|Business       | 90500.00|
0005432939681|    77106|Business       |105900.00|

demo=# SELECT * from bookings.ticket_flights_part_com limit 20;

ticket_no    |flight_id|fare_conditions|amount  |
-------------+---------+---------------+--------+
0005435404929|    34599|Comfort        |24400.00|
0005434552007|    63984|Comfort        |47400.00|
0005434572905|    70862|Comfort        |24400.00|
0005434552664|    64033|Comfort        |47400.00|
0005434572950|    70675|Comfort        |24400.00|
0005434546584|     1766|Comfort        |47400.00|
0005434712978|     1825|Comfort        |47400.00|
0005435614586|    70829|Comfort        |24400.00|
0005434795010|    64124|Comfort        |47600.00|
0005434532591|     1673|Comfort        |47400.00|
0005434830163|    34377|Comfort        |47600.00|
0005434846168|    94372|Comfort        |19900.00|
0005434795167|    64291|Comfort        |47600.00|
0005434853725|    22683|Comfort        |19900.00|
0005432486376|   198442|Comfort        |23900.00|
0005435119866|    22513|Comfort        |19900.00|
0005435612210|    34509|Comfort        |24400.00|
0005434855084|    94415|Comfort        |19900.00|
0005435584817|    70686|Comfort        |24400.00|
0005435115658|    22618|Comfort        |19900.00|

demo=# SELECT * from bookings.ticket_flights_part_eco limit 20;

ticket_no    |flight_id|fare_conditions|amount  |
-------------+---------+---------------+--------+
0005435838889|    38881|Economy        |66400.00|
0005434274124|   102277|Economy        |48400.00|
0005435858017|    28072|Economy        |30200.00|
0005434878337|    65667|Economy        |16600.00|
0005433561973|    76885|Economy        |35300.00|
0005433559471|    77085|Economy        |35300.00|
0005435468992|   117225|Economy        |66400.00|
0005435835936|    39095|Economy        |66400.00|
0005433846707|    89907|Economy        |33300.00|
0005434863020|    65470|Economy        |16600.00|
0005433556927|    76884|Economy        |35300.00|
0005434274428|   102273|Economy        |48400.00|
0005432683235|     7763|Economy        |38300.00|
0005432941967|   163927|Economy        |35300.00|
0005435277537|    36291|Economy        |33300.00|
0005432947147|    77101|Economy        |35300.00|
0005432892357|     9586|Economy        |50100.00|
0005434274477|   102093|Economy        |48400.00|
0005435814947|   116902|Economy        |66600.00|
0005434274559|   102157|Economy        |48400.00|
```
7.***Проверим как работает выборка из секционированой таблицы***
```sql
demo=# SELECT * from bookings.ticket_flights_part where fare_conditions = 'Comfort' limit 20;

ticket_no    |flight_id|fare_conditions|amount  |
-------------+---------+---------------+--------+
0005435404929|    34599|Comfort        |24400.00|
0005434552007|    63984|Comfort        |47400.00|
0005434572905|    70862|Comfort        |24400.00|
0005434552664|    64033|Comfort        |47400.00|
0005434572950|    70675|Comfort        |24400.00|
0005434546584|     1766|Comfort        |47400.00|
0005434712978|     1825|Comfort        |47400.00|
0005435614586|    70829|Comfort        |24400.00|
0005434795010|    64124|Comfort        |47600.00|
0005434532591|     1673|Comfort        |47400.00|
0005434830163|    34377|Comfort        |47600.00|
0005434846168|    94372|Comfort        |19900.00|
0005434795167|    64291|Comfort        |47600.00|
0005434853725|    22683|Comfort        |19900.00|
0005432486376|   198442|Comfort        |23900.00|
0005435119866|    22513|Comfort        |19900.00|
0005435612210|    34509|Comfort        |24400.00|
0005434855084|    94415|Comfort        |19900.00|
0005435584817|    70686|Comfort        |24400.00|
0005435115658|    22618|Comfort        |19900.00|
```
8.***Посмотрим план запроса на эту таблицу!***
```sql
QUERY PLAN                                                                                        |
--------------------------------------------------------------------------------------------------+
Seq Scan on ticket_flights_part_com ticket_flights_part  (cost=0.00..2916.56 rows=139965 width=33)|
  Filter: ((fare_conditions)::text = 'Comfort'::text)                                             |
```
>Видим что план запроса ищёт только по секции ticket_flights_part_com

✨Magic ✨