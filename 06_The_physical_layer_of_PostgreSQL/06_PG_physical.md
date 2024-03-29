-- развернем ВМ postgres в GCE
```
gcloud beta compute --project=celtic-house-266612 instances create postgres --zone=us-central1-a --machine-type=e2-medium --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE 
--service-account=933982307116-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --image=ubuntu-2104-hirsute-v20210928 --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-ssd --boot-disk-device-name=postgres --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
 
gcloud compute ssh postgres
``` 
-- установим 14 версию
-- https://www.postgresql.org/download/linux/ubuntu/
```bash
sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && 
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt -y install postgresql-14
```
-- посмотрим, что кластер стартовал
>pg_lsclusters

-- посмотрим файлы
```bash
sudo su postgres
cd /var/lib/postgresql/14/main
ls -l

sudo -u postgres psql

sudo su postgres
psql
```
-- Как посмотреть конфигурационные файлы?
```sql
show hba_file;
show config_file;
show data_directory;
```
-- Все параметры (как думаете сколько у нас параметров для настроек?:):
```sql
# show all;
-- context
-- postmaster - перезапуск инстанса
-- sighup - во время работы
# SELECT name, setting, context, short_desc FROM pg_settings;
```
```bash
ss -tlpn
netstat -a | grep postgresql
```
-- open access
```sql
# show listen_addresses;
# ALTER SYSTEM SET listen_addresses = '10.128.0.54'; -- создает в /var/lib/postgresql postgresql.auto.conf с параметрами
```
-- uncomment listen_addresses = '*'
>sudo nano /etc/postgresql/14/main/postgresql.conf

-- host    all             all             0.0.0.0/0               md5/scram-sha-256
>sudo nano /etc/postgresql/14/main/pg_hba.conf

-- change password
>ALTER USER postgres PASSWORD 'otus$123';

-- restart server
>sudo pg_ctlcluster 14 main restart

-- try access
>psql -h 34.134.57.202 -U postgres -W


-- Расширенный вывод информации - вертикальный вывод колонок
```sql
SELECT * FROM pg_stat_activity;
\x
SELECT * FROM pg_stat_activity;
\x

SELECT * FROM pg_stat_activity \gx

select * from pg_stat_activity \g | less
```
```bash
\set ECHO_HIDDEN on
\l
\set ECHO_HIDDEN off


sudo su postgres
cat $HOME/.psql_history
``` 

-- Поподробнее из psql:
```sql
# SELECT pg_backend_pid();
# SELECT inet_client_addr();
# SELECT inet_client_port();
# SELECT inet_server_addr();
# SELECT inet_server_port();
# SELECT datid, datname, pid, usename, application_name, client_addr, backend_xid FROM pg_stat_activity;
```
-- табличное пространство практика
```bash
sudo mkdir /home/postgres
sudo chown postgres /home/postgres
sudo su postgres
cd /home/postgres
mkdir tmptblspc

CREATE TABLESPACE ts location '/home/postgres/tmptblspc';
\db
CREATE DATABASE app TABLESPACE ts;
\c app
\l+ -- посмотреть дефолтный tablespace
CREATE TABLE test (i int);
CREATE TABLE test2 (i int) TABLESPACE pg_default;
SELECT tablename, tablespace FROM pg_tables WHERE schemaname = 'public';
ALTER TABLE test set TABLESPACE pg_default;
SELECT oid, spcname FROM pg_tablespace; -- oid унимальный номер, по кторому можем найти файлы
SELECT oid, datname,dattablespace FROM pg_database;
```
-- всегда можем посмотреть, где лежит таблица
>SELECT pg_relation_filepath('test2');

-- Узнать размер, занимаемый базой данных и объектами в ней, можно с помощью ряда функций.
>SELECT pg_database_size('app');

-- Для упрощения восприятия можно вывести число в отформатированном виде:
>SELECT pg_size_pretty(pg_database_size('app'));

-- Полный размер таблицы (вместе со всеми индексами):
>SELECT pg_size_pretty(pg_total_relation_size('test2'));

-- И отдельно размер таблицы...
>SELECT pg_size_pretty(pg_table_size('test2'));

-- ...и индексов:
>SELECT pg_size_pretty(pg_indexes_size('test2'));

-- При желании можно узнать и размер отдельных слоев таблицы, например:
>SELECT pg_size_pretty(pg_relation_size('test2','vm'));

-- Размер табличного пространства показывает другая функция:
>SELECT pg_size_pretty(pg_tablespace_size('ts'));

-- посмотрим на файловую систему
-- sudo apt install mc
-- /var/lib/postgresql
>\l+
```sql
SELECT d.datname as "Name",
       r.rolname as "Owner",
       pg_catalog.pg_encoding_to_char(d.encoding) as "Encoding",
       pg_catalog.shobj_description(d.oid, 'pg_database') as "Description",
       t.spcname as "tablespace"
FROM pg_catalog.pg_DATABASE d
  JOIN pg_catalog.pg_roles r ON d.datdba = r.oid
  JOIN pg_catalog.pg_tablespace t on d.datTABLEspace = t.oid
ORDER BY 1;
```

-- зададим переменную
```sql
SELECT oid as tsoid FROM pg_tablespace WHERE spcname='ts' \gset 
SELECT datname FROM pg_database WHERE oid in (SELECT pg_tablespace_databases(:tsoid));
```

--с дефолтным неймспейсом не все так просто
>SELECT count(*) FROM pg_class WHERE reltablespace = 0;

>\! pwd

>\i /var/lib/postgresql/14/main/s.sql

# Физический уровень PostgreSQL.
___
1.[pspg. Часть 1](https://ptolmachev.ru/pspg-chast-1.html "pspg. Часть 1")

2.[Как использовать pspg](https://pgconf.ru/2021/288291 "Как использовать pspg")

3.[How Postgres Stores Rows](https://ketansingh.me/posts/how-postgres-stores-rows/ "How Postgres Stores Rows")