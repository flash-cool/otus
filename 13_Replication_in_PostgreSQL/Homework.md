# Репликация 
_____

- Цели
  - реализовать свой миникластер на 3 ВМ.
  
1.***На 1 ВМ создаем таблицы test для записи, test2 для запросов на чтение.***
>Создаём кластер и меняем параметр wal_level

```bash
root@pg:~# sudo -u postgres psql
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# alter system set wal_level = logical;
ALTER SYSTEM
postgres=#
\q
root@pg:~# pg_ctlcluster 15 main restart
root@pg:~# sudo -u postgres psql
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# show wal_level;
 wal_level
-----------
 logical
(1 row)
```
>Создаём таблицы

```sql
postgres=# create database rep;
CREATE DATABASE
postgres=# \c rep
You are now connected to database "rep" as user "postgres".
rep=# create table writevm1 as select generate_series(1, 10) as id, md5(random()::text)::char(10) as fio;
SELECT 10
rep=# create table writevm2(num int, fi text);
CREATE TABLE
rep=# select * from writevm1;
 id |    fio
----+------------
  1 | 699c8e4165
  2 | 5b7f29bc2c
  3 | c74212da45
  4 | a1302c7d72
  5 | d1e0a89ea1
  6 | 8c86cb8c7d
  7 | 157365d165
  8 | ed01d459e7
  9 | 106abcd82d
 10 | 6be20021c8
(10 rows)

```
2.***На 2 ВМ создаем таблицы test2 для записи, test для запросов на чтение.***
>Создаём кластер и меняем параметр wal_level

```bash
root@pg:~# pg_ctlcluster 15 main start
root@pg:~# sudo -u postgres psql
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# alter system set wal_level = logical;
ALTER SYSTEM
postgres=#
\q
root@pg:~# pg_ctlcluster 15 main restart
root@pg:~# sudo -u postgres psql
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# show wal_level;
 wal_level
-----------
 logical
(1 row)
```
>Создаём таблицы

```sql
postgres=# create database repvm2;
CREATE DATABASE
postgres=# \c repvm2
You are now connected to database "repvm2" as user "postgres".
repvm2=# create table writevm2 as select generate_series(1, 10) as num, md5(random()::text)::char(10) as fi;
SELECT 10
repvm2=# create table writevm1(id int, fio text);
CREATE TABLE
repvm2=# select * from writevm2;
 num |     fi
-----+------------
   1 | e13c30155c
   2 | ffb13fbb36
   3 | 8f6332d5dd
   4 | a82c3af96a
   5 | b46d246564
   6 | 2af38f7000
   7 | e51f498135
   8 | 7d5e81e764
   9 | a1ed93c4f0
  10 | aa462107c4
(10 rows)
```
3.***Создаем публикацию таблицы test на ВМ №1 и подписываемся на публикацию таблицы test2 с ВМ №2.***
```sql
rep=# create publication rep for table writevm1;
CREATE PUBLICATION
rep=# \dRp+
                              Publication rep
  Owner   | All tables | Inserts | Updates | Deletes | Truncates | Via root
----------+------------+---------+---------+---------+-----------+----------
 postgres | f          | t       | t       | t       | t         | f
Tables:
    "public.writevm1"

rep=# create subscription repvm2_sub
connection 'host=172.16.2.143 port=5432 user=postgres password=xxxxxx dbname=repvm2'
publication repvm2 with (copy_data = true);
NOTICE:  created replication slot "repvm2_sub" on publisher
CREATE SUBSCRIPTION
rep=# \dRs
             List of subscriptions
    Name    |  Owner   | Enabled | Publication
------------+----------+---------+-------------
 repvm2_sub | postgres | t       | {repvm2}
(1 row)

-- Console #1  Проверяем логическую репликацию с ВМ №2

rep=# select * from writevm2;
 num |     fi
-----+------------
   1 | e13c30155c
   2 | ffb13fbb36
   3 | 8f6332d5dd
   4 | a82c3af96a
   5 | b46d246564
   6 | 2af38f7000
   7 | e51f498135
   8 | 7d5e81e764
   9 | a1ed93c4f0
  10 | aa462107c4
(10 rows)

-- Console #2 Добавим строчку в таблицу

repvm2=# insert into writevm2 values (11, 'test_rep_2');
INSERT 0 1

-- Console #1  Проверяем появились данные или нет с ВМ №2

rep=# select * from writevm2;
 num |     fi
-----+------------
   1 | e13c30155c
   2 | ffb13fbb36
   3 | 8f6332d5dd
   4 | a82c3af96a
   5 | b46d246564
   6 | 2af38f7000
   7 | e51f498135
   8 | 7d5e81e764
   9 | a1ed93c4f0
  10 | aa462107c4
  11 | test_rep_2
(11 rows)
```
4.***Создаем публикацию таблицы test2 на ВМ №2 и подписываемся на публикацию таблицы test1 с ВМ №1.***
```sql
repvm2=# create publication repvm2 for table writevm2;
CREATE PUBLICATION
repvm2=# \dRp+
                             Publication repvm2
  Owner   | All tables | Inserts | Updates | Deletes | Truncates | Via root
----------+------------+---------+---------+---------+-----------+----------
 postgres | f          | t       | t       | t       | t         | f
Tables:
    "public.writevm2"

repvm2=# create subscription rep_sub
connection 'host=172.16.2.218 port=5432 user=postgres password=xxxxxx dbname=rep'
publication rep with (copy_data = true);
NOTICE:  created replication slot "rep_sub" on publisher
CREATE SUBSCRIPTION
repvm2=# \dRs
           List of subscriptions
  Name   |  Owner   | Enabled | Publication
---------+----------+---------+-------------
 rep_sub | postgres | t       | {rep}
(1 row)

-- Console #2  Проверяем логическую репликацию с ВМ №1

repvm2=# select * from writevm1;
 id |    fio
----+------------
  1 | 699c8e4165
  2 | 5b7f29bc2c
  3 | c74212da45
  4 | a1302c7d72
  5 | d1e0a89ea1
  6 | 8c86cb8c7d
  7 | 157365d165
  8 | ed01d459e7
  9 | 106abcd82d
 10 | 6be20021c8
(10 rows)

-- Console #1 Добавим строчку в таблицу

rep=# insert into writevm1 values (11, 'test_rep_1');
INSERT 0 1

-- Console #2  Проверяем появились данные или нет с ВМ №2

repvm2=# select * from writevm1;
 id |    fio
----+------------
  1 | 699c8e4165
  2 | 5b7f29bc2c
  3 | c74212da45
  4 | a1302c7d72
  5 | d1e0a89ea1
  6 | 8c86cb8c7d
  7 | 157365d165
  8 | ed01d459e7
  9 | 106abcd82d
 10 | 6be20021c8
 11 | test_rep_1
(11 rows)
```
5.***3 ВМ использовать как реплику для чтения и бэкапов (подписаться на таблицы из ВМ №1 и №2 ).***
```sql
postgres=# create database repvm3;
CREATE DATABASE
postgres=# \c repvm3
You are now connected to database "repvm3" as user "postgres".
repvm3=#  create table writevm1(id int, fio text);
CREATE TABLE
repvm3=# create table writevm2(num int, fi text);
CREATE TABLE
repvm3=# create subscription repvm2_3_sub
connection 'host=172.16.2.143 port=5432 user=postgres password=xxxxxx dbname=repvm2'
publication repvm2 with (copy_data = true);
NOTICE:  created replication slot "repvm2_3_sub" on publisher
CREATE SUBSCRIPTION
repvm3=# create subscription rep_3_sub
connection 'host=172.16.2.218 port=5432 user=postgres password=xxxxxx dbname=rep'
publication rep with (copy_data = true);
NOTICE:  created replication slot "rep_3_sub" on publisher
CREATE SUBSCRIPTION
repvm3=# \dRs
              List of subscriptions
     Name     |  Owner   | Enabled | Publication
--------------+----------+---------+-------------
 rep_3_sub    | postgres | t       | {rep}
 repvm2_3_sub | postgres | t       | {repvm2}
(2 rows)

repvm3=# select * from pg_stat_subscription \gx
-[ RECORD 1 ]---------+------------------------------
subid                 | 16421
subname               | repvm2_3_sub
pid                   | 582
relid                 |
received_lsn          | 0/2281AF8
last_msg_send_time    | 2024-01-26 04:47:36.056108-09
last_msg_receipt_time | 2024-01-26 04:47:37.279356-09
latest_end_lsn        | 0/2281AF8
latest_end_time       | 2024-01-26 04:47:36.056108-09
-[ RECORD 2 ]---------+------------------------------
subid                 | 16422
subname               | rep_3_sub
pid                   | 585
relid                 |
received_lsn          | 0/227F900
last_msg_send_time    | 2024-01-26 04:47:58.57278-09
last_msg_receipt_time | 2024-01-26 04:47:59.590249-09
latest_end_lsn        | 0/227F900
latest_end_time       | 2024-01-26 04:47:58.57278-09
```
> Проверяем данные в таблицах

```sql
repvm3=# select * from writevm2;
 num |     fi
-----+------------
   1 | e13c30155c
   2 | ffb13fbb36
   3 | 8f6332d5dd
   4 | a82c3af96a
   5 | b46d246564
   6 | 2af38f7000
   7 | e51f498135
   8 | 7d5e81e764
   9 | a1ed93c4f0
  10 | aa462107c4
  11 | test_rep_2
(11 rows)

repvm3=# select * from writevm1;
 id |    fio
----+------------
  1 | 699c8e4165
  2 | 5b7f29bc2c
  3 | c74212da45
  4 | a1302c7d72
  5 | d1e0a89ea1
  6 | 8c86cb8c7d
  7 | 157365d165
  8 | ed01d459e7
  9 | 106abcd82d
 10 | 6be20021c8
 11 | test_rep_1
(11 rows)
```
6.***Реализовать горячее реплицирование для высокой доступности на 4ВМ. Источником должна выступать ВМ №3. Написать с какими проблемами столкнулись.***
>Выполняем команды на ВМ №4

```bash
root@pg:~# sudo rm -rf /var/lib/postgresql/15/main
root@pg:~# pg_lsclusters
Ver Cluster Port Status Owner     Data directory              Log file
15  main    5432 online <unknown> /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
root@pg:~#  sudo -u postgres pg_basebackup -h 172.16.2.147 -U postgres -R -D /var/lib/postgresql/15/main
could not change directory to "/root": Permission denied
Password:
root@pg:~# pg_ctlcluster 15 main start
root@pg:~# pg_ctlcluster 15 main start
root@pg:~# pg_lsclusters
Ver Cluster Port Status          Owner    Data directory              Log file
15  main    5432 online,recovery postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
>Проверим появились таблицы или нет.

```sql
postgres=# \l
                                                 List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    | ICU Locale | Locale Provider |   Access privileges
-----------+----------+----------+-------------+-------------+------------+-----------------+-----------------------
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            |
 repvm3    | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            |
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            | =c/postgres          +
           |          |          |             |             |            |                 | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 |            | libc            | =c/postgres          +
           |          |          |             |             |            |                 | postgres=CTc/postgres
(4 rows)

postgres=# \c repvm3
You are now connected to database "repvm3" as user "postgres".
repvm3=# \dt
          List of relations
 Schema |   Name   | Type  |  Owner
--------+----------+-------+----------
 public | writevm1 | table | postgres
 public | writevm2 | table | postgres
(2 rows)

repvm3=# select * from writevm1;
 id |    fio
----+------------
  1 | 699c8e4165
  2 | 5b7f29bc2c
  3 | c74212da45
  4 | a1302c7d72
  5 | d1e0a89ea1
  6 | 8c86cb8c7d
  7 | 157365d165
  8 | ed01d459e7
  9 | 106abcd82d
 10 | 6be20021c8
 11 | test_rep_1
(11 rows)

repvm3=# select * from writevm2;
 num |     fi
-----+------------
   1 | e13c30155c
   2 | ffb13fbb36
   3 | 8f6332d5dd
   4 | a82c3af96a
   5 | b46d246564
   6 | 2af38f7000
   7 | e51f498135
   8 | 7d5e81e764
   9 | a1ed93c4f0
  10 | aa462107c4
  11 | test_rep_2
(11 rows)

-- Console #1 Добавим строчку в таблицу

rep=# insert into writevm1 values (12, 'test_sup_1');
INSERT 0 1

-- Console #2 Добавим строчку в таблицу

repvm2=# insert into writevm2 values (12, 'test_sup_2');
INSERT 0 1

-- Console #4 проверим появились ли строчки

repvm3=# select * from writevm1;
 id |    fio
----+------------
  1 | 699c8e4165
  2 | 5b7f29bc2c
  3 | c74212da45
  4 | a1302c7d72
  5 | d1e0a89ea1
  6 | 8c86cb8c7d
  7 | 157365d165
  8 | ed01d459e7
  9 | 106abcd82d
 10 | 6be20021c8
 11 | test_rep_1
 12 | test_sup_1
(12 rows)

repvm3=# select * from writevm2;
 num |     fi
-----+------------
   1 | e13c30155c
   2 | ffb13fbb36
   3 | 8f6332d5dd
   4 | a82c3af96a
   5 | b46d246564
   6 | 2af38f7000
   7 | e51f498135
   8 | 7d5e81e764
   9 | a1ed93c4f0
  10 | aa462107c4
  11 | test_rep_2
  12 | test_sup_2
(12 rows)

postgres=# select * from pg_stat_wal_receiver \gx
-[ RECORD 1 ]---------+---------------------------------
pid                   | 649
status                | streaming
receive_start_lsn     | 0/6000000
receive_start_tli     | 1
written_lsn           | 0/60023E0
flushed_lsn           | 0/60023E0
received_tli          | 1
last_msg_send_time    | 2024-01-26 05:42:48.193253-09
last_msg_receipt_time | 2024-01-26 05:42:47.291472-09
latest_end_lsn        | 0/60023E0
latest_end_time       | 2024-01-26 05:38:17.536954-09
slot_name             |
sender_host           | 172.16.2.147
sender_port           | 5432
conninfo              | user=postgres password=******** 
						channel_binding=prefer dbname=replication host=172.16.2.147 port=5432 
						fallback_application_name=15/main sslmode=prefer sslcompression=0 
						sslcertmode=allow sslsni=1 ssl_min_protocol_version=TLSv1.2 
						gssencmode=prefer krbsrvname=postgres gssdelegation=0 
						target_session_attrs=any load_balance_hosts=disable
```
>Самое сложное было во всём этом не запутаться (что сделать не удалось).

```
-- Перевод в состояние мастера.
sudo pg_ctlcluster 15 main promote

-- Проверить статус репликации.
SELECT * FROM pg_stat_replication \gx

-- Посмотреть список слотов репликации.
SELECT * FROM pg_replication_slots;

-- Удаление слота репликации "replica".
select pg_drop_replication_slot('replica);
```

✨Magic ✨