# Работа с join'ами, статистикой 
_____

- Цели
	- Знать и уметь применять различные виды join'ов
	- Строить и анализировать план выполенения запроса
	- Оптимизировать запрос
	- Уметь собирать и анализировать статистику для таблицы
  
1.***Реализовать прямое соединение двух или более таблиц.***
```sql
demo=# SELECT * FROM airports_data a
JOIN flights f 
ON a.airport_code = f.arrival_airport 
limit 15;

airport_code|airport_name                                                |city                                               |coordinates                            |timezone          |flight_id|flight_no|scheduled_departure          |scheduled_arrival            |departure_airport|arrival_airport|status   |aircraft_code|actual_departure|actual_arrival|
------------+------------------------------------------------------------+---------------------------------------------------+---------------------------------------+------------------+---------+---------+-----------------------------+-----------------------------+-----------------+---------------+---------+-------------+----------------+--------------+
KUF         |{"en": "Kurumoch International Airport", "ru": "Курумоч"}   |{"en": "Samara", "ru": "Самара"}                   |(50.16429901123,53.504901885986)       |Europe/Samara     |     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
ROV         |{"en": "Rostov-on-Don Airport", "ru": "Ростов-на-Дону"}     |{"en": "Rostov", "ru": "Ростов-на-Дону"}           |(39.8180999756,47.2582015991)          |Europe/Moscow     |     3940|PG0212   |2017-09-04 18:20:00.000 +0300|2017-09-04 19:35:00.000 +0300|DME              |ROV            |Scheduled|321          |                |              |
VOZ         |{"en": "Voronezh International Airport", "ru": "Воронеж"}   |{"en": "Voronezh", "ru": "Воронеж"}                |(39.22959899902344,51.81420135498047)  |Europe/Moscow     |     4018|PG0416   |2017-09-13 19:20:00.000 +0300|2017-09-13 19:55:00.000 +0300|DME              |VOZ            |Scheduled|CR2          |                |              |
TBW         |{"en": "Donskoye Airport", "ru": "Донское"}                 |{"en": "Tambow", "ru": "Тамбов"}                   |(41.482799530029,52.806098937988)      |Europe/Moscow     |     4587|PG0055   |2017-09-03 14:10:00.000 +0300|2017-09-03 15:25:00.000 +0300|DME              |TBW            |Scheduled|CN1          |                |              |
PES         |{"en": "Petrozavodsk Airport", "ru": "Бесовец"}             |{"en": "Petrozavodsk", "ru": "Петрозаводск"}       |(34.154701232910156,61.88520050048828) |Europe/Moscow     |     5694|PG0341   |2017-08-31 10:50:00.000 +0300|2017-08-31 11:55:00.000 +0300|DME              |PES            |Scheduled|CR2          |                |              |
JOK         |{"en": "Yoshkar-Ola Airport", "ru": "Йошкар-Ола"}           |{"en": "Yoshkar-Ola", "ru": "Йошкар-Ола"}          |(47.904701232910156,56.700599670410156)|Europe/Moscow     |     6428|PG0335   |2017-08-24 09:30:00.000 +0300|2017-08-24 11:35:00.000 +0300|DME              |JOK            |Scheduled|CN1          |                |              |
JOK         |{"en": "Yoshkar-Ola Airport", "ru": "Йошкар-Ола"}           |{"en": "Yoshkar-Ola", "ru": "Йошкар-Ола"}          |(47.904701232910156,56.700599670410156)|Europe/Moscow     |     6664|PG0335   |2017-09-07 09:30:00.000 +0300|2017-09-07 11:35:00.000 +0300|DME              |JOK            |Scheduled|CN1          |                |              |
NAL         |{"en": "Nalchik Airport", "ru": "Нальчик"}                  |{"en": "Nalchik", "ru": "Нальчик"}                 |(43.636600494384766,43.512901306152344)|Europe/Moscow     |     7455|PG0136   |2017-09-10 15:30:00.000 +0300|2017-09-10 17:30:00.000 +0300|DME              |NAL            |Scheduled|CR2          |                |              |
MRV         |{"en": "Mineralnyye Vody Airport", "ru": "Минеральные Воды"}|{"en": "Mineralnye Vody", "ru": "Минеральные Воды"}|(43.08190155029297,44.225101470947266) |Europe/Moscow     |     9994|PG0210   |2017-09-01 18:00:00.000 +0300|2017-09-01 19:50:00.000 +0300|DME              |MRV            |Scheduled|733          |                |              |
HMA         |{"en": "Khanty Mansiysk Airport", "ru": "Ханты-Мансийск"}   |{"en": "Khanty-Mansiysk", "ru": "Ханты-Мансийск"}  |(69.08609771728516,61.028499603271484) |Asia/Yekaterinburg|    11283|PG0239   |2017-08-22 09:05:00.000 +0300|2017-08-22 11:40:00.000 +0300|DME              |HMA            |Scheduled|SU9          |                |              |
HMA         |{"en": "Khanty Mansiysk Airport", "ru": "Ханты-Мансийск"}   |{"en": "Khanty-Mansiysk", "ru": "Ханты-Мансийск"}  |(69.08609771728516,61.028499603271484) |Asia/Yekaterinburg|    11476|PG0239   |2017-09-14 09:05:00.000 +0300|2017-09-14 11:40:00.000 +0300|DME              |HMA            |Scheduled|SU9          |                |              |
OVS         |{"en": "Sovetskiy Airport", "ru": "Советский"}              |{"en": "Sovetskiy", "ru": "Советский"}             |(63.60191345214844,61.326622009277344) |Asia/Yekaterinburg|    11790|PG0542   |2017-09-11 13:35:00.000 +0300|2017-09-11 15:45:00.000 +0300|DME              |OVS            |Scheduled|SU9          |                |              |
NYM         |{"en": "Nadym Airport", "ru": "Надым"}                      |{"en": "Nadym", "ru": "Надым"}                     |(72.69889831542969,65.48090362548828)  |Asia/Yekaterinburg|    12473|PG0639   |2017-08-25 14:50:00.000 +0300|2017-08-25 17:55:00.000 +0300|DME              |NYM            |Scheduled|CR2          |                |              |
PEZ         |{"en": "Penza Airport", "ru": "Пенза"}                      |{"en": "Penza", "ru": "Пенза"}                     |(45.02109909057617,53.110599517822266) |Europe/Moscow     |    16953|PG0029   |2017-09-10 09:40:00.000 +0300|2017-09-10 11:25:00.000 +0300|DME              |PEZ            |Scheduled|CN1          |                |              |
URS         |{"en": "Kursk East Airport", "ru": "Курск-Восточный"}       |{"en": "Kursk", "ru": "Курск"}                     |(36.29560089111328,51.7505989074707)   |Europe/Moscow     |    18446|PG0454   |2017-08-17 10:05:00.000 +0300|2017-08-17 10:40:00.000 +0300|DME              |URS            |Scheduled|SU9          |                |              |
```
```sql
demo=# EXPLAIN
SELECT * FROM airports_data a
JOIN flights f 
ON a.airport_code = f.arrival_airport ;

QUERY PLAN                                                                                                  |
------------------------------------------------------------------------------------------------------------+
Limit  (cost=0.15..0.86 rows=15 width=208)                                                                  |
  ->  Nested Loop  (cost=0.15..10130.73 rows=214867 width=208)                                              |
        ->  Seq Scan on flights f  (cost=0.00..4772.67 rows=214867 width=63)                                |
        ->  Memoize  (cost=0.15..0.17 rows=1 width=145)                                                     |
              Cache Key: f.arrival_airport                                                                  |
              Cache Mode: logical                                                                           |
              ->  Index Scan using airports_data_pkey on airports_data a  (cost=0.14..0.16 rows=1 width=145)|
                    Index Cond: (airport_code = f.arrival_airport)                                          |
```
>Для соединения используется Nested Loop Join (перебирает все значения)

2.***Реализовать левостороннее (или правостороннее)соединение двух или более таблиц.***
```sql
demo=# SELECT *
FROM airports_data a
LEFT JOIN flights f 
ON a.airport_code = f.arrival_airport 
limit 15;

airport_code|airport_name                                                |city                                               |coordinates                            |timezone          |flight_id|flight_no|scheduled_departure          |scheduled_arrival            |departure_airport|arrival_airport|status   |aircraft_code|actual_departure|actual_arrival|
------------+------------------------------------------------------------+---------------------------------------------------+---------------------------------------+------------------+---------+---------+-----------------------------+-----------------------------+-----------------+---------------+---------+-------------+----------------+--------------+
KUF         |{"en": "Kurumoch International Airport", "ru": "Курумоч"}   |{"en": "Samara", "ru": "Самара"}                   |(50.16429901123,53.504901885986)       |Europe/Samara     |     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
ROV         |{"en": "Rostov-on-Don Airport", "ru": "Ростов-на-Дону"}     |{"en": "Rostov", "ru": "Ростов-на-Дону"}           |(39.8180999756,47.2582015991)          |Europe/Moscow     |     3940|PG0212   |2017-09-04 18:20:00.000 +0300|2017-09-04 19:35:00.000 +0300|DME              |ROV            |Scheduled|321          |                |              |
VOZ         |{"en": "Voronezh International Airport", "ru": "Воронеж"}   |{"en": "Voronezh", "ru": "Воронеж"}                |(39.22959899902344,51.81420135498047)  |Europe/Moscow     |     4018|PG0416   |2017-09-13 19:20:00.000 +0300|2017-09-13 19:55:00.000 +0300|DME              |VOZ            |Scheduled|CR2          |                |              |
TBW         |{"en": "Donskoye Airport", "ru": "Донское"}                 |{"en": "Tambow", "ru": "Тамбов"}                   |(41.482799530029,52.806098937988)      |Europe/Moscow     |     4587|PG0055   |2017-09-03 14:10:00.000 +0300|2017-09-03 15:25:00.000 +0300|DME              |TBW            |Scheduled|CN1          |                |              |
PES         |{"en": "Petrozavodsk Airport", "ru": "Бесовец"}             |{"en": "Petrozavodsk", "ru": "Петрозаводск"}       |(34.154701232910156,61.88520050048828) |Europe/Moscow     |     5694|PG0341   |2017-08-31 10:50:00.000 +0300|2017-08-31 11:55:00.000 +0300|DME              |PES            |Scheduled|CR2          |                |              |
JOK         |{"en": "Yoshkar-Ola Airport", "ru": "Йошкар-Ола"}           |{"en": "Yoshkar-Ola", "ru": "Йошкар-Ола"}          |(47.904701232910156,56.700599670410156)|Europe/Moscow     |     6428|PG0335   |2017-08-24 09:30:00.000 +0300|2017-08-24 11:35:00.000 +0300|DME              |JOK            |Scheduled|CN1          |                |              |
JOK         |{"en": "Yoshkar-Ola Airport", "ru": "Йошкар-Ола"}           |{"en": "Yoshkar-Ola", "ru": "Йошкар-Ола"}          |(47.904701232910156,56.700599670410156)|Europe/Moscow     |     6664|PG0335   |2017-09-07 09:30:00.000 +0300|2017-09-07 11:35:00.000 +0300|DME              |JOK            |Scheduled|CN1          |                |              |
NAL         |{"en": "Nalchik Airport", "ru": "Нальчик"}                  |{"en": "Nalchik", "ru": "Нальчик"}                 |(43.636600494384766,43.512901306152344)|Europe/Moscow     |     7455|PG0136   |2017-09-10 15:30:00.000 +0300|2017-09-10 17:30:00.000 +0300|DME              |NAL            |Scheduled|CR2          |                |              |
MRV         |{"en": "Mineralnyye Vody Airport", "ru": "Минеральные Воды"}|{"en": "Mineralnye Vody", "ru": "Минеральные Воды"}|(43.08190155029297,44.225101470947266) |Europe/Moscow     |     9994|PG0210   |2017-09-01 18:00:00.000 +0300|2017-09-01 19:50:00.000 +0300|DME              |MRV            |Scheduled|733          |                |              |
HMA         |{"en": "Khanty Mansiysk Airport", "ru": "Ханты-Мансийск"}   |{"en": "Khanty-Mansiysk", "ru": "Ханты-Мансийск"}  |(69.08609771728516,61.028499603271484) |Asia/Yekaterinburg|    11283|PG0239   |2017-08-22 09:05:00.000 +0300|2017-08-22 11:40:00.000 +0300|DME              |HMA            |Scheduled|SU9          |                |              |
HMA         |{"en": "Khanty Mansiysk Airport", "ru": "Ханты-Мансийск"}   |{"en": "Khanty-Mansiysk", "ru": "Ханты-Мансийск"}  |(69.08609771728516,61.028499603271484) |Asia/Yekaterinburg|    11476|PG0239   |2017-09-14 09:05:00.000 +0300|2017-09-14 11:40:00.000 +0300|DME              |HMA            |Scheduled|SU9          |                |              |
OVS         |{"en": "Sovetskiy Airport", "ru": "Советский"}              |{"en": "Sovetskiy", "ru": "Советский"}             |(63.60191345214844,61.326622009277344) |Asia/Yekaterinburg|    11790|PG0542   |2017-09-11 13:35:00.000 +0300|2017-09-11 15:45:00.000 +0300|DME              |OVS            |Scheduled|SU9          |                |              |
NYM         |{"en": "Nadym Airport", "ru": "Надым"}                      |{"en": "Nadym", "ru": "Надым"}                     |(72.69889831542969,65.48090362548828)  |Asia/Yekaterinburg|    12473|PG0639   |2017-08-25 14:50:00.000 +0300|2017-08-25 17:55:00.000 +0300|DME              |NYM            |Scheduled|CR2          |                |              |
PEZ         |{"en": "Penza Airport", "ru": "Пенза"}                      |{"en": "Penza", "ru": "Пенза"}                     |(45.02109909057617,53.110599517822266) |Europe/Moscow     |    16953|PG0029   |2017-09-10 09:40:00.000 +0300|2017-09-10 11:25:00.000 +0300|DME              |PEZ            |Scheduled|CN1          |                |              |
URS         |{"en": "Kursk East Airport", "ru": "Курск-Восточный"}       |{"en": "Kursk", "ru": "Курск"}                     |(36.29560089111328,51.7505989074707)   |Europe/Moscow     |    18446|PG0454   |2017-08-17 10:05:00.000 +0300|2017-08-17 10:40:00.000 +0300|DME              |URS            |Scheduled|SU9          |                |              |
```
```sql
demo=# EXPLAIN
SELECT *
FROM airports_data a
LEFT JOIN flights f 
ON a.airport_code = f.arrival_airport;

QUERY PLAN                                                                   |
-----------------------------------------------------------------------------+
Hash Right Join  (cost=5.34..5365.02 rows=214867 width=208)                  |
  Hash Cond: (f.arrival_airport = a.airport_code)                            |
  ->  Seq Scan on flights f  (cost=0.00..4772.67 rows=214867 width=63)       |
  ->  Hash  (cost=4.04..4.04 rows=104 width=145)                             |
        ->  Seq Scan on airports_data a  (cost=0.00..4.04 rows=104 width=145)|
```
>Для соединения используется Hash Right Join (в качестве внутренней таблицы выбрал меньшую)

3.***Реализовать кросс соединение двух или более таблиц.***
```sql
demo=# SELECT *
FROM airports_data a
CROSS JOIN flights f limit 15;

airport_code|airport_name                                                      |city                                                     |coordinates                            |timezone          |flight_id|flight_no|scheduled_departure          |scheduled_arrival            |departure_airport|arrival_airport|status   |aircraft_code|actual_departure|actual_arrival|
------------+------------------------------------------------------------------+---------------------------------------------------------+---------------------------------------+------------------+---------+---------+-----------------------------+-----------------------------+-----------------+---------------+---------+-------------+----------------+--------------+
YKS         |{"en": "Yakutsk Airport", "ru": "Якутск"}                         |{"en": "Yakutsk", "ru": "Якутск"}                        |(129.77099609375,62.093299865722656)   |Asia/Yakutsk      |     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
MJZ         |{"en": "Mirny Airport", "ru": "Мирный"}                           |{"en": "Mirnyj", "ru": "Мирный"}                         |(114.03900146484375,62.534698486328125)|Asia/Yakutsk      |     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
KHV         |{"en": "Khabarovsk-Novy Airport", "ru": "Хабаровск-Новый"}        |{"en": "Khabarovsk", "ru": "Хабаровск"}                  |(135.18800354004,48.52799987793)       |Asia/Vladivostok  |     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
PKC         |{"en": "Yelizovo Airport", "ru": "Елизово"}                       |{"en": "Petropavlovsk", "ru": "Петропавловск-Камчатский"}|(158.45399475097656,53.16790008544922) |Asia/Kamchatka    |     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
UUS         |{"en": "Yuzhno-Sakhalinsk Airport", "ru": "Хомутово"}             |{"en": "Yuzhno-Sakhalinsk", "ru": "Южно-Сахалинск"}      |(142.71800231933594,46.88869857788086) |Asia/Sakhalin     |     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
VVO         |{"en": "Vladivostok International Airport", "ru": "Владивосток"}  |{"en": "Vladivostok", "ru": "Владивосток"}               |(132.1479949951172,43.39899826049805)  |Asia/Vladivostok  |     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
LED         |{"en": "Pulkovo Airport", "ru": "Пулково"}                        |{"en": "St. Petersburg", "ru": "Санкт-Петербург"}        |(30.262500762939453,59.80030059814453) |Europe/Moscow     |     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
KGD         |{"en": "Khrabrovo Airport", "ru": "Храброво"}                     |{"en": "Kaliningrad", "ru": "Калининград"}               |(20.592599868774414,54.88999938964844) |Europe/Kaliningrad|     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
KEJ         |{"en": "Kemerovo Airport", "ru": "Кемерово"}                      |{"en": "Kemorovo", "ru": "Кемерово"}                     |(86.1072006225586,55.27009963989258)   |Asia/Novokuznetsk |     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
CEK         |{"en": "Chelyabinsk Balandino Airport", "ru": "Челябинск"}        |{"en": "Chelyabinsk", "ru": "Челябинск"}                 |(61.5033,55.305801)                    |Asia/Yekaterinburg|     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
MQF         |{"en": "Magnitogorsk International Airport", "ru": "Магнитогорск"}|{"en": "Magnetiogorsk", "ru": "Магнитогорск"}            |(58.755699157714844,53.39310073852539) |Asia/Yekaterinburg|     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
PEE         |{"en": "Bolshoye Savino Airport", "ru": "Пермь"}                  |{"en": "Perm", "ru": "Пермь"}                            |(56.021198272705,57.914501190186)      |Asia/Yekaterinburg|     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
SGC         |{"en": "Surgut Airport", "ru": "Сургут"}                          |{"en": "Surgut", "ru": "Сургут"}                         |(73.40180206298828,61.34370040893555)  |Asia/Yekaterinburg|     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
BZK         |{"en": "Bryansk Airport", "ru": "Брянск"}                         |{"en": "Bryansk", "ru": "Брянск"}                        |(34.176399231,53.214199066199996)      |Europe/Moscow     |     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
MRV         |{"en": "Mineralnyye Vody Airport", "ru": "Минеральные Воды"}      |{"en": "Mineralnye Vody", "ru": "Минеральные Воды"}      |(43.08190155029297,44.225101470947266) |Europe/Moscow     |     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
```
```sql
demo=# EXPLAIN
SELECT *
FROM airports_data a
CROSS JOIN flights f;

QUERY PLAN                                                                     |
-------------------------------------------------------------------------------+
Nested Loop  (cost=0.00..284104.07 rows=22346168 width=208)                    |
  ->  Seq Scan on flights f  (cost=0.00..4772.67 rows=214867 width=63)         |
  ->  Materialize  (cost=0.00..4.56 rows=104 width=145)                        |
        ->  Seq Scan on airports_data a  (cost=0.00..4.04 rows=104 width=145)  |
JIT:                                                                           |
  Functions: 3                                                                 |
  Options: Inlining false, Optimization false, Expressions true, Deforming true|
```
>Для соединения используется Nested Loop Join и JIT компилятор.

4.***Реализовать полное соединение двух или более таблиц.***
```sql
demo=# SELECT *
FROM airports_data a
FULL JOIN flights f
ON a.airport_code = f.arrival_airport limit 15;

airport_code|airport_name                                                |city                                               |coordinates                            |timezone          |flight_id|flight_no|scheduled_departure          |scheduled_arrival            |departure_airport|arrival_airport|status   |aircraft_code|actual_departure|actual_arrival|
------------+------------------------------------------------------------+---------------------------------------------------+---------------------------------------+------------------+---------+---------+-----------------------------+-----------------------------+-----------------+---------------+---------+-------------+----------------+--------------+
KUF         |{"en": "Kurumoch International Airport", "ru": "Курумоч"}   |{"en": "Samara", "ru": "Самара"}                   |(50.16429901123,53.504901885986)       |Europe/Samara     |     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |
ROV         |{"en": "Rostov-on-Don Airport", "ru": "Ростов-на-Дону"}     |{"en": "Rostov", "ru": "Ростов-на-Дону"}           |(39.8180999756,47.2582015991)          |Europe/Moscow     |     3940|PG0212   |2017-09-04 18:20:00.000 +0300|2017-09-04 19:35:00.000 +0300|DME              |ROV            |Scheduled|321          |                |              |
VOZ         |{"en": "Voronezh International Airport", "ru": "Воронеж"}   |{"en": "Voronezh", "ru": "Воронеж"}                |(39.22959899902344,51.81420135498047)  |Europe/Moscow     |     4018|PG0416   |2017-09-13 19:20:00.000 +0300|2017-09-13 19:55:00.000 +0300|DME              |VOZ            |Scheduled|CR2          |                |              |
TBW         |{"en": "Donskoye Airport", "ru": "Донское"}                 |{"en": "Tambow", "ru": "Тамбов"}                   |(41.482799530029,52.806098937988)      |Europe/Moscow     |     4587|PG0055   |2017-09-03 14:10:00.000 +0300|2017-09-03 15:25:00.000 +0300|DME              |TBW            |Scheduled|CN1          |                |              |
PES         |{"en": "Petrozavodsk Airport", "ru": "Бесовец"}             |{"en": "Petrozavodsk", "ru": "Петрозаводск"}       |(34.154701232910156,61.88520050048828) |Europe/Moscow     |     5694|PG0341   |2017-08-31 10:50:00.000 +0300|2017-08-31 11:55:00.000 +0300|DME              |PES            |Scheduled|CR2          |                |              |
JOK         |{"en": "Yoshkar-Ola Airport", "ru": "Йошкар-Ола"}           |{"en": "Yoshkar-Ola", "ru": "Йошкар-Ола"}          |(47.904701232910156,56.700599670410156)|Europe/Moscow     |     6428|PG0335   |2017-08-24 09:30:00.000 +0300|2017-08-24 11:35:00.000 +0300|DME              |JOK            |Scheduled|CN1          |                |              |
JOK         |{"en": "Yoshkar-Ola Airport", "ru": "Йошкар-Ола"}           |{"en": "Yoshkar-Ola", "ru": "Йошкар-Ола"}          |(47.904701232910156,56.700599670410156)|Europe/Moscow     |     6664|PG0335   |2017-09-07 09:30:00.000 +0300|2017-09-07 11:35:00.000 +0300|DME              |JOK            |Scheduled|CN1          |                |              |
NAL         |{"en": "Nalchik Airport", "ru": "Нальчик"}                  |{"en": "Nalchik", "ru": "Нальчик"}                 |(43.636600494384766,43.512901306152344)|Europe/Moscow     |     7455|PG0136   |2017-09-10 15:30:00.000 +0300|2017-09-10 17:30:00.000 +0300|DME              |NAL            |Scheduled|CR2          |                |              |
MRV         |{"en": "Mineralnyye Vody Airport", "ru": "Минеральные Воды"}|{"en": "Mineralnye Vody", "ru": "Минеральные Воды"}|(43.08190155029297,44.225101470947266) |Europe/Moscow     |     9994|PG0210   |2017-09-01 18:00:00.000 +0300|2017-09-01 19:50:00.000 +0300|DME              |MRV            |Scheduled|733          |                |              |
HMA         |{"en": "Khanty Mansiysk Airport", "ru": "Ханты-Мансийск"}   |{"en": "Khanty-Mansiysk", "ru": "Ханты-Мансийск"}  |(69.08609771728516,61.028499603271484) |Asia/Yekaterinburg|    11283|PG0239   |2017-08-22 09:05:00.000 +0300|2017-08-22 11:40:00.000 +0300|DME              |HMA            |Scheduled|SU9          |                |              |
HMA         |{"en": "Khanty Mansiysk Airport", "ru": "Ханты-Мансийск"}   |{"en": "Khanty-Mansiysk", "ru": "Ханты-Мансийск"}  |(69.08609771728516,61.028499603271484) |Asia/Yekaterinburg|    11476|PG0239   |2017-09-14 09:05:00.000 +0300|2017-09-14 11:40:00.000 +0300|DME              |HMA            |Scheduled|SU9          |                |              |
OVS         |{"en": "Sovetskiy Airport", "ru": "Советский"}              |{"en": "Sovetskiy", "ru": "Советский"}             |(63.60191345214844,61.326622009277344) |Asia/Yekaterinburg|    11790|PG0542   |2017-09-11 13:35:00.000 +0300|2017-09-11 15:45:00.000 +0300|DME              |OVS            |Scheduled|SU9          |                |              |
NYM         |{"en": "Nadym Airport", "ru": "Надым"}                      |{"en": "Nadym", "ru": "Надым"}                     |(72.69889831542969,65.48090362548828)  |Asia/Yekaterinburg|    12473|PG0639   |2017-08-25 14:50:00.000 +0300|2017-08-25 17:55:00.000 +0300|DME              |NYM            |Scheduled|CR2          |                |              |
PEZ         |{"en": "Penza Airport", "ru": "Пенза"}                      |{"en": "Penza", "ru": "Пенза"}                     |(45.02109909057617,53.110599517822266) |Europe/Moscow     |    16953|PG0029   |2017-09-10 09:40:00.000 +0300|2017-09-10 11:25:00.000 +0300|DME              |PEZ            |Scheduled|CN1          |                |              |
URS         |{"en": "Kursk East Airport", "ru": "Курск-Восточный"}       |{"en": "Kursk", "ru": "Курск"}                     |(36.29560089111328,51.7505989074707)   |Europe/Moscow     |    18446|PG0454   |2017-08-17 10:05:00.000 +0300|2017-08-17 10:40:00.000 +0300|DME              |URS            |Scheduled|SU9          |                |              |
```
```sql
demo=# EXPLAIN
SELECT *
FROM airports_data a
FULL JOIN flights f
ON a.airport_code = f.arrival_airport;

QUERY PLAN                                                                   |
-----------------------------------------------------------------------------+
Hash Full Join  (cost=5.34..5365.02 rows=214867 width=208)                   |
  Hash Cond: (f.arrival_airport = a.airport_code)                            |
  ->  Seq Scan on flights f  (cost=0.00..4772.67 rows=214867 width=63)       |
  ->  Hash  (cost=4.04..4.04 rows=104 width=145)                             |
        ->  Seq Scan on airports_data a  (cost=0.00..4.04 rows=104 width=145)|
```
>Для соединения используется Hash Full Join. 

5.***Реализовать запрос, в котором будут использованы разные типы соединений.***
```sql
demo=# SELECT *
FROM airports_data a
JOIN flights f 
ON a.airport_code = f.arrival_airport 
right join aircrafts_data ad
ON f.aircraft_code = ad.aircraft_code
limit 15;

airport_code|airport_name                                                |city                                               |coordinates                            |timezone          |flight_id|flight_no|scheduled_departure          |scheduled_arrival            |departure_airport|arrival_airport|status   |aircraft_code|actual_departure|actual_arrival|aircraft_code|model                                                     |range|
------------+------------------------------------------------------------+---------------------------------------------------+---------------------------------------+------------------+---------+---------+-----------------------------+-----------------------------+-----------------+---------------+---------+-------------+----------------+--------------+-------------+----------------------------------------------------------+-----+
KUF         |{"en": "Kurumoch International Airport", "ru": "Курумоч"}   |{"en": "Samara", "ru": "Самара"}                   |(50.16429901123,53.504901885986)       |Europe/Samara     |     2880|PG0216   |2017-09-14 14:10:00.000 +0300|2017-09-14 15:15:00.000 +0300|DME              |KUF            |Scheduled|763          |                |              |763          |{"en": "Boeing 767-300", "ru": "Боинг 767-300"}           | 7900|
ROV         |{"en": "Rostov-on-Don Airport", "ru": "Ростов-на-Дону"}     |{"en": "Rostov", "ru": "Ростов-на-Дону"}           |(39.8180999756,47.2582015991)          |Europe/Moscow     |     3940|PG0212   |2017-09-04 18:20:00.000 +0300|2017-09-04 19:35:00.000 +0300|DME              |ROV            |Scheduled|321          |                |              |321          |{"en": "Airbus A321-200", "ru": "Аэробус A321-200"}       | 5600|
VOZ         |{"en": "Voronezh International Airport", "ru": "Воронеж"}   |{"en": "Voronezh", "ru": "Воронеж"}                |(39.22959899902344,51.81420135498047)  |Europe/Moscow     |     4018|PG0416   |2017-09-13 19:20:00.000 +0300|2017-09-13 19:55:00.000 +0300|DME              |VOZ            |Scheduled|CR2          |                |              |CR2          |{"en": "Bombardier CRJ-200", "ru": "Бомбардье CRJ-200"}   | 2700|
TBW         |{"en": "Donskoye Airport", "ru": "Донское"}                 |{"en": "Tambow", "ru": "Тамбов"}                   |(41.482799530029,52.806098937988)      |Europe/Moscow     |     4587|PG0055   |2017-09-03 14:10:00.000 +0300|2017-09-03 15:25:00.000 +0300|DME              |TBW            |Scheduled|CN1          |                |              |CN1          |{"en": "Cessna 208 Caravan", "ru": "Сессна 208 Караван"}  | 1200|
PES         |{"en": "Petrozavodsk Airport", "ru": "Бесовец"}             |{"en": "Petrozavodsk", "ru": "Петрозаводск"}       |(34.154701232910156,61.88520050048828) |Europe/Moscow     |     5694|PG0341   |2017-08-31 10:50:00.000 +0300|2017-08-31 11:55:00.000 +0300|DME              |PES            |Scheduled|CR2          |                |              |CR2          |{"en": "Bombardier CRJ-200", "ru": "Бомбардье CRJ-200"}   | 2700|
JOK         |{"en": "Yoshkar-Ola Airport", "ru": "Йошкар-Ола"}           |{"en": "Yoshkar-Ola", "ru": "Йошкар-Ола"}          |(47.904701232910156,56.700599670410156)|Europe/Moscow     |     6428|PG0335   |2017-08-24 09:30:00.000 +0300|2017-08-24 11:35:00.000 +0300|DME              |JOK            |Scheduled|CN1          |                |              |CN1          |{"en": "Cessna 208 Caravan", "ru": "Сессна 208 Караван"}  | 1200|
JOK         |{"en": "Yoshkar-Ola Airport", "ru": "Йошкар-Ола"}           |{"en": "Yoshkar-Ola", "ru": "Йошкар-Ола"}          |(47.904701232910156,56.700599670410156)|Europe/Moscow     |     6664|PG0335   |2017-09-07 09:30:00.000 +0300|2017-09-07 11:35:00.000 +0300|DME              |JOK            |Scheduled|CN1          |                |              |CN1          |{"en": "Cessna 208 Caravan", "ru": "Сессна 208 Караван"}  | 1200|
NAL         |{"en": "Nalchik Airport", "ru": "Нальчик"}                  |{"en": "Nalchik", "ru": "Нальчик"}                 |(43.636600494384766,43.512901306152344)|Europe/Moscow     |     7455|PG0136   |2017-09-10 15:30:00.000 +0300|2017-09-10 17:30:00.000 +0300|DME              |NAL            |Scheduled|CR2          |                |              |CR2          |{"en": "Bombardier CRJ-200", "ru": "Бомбардье CRJ-200"}   | 2700|
MRV         |{"en": "Mineralnyye Vody Airport", "ru": "Минеральные Воды"}|{"en": "Mineralnye Vody", "ru": "Минеральные Воды"}|(43.08190155029297,44.225101470947266) |Europe/Moscow     |     9994|PG0210   |2017-09-01 18:00:00.000 +0300|2017-09-01 19:50:00.000 +0300|DME              |MRV            |Scheduled|733          |                |              |733          |{"en": "Boeing 737-300", "ru": "Боинг 737-300"}           | 4200|
HMA         |{"en": "Khanty Mansiysk Airport", "ru": "Ханты-Мансийск"}   |{"en": "Khanty-Mansiysk", "ru": "Ханты-Мансийск"}  |(69.08609771728516,61.028499603271484) |Asia/Yekaterinburg|    11283|PG0239   |2017-08-22 09:05:00.000 +0300|2017-08-22 11:40:00.000 +0300|DME              |HMA            |Scheduled|SU9          |                |              |SU9          |{"en": "Sukhoi Superjet-100", "ru": "Сухой Суперджет-100"}| 3000|
HMA         |{"en": "Khanty Mansiysk Airport", "ru": "Ханты-Мансийск"}   |{"en": "Khanty-Mansiysk", "ru": "Ханты-Мансийск"}  |(69.08609771728516,61.028499603271484) |Asia/Yekaterinburg|    11476|PG0239   |2017-09-14 09:05:00.000 +0300|2017-09-14 11:40:00.000 +0300|DME              |HMA            |Scheduled|SU9          |                |              |SU9          |{"en": "Sukhoi Superjet-100", "ru": "Сухой Суперджет-100"}| 3000|
OVS         |{"en": "Sovetskiy Airport", "ru": "Советский"}              |{"en": "Sovetskiy", "ru": "Советский"}             |(63.60191345214844,61.326622009277344) |Asia/Yekaterinburg|    11790|PG0542   |2017-09-11 13:35:00.000 +0300|2017-09-11 15:45:00.000 +0300|DME              |OVS            |Scheduled|SU9          |                |              |SU9          |{"en": "Sukhoi Superjet-100", "ru": "Сухой Суперджет-100"}| 3000|
NYM         |{"en": "Nadym Airport", "ru": "Надым"}                      |{"en": "Nadym", "ru": "Надым"}                     |(72.69889831542969,65.48090362548828)  |Asia/Yekaterinburg|    12473|PG0639   |2017-08-25 14:50:00.000 +0300|2017-08-25 17:55:00.000 +0300|DME              |NYM            |Scheduled|CR2          |                |              |CR2          |{"en": "Bombardier CRJ-200", "ru": "Бомбардье CRJ-200"}   | 2700|
PEZ         |{"en": "Penza Airport", "ru": "Пенза"}                      |{"en": "Penza", "ru": "Пенза"}                     |(45.02109909057617,53.110599517822266) |Europe/Moscow     |    16953|PG0029   |2017-09-10 09:40:00.000 +0300|2017-09-10 11:25:00.000 +0300|DME              |PEZ            |Scheduled|CN1          |                |              |CN1          |{"en": "Cessna 208 Caravan", "ru": "Сессна 208 Караван"}  | 1200|
URS         |{"en": "Kursk East Airport", "ru": "Курск-Восточный"}       |{"en": "Kursk", "ru": "Курск"}                     |(36.29560089111328,51.7505989074707)   |Europe/Moscow     |    18446|PG0454   |2017-08-17 10:05:00.000 +0300|2017-08-17 10:40:00.000 +0300|DME              |URS            |Scheduled|SU9          |                |              |SU9          |{"en": "Sukhoi Superjet-100", "ru": "Сухой Суперджет-100"}| 3000|
```
```sql
demo=# EXPLAIN
SELECT *
FROM airports_data a
JOIN flights f 
ON a.airport_code = f.arrival_airport 
right join aircrafts_data ad
ON f.aircraft_code = ad.aircraft_code
limit 15;

QUERY PLAN                                                                               |
-----------------------------------------------------------------------------------------+
Limit  (cost=6.54..6.97 rows=15 width=260)                                               |
  ->  Hash Right Join  (cost=6.54..6195.85 rows=214867 width=260)                        |
        Hash Cond: (f.aircraft_code = ad.aircraft_code)                                  |
        ->  Hash Join  (cost=5.34..5365.02 rows=214867 width=208)                        |
              Hash Cond: (f.arrival_airport = a.airport_code)                            |
              ->  Seq Scan on flights f  (cost=0.00..4772.67 rows=214867 width=63)       |
              ->  Hash  (cost=4.04..4.04 rows=104 width=145)                             |
                    ->  Seq Scan on airports_data a  (cost=0.00..4.04 rows=104 width=145)|
        ->  Hash  (cost=1.09..1.09 rows=9 width=52)                                      |
              ->  Seq Scan on aircrafts_data ad  (cost=0.00..1.09 rows=9 width=52)       |
```
>Для соединения используется Hash Right Join

6.***К работе приложить структуру таблиц, для которых выполнялись соединения.***
```sql
demo=# \d airports_data
                Table "bookings.airports_data"
    Column    |     Type     | Collation | Nullable | Default
--------------+--------------+-----------+----------+---------
 airport_code | character(3) |           | not null |
 airport_name | jsonb        |           | not null |
 city         | jsonb        |           | not null |
 coordinates  | point        |           | not null |
 timezone     | text         |           | not null |
Indexes:
    "airports_data_pkey" PRIMARY KEY, btree (airport_code)
Referenced by:
    TABLE "flights" CONSTRAINT "flights_arrival_airport_fkey" FOREIGN KEY (arrival_airport) REFERENCES airports_data(airport_code)
    TABLE "flights" CONSTRAINT "flights_departure_airport_fkey" FOREIGN KEY (departure_airport) REFERENCES airports_data(airport_code)

demo=# \d flights
                                              Table "bookings.flights"
       Column        |           Type           | Collation | Nullable |                  Default
---------------------+--------------------------+-----------+----------+--------------------------------------------
 flight_id           | integer                  |           | not null | nextval('flights_flight_id_seq'::regclass)
 flight_no           | character(6)             |           | not null |
 scheduled_departure | timestamp with time zone |           | not null |
 scheduled_arrival   | timestamp with time zone |           | not null |
 departure_airport   | character(3)             |           | not null |
 arrival_airport     | character(3)             |           | not null |
 status              | character varying(20)    |           | not null |
 aircraft_code       | character(3)             |           | not null |
 actual_departure    | timestamp with time zone |           |          |
 actual_arrival      | timestamp with time zone |           |          |
Indexes:
    "flights_pkey" PRIMARY KEY, btree (flight_id)
    "flights_flight_no_scheduled_departure_key" UNIQUE CONSTRAINT, btree (flight_no, scheduled_departure)
Check constraints:
    "flights_check" CHECK (scheduled_arrival > scheduled_departure)
    "flights_check1" CHECK (actual_arrival IS NULL OR actual_departure IS NOT NULL AND actual_arrival IS NOT NULL AND actual_arrival > actual_departure)
    "flights_status_check" CHECK (status::text = ANY (ARRAY['On Time'::character varying::text, 'Delayed'::character varying::text, 'Departed'::character varying::text, 'Arrived'::character varying::text, 'Scheduled'::character varying::text, 'Cancelled'::character varying::text]))
Foreign-key constraints:
    "flights_aircraft_code_fkey" FOREIGN KEY (aircraft_code) REFERENCES aircrafts_data(aircraft_code)
    "flights_arrival_airport_fkey" FOREIGN KEY (arrival_airport) REFERENCES airports_data(airport_code)
    "flights_departure_airport_fkey" FOREIGN KEY (departure_airport) REFERENCES airports_data(airport_code)
Referenced by:
    TABLE "ticket_flights" CONSTRAINT "ticket_flights_flight_id_fkey" FOREIGN KEY (flight_id) REFERENCES flights(flight_id)

demo=# \d aircrafts_data
                Table "bookings.aircrafts_data"
    Column     |     Type     | Collation | Nullable | Default
---------------+--------------+-----------+----------+---------
 aircraft_code | character(3) |           | not null |
 model         | jsonb        |           | not null |
 range         | integer      |           | not null |
Indexes:
    "aircrafts_pkey" PRIMARY KEY, btree (aircraft_code)
Check constraints:
    "aircrafts_range_check" CHECK (range > 0)
Referenced by:
    TABLE "flights" CONSTRAINT "flights_aircraft_code_fkey" FOREIGN KEY (aircraft_code) REFERENCES aircrafts_data(aircraft_code)
    TABLE "seats" CONSTRAINT "seats_aircraft_code_fkey" FOREIGN KEY (aircraft_code) REFERENCES aircrafts_data(aircraft_code) ON DELETE CASCADE
```

✨Magic ✨