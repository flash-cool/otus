# MVCC, vacuum и autovacuum. 
_____

- Цели
  - запустить нагрузочный тест pgbench
  - настроить параметры autovacuum
  - проверить работу autovacuum
  
1.***Установить на него PostgreSQL 15 с дефолтными настройками***
```bash
root@pg:~# pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
postgres=# SELECT name, setting, context, short_desc FROM pg_settings WHERE name in ('max_connections', 'shared_buffers','effective_cache_size','maintenance_work_mem','checkpoint_completion_target','wal_buffers','default_statistics_target','random_page_cost','effective_io_concurrency','work_mem', 'min_wal_size', 'max_wal_size');
             name             | setting |  context   |                                        short_desc
------------------------------+---------+------------+------------------------------------------------------------------------------------------
 checkpoint_completion_target | 0.9     | sighup     | Time spent flushing dirty buffers during checkpoint, as fraction of checkpoint interval.
 default_statistics_target    | 100     | user       | Sets the default statistics target.
 effective_cache_size         | 524288  | user       | Sets the planner's assumption about the total size of the data caches.
 effective_io_concurrency     | 1       | user       | Number of simultaneous requests that can be handled efficiently by the disk subsystem.
 maintenance_work_mem         | 65536   | user       | Sets the maximum memory to be used for maintenance operations.
 max_connections              | 100     | postmaster | Sets the maximum number of concurrent connections.
 max_wal_size                 | 1024    | sighup     | Sets the WAL size that triggers a checkpoint.
 min_wal_size                 | 80      | sighup     | Sets the minimum size to shrink the WAL to.
 random_page_cost             | 4       | user       | Sets the planner's estimate of the cost of a nonsequentially fetched disk page.
 shared_buffers               | 16384   | postmaster | Sets the number of shared memory buffers used by the server.
 wal_buffers                  | 512     | postmaster | Sets the number of disk-page buffers in shared memory for WAL.
 work_mem                     | 4096    | user       | Sets the maximum memory to be used for query workspaces.
(12 rows)
```
2.***Создать БД для тестов: выполнить pgbench -i postgres***
```bash
postgres=# CREATE DATABASE bench;
CREATE DATABASE
postgres@pg:/root$ pgbench  -i bench
dropping old tables...
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.06 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 1.98 s (drop tables 0.02 s, create tables 0.03 s, client-side generate 1.16 s, vacuum 0.04 s, primary keys 0.73 s).
```
3.***Запустить pgbench -c8 -P 6 -T 60 -U postgres postgres***
```bash
postgres@pg:/root$ pgbench -c8 -P 6 -T 60 -U postgres bench
pgbench (15.5 (Debian 15.5-1.pgdg120+1))
starting vacuum...end.
progress: 6.0 s, 124.5 tps, lat 63.014 ms stddev 50.241, 0 failed
progress: 12.0 s, 143.3 tps, lat 56.244 ms stddev 37.474, 0 failed
progress: 18.0 s, 126.5 tps, lat 63.080 ms stddev 45.524, 0 failed
progress: 24.0 s, 151.8 tps, lat 52.733 ms stddev 44.033, 0 failed
progress: 30.0 s, 155.3 tps, lat 51.897 ms stddev 48.018, 0 failed
progress: 36.0 s, 166.0 tps, lat 47.984 ms stddev 39.267, 0 failed
progress: 42.0 s, 168.2 tps, lat 47.528 ms stddev 39.519, 0 failed
progress: 48.0 s, 182.5 tps, lat 43.802 ms stddev 42.904, 0 failed
progress: 54.0 s, 168.2 tps, lat 47.681 ms stddev 37.899, 0 failed
progress: 60.0 s, 182.5 tps, lat 43.898 ms stddev 34.187, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 9421
number of failed transactions: 0 (0.000%)
latency average = 50.978 ms
latency stddev = 42.276 ms
initial connection time = 13.596 ms
tps = 156.885863 (without initial connection time)
```
4.***Применить параметры настройки PostgreSQL из прикрепленного к материалам занятия файла***

>max_connections				Максимальное количество одновременных подключений

>shared_buffers					Устанавливает объем памяти, который сервер базы данных использует для буферов общей памяти.

>effective_cache_size			Оценка памяти, доступной для кэширования диска.

>maintenance_work_mem			Параметр памяти, используемый для задач обслуживания.

>checkpoint_completion_target	Это доля времени между контрольными точками для завершения контрольной точки.

>wal_buffers					WAL (журнал предзаписи) в буферы, а затем эти буферы сбрасываются на диск. Много одновременных подключений, то более высокое значение может повысить производительность.

>default_statistics_target		Устанавливает цель статистики по умолчанию для столбцов таблицы. Большие значения увеличивают время, необходимое для выполнения ANALYZE

>random_page_cost				Устанавливает оценку планировщиком стоимости страницы диска, извлекаемой непоследовательно. Важность затрат дискового ввода-вывода

>effective_io_concurrency		Устанавливает количество одновременных дисковых операций ввода-вывода, которые, как ожидает PostgreSQL , могут выполняться одновременно.

>work_mem						Эта настройка используется для сложной сортировки

>min_wal_size					Пока использование диска WAL остается ниже этого значения, старые файлы WAL всегда перерабатываются для будущего использования на контрольной точке, а не удаляются.

>max_wal_size					Максимальный размер, позволяющий увеличить WAL во время автоматических контрольных точек.

```bash
root@pg:~# pg_ctlcluster 15 main stop
root@pg:~# pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
root@pg:~# pg_ctlcluster 15 main start
root@pg:~# su postgres
postgres@pg:/root$ psql
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# SELECT name, setting, context, short_desc FROM pg_settings WHERE name in ('max_connections', 'shared_buffers','effective_cache_size','maintenance_work_mem','checkpoint_completion_target','wal_buffers','default_statistics_target','random_page_cost','effective_io_concurrency','work_mem', 'min_wal_size', 'max_wal_size');
             name             | setting |  context   |                                        short_desc
------------------------------+---------+------------+------------------------------------------------------------------------------------------
 checkpoint_completion_target | 0.9     | sighup     | Time spent flushing dirty buffers during checkpoint, as fraction of checkpoint interval.
 default_statistics_target    | 100     | user       | Sets the default statistics target.
 effective_cache_size         | 524288  | user       | Sets the planner's assumption about the total size of the data caches.
 effective_io_concurrency     | 1       | user       | Number of simultaneous requests that can be handled efficiently by the disk subsystem.
 maintenance_work_mem         | 65536   | user       | Sets the maximum memory to be used for maintenance operations.
 max_connections              | 40      | postmaster | Sets the maximum number of concurrent connections.
 max_wal_size                 | 16384   | sighup     | Sets the WAL size that triggers a checkpoint.
 min_wal_size                 | 4096    | sighup     | Sets the minimum size to shrink the WAL to.
 random_page_cost             | 4       | user       | Sets the planner's estimate of the cost of a nonsequentially fetched disk page.
 shared_buffers               | 131072  | postmaster | Sets the number of shared memory buffers used by the server.
 wal_buffers                  | 2048    | postmaster | Sets the number of disk-page buffers in shared memory for WAL.
 work_mem                     | 4096    | user       | Sets the maximum memory to be used for query workspaces.
(12 rows)
```
5.***Протестировать заново***
```bash
postgres@pg:/root$ pgbench -c8 -P 6 -T 60 -U postgres bench
pgbench (15.5 (Debian 15.5-1.pgdg120+1))
starting vacuum...end.
progress: 6.0 s, 155.0 tps, lat 51.359 ms stddev 43.113, 0 failed
progress: 12.0 s, 209.2 tps, lat 38.167 ms stddev 30.147, 0 failed
progress: 18.0 s, 231.7 tps, lat 34.578 ms stddev 24.921, 0 failed
progress: 24.0 s, 211.8 tps, lat 37.626 ms stddev 31.423, 0 failed
progress: 30.0 s, 160.0 tps, lat 50.173 ms stddev 47.065, 0 failed
progress: 36.0 s, 153.3 tps, lat 51.983 ms stddev 42.439, 0 failed
progress: 42.0 s, 169.5 tps, lat 47.294 ms stddev 36.160, 0 failed
progress: 48.0 s, 158.3 tps, lat 50.537 ms stddev 36.713, 0 failed
progress: 54.0 s, 177.8 tps, lat 44.844 ms stddev 34.511, 0 failed
progress: 60.0 s, 184.5 tps, lat 43.575 ms stddev 31.789, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 8
number of threads: 1
maximum number of tries: 1
duration: 60 s
number of transactions actually processed: 10875
number of failed transactions: 0 (0.000%)
latency average = 44.145 ms
latency stddev = 36.121 ms
initial connection time = 14.284 ms
tps = 181.127585 (without initial connection time)
```

>Увеличилось начальное время подключения

>уменьшился latency stddev

>Уменьшилась средняя задержка

>Обработал 10875 транзакций с пропускной способностью примерно 181

```
Обработал больше транзакций и уменьшились среднии задержки (Думаю связано с тем что увеличили объем памяти,
который сервер базы данных использует для буферов общей памяти и увеличили количество одновременных дисковых операций ввода-вывода)
```
6.***Создать таблицу с текстовым полем и заполнить случайными или сгенерированными данным в размере 1млн строк***
```sql
postgres=# create database otus;
CREATE DATABASE
postgres=# \c otus
otus=# create table what ( number_c int4, speed int4, track text);
CREATE TABLE
otus=# insert into what (number_c, speed, track) select i, random() * 100, 'leman' from generate_series(1,1000000) i;
INSERT 0 1000000
otus=# select count(*) from what;
  count
---------
 1000000
(1 row)

otus=# select * from what limit 3;
 number_c | speed | track
----------+-------+-------
        1 |    26 | leman
        2 |    21 | leman
        3 |    83 | leman
(3 rows)
```
7.***Посмотреть размер файла с таблицей***
```sql
otus=# SELECT pg_size_pretty(pg_TABLE_size('what'));
 pg_size_pretty
----------------
 42 MB
(1 row)
```
8.***5 раз обновить все строчки и добавить к каждой строчке любой символ***
```sql
otus=# UPDATE what
SET speed = speed * 1.05;
UPDATE 1000000
otus=# UPDATE what
SET speed = speed + 5;
UPDATE 1000000
otus=# UPDATE what
SET speed = speed + 10;
UPDATE 1000000
otus=# UPDATE what
SET speed = speed + 100;
UPDATE 1000000
otus=# UPDATE what
SET speed = speed - 65;
UPDATE 1000000
otus=#

```
9.***Посмотреть количество мертвых строчек в таблице и когда последний раз приходил автовакуум***
```sql
otus=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'what';
 relname | n_live_tup | n_dead_tup | ratio% |        last_autovacuum
---------+------------+------------+--------+-------------------------------
 what    |    1000000 |    1000185 |    100 | 2023-12-29 17:26:28.944415+07
(1 row)

```

>2023-12-29 17:26:28.944415+07

10.***Подождать некоторое время, проверяя, пришел ли автовакуум***
```sql
otus=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'what';
 relname | n_live_tup | n_dead_tup | ratio% |        last_autovacuum
---------+------------+------------+--------+-------------------------------
 what    |    1599830 |          0 |      0 | 2023-12-29 17:27:17.011966+07
(1 row)
```

>2023-12-29 17:27:17.011966+07

11.***5 раз обновить все строчки и добавить к каждой строчке любой символ***
```sql
otus=# UPDATE what
SET track = 'spb';
UPDATE 1000000
otus=# UPDATE what
SET track = 'lol';
UPDATE 1000000
otus=# UPDATE what
SET track = 'nn';
UPDATE 1000000
otus=# UPDATE what
SET track = 'my';
UPDATE 1000000
otus=# UPDATE what
SET track = track ||'new';
UPDATE 1000000
otus=# select * from what limit 2;
 number_c | speed | track
----------+-------+-------
      108 |   145 | mynew
      109 |    68 | mynew
(2 rows)
```
12.***Посмотреть размер файла с таблицей***
```sql
otus=# SELECT pg_size_pretty(pg_TABLE_size('what'));
 pg_size_pretty
----------------
 211 MB
(1 row)
```
13.***Отключить Автовакуум на конкретной таблице***
```sql
otus=# ALTER TABLE what SET (autovacuum_enabled = off);
ALTER TABLE
```
14.***10 раз обновить все строчки и добавить к каждой строчке любой символ***
```sql
otus=# UPDATE what SET track = track ||'a';
UPDATE 1000000
otus=# UPDATE what SET track = 'lol' || track;
UPDATE 1000000
otus=# UPDATE what SET speed = speed + 50;
UPDATE 1000000
otus=# UPDATE what SET speed = speed + 500;
UPDATE 1000000
otus=# UPDATE what SET speed = speed + 5000;
UPDATE 1000000
otus=# UPDATE what SET track = track ||'wal';
UPDATE 1000000
otus=# UPDATE what SET track = track ||'aw';
UPDATE 1000000
otus=# UPDATE what SET track =  'u' || track;
UPDATE 1000000
otus=# UPDATE what SET speed = speed - 134;
UPDATE 1000000
otus=# UPDATE what SET speed = speed - 7;
UPDATE 1000000
```
15.***Посмотреть размер файла с таблицей***
```sql
otus=# SELECT pg_size_pretty(pg_TABLE_size('what'));
 pg_size_pretty
----------------
 586 MB
(1 row)
```
16.***Объясните полученный результат. Не забудьте включить автовакуум***
```sql
otus=# SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'what';
 relname | n_live_tup | n_dead_tup | ratio% |        last_autovacuum
---------+------------+------------+--------+-------------------------------
 what    |    1000000 |    9996061 |    999 | 2023-12-29 17:40:17.274083+07
(1 row)
otus=# ALTER TABLE what SET (autovacuum_enabled = on);
ALTER TABLE
```
>Т.к. autovacuum был отключен при обновлении данных появилось почти 10 млн. мёртвых строк которые занимают место на диске.

17.***Задание со звездочкой не делал***