-- развернем ВМ postgres в GCE
```
gcloud beta compute --project=celtic-house-266612 instances create postgres --zone=us-central1-a --machine-type=e2-medium --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=933982307116-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --image-family=ubuntu-2004-lts --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-ssd --boot-disk-device-name=postgres --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
 
gcloud compute ssh postgres

sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-14
```
-- посмотрим, что кластер стартовал
```bash
pg_lsclusters

sudo -u postgres psql
```
-- Кто помнит? Как посмотреть конфигурационные файлы?
```sql
show hba_file;
show config_file;
```
-- database
-- system catalog
>SELECT oid, datname, datistemplate, datallowconn FROM pg_database;

-- size
>SELECT pg_size_pretty(pg_database_size('postgres'));

-- schema
>\dn

-- current schema
>SELECT current_schema();

-- view table
>\d pg_database

-- list of ALL namespaces
>SELECT * FROM pg_namespace;

-- seach path
>SHOW search_path;

-- SET search_path to .. - в рамках сессии
-- параметр можно установить и на уровне отдельной базы данных:
-- ALTER DATABASE otus SET search_path = public, special;
-- в рамках кластера в файле postgresql.conf
>\dt

-- интересное поведение и search_path
```
\d pg_database
CREATE TABLE pg_database (i int);
```
-- все равно видим pg_catalog.pg_database
>\d pg_database
-- чтобы получить доступ к толко что созданной таблице используем указание схемы
```
\d public.pg_database
SELECT * FROM pg_database limit 1;
```
-- в 1 схеме или разных?
```sql
CREATE TABLE t1(i int);
CREATE SCHEMA postgres;
CREATE TABLE t2(i int);

CREATE TABLE t1(i int);
\dt
\dt public.*
SET search_path TO public, "$user";
\dt

SET search_path TO public, "$user", pg_catalog;
\dt

create temp table t1(i int);
\dt

SET search_path TO public, "$user", pg_catalog, pg_temp;
\dt
```
-- можем переносить таблицу между схемами - при этом меняется только запись в pg_class, физически данные на месте
>ALTER TABLE t2 SET SCHEMA public;

-- relations
```sql
SELECT * FROM pg_class \gx

CREATE DATABASE logical;
\c logical
CREATE TABLE testL(i int);
SELECT 'testL'::regclass::oid;
```
-- look on filesystem
```sql
SELECT oid, datname FROM pg_database WHERE datname='logical';

sudo su
cd /var/lib/postgresql/14/main/base/16407
ls -l | grep 16408
```
-- adding some data
>INSERT INTO testL VALUES (1),(3),(5);

-- look on filesystem
```bash
ls -l | grep 16406  
exit
sudo -u postgres psql
```
-- create index on new table
```sql
CREATE index indexL on testL (i);
SELECT 'indexL'::regclass::oid;
```
-- look on filesystem
>ls -l | grep 16411

-- мы также можем посмотреть, что происходит внутри вызова системных команд
```bash
\set ECHO_HIDDEN on
\l
\d
\set ECHO_HIDDEN off
```
-- view
-- materialized view
```sql
create table sklad (id serial PRIMARY KEY, name text, kolvo int, price numeric(17,2));
create table sales(id serial PRIMARY KEY, kolvo int, summa numeric(17,2), fk_skladID int references sklad(id), salesDate date);

insert into sklad (id, name, price) values (1, 'Сливы', 100), (2, 'Яблоки', 120);
insert into sales(fk_skladID, kolvo) values (1, 10), (2, 5);

create view v_sales as 
	select s.*, sk.name 
	from sales as s
	join sklad sk
		on s.fk_skladID = sk.id;

select * from v_sales;

insert into sales(fk_skladID, kolvo) values (1, 5);

select * from v_sales;

create materialized view ms as select s.*, sk.name 
	from sales as s
	join sklad sk
		on s.fk_skladID = sk.id;

select * from ms;

insert into sales(fk_skladID, kolvo) values (1, 5);

select * from ms;
```
-- https://postgrespro.ru/docs/postgresql/14/sql-refreshmaterializedview
```sql
refresh materialized view ms;

select * from ms;

refresh materialized view CONCURRENTLY ms WITH DATA;

CREATE UNIQUE INDEX ui ON sklad(id);
refresh materialized view CONCURRENTLY ms WITH DATA;
DROP INDEX ui;
```
-- index unique on MAT VIEW!!!
```sql
CREATE UNIQUE INDEX ui ON ms(id);
refresh materialized view CONCURRENTLY ms WITH DATA;
```

-- foreign table
```sql
CREATE DATABASE testfdw;
\c testfdw
CREATE TABLE testf(i int);
INSERT INTO testf values (111), (222);
```
-- pass 123
```sql
\password

\c logical
create extension postgres_fdw;
CREATE SERVER myserver FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host 'localhost', dbname 'testfdw', port '5432');
CREATE USER MAPPING FOR postgres SERVER myserver OPTIONS (user 'postgres', password '123');
CREATE FOREIGN TABLE testf(i int) server myserver;
select * from testf;
```
-- также возможны джойны и тд

-- another extension dblink

-- Users
```sql
SELECT usename, usesuper FROM pg_catalog.pg_user;
\du

CREATE USER test;
SELECT * FROM pg_catalog.pg_user;
```
-- попробуем законнектиться
```sql
\c - test

ALTER USER test LOGIN;
\c - test
```
-- почему не подключились?
-- peer аутентификация через unix socket, а в unix нет пользователя тест
-- включим md5
>\password test

-- или
```sql
ALTER USER test PASSWORD 'otus$123';

sudo -u postgres psql -U test -h 127.0.0.1 -W -d postgres

exit

sudo -u postgres psql
CREATE TABLE testa(i int);
INSERT INTO testa values (333), (444);

CREATE TABLE testa2(i int);
INSERT INTO testa2 values (555), (6666);
```
-- выдадим группе PUBLIC права на эту таблицу
```sql
GRANT SELECT ON testa TO PUBLIC;
GRANT SELECT, UPDATE, INSERT ON testa TO test;
-- GRANT SELECT (col1), UPDATE (col1) ON testa TO test;

\dp testa
ALTER TABLE testa SET SCHEMA public;
ALTER TABLE testa2 SET SCHEMA public;

exit
sudo -u postgres psql -U test -h 127.0.0.1 -W -d postgres
\dt
select * from sklad;
select * from testa;
insert into testa values(777);
```
-- попробуем нового юзера создать из под test, postgres
```sql
CREATE USER test2 WITH PASSWORD 'otus$123' NOLOGIN;
sudo -u postgres psql -U test2 -h 127.0.0.1 -W -d postgres
```

# Логический уровень PostgreSQL.
___
1.[LDAP Authentication](https://www.postgresql.org/docs/14/auth-ldap.htm "LDAP Authentication")

2.[Аутентификация GSSAPI](https://postgrespro.ru/docs/postgresql/14/gssapi-auth "Аутентификация GSSAPI")

3.[Managing PostgreSQL users and roles](https://aws.amazon.com/ru/blogs/database/managing-postgresql-users-and-roles/ "Managing PostgreSQL users and roles")

4.[What is a ‘Role’ and how to Create one](https://severalnines.com/blog/postgresql-privileges-user-management-what-you-should-know/ "What is a ‘Role’ and how to Create one")

5.[PostgreS'L - Проверка подлинности LDAP на active Directory](https://techexpert.tips/ru/postgresql-ru/postgresl-%D0%BF%D1%80%D0%BE%D0%B2%D0%B5%D1%80%D0%BA%D0%B0-%D0%BF%D0%BE%D0%B4%D0%BB%D0%B8%D0%BD%D0%BD%D0%BE%D1%81%D1%82%D0%B8-ldap-%D0%BD%D0%B0-active-directory/ "PostgreS'L - Проверка подлинности LDAP на active Directory")

6.[TDS Foreign data wrapper](https://github.com/tds-fdw/tds_fdw "TDS Foreign data wrapper")

