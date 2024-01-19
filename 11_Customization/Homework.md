# Нагрузочное тестирование и тюнинг PostgreSQL 
_____

- Цели
  - сделать нагрузочное тестирование PostgreSQL
  - настроить параметры PostgreSQL для достижения максимальной производительности
  
1.***Поставить PostgreSQL 15 любым способом***
```bash
root@pg:~# pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
root@pg:~# sudo -u postgres pgbench -i bench
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data (client-side)...
100000 of 100000 tuples (100%) done (elapsed 0.07 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done in 0.19 s (drop tables 0.00 s, create tables 0.02 s, client-side generate 0.10 s, vacuum 0.03 s, primary keys 0.04 s).
root@pg:~# sudo -u postgres psql
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# \c bench
You are now connected to database "bench" as user "postgres".
bench=# \dt
              List of relations
 Schema |       Name       | Type  |  Owner
--------+------------------+-------+----------
 public | pgbench_accounts | table | postgres
 public | pgbench_branches | table | postgres
 public | pgbench_history  | table | postgres
 public | pgbench_tellers  | table | postgres
 public | what             | table | postgres
(5 rows)
```
>Параметры виртуальной машины

```
cores: 2
memory: 8192
scsi0: M2:3003/vm-3003-disk-0.qcow2,discard=on,iothread=1,size=50G
```
2.***Настроить кластер PostgreSQL 15 на максимальную производительность, показать какие параметры в какие значения устанавливали и почему***
```
--Уменьшил количество подключений, чем меньше тем проще работать серверу.
max_connections = 20
--Увеличил до 70% от оперативной памяти что бы всё выполнялось в ней.
shared_buffers = 6GB
--Предоставляет оценку памяти, доступной для кэширования диска.
effective_cache_size = 6GB
--Параметр памяти, используемый для задач обслуживания.
maintenance_work_mem = 512MB
--Как часто делается контрольная точка. Слишком большое может привезти к потерям данных.
checkpoint_timeout = '15 min'
--Это доля времени между контрольными точками
checkpoint_completion_target = 0.9
--Сначала записывает записи в буферы. Если много одновременных подключений, повышает производительность.
wal_buffers = 32MB
--Как часто собирает статистику.
default_statistics_target = 100
--Говорим PG что у нас SSD, построении плана запроса.
random_page_cost = 1.1
--Допустимое число параллельных операций ввода/вывода. Чем больше это число, тем больше операций ввода/вывода
effective_io_concurrency = 200
--Настройка используется для сложной сортировки.
work_mem = 52428kB
--Отключена авто поднастройка БД
huge_pages = off
--Минимальный объём журнала. Из-за большого размера checkpoint должны делаться по времени (не будет принудительный).
min_wal_size = 2GB
--Максимальный объём журнала.  Из-за большого размера checkpoint должны делаться по времени (не будет принудительный).
max_wal_size = 8GB
--Увеличивает производительность, транзакция фиксируется очень быстро, потому что она не будет ожидать сброса файла WAL
synchronous_commit = off
```
3.***Нагрузить кластер через утилиту через утилиту pgbench***
```bash
--До тюнинга PG

postgres=# SELECT name, setting, context, short_desc FROM pg_settings WHERE name in ('max_connections', 'shared_buffers','effective_cache_size','maintenance_work_mem','checkpoint_timeout','checkpoint_completion_target','wal_buffers','default_statistics_target','random_page_cost','effective_io_concurrency','work_mem','huge_pages','min_wal_size','max_wal_size','synchronous_commit');
             name             | setting |  context   |                                        short_desc
------------------------------+---------+------------+------------------------------------------------------------------------------------------
 checkpoint_completion_target | 0.9     | sighup     | Time spent flushing dirty buffers during checkpoint, as fraction of checkpoint interval.
 checkpoint_timeout           | 300     | sighup     | Sets the maximum time between automatic WAL checkpoints.
 default_statistics_target    | 100     | user       | Sets the default statistics target.
 effective_cache_size         | 524288  | user       | Sets the planner's assumption about the total size of the data caches.
 effective_io_concurrency     | 1       | user       | Number of simultaneous requests that can be handled efficiently by the disk subsystem.
 huge_pages                   | try     | postmaster | Use of huge pages on Linux or Windows.
 maintenance_work_mem         | 65536   | user       | Sets the maximum memory to be used for maintenance operations.
 max_connections              | 100     | postmaster | Sets the maximum number of concurrent connections.
 max_wal_size                 | 1024    | sighup     | Sets the WAL size that triggers a checkpoint.
 min_wal_size                 | 80      | sighup     | Sets the minimum size to shrink the WAL to.
 random_page_cost             | 4       | user       | Sets the planner's estimate of the cost of a nonsequentially fetched disk page.
 shared_buffers               | 16384   | postmaster | Sets the number of shared memory buffers used by the server.
 synchronous_commit           | on      | user       | Sets the current transaction's synchronization level.
 wal_buffers                  | 512     | postmaster | Sets the number of disk-page buffers in shared memory for WAL.
 work_mem                     | 4096    | user       | Sets the maximum memory to be used for query workspaces.
(15 rows)
postgres@pg:/root$ pgbench -c 18 -j 2 -P 10 -T 120 -U postgres bench
pgbench (15.5 (Debian 15.5-1.pgdg120+1))
starting vacuum...end.
progress: 10.0 s, 601.0 tps, lat 29.849 ms stddev 23.613, 0 failed
progress: 20.0 s, 766.3 tps, lat 23.486 ms stddev 14.328, 0 failed
progress: 30.0 s, 770.3 tps, lat 23.371 ms stddev 14.844, 0 failed
progress: 40.0 s, 702.7 tps, lat 25.612 ms stddev 15.777, 0 failed
progress: 50.0 s, 704.4 tps, lat 25.552 ms stddev 15.748, 0 failed
progress: 60.0 s, 686.7 tps, lat 26.215 ms stddev 15.477, 0 failed
progress: 70.0 s, 687.5 tps, lat 26.188 ms stddev 15.267, 0 failed
progress: 80.0 s, 685.3 tps, lat 26.250 ms stddev 15.633, 0 failed
progress: 90.0 s, 683.8 tps, lat 26.324 ms stddev 16.783, 0 failed
progress: 100.0 s, 682.8 tps, lat 26.364 ms stddev 16.195, 0 failed
progress: 110.0 s, 683.3 tps, lat 26.355 ms stddev 15.928, 0 failed
progress: 120.0 s, 688.4 tps, lat 26.142 ms stddev 15.655, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 18
number of threads: 2
maximum number of tries: 1
duration: 120 s
number of transactions actually processed: 83443
number of failed transactions: 0 (0.000%)
latency average = 25.884 ms
latency stddev = 16.375 ms
initial connection time = 17.240 ms
tps = 695.299685 (without initial connection time)
```
>Обработал 83443 транзакций с пропускной способностью примерно 695

```bash
--После тюнинга PG

postgres=# SELECT name, setting, context, short_desc FROM pg_settings WHERE name in ('max_connections', 'shared_buffers','effective_cache_size','maintenance_work_mem','checkpoint_timeout','checkpoint_completion_target','wal_buffers','default_statistics_target','random_page_cost','effective_io_concurrency','work_mem','huge_pages','min_wal_size','max_wal_size','synchronous_commit');
             name             | setting |  context   |                                        short_desc
------------------------------+---------+------------+------------------------------------------------------------------------------------------
 checkpoint_completion_target | 0.9     | sighup     | Time spent flushing dirty buffers during checkpoint, as fraction of checkpoint interval.
 checkpoint_timeout           | 900     | sighup     | Sets the maximum time between automatic WAL checkpoints.
 default_statistics_target    | 100     | user       | Sets the default statistics target.
 effective_cache_size         | 786432  | user       | Sets the planner's assumption about the total size of the data caches.
 effective_io_concurrency     | 200     | user       | Number of simultaneous requests that can be handled efficiently by the disk subsystem.
 huge_pages                   | off     | postmaster | Use of huge pages on Linux or Windows.
 maintenance_work_mem         | 524288  | user       | Sets the maximum memory to be used for maintenance operations.
 max_connections              | 20      | postmaster | Sets the maximum number of concurrent connections.
 max_wal_size                 | 8192    | sighup     | Sets the WAL size that triggers a checkpoint.
 min_wal_size                 | 2048    | sighup     | Sets the minimum size to shrink the WAL to.
 random_page_cost             | 1.1     | user       | Sets the planner's estimate of the cost of a nonsequentially fetched disk page.
 shared_buffers               | 786432  | postmaster | Sets the number of shared memory buffers used by the server.
 synchronous_commit           | off     | user       | Sets the current transaction's synchronization level.
 wal_buffers                  | 2048    | postmaster | Sets the number of disk-page buffers in shared memory for WAL.
 work_mem                     | 52428   | user       | Sets the maximum memory to be used for query workspaces.
(15 rows)
postgres@pg:/root$ pgbench -c 18 -j 2 -P 10 -T 120 -U postgres bench
pgbench (15.5 (Debian 15.5-1.pgdg120+1))
starting vacuum...end.
progress: 10.0 s, 4236.0 tps, lat 4.239 ms stddev 2.880, 0 failed
progress: 20.0 s, 4203.9 tps, lat 4.282 ms stddev 2.570, 0 failed
progress: 30.0 s, 4215.9 tps, lat 4.269 ms stddev 2.517, 0 failed
progress: 40.0 s, 4237.7 tps, lat 4.247 ms stddev 2.529, 0 failed
progress: 50.0 s, 4237.9 tps, lat 4.247 ms stddev 2.494, 0 failed
progress: 60.0 s, 4222.0 tps, lat 4.263 ms stddev 2.759, 0 failed
progress: 70.0 s, 4232.2 tps, lat 4.253 ms stddev 2.648, 0 failed
progress: 80.0 s, 4234.0 tps, lat 4.251 ms stddev 2.955, 0 failed
progress: 90.0 s, 4213.8 tps, lat 4.272 ms stddev 2.742, 0 failed
progress: 100.0 s, 4214.5 tps, lat 4.270 ms stddev 3.045, 0 failed
progress: 110.0 s, 4230.0 tps, lat 4.255 ms stddev 2.718, 0 failed
progress: 120.0 s, 4249.0 tps, lat 4.236 ms stddev 2.787, 0 failed
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 18
number of threads: 2
maximum number of tries: 1
duration: 120 s
number of transactions actually processed: 507286
number of failed transactions: 0 (0.000%)
latency average = 4.257 ms
latency stddev = 2.726 ms
initial connection time = 19.033 ms
tps = 4227.402004 (without initial connection time)
```
>Обработал 507286 транзакций с пропускной способностью примерно 4227

4.***Написать какого значения tps удалось достичь***
>Пропускной способностью примерно увеличилась почти в 5 раз до 4227 транзакций в секунду

9.***Задание со *: аналогично протестировать через утилиту https://github.com/Percona-Lab/sysbench-tpcc ***
```

```
>

:heavy_exclamation_mark:
:white_check_mark:

✨Magic ✨

