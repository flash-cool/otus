**Для установки 13 версии (без 12)**
**https://www.postgresql.org/download/linux/ubuntu/**
```bash
sudo apt update && sudo apt upgrade -y -q
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
```
**Установится 13 версия**
>sudo apt-get -y install postgresql`

**Если 13 поверх 12**
```bash
sudo apt update && sudo apt upgrade -y && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt-get -y install postgresql-13
```
**14 версия**
```bash
sudo apt update && sudo apt upgrade -y && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt-get -y install postgresql-14
```
**Установка Postgres 15**
```bash
sudo apt update && sudo apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-15
```
**Если будете экспериментировать с промежуточными версиями, не LTS**
**Корректно добавим к upgrade & install postgres**
>sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q
```bash
sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-14
```
**Посмотрим, что кластер стартовал**
>pg_lsclusters

**Посмотрим новый метод шифрования пароля**
>sudo cat /etc/postgresql/14/main/pg_hba.conf

**Cтарый**
>sudo cat /etc/postgresql/13/main/pg_hba.conf

**Удалим все**
>sudo pg_ctlcluster 12 main stop
>sudo pg_dropcluster 12 main

**Создадим 14 версии под пользователем postgres**
>sudo -u postgres pg_createcluster 14 main
>pg_lsclusters
>sudo pg_ctlcluster 14 main start
>sudo -u postgres psql
>sudo su postgres
>psql

**Создадим табличку для тестов**
**https://www.postgresql.org/docs/14/sql-set-transaction.html**
```bash
CREATE DATABASE iso;
\c iso
```
**Список БД**
```sql
\l
SELECT current_database();
CREATE TABLE test (i serial, amount int);
INSERT INTO test(amount) VALUES (100);
INSERT INTO test(amount) VALUES (500);
SELECT * FROM test;

\echo :AUTOCOMMIT
\set AUTOCOMMIT OFF
show transaction isolation level;
set transaction isolation level read committed;
set transaction isolation level repeatable read;
set transaction isolation level serializable;
SELECT txid_current();
\set AUTOCOMMIT ON
SELECT txid_current();
SELECT * FROM test;
commit;

SELECT * FROM pg_stat_activity;
```
**Глобально можно изменить**
  - ALTER DATABASE <db name> SET DEFAULT_TRANSACTION_ISOLATION TO 'read committed';
  - set the default_transaction_isolation parameter appropriately, 
  - either in postgresql.conf or with ALTER SYSTEM. After reloading, this will apply to the whole cluster.
  - You can also use ALTER DATABASE or ALTER ROLE to change the setting for a database or user only.


**test TRANSACTION ISOLATION LEVEL READ COMMITTED;**
**1 console**
```sql
BEGIN;
SELECT * FROM test;
```
**2 console**
>sudo -u postgres psql

```sql
\c iso
BEGIN;
UPDATE test set amount = 555 WHERE i = 1;
COMMIT;
```
**1 console**
```sql
SELECT * FROM test; -- different values
COMMIT;
```

**TRANSACTION ISOLATION LEVEL REPEATABLE READ;**
**1 console**
```sql
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT * FROM test;
 i | amount
---+--------
 2 |    500
 1 |    555
(2 rows)
```
**2 console**
```sql
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
INSERT INTO test VALUES (777);
COMMIT;
```
**1 console**
```sql
SELECT * FROM test;
 i | amount
---+--------
 2 |    500
 1 |    555
(2 rows)
```
**TRANSACTION ISOLATION LEVEL SERIALIZABLE;**
```sql
DROP TABLE IF EXISTS testS;
CREATE TABLE testS (i int, amount int);
INSERT INTO TESTS VALUES (1,10), (1,20), (2,100), (2,200); 
```
**1 console**
```sql
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT sum(amount) FROM testS WHERE i = 1;
INSERT INTO testS VALUES (2,30);
```
**2 consol**
```sql
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT sum(amount) FROM testS WHERE i = 2;
INSERT INTO testS VALUES (1,300);
```
**1 console**
>COMMIT;

**2 console**
>COMMIT;

**То же самое на RR**
**1 console**
```sql
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT sum(amount) FROM testS WHERE i = 1;
INSERT INTO testS VALUES (2,30);
```
**2 consol**
```sql
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT sum(amount) FROM testS WHERE i = 2;
INSERT INTO testS VALUES (1,300);
```
**1 console**
>COMMIT;

**2 console**
>COMMIT;


**Как выйти из psql Postgres до 10 версии?**
```bash
\q
exit
```

**Проблема с ключами**
```bash
sudo rm -rf /var/lib/apt/lists/*

cd /tmp
wget -c http://dl.google.com/linux/linux_signing_key.pub
sudo apt-key add linux_signing_key.pub

wget -c https://packages.microsoft.com/keys/microsoft.asc
sudo apt-key add microsoft.asc

wget -c https://www.postgresql.org/media/keys/ACCC4CF8.asc
sudo apt-key add ACCC4CF8.asc

sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 78BD65473CB3BD13
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EB3E94ADBE1229CF
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AB9660B9EB2CC88B
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7FCC7D46ACCC4CF8
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1E9377A2BA9EF27F

sudo apt-get update with optional sudo apt-get dist-upgrade
```

***Ссылки из второго занятия***
___
1.[Практическое владение языком SQL](https://sql-ex.ru/ "Практическое владение языком SQL")

2.[Simple SQL Queries](https://pgexercises.com/questions/basic/ "Simple SQL Queries")

3.[Что такое транзакция](https://habr.com/ru/articles/537594/ "Что такое транзакция")

4.[К чему может привести ослабление уровня изоляции транзакций в базах данных](https://habr.com/ru/companies/otus/articles/501294/ "К чему может привести ослабление уровня изоляции транзакций в базах данных")

5.[Уровни изоляции транзакций с примерами на PostgreSQL](https://habr.com/ru/articles/317884/ "Уровни изоляции транзакций с примерами на PostgreSQL")