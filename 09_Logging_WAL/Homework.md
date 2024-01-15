# Работа с журналами 
_____

- Цели
  - уметь работать с журналами и контрольными точками
  - уметь настраивать параметры журналов
  
1.***Настройте выполнение контрольной точки раз в 30 секунд***
```sql
postgres=# alter system set checkpoint_timeout = '30s';
ALTER SYSTEM
postgres=#
\q
root@pg:~# pg_ctlcluster 15 main restart
root@pg:~# sudo -u postgres psql
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# SELECT name, setting, context, short_desc FROM pg_settings WHERE name='checkpoint_timeout';
        name        | setting | context |                        short_desc
--------------------+---------+---------+----------------------------------------------------------
 checkpoint_timeout | 30      | sighup  | Sets the maximum time between automatic WAL checkpoints.
(1 row)
postgres=# select pg_current_wal_insert_lsn();
 pg_current_wal_insert_lsn
---------------------------
 0/1540478
(1 row)
```
2.***10 минут c помощью утилиты pgbench подавайте нагрузку.***
```bash
root@pg:~# sudo -u postgres pgbench -c8 -P 6 -T 600 -U postgres bench
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 600 s
number of transactions actually processed: 446796
number of failed transactions: 0 (0.000%)
latency average = 10.742 ms
latency stddev = 6.172 ms
initial connection time = 13.306 ms
tps = 744.661896 (without initial connection time)
```
3.***Измерьте, какой объем журнальных файлов был сгенерирован за это время. Оцените, какой объем приходится в среднем на одну контрольную точку.***
```sql
postgres=# select pg_current_wal_lsn();
 pg_current_wal_lsn
--------------------
 0/220F3178
(1 row)
postgres=# select '0/220F3178'::pg_lsn - '0/1540478'::pg_lsn as bytes;
   bytes
-----------
 549137664
(1 row)
```
> На одну контрольную точку приходится 523Mb / 20 = 26,15 Mb

4.***Проверьте данные статистики: все ли контрольные точки выполнялись точно по расписанию. Почему так произошло***
```sql
postgres=# SELECT * FROM pg_stat_bgwriter \gx
-[ RECORD 1 ]---------+------------------------------
checkpoints_timed     | 96
checkpoints_req       | 1
checkpoint_write_time | 650970
checkpoint_sync_time  | 424
buffers_checkpoint    | 47418
buffers_clean         | 0
maxwritten_clean      | 0
buffers_backend       | 6732
buffers_backend_fsync | 0
buffers_alloc         | 8788
stats_reset           | 2024-01-15 03:06:28.862787-09
```
> Одна контрольная точка выполнилась принудительно, скорее всего из-за переполнения shared_buffers гряным буфером (выполнилась что бы скинуть их на диск)

5.***Сравните tps в синхронном/асинхронном режиме утилитой pgbench. Объясните полученный результат.***
```bash
postgres=# SELECT name, setting, context, short_desc FROM pg_settings WHERE name='synchronous_commit';
        name        | setting | context |                      short_desc
--------------------+---------+---------+-------------------------------------------------------
 synchronous_commit | on      | user    | Sets the current transaction's synchronization level.
(1 row)

postgres=#
\q
root@pg:~# sudo -u postgres pgbench -c8 -P 6 -T 60 -U postgres bench
pgbench (15.5 (Debian 15.5-1.pgdg120+1))
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 45970
number of failed transactions: 0 (0.000%)
latency average = 10.439 ms
latency stddev = 5.755 ms
initial connection time = 13.715 ms
tps = 766.204900 (without initial connection time)

postgres=# SELECT name, setting, context, short_desc FROM pg_settings WHERE name='synchronous_commit';
        name        | setting | context |                      short_desc
--------------------+---------+---------+-------------------------------------------------------
 synchronous_commit | off     | user    | Sets the current transaction's synchronization level.
(1 row)
root@pg:~# sudo -u postgres pgbench -c8 -P 6 -T 60 -U postgres bench
pgbench (15.5 (Debian 15.5-1.pgdg120+1))
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 260117
number of failed transactions: 0 (0.000%)
latency average = 1.845 ms
latency stddev = 0.507 ms
initial connection time = 12.939 ms
tps = 4335.606625 (without initial connection time)
```
>В асинхронном tps в разы лучше потому что не ждёт фиксации изменения, а записывает заполненные страницы из-за чего уменьшается время отклика.

6.***Создайте новый кластер с включенной контрольной суммой страниц. Создайте таблицу. Вставьте несколько значений.***
```bash
root@pg:~# sudo pg_createcluster 15 main --  --data-checksums
Creating new PostgreSQL cluster 15/main ...
/usr/lib/postgresql/15/bin/initdb -D /var/lib/postgresql/15/main --auth-local peer --auth-host scram-sha-256 --no-instructions --data-checksums
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.

The database cluster will be initialized with locale "en_US.UTF-8".
The default database encoding has accordingly been set to "UTF8".
The default text search configuration will be set to "english".

Data page checksums are enabled.

fixing permissions on existing directory /var/lib/postgresql/15/main ... ok
creating subdirectories ... ok
selecting dynamic shared memory implementation ... posix
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting default time zone ... US/Alaska
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
root@pg:~# sudo systemctl enable postgresql --now
Synchronizing state of postgresql.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable postgresql
root@pg:~# pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
root@pg:~# sudo -u postgres psql
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# create database bench;
CREATE DATABASE
bench=# create table what ( num int, name text);
CREATE TABLE
bench=# insert into what(num, name) values ('1', 'hogan');
INSERT 0 1
bench=# insert into what(num, name) values ('1', 'petr');
INSERT 0 1
bench=# select * from what;
 num | name
-----+-------
   1 | hogan
   1 | petr
(2 rows)
bench=# SELECT name, setting FROM pg_settings WHERE name= 'data_checksums';
      name      | setting
----------------+---------
 data_checksums | on
(1 row)
```
7.***Выключите кластер. Измените пару байт в таблице. Включите кластер и сделайте выборку из таблицы. Что и почему произошло? как проигнорировать ошибку и продолжить работу?***
```bash
bench=# SELECT pg_relation_filepath('what');
 pg_relation_filepath
----------------------
 base/16384/16394
(1 row)

root@pg:~# pg_ctlcluster 15 main stop
root@pg:~# pg_ctlcluster 15 main start
root@pg:~# sudo -u postgres psql
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# \c bench
You are now connected to database "bench" as user "postgres".
bench=# select * from what;
WARNING:  page verification failed, calculated checksum 2580 but expected 9279
ERROR:  invalid page in block 0 of relation base/16384/16394

bench=# set ignore_checksum_failure = on; select * from what;
SET
WARNING:  page verification failed, calculated checksum 2580 but expected 9279
ERROR:  invalid page in block 0 of relation base/16384/16394
bench=# SELECT name, setting, context, short_desc FROM pg_settings WHERE name='ignore_checksum_failure';
          name           | setting |  context  |                   short_desc
-------------------------+---------+-----------+------------------------------------------------
 ignore_checksum_failure | on      | superuser | Continues processing after a checksum failure.
(1 row)

bench=# select * from what;
WARNING:  page verification failed, calculated checksum 2580 but expected 9279
ERROR:  invalid page in block 0 of relation base/16384/16394
```
>Пишут что этот параметр (ignore_checksum_failure) позволяет игнорировать ошибку checksum, но у меня ничего не поменялось.

```bash
bench=# VACUUM FULL VERBOSE ANALYZE what;
INFO:  vacuuming "public.what"
INFO:  "public.what": found 0 removable, 0 nonremovable row versions in 0 pages
DETAIL:  0 dead row versions cannot be removed yet.
CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s.
INFO:  analyzing "public.what"
INFO:  "what": scanned 0 of 0 pages, containing 0 live rows and 0 dead rows; 0 rows in sample, 0 estimated total rows
VACUUM
bench=# REINDEX table what;
REINDEX
bench=# select * from what;
 num | name
-----+------
(0 rows)
```
>После таких действи таблица стала доступна, но пустая.


✨Magic ✨