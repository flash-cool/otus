# Блокировки 
_____

- Цели
  - понимать как работает механизм блокировок объектов и строк.
  
1.***Настройте сервер так, чтобы в журнал сообщений сбрасывалась информация о блокировках, удерживаемых более 200 миллисекунд.***
```sql
postgres=# SELECT name, setting, context, short_desc FROM pg_settings WHERE name in ('log_lock_waits', 'deadlock_timeout');
       name       | setting |  context  |                          short_desc
------------------+---------+-----------+---------------------------------------------------------------
 deadlock_timeout | 200     | superuser | Sets the time to wait on a lock before checking for deadlock.
 log_lock_waits   | on      | superuser | Logs long lock waits.
(2 rows)
```
2.***Воспроизведите ситуацию, при которой в журнале появятся такие сообщения.***
```sql
-- Session #1
bench=# BEGIN;
BEGIN
bench=*# LOCK TABLE what;
LOCK TABLE

-- Session #2
bench=# begin;
BEGIN
bench=*# select * from what;

-- Session #1
bench=*# SELECT locktype, mode, granted, pid, pg_blocking_pids(pid) AS wait_for
FROM pg_locks WHERE relation = 'what'::regclass;
 locktype |        mode         | granted |  pid  | wait_for
----------+---------------------+---------+-------+----------
 relation | AccessShareLock     | f       | 28775 | {28664}
 relation | AccessExclusiveLock | t       | 28664 | {}
(2 rows)

bench=*# commit;
COMMIT

-- Session #2

 num | name
-----+-------
   1 | petr
   2 | yurii
(2 rows)

bench=*# commit;
COMMIT
```
>В журнале появилось следующая запись

```
2024-01-19 02:03:57.531 AKST [28775] postgres@bench LOG:  process 28775 still waiting for AccessShareLock on relation 16389 of database 16388 after 200.155 ms at character 15
2024-01-19 02:03:57.531 AKST [28775] postgres@bench DETAIL:  Process holding the lock: 28664. Wait queue: 28775.
2024-01-19 02:03:57.531 AKST [28775] postgres@bench STATEMENT:  select * from what;
2024-01-19 02:04:56.765 AKST [28775] postgres@bench LOG:  process 28775 acquired AccessShareLock on relation 16389 of database 16388 after 59433.447 ms at character 15
2024-01-19 02:04:56.765 AKST [28775] postgres@bench STATEMENT:  select * from what
```

3.***Смоделируйте ситуацию обновления одной и той же строки тремя командами UPDATE в разных сеансах.***
```sql
-- Session #1
bench=# BEGIN;
BEGIN
bench=*# UPDATE what SET num = num + 100 WHERE name = 'petr';
UPDATE 1
bench=*#

-- Session #2
bench=# begin;
BEGIN
bench=*# UPDATE what SET num = num + 200 WHERE name = 'petr';

-- Session #3
bench=# begin;
BEGIN
bench=*# UPDATE what SET num = num + 300 WHERE name = 'petr';
```
4.***Изучите возникшие блокировки в представлении pg_locks и убедитесь, что все они понятны.***
```sql
bench=*# SELECT locktype, relation::REGCLASS, mode, granted, pid, pg_blocking_pids(pid) AS wait_for
FROM pg_locks WHERE relation = 'what'::regclass order by pid;
 locktype | relation |       mode       | granted |  pid  | wait_for
----------+----------+------------------+---------+-------+----------
 relation | what     | RowExclusiveLock | t       | 28664 | {}
 relation | what     | RowExclusiveLock | t       | 28775 | {28664}
 tuple    | what     | ExclusiveLock    | t       | 28775 | {28664}
 relation | what     | RowExclusiveLock | t       | 29021 | {28775}
 tuple    | what     | ExclusiveLock    | f       | 29021 | {28775}
(5 rows)

bench=*#

```
5.***Пришлите список блокировок и объясните, что значит каждая.***
```
-- #relation | what     | RowExclusiveLock | t       | 28664 | {}
Блокировка строки при update

-- #relation | what     | RowExclusiveLock | t       | 28775 | {28664}
Это из второй консоли, ждёт окончания update из первой консоли
Блокировка строки при update

-- #tuple    | what     | ExclusiveLock    | t       | 28775 | {28664}
Это из второй консоли, ждёт окончания update из первой консоли
Исключительная блокировка на версию строки

-- #relation | what     | RowExclusiveLock | t       | 29021 | {28775}
Это из третьей консоли, ждёт окончания update из второй консоли
Блокировка строки при update

-- #tuple    | what     | ExclusiveLock    | f       | 29021 | {28775}
Это из третьей консоли, ждёт окончания update из второй консоли
Исключительная блокировка на версию строки

```
6.***Воспроизведите взаимоблокировку трех транзакций.***
```sql
-- Session #1
bench=# begin;
BEGIN
bench=*# UPDATE what SET num = num + 100 WHERE name = 'yurii';
UPDATE 1

-- Session #2
bench=# begin;
BEGIN
bench=*# UPDATE what SET num = num + 100 WHERE name = 'petr';
UPDATE 1

-- Session #3
bench=*# UPDATE what SET num = num + 100 WHERE name = 'roman';
UPDATE 1

-- Session #1
bench=*# UPDATE what SET num = num - 1 WHERE name = 'petr';
UPDATE 1

-- Session #2
bench=*# UPDATE what SET num = num - 1 WHERE name = 'roman';
UPDATE 1

-- Session #3
bench=*# UPDATE what SET num = num - 1 WHERE name = 'yurii';
ERROR:  deadlock detected
DETAIL:  Process 29398 waits for ShareLock on transaction 747; blocked by process 29386.
Process 29386 waits for ShareLock on transaction 748; blocked by process 29397.
Process 29397 waits for ShareLock on transaction 749; blocked by process 29398.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (0,7) in relation "what"
```
7.***Можно ли разобраться в ситуации постфактум, изучая журнал сообщений?***
>В принцыпе да, по логам понятно что происходило.

```
2024-01-19 04:07:32.652 AKST [29386] postgres@bench LOG:  process 29386 still waiting for ShareLock on transaction 748 after 200.163 ms
2024-01-19 04:07:32.652 AKST [29386] postgres@bench DETAIL:  Process holding the lock: 29397. Wait queue: 29386.
2024-01-19 04:07:32.652 AKST [29386] postgres@bench CONTEXT:  while updating tuple (0,11) in relation "what"
2024-01-19 04:07:32.652 AKST [29386] postgres@bench STATEMENT:  UPDATE what SET num = num - 1 WHERE name = 'petr';
2024-01-19 04:07:39.694 AKST [29397] postgres@bench LOG:  process 29397 still waiting for ShareLock on transaction 749 after 200.153 ms
2024-01-19 04:07:39.694 AKST [29397] postgres@bench DETAIL:  Process holding the lock: 29398. Wait queue: 29397.
2024-01-19 04:07:39.694 AKST [29397] postgres@bench CONTEXT:  while updating tuple (0,10) in relation "what"
2024-01-19 04:07:39.694 AKST [29397] postgres@bench STATEMENT:  UPDATE what SET num = num - 1 WHERE name = 'roman';
2024-01-19 04:07:45.044 AKST [29398] postgres@bench LOG:  process 29398 detected deadlock while waiting for ShareLock on transaction 747 after 200.158 ms
2024-01-19 04:07:45.044 AKST [29398] postgres@bench DETAIL:  Process holding the lock: 29386. Wait queue: .
2024-01-19 04:07:45.044 AKST [29398] postgres@bench CONTEXT:  while updating tuple (0,7) in relation "what"
2024-01-19 04:07:45.044 AKST [29398] postgres@bench STATEMENT:  UPDATE what SET num = num - 1 WHERE name = 'yurii';
2024-01-19 04:07:45.044 AKST [29398] postgres@bench ERROR:  deadlock detected
2024-01-19 04:07:45.044 AKST [29398] postgres@bench DETAIL:  Process 29398 waits for ShareLock on transaction 747; blocked by process 29386.
	Process 29386 waits for ShareLock on transaction 748; blocked by process 29397.
	Process 29397 waits for ShareLock on transaction 749; blocked by process 29398.
	Process 29398: UPDATE what SET num = num - 1 WHERE name = 'yurii';
	Process 29386: UPDATE what SET num = num - 1 WHERE name = 'petr';
	Process 29397: UPDATE what SET num = num - 1 WHERE name = 'roman';
2024-01-19 04:07:45.044 AKST [29398] postgres@bench HINT:  See server log for query details.
2024-01-19 04:07:45.044 AKST [29398] postgres@bench CONTEXT:  while updating tuple (0,7) in relation "what"
2024-01-19 04:07:45.044 AKST [29398] postgres@bench STATEMENT:  UPDATE what SET num = num - 1 WHERE name = 'yurii';
2024-01-19 04:07:45.044 AKST [29397] postgres@bench LOG:  process 29397 acquired ShareLock on transaction 749 after 5549.566 ms
2024-01-19 04:07:45.044 AKST [29397] postgres@bench CONTEXT:  while updating tuple (0,10) in relation "what"
2024-01-19 04:07:45.044 AKST [29397] postgres@bench STATEMENT:  UPDATE what SET num = num - 1 WHERE name = 'roman';

```
8.***Могут ли две транзакции, выполняющие единственную команду UPDATE одной и той же таблицы (без where), заблокировать друг друга?***

:heavy_exclamation_mark:`Не знаю как.`

>Попытка сделать

```sql
-- 1 console. Стар транзакции
postgres=# BEGIN;
BEGIN

postgres=*# UPDATE what SET name = roman;
UPDATE 3

-- 2 console. Стар транзакции
postgres=# BEGIN;
BEGIN

postgres=*# UPDATE what SET name = lol;


-- 1 console. Коммит
postgres=*# COMMIT;
COMMIT

-- 2 console. Пошла дальше. Коммит
UPDATE 3

postgres=*# COMMIT;
COMMIT

-- Смотрим таблицу what
postgres=# SELECT * FROM what;
 num | name
-----+-------
   1 | lol
   2 | lol
(3 rows)
```

white_check_mark:`Значит да.`

✨Magic ✨