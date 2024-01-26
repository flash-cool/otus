# Бэкапы 
_____

- Цели
  - применить логический бэкап. Восстановиться из бэкапа.
  
1.***Создаем ВМ/докер c ПГ***
```bash
root@pg:~# pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
2.***Создаем БД, схему и в ней таблицу. Заполним таблицы автосгенерированными 100 записями.***
```sql
postgres=# CREATE SCHEMA master;
CREATE SCHEMA
postgres=# create database home;
CREATE DATABASE
postgres=# \c home
You are now connected to database "home" as user "postgres".
home=# create table work as select generate_series(1, 100) as num, md5(random()::text)::char(10) as fio;
SELECT 100
home=# select * from work LIMIT 10;
 num |    fio
-----+------------
   1 | 27e1c13597
   2 | e561159e8b
   3 | de24fd5a22
   4 | 1fdf2c9d46
   5 | d29e47b27e
   6 | 20484387ff
   7 | 3752baac8d
   8 | 4096bff88e
   9 | bbcd9e934a
  10 | 14a2c8cd1a
(10 rows)

```
3.***Под линукс пользователем Postgres создадим каталог для бэкапов***
```bash
root@pg:~# mkdir /mnt/pgbackup
root@pg:~# chmod 777 -R /mnt/pgbackup
root@pg:~# ls -lah /mnt
total 12K
drwxr-xr-x  3 root root 4.0K Jan 26 02:06 .
drwxr-xr-x 18 root root 4.0K Jan 15 02:04 ..
drwxrwxrwx  2 root root 4.0K Jan 26 02:06 pgbackup
```
4.***Сделаем логический бэкап используя утилиту COPY***
```bash
postgres=# \c home
You are now connected to database "home" as user "postgres".
home=# \copy work to '/mnt/pgbackup/copy.sql';
COPY 100
home=#
\q
root@pg:~# cat /mnt/pgbackup/copy.sql
1       27e1c13597
2       e561159e8b
3       de24fd5a22
4       1fdf2c9d46
5       d29e47b27e
6       20484387ff
7       3752baac8d
8       4096bff88e

```
5.***Восстановим в 2 таблицу данные из бэкапа.***
```sql
postgres=# \c home
You are now connected to database "home" as user "postgres".
home=# create table copy(num int, fio text);
CREATE TABLE
home=# \copy copy from '/mnt/pgbackup/copy.sql';
COPY 100
home=# select * from work LIMIT 10;
 num |    fio
-----+------------
   1 | 27e1c13597
   2 | e561159e8b
   3 | de24fd5a22
   4 | 1fdf2c9d46
   5 | d29e47b27e
   6 | 20484387ff
   7 | 3752baac8d
   8 | 4096bff88e
   9 | bbcd9e934a
  10 | 14a2c8cd1a
(10 rows)

home=# select * from copy LIMIT 10;
 num |    fio
-----+------------
   1 | 27e1c13597
   2 | e561159e8b
   3 | de24fd5a22
   4 | 1fdf2c9d46
   5 | d29e47b27e
   6 | 20484387ff
   7 | 3752baac8d
   8 | 4096bff88e
   9 | bbcd9e934a
  10 | 14a2c8cd1a
(10 rows)
```
6.***Используя утилиту pg_dump создадим бэкап в кастомном сжатом формате двух таблиц***
```bash
root@pg:/mnt/pgbackup# sudo -u postgres pg_dump -d home --create | gzip > /mnt/pgbackup/backup.dump.gz
root@pg:/mnt/pgbackup# ls -lah /mnt/pgbackup/
total 16K
drwxrwxrwx 2 root     root     4.0K Jan 26 02:21 .
drwxr-xr-x 3 root     root     4.0K Jan 26 02:06 ..
-rw-r--r-- 1 root     root     1.6K Jan 26 02:21 backup.dump.gz
-rw-r--r-- 1 postgres postgres 1.4K Jan 26 02:08 copy.sql
```
7.***Используя утилиту pg_restore восстановим в новую БД только вторую таблицу!***
```bash
root@pg:/mnt/pgbackup# sudo -u postgres psql
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# create database back;
CREATE DATABASE
postgres=#
\q
root@pg:/mnt/pgbackup# sudo -u postgres pg_dump -d home --create | gzip > /mnt/pgbackup/backup.sql.gz
root@pg:/mnt/pgbackup# gunzip backup.sql.gz
root@pg:/mnt/pgbackup# sudo -u postgres pg_restore -t copy -d back /mnt/pgbackup/backup.sql
pg_restore: error: input file appears to be a text format dump. Please use psql.
root@pg:/mnt/pgbackup# rm -rf /mnt/pgbackup/backup*
root@pg:/mnt/pgbackup# sudo -u postgres pg_dump -d home --create -Fc | gzip > /mnt/pgbackup/backup.sql.gz
root@pg:/mnt/pgbackup# gunzip backup.sql.gz
root@pg:/mnt/pgbackup# sudo -u postgres pg_restore -t copy -d back /mnt/pgbackup/backup.sql
root@pg:/mnt/pgbackup# sudo -u postgres psql
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# \c back
You are now connected to database "back" as user "postgres".
back=# \dt
        List of relations
 Schema | Name | Type  |  Owner
--------+------+-------+----------
 public | copy | table | postgres
(1 row)

back=# select * from copy LIMIT 10;
 num |    fio
-----+------------
   1 | 27e1c13597
   2 | e561159e8b
   3 | de24fd5a22
   4 | 1fdf2c9d46
   5 | d29e47b27e
   6 | 20484387ff
   7 | 3752baac8d
   8 | 4096bff88e
   9 | bbcd9e934a
  10 | 14a2c8cd1a
(10 rows)
```
>Не указал параметры для восстановления с помощью pg_restore, просил использовать psql. После указания параметров всё получилось.

✨Magic ✨