1.***Создайте новый кластер с включенной контрольной суммой страниц. Создайте таблицу. Вставьте несколько значений.***
```sql
root@pg:~# sudo /usr/lib/postgresql/15/bin/pg_checksums  --enable -D /var/lib/postgresql/15/main/
Checksum operation completed
Files scanned:   1560
Blocks scanned:  10004
Files written:  1291
Blocks written: 10004
pg_checksums: syncing data directory
pg_checksums: updating control file
Checksums enabled in cluster
root@pg:~# pg_ctlcluster 15 main start
root@pg:~# sudo -u postgres psql
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# SHOW data_checksums;
 data_checksums
----------------
 on
(1 row)
bench=# select * from what;
 num | name
-----+-------
 202 | yurii
   1 | roman
 799 | petr
(3 rows)
```
2.***Выключите кластер. Измените пару байт в таблице. Включите кластер и сделайте выборку из таблицы. Что и почему произошло? как проигнорировать ошибку и продолжить работу?***
```bash
bench=# SELECT pg_relation_filepath('what');
 pg_relation_filepath
----------------------
 base/16388/16389
(1 row)

bench=#
\q
root@pg:~# pg_ctlcluster 15 main stop
root@pg:~# nano /var/lib/postgresql/15/main/base/16388/16389
root@pg:~# pg_ctlcluster 15 main start
root@pg:~# sudo -u postgres psql
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# \c bench
You are now connected to database "bench" as user "postgres".
bench=# select * from what;
WARNING:  page verification failed, calculated checksum 57771 but expected 46584
ERROR:  invalid page in block 0 of relation base/16388/16389
bench=# SET ignore_checksum_failure = on;
SET
bench=# select * from what;
WARNING:  page verification failed, calculated checksum 57771 but expected 46584
 num | name
-----+-------
 202 | yurii
   1 | roman
 799 | petr
(3 rows)
```
>В этот раз сработал. Попробовал ещё раз сделать так же как в прошлый раз, и снова не сработало.

>Единственное отличие в том что вносил изменения через WinSCP, подозреваю что какая то проблема с кодировкой при таком внесении изменений.