create database otus;
\c otus

create table students as select generate_series(1, 10) as id, md5(random()::text)::char(10) as fio;

-- ЛОГИЧЕСКИЙ БЭКАП
-- \help copy

\copy students to '/tmp/backup_copy.sql';
\copy students from '/tmp/backup_copy.sql';

\copy students to '/tmp/backup_copy.sql' with delimiter ',';
insert into students values (11, 'mos, ru');
\copy students from '/tmp/backup_copy.sql' with delimiter ',';


-- pg_dump

sudo -u postgres pg_dump -d otus --create > /tmp/backup_dump.sql
sudo -u postgres psql < /tmp/backup_dump.sql


-- архив

sudo -u postgres pg_dump -d otus --create -Fc > /tmp/backup_dump.gz
sudo -u postgres pg_dump -d otus --create | gzip > /tmp/backup_dump2.gz

sudo -u postgres pg_restore -d otus /tmp/backup_dump.gz

sudo pg_createcluster 14 main2
pg_lsclusters
sudo pg_ctlcluster 14 main2 start

sudo -u postgres psql -p 5433 < /tmp/backup_dump.gz
sudo -u postgres psql -p 5433
\conninfo

sudo -u postgres pg_dump -d otus --create -Fd -f /tmp/test.dir
sudo -u postgres pg_restore -d otus /tmp/test.dir

gzip -dc backup_dump.gz


-- pg_dumpall
sudo -u postgres pg_dumpall > /tmp/backup_alldump.sql
sudo -u postgres psql < /tmp/backup_alldump.sql


-- ФИЗИЧЕСКИЙ БЭКАП (СОЗДАНИЕ АВТОНОМНОГО БЭКАПА)

sudo rm -rf /var/lib/postgresql/14/main2
sudo -u postgres pg_basebackup -p 5432 -D /var/lib/postgresql/14/main2
sudo pg_ctlcluster 14 main2 start

pg_lsclusters
sudo pg_dropcluster 14 main2

select name, setting from pg_settings where name in ('archive_mode','archive_command','archive_timeout');

-- Резервное копирование и восстановление
___

https://github.com/wal-g/wal-g
https://github.com/postgrespro/pg_probackup
https://pgbarman.org/
