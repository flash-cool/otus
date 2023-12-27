# Установка PostgreSQL 
_____
1.***Поставить на OC Docker Engine***
```
root@POL:~# systemctl status docker
* docker.service - Docker Application Container Engine
     Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
     Active: active (running) since Wed 2023-12-13 11:40:38 CET; 29min ago
TriggeredBy: * docker.socket
       Docs: https://docs.docker.com
   Main PID: 1846 (dockerd)
      Tasks: 8
     Memory: 36.3M
        CPU: 832ms
     CGroup: /system.slice/docker.service
             `-1846 /usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock

Dec 13 11:40:36 POL.ip-ptr.tech systemd[1]: Starting Docker Application Container Engine...
Dec 13 11:40:36 POL.ip-ptr.tech dockerd[1846]: time="2023-12-13T11:40:36.762698716+01:00" level=info msg="Starting up"
Dec 13 11:40:36 POL.ip-ptr.tech dockerd[1846]: time="2023-12-13T11:40:36.894929311+01:00" level=info msg="Loading containers: start."
Dec 13 11:40:38 POL.ip-ptr.tech dockerd[1846]: time="2023-12-13T11:40:38.042258488+01:00" level=info msg="Firewalld: interface docker0 already part of docker zone, returning"
Dec 13 11:40:38 POL.ip-ptr.tech dockerd[1846]: time="2023-12-13T11:40:38.291527879+01:00" level=info msg="Loading containers: done."
Dec 13 11:40:38 POL.ip-ptr.tech dockerd[1846]: time="2023-12-13T11:40:38.361734713+01:00" level=info msg="Docker daemon" commit=311b9ff graphdriver=overlay2 version=24.0.7
Dec 13 11:40:38 POL.ip-ptr.tech dockerd[1846]: time="2023-12-13T11:40:38.362838200+01:00" level=info msg="Daemon has completed initialization"
Dec 13 11:40:38 POL.ip-ptr.tech dockerd[1846]: time="2023-12-13T11:40:38.454635351+01:00" level=info msg="API listen on /run/docker.sock"
Dec 13 11:40:38 POL.ip-ptr.tech systemd[1]: Started Docker Application Container Engine.
```
2.***Сделать каталог /mnt/docker/postgres***
```
root@POL:~# mkdir -p /mnt/docker/postgres
root@POL:~# ls -lah /mnt/docker/
total 12K
drwxr-xr-x 3 root docker 4.0K Dec 13 12:10 .
drwxr-xr-x 3 root root   4.0K Dec 13 12:10 ..
drwxr-xr-x 2 root docker 4.0K Dec 13 12:10 postgres
```
3.***Развернуть контейнер с PostgreSQL 15 смонтировав в него /var/docker/postgres***
```
root@POL:~# sudo docker network create super-net
aedcbef9782965301319e088fff82dcdf224aa952af9f4bf38f2a5b97df9009f
root@POL:~# sudo docker run --name pg-server --network super-net -e POSTGRES_PASSWORD=xxxxxx -d -p 5432:5432 -v /mnt/docker/postgres:/var/lib/postgresql/data postgres:15
Unable to find image 'postgres:15' locally
15: Pulling from library/postgres
1f7ce2fa46ab: Pull complete
90fbd05a6c64: Pull complete
c107a494d63c: Pull complete
8b1f93317ded: Pull complete
b4e0db51dfb9: Pull complete
ffcd2018dc44: Pull complete
bb8fb522edb2: Pull complete
d83898b9620b: Pull complete
7c74348418e9: Pull complete
a56b24ebf993: Pull complete
aa48b46b9cdb: Pull complete
be71efae0c17: Pull complete
22902c020f47: Pull complete
Digest: sha256:cc6dcc9ec987ce2887ac746114a72b288e490ba14f4658731c2822600aab8d00
Status: Downloaded newer image for postgres:15
40a73da1b91b6accf2cc2f2d7990dee16be5475aff1475667eb3a2b767cac25c
root@POL:~# docker ps
CONTAINER ID   IMAGE         COMMAND                  CREATED         STATUS         PORTS                                       NAMES
40a73da1b91b   postgres:15   "docker-entrypoint.s…"   8 seconds ago   Up 7 seconds   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp   pg-server
```
4.***Развернуть контейнер с клиентом postgres***
```
root@POL:~# sudo docker run -it --rm --network super-net --name pg-client postgres:15 psql -h pg-server -U postgres
Password for user postgres:
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=#
```
5.***Подключится из контейнера с клиентом к контейнеру с сервером и сделать таблицу с парой строк***
```
 postgres=# create table testpg(num serial, first_name text, second_name text);
CREATE TABLE
postgres=# insert into testpg(first_name, second_name) values('lost', 'man'); insert into testpg(first_name, second_name) values('grow', 'lol');
INSERT 0 1
INSERT 0 1
postgres=# select * from testpg;
 num | first_name | second_name
-----+------------+-------------
   1 | lost       | man
   2 | lost       | man
   3 | grow       | lol
(3 rows)
```
6.***Подключится к контейнеру с сервером с ноутбука/компьютера извне***
```
[root@pol-testpg-04 ~]# psql -p 5432 -U postgres -h 172.16.**.*** -d postgres -W
Пароль:
psql (11.12, сервер 15.5 (Debian 15.5-1.pgdg120+1))
ПРЕДУПРЕЖДЕНИЕ: psql имеет базовую версию 13, а сервер - 15.
                Часть функций psql может не работать.
Введите "help", чтобы получить справку.

postgres=# \l+
                                                                       Список баз данных
    Имя    | Владелец | Кодировка | LC_COLLATE |  LC_CTYPE  |     Права доступа     | Размер  | Табл. пространство |                  Описание
-----------+----------+-----------+------------+------------+-----------------------+---------+--------------------+--------------------------------------------
 postgres  | postgres | UTF8      | en_US.utf8 | en_US.utf8 |                       | 7525 kB | pg_default         | default administrative connection database
 template0 | postgres | UTF8      | en_US.utf8 | en_US.utf8 | =c/postgres          +| 7297 kB | pg_default         | unmodifiable empty database
           |          |           |            |            | postgres=CTc/postgres |         |                    |
 template1 | postgres | UTF8      | en_US.utf8 | en_US.utf8 | =c/postgres          +| 7525 kB | pg_default         | default template for new databases
           |          |           |            |            | postgres=CTc/postgres |         |                    |
(3 строки)

postgres=# select * from testpg;
 num | first_name | second_name
-----+------------+-------------
   1 | lost       | man
   2 | lost       | man
   3 | grow       | lol
(3 строки)

```
7.***Удалить контейнер с сервером***
```
 root@POL:~# docker ps
CONTAINER ID   IMAGE         COMMAND                  CREATED          STATUS          PORTS                                       NAMES
40a73da1b91b   postgres:15   "docker-entrypoint.s…"   38 minutes ago   Up 38 minutes   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp   pg-server
root@POL:~# docker stop 40a73da1b91b
40a73da1b91b
root@POL:~# docker rm 40a73da1b91b
40a73da1b91b
root@POL:~# docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
root@POL:~# ls -lah /m
media/ mnt/
root@POL:~# ls -lah /mnt/docker/postgres/
total 132K
drwx------ 19 systemd-coredump docker           4.0K Dec 13 12:57 .
drwxr-xr-x  3 root             docker           4.0K Dec 13 12:10 ..
-rw-------  1 systemd-coredump systemd-coredump    3 Dec 13 12:18 PG_VERSION
drwx------  5 systemd-coredump systemd-coredump 4.0K Dec 13 12:18 base
drwx------  2 systemd-coredump systemd-coredump 4.0K Dec 13 12:21 global
drwx------  2 systemd-coredump systemd-coredump 4.0K Dec 13 12:18 pg_commit_ts
drwx------  2 systemd-coredump systemd-coredump 4.0K Dec 13 12:18 pg_dynshmem
-rw-------  1 systemd-coredump systemd-coredump 4.8K Dec 13 12:18 pg_hba.conf
-rw-------  1 systemd-coredump systemd-coredump 1.6K Dec 13 12:18 pg_ident.conf
drwx------  4 systemd-coredump systemd-coredump 4.0K Dec 13 12:57 pg_logical
drwx------  4 systemd-coredump systemd-coredump 4.0K Dec 13 12:18 pg_multixact
drwx------  2 systemd-coredump systemd-coredump 4.0K Dec 13 12:18 pg_notify
drwx------  2 systemd-coredump systemd-coredump 4.0K Dec 13 12:18 pg_replslot
drwx------  2 systemd-coredump systemd-coredump 4.0K Dec 13 12:18 pg_serial
drwx------  2 systemd-coredump systemd-coredump 4.0K Dec 13 12:18 pg_snapshots
drwx------  2 systemd-coredump systemd-coredump 4.0K Dec 13 12:57 pg_stat
drwx------  2 systemd-coredump systemd-coredump 4.0K Dec 13 12:18 pg_stat_tmp
drwx------  2 systemd-coredump systemd-coredump 4.0K Dec 13 12:18 pg_subtrans
drwx------  2 systemd-coredump systemd-coredump 4.0K Dec 13 12:18 pg_tblspc
drwx------  2 systemd-coredump systemd-coredump 4.0K Dec 13 12:18 pg_twophase
drwx------  3 systemd-coredump systemd-coredump 4.0K Dec 13 12:18 pg_wal
drwx------  2 systemd-coredump systemd-coredump 4.0K Dec 13 12:18 pg_xact
-rw-------  1 systemd-coredump systemd-coredump   88 Dec 13 12:18 postgresql.auto.conf
-rw-------  1 systemd-coredump systemd-coredump  29K Dec 13 12:18 postgresql.conf
-rw-------  1 systemd-coredump systemd-coredump   36 Dec 13 12:18 postmaster.opts
```
8.***Создать его заново и подключится снова из контейнера с клиентом к контейнеру с сервером***
```
root@POL:~# sudo docker run --name pg-server --network super-net -e POSTGRES_PASSWORD=xxxxxx -d -p 5432:5432 -v /mnt/docker/postgres:/var/lib/postgresql/data postgres:15
a101c7e7141bcf4e067631b78a2683f6570661c57b3dc74c19563467ba12c169
root@POL:~# docker ps
CONTAINER ID   IMAGE         COMMAND                  CREATED         STATUS         PORTS                                       NAMES
a101c7e7141b   postgres:15   "docker-entrypoint.s…"   5 seconds ago   Up 4 seconds   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp   pg-server
root@POL:~# sudo docker run -it --rm --network super-net --name pg-client postgres:15 psql -h pg-server -U postgres
Password for user postgres:
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=#
```
9.***Проверить, что данные остались на месте***
```
 postgres=# select * from testpg;
 num | first_name | second_name
-----+------------+-------------
   1 | lost       | man
   2 | lost       | man
   3 | grow       | lol
(3 rows)

postgres=#
```
10.**Комментарий**

:heavy_exclamation_mark:***Столкнулся с проблемой, не получилось подключится из локальной сети к машине с Docker PostgreSQL (разворачивалась всё в локальной сети предприятия).***:heavy_exclamation_mark:

***Проблема оказалась в том что в локальной сети у моеё машины был IP 172.17.10.14/24 и эта подсеть пересеклась с сетью развёрнутого Docker.***

>docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500
>>link/ether 02:42:19:ed:38:70 brd ff:ff:ff:ff:ff:ff

>>inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0

>>valid_lft forever preferred_lft forever

***Решить проблему помогло изменение подсети Docker на другую, которая не пересекалась с моей.***:white_check_mark:

✨Magic ✨