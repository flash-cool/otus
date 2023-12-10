## SQL и реляционные СУБД. Введение в PostgreSQL 
1.<span style="color:blue">*Поставить PostgreSQL*</span>
```
root@AMS:/tmp# pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
2.<span style="color:blue">*Выключить auto commit*</span>
>postgres=# \set AUTOCOMMIT OFF

2.<span style="color:blue">*Сделать в первой сессии новую таблицу и наполнить ее данными create table persons(id serial, first_name text, second_name text); insert into persons(first_name, second_name) values('ivan', 'ivanov'); insert into persons(first_name, second_name) values('petr', 'petrov'); commit;*</span>
```
postgres=# create table persons(id serial, first_name text, second_name text);
CREATE TABLE
postgres=*# insert into persons(first_name, second_name) values('ivan', 'ivanov');
INSERT 0 1
postgres=*# insert into persons(first_name, second_name) values('petr', 'petrov');
INSERT 0 1
postgres=*# commit;
COMMIT
postgres=# 
```
3.<span style="color:blue">*Посмотреть текущий уровень изоляции: show transaction isolation level*</span>
```
postgres=# show transaction isolation level;                                                                          x
 transaction_isolation                                                                                                x
-----------------------                                                                                               x
 read committed                                                                                                       x
(1 row)    
```
4.<span style="color:blue">*Начать новую транзакцию в обоих сессиях с дефолтным (не меняя) уровнем изоляции
в первой сессии добавить новую запись insert into persons(first_name, second_name) values('sergey', 'sergeev');*</span>
```
postgres=# begin;                                                                                                     x
BEGIN                                                                                                                 x
postgres=*# insert into persons(first_name, second_name) values('supe', 'men');                                       x
INSERT 0 1                                                                                                            x
postgres=*#  
```
5.<span style="color:blue">*Сделать select from persons во второй сессии*</span>
```
postgres=# begin;
xBEGIN
xpostgres=*# select * from persons;
x id | first_name | second_name
x----+------------+-------------
x  1 | ivan       | ivanov
x  2 | petr       | petrov
x(2 rows)
x
xpostgres=*#
```
:heavy_exclamation_mark:<span style="color:red">`Не вижу, так как транзакция в первой сессии не завершина (нет грязного чтения)`</span>

6.<span style="color:blue">*Завершить первую транзакцию - commit;*</span>
```
postgres=*# commit;                                                                                                   x
COMMIT                                                                                                                x
postgres=# 
```
7.<span style="color:blue">*Сделать select from persons во второй сессии*</span>
```
postgres=*# select * from persons;
x id | first_name | second_name
x----+------------+-------------
x  1 | ivan       | ivanov
x  2 | petr       | petrov
x  3 | supe       | men
x(3 rows)
x
xpostgres=*#
```
:white_check_mark:<span style="color:green">`Вижу, так как транзакция в первой сессии завершина и данные в базу записаны`</span>

8.<span style="color:blue">*Завершите транзакцию во второй сессии*</span>
```
postgres=*# commit;                                                                                                   x
COMMIT 
```
9.<span style="color:blue">*Начать новые но уже repeatable read транзации - set transaction isolation level repeatable read;*</span>
```
postgres=# set transaction isolation level repeatable read;                                                           x
SET 
```
10.<span style="color:blue">*В первой сессии добавить новую запись insert into persons(first_name, second_name) values('sveta', 'svetova');*</span>
```
postgres=*# insert into persons(first_name, second_name) values('halk', 'hogan');                                     x
INSERT 0 1                                                                                                            x
postgres=*#
```
11.<span style="color:blue">*Сделать select* from persons во второй сессии*</span>
```
postgres=*# select* from persons;
x id | first_name | second_name
x----+------------+-------------
x  1 | ivan       | ivanov
x  2 | petr       | petrov
x  3 | supe       | men
x(3 rows)
x
xpostgres=*#
```
:heavy_exclamation_mark:<span style="color:red">`Не вижу, так как транзакция в первой сессии не завершина`</span>

12.<span style="color:blue">*Завершить первую транзакцию - commit;*</span>
```
postgres=*# commit;                                                                                                   x
COMMIT                                                                                                                x
postgres=#  
```
13.<span style="color:blue">*Сделать select from persons во второй сессии*</span>
```
postgres=*# select* from persons;
x id | first_name | second_name
x----+------------+-------------
x  1 | ivan       | ivanov
x  2 | petr       | petrov
x  3 | supe       | men
x(3 rows)
x
xpostgres=*#
```
:heavy_exclamation_mark:<span style="color:red">`Не вижу, так как транзакция в второй сессии не завершина (на данном уровни изоляции каждый работает со своим снимком базы)`</span>

14.<span style="color:blue">*Завершить вторую транзакцию*</span>
```
postgres=*# commit;                                                                                                   x
COMMIT                                                                                                                x
postgres=#
```
15.<span style="color:blue">*Сделать select * from persons во второй сессии*</span>
```
xpostgres=# select* from persons;
x id | first_name | second_name
x----+------------+-------------
x  1 | ivan       | ivanov
x  2 | petr       | petrov
x  3 | supe       | men
x  4 | halk       | hogan
x(4 rows)
```
:white_check_mark:<span style="color:green">`Вижу , так как обе транзакции в сессиях были заверншины`</span>