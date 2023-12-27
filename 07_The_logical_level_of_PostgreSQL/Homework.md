# Логический уровень PostgreSQL 
_____

- Цели
  - создание новой базы данных, схемы и таблицы
  - создание роли для чтения данных из созданной схемы созданной базы данных
  - создание роли для чтения и записи из созданной схемы созданной базы данных
  
1.***Создайте новый кластер PostgresSQL 14***
```bash
root@POL:~# pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
2.***Зайдите в созданный кластер под пользователем postgres***
```bash
root@POL:~# sudo -u postgres psql
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg110+1))
Type "help" for help.

postgres=#
```
3.***Создайте новую базу данных testdb***
```sql
postgres=# CREATE DATABASE hw_otus;
CREATE DATABASE
```
4.***Зайдите в созданную базу данных под пользователем postgres***
```sql
postgres=# \c hw_otus
You are now connected to database "hw_otus" as user "postgres".
```
5.***Создайте новую схему testnm***
```sql
postgres=# CREATE SCHEMA testhw;
CREATE SCHEMA
```
6.***Создайте новую таблицу t1 с одной колонкой c1 типа intege***
```sql
postgres=# CREATE TABLE t1(c1 int);
CREATE TABLE
```
7.***Вставьте строку со значением c1=1***
```sql
hw_otus=# INSERT INTO t1(c1) VALUES (1);
INSERT 0 1
hw_otus=# select c1 from t1;
 c1
----
  1
(1 row)
```
8.***Создайте новую роль readonly***
```sql
hw_otus=# CREATE ROLE readonly;
CREATE ROLE
```
9.***Даайте новой роли право на подключение к базе данных testdb***
```sql
hw_otus=# GRANT CONNECT ON DATABASE hw_otus TO readonly;
GRANT
```
10.***Дайте новой роли право на использование схемы testnm***
```sql
hw_otus=# GRANT USAGE ON SCHEMA testhw TO readonly;
GRANT
```
11.***Дайте новой роли право на select для всех таблиц схемы testnm***
```sql
hw_otus=# GRANT SELECT ON ALL TABLES IN SCHEMA testhw TO readonly;
GRANT
```
12.***Создайте пользователя testread с паролем test123***
```sql
hw_otus=# CREATE USER testread PASSWORD 'test123';
CREATE ROLE
```
13.***Дайте роль readonly пользователю testread***
```sql
hw_otus=# GRANT readonly TO testread;
GRANT ROLE
```
14.***Зйдите под пользователем testread в базу данных testdb***
```bash
root@POL:~# psql -U testread -W  -h 127.0.0.1 -d hw_otus
Password:
psql (15.5 (Debian 15.5-1.pgdg110+1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.

hw_otus=>
```
15.***Сделайте select * from t1;***
```sql
hw_otus=> select * from t1;
ERROR:  permission denied for table t1
```

:heavy_exclamation_mark:`Не получилось т.к. явно не указали в какой схеме создавать таблицу и она попала в схему public, а у роли readonly нет прав на эту схему`:heavy_exclamation_mark:

```sql
postgres-# \dt public.*
        List of relations
 Schema | Name | Type  |  Owner
--------+------+-------+----------
 public | t1   | table | postgres
(1 row)
```
16.***Вернитесь в базу данных testdb под пользователем postgres***
```bash
root@POL:~# sudo -u postgres psql
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg110+1))
Type "help" for help.

postgres=#
```
17.***Удалите таблицу t1***
```sql
hw_otus=# DROP TABLE t1;
DROP TABLE
```
18.***Создайте ее заново но уже с явным указанием имени схемы testnm***
```sql
hw_otus=# CREATE TABLE testhw.t1(c1 int);
CREATE TABLE
```
19.***Вставьте строку со значением c1=1***
```sql
hw_otus=# INSERT INTO testhw.t1(c1) VALUES (1);
INSERT 0 1
hw_otus=# GRANT SELECT ON ALL TABLES IN SCHEMA testhw TO readonly;
GRANT
```
20.***Зайдите под пользователем testread в базу данных testdb***
```bash
root@POL:~# psql -U testread -W  -h 127.0.0.1 -d hw_otus
Password:
psql (15.5 (Debian 15.5-1.pgdg110+1))
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
Type "help" for help.

hw_otus=>
```
21.***Сделайте select * from testhw.t1;***
```sql
hw_otus=> select * from testhw.t1;
 c1
----
  1
(1 row)
```

:white_check_mark:`Получилось т.к. после создания таблицы выдал права на схему testhw`:white_check_mark:

>Но если создать ещё одну таблицу явно указав схему, прав на чтение не будет
>Это из-за того что права на схему выдаются на уже созданные объекты,
>на обыекты созданные после выдачи, прав не будет
>Решить это можно выполнив команду ALTER DEFAULT PRIVILEGES IN SCHEMA testhw GRANT SELECT ON TABLES TO readonly;
>Она автоматически предоставляет разрешения роли readonly доступность новых таблиц.

22.***Теперь попробуйте выполнить команду create table t2(c1 integer); insert into t2 values (2);***
```sql
hw_otus=> create table t2(c1 integer); insert into t2 values (2);
ERROR:  permission denied for schema public
LINE 1: create table t2(c1 integer);
                     ^
ERROR:  relation "t2" does not exist
LINE 1: insert into t2 values (2);
                    ^
```
>Не понял в чём дело и посмотрел шпаргалку, не знаю как так получилось.
>Прочитал до конца и понял почему была указана 14 версия, я использовал 15. 

✨Magic ✨