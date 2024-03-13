-- посмотрим виртуальный id транзакции
```sql
SELECT txid_current();
CREATE TABLE test(i int);
INSERT INTO test VALUES (10),(20),(30);

SELECT i, xmin,xmax,cmin,cmax,ctid FROM test;
```
-- посмотрим мертвые туплы
```sql
SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'test';

update test set i = 100 where i = 10;


CREATE EXTENSION pageinspect;
\dx+
SELECT lp as tuple, t_xmin, t_xmax, t_field3 as t_cid, t_ctid FROM heap_page_items(get_raw_page('test',0));
SELECT * FROM heap_page_items(get_raw_page('test',0)) \gx
```
-- попробуем изменить данные и откатить транзакцию и посмотреть
```sql
\echo :AUTOCOMMIT
\set AUTOCOMMIT OFF
commit;

insert into test values(50),(60),(70);

select * from test;

rollback;
commit;
```
-- vacuum
```sql
vacuum verbose test;
SELECT lp as tuple, t_xmin, t_xmax, t_field3 as t_cid, t_ctid FROM heap_page_items(get_raw_page('test',0));
SELECT pg_relation_filepath('test');
vacuum full test;
SELECT pg_relation_filepath('test');

SELECT relname, n_live_tup, n_dead_tup, trunc(100*n_dead_tup/(n_live_tup+1))::float "ratio%", last_autovacuum FROM pg_stat_user_TABLEs WHERE relname = 'test';

SELECT name, setting, context, short_desc FROM pg_settings WHERE name in ('max_connections', 'shared_buffers','effective_cache_size','maintenance_work_mem','checkpoint_completion_target','wal_buffers','default_statistics_target','random_page_cost','effective_io_concurrency','work_mem', 'min_wal_size', 'max_wal_size');
```
-- Autovacuum
```sql
SELECT name, setting, context, short_desc FROM pg_settings WHERE name like 'autovacuum%';

SELECT * FROM pg_stat_activity WHERE query ~ 'autovacuum'  q\gx

select c.relname,
current_setting('autovacuum_vacuum_threshold') as av_base_thresh,
current_setting('autovacuum_vacuum_scale_factor') as av_scale_factor,
(current_setting('autovacuum_vacuum_threshold')::int +
(current_setting('autovacuum_vacuum_scale_factor')::float * c.reltuples)) as av_thresh,
s.n_dead_tup
from pg_stat_user_tables s join pg_class c ON s.relname = c.relname
where s.n_dead_tup > (current_setting('autovacuum_vacuum_threshold')::int
+ (current_setting('autovacuum_vacuum_scale_factor')::float * c.reltuples));


CREATE TABLE student(
  id serial,
  fio char(100)
) WITH (autovacuum_enabled = off);

CREATE INDEX idx_fio ON student(fio);

INSERT INTO student(fio) SELECT 'noname' FROM generate_series(1,500000);

SELECT pg_size_pretty(pg_TABLE_size('student'));

SELECT pg_size_pretty(pg_relation_size('student','vm'));

update student set fio = 'name';

ALTER TABLE student SET (autovacuum_enabled = on);


SELECT pg_size_pretty(pg_TABLE_size('student'));
```
-- уровни изоляции транзакций
-- создадим табличку для тестов
```sql
CREATE TABLE test2 (i serial, amount int);
INSERT INTO test2(amount) VALUES (100),(500);
SELECT * FROM test2;

show transaction isolation level;

\set AUTOCOMMIT OFF
```
-- TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- 1 console
```sql
begin;
SELECT * FROM test2;
```
-- 2 consoleapp=#
```sql
begin;
UPDATE test2 set amount = 555 WHERE i = 1;
SELECT * FROM test2;
commit;
```
-- TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- 1 console
```sql
begin;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SHOW TRANSACTION ISOLATION LEVEL;
```
-- 2 console
```sql
begin;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
INSERT INTO test2(amount) VALUES (777);
SELECT * FROM test2;
COMMIT;
```
-- 1 console
```sql
SELECT * FROM test2;
COMMIT;
SELECT * FROM test2;
```
-- TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- 1 console
```sql
DROP TABLE IF EXISTS testS;
CREATE TABLE testS (i int, amount int);
INSERT INTO testS VALUES (1,10), (1,20), (2,100), (2,200); 


BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT sum(amount) FROM testS WHERE i = 1;
INSERT INTO testS VALUES (2,30);
```
-- 2 consol
```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT sum(amount) FROM testS WHERE i = 2;
INSERT INTO testS VALUES (1,300);
SELECT * FROM testS; 
```
-- 1 console
>COMMIT;

-- 2 console 
>COMMIT;

>DROP TABLE IF EXISTS testS;

```sql
create table what ( number_c int4, speed int4, track text);
insert into whatever (time_c, speed) select i, random() * 100 from generate_series(1,10) i;


UPDATE what SET speed = speed * 1.05;

UPDATE what SET track = track ||'a';

UPDATE `table_name` SET `field` = `field` + 1

CREATE PROCEDURE upspeed10 ()
DECLARE
i integer := 1000;
  BEGIN
   WHILE i>0 DO
     UPDATE what SET speed = speed + i;
     SET i=i-100;
   END WHILE;
  end
```

# MVCC, vacuum и autovacuum.
___
1.[Давайте отключим vacuum?! Алексей Лесовский](https://habr.com/ru/articles/501516/ "Давайте отключим vacuum?! Алексей Лесовский")

2.[PostgreSQL Vacuuming Command to Optimize Database Performance](https://www.percona.com/blog/postgresql-vacuuming-to-optimize-database-performance-and-reclaim-space/ "PostgreSQL Vacuuming Command to Optimize Database Performance")