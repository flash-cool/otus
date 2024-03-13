-- Patroni в DCS (Distributed Configuration Store) используется для управления конфигурацией и состоянием базы данных PostgreSQL. Он предоставляет механизм для автоматического обнаружения сбоев и восстановления базы данных, а также обеспечивает высокую доступность и отказоустойчивость системы. Patroni также позволяет управлять кластером PostgreSQL, включая масштабирование и балансировку нагрузки.

-- Etcd (изначально назывался "etcd") - это распределенное, надежное и высокодоступное хранилище ключ-значение, которое используется для хранения данных конфигурации, состояния кластера и других данных в распределенных системах. Etcd обеспечивает консистентность данных и поддерживает механизмы обнаружения сбоев и восстановления, что делает его полезным инструментом для управления состоянием и конфигурацией в распределенных системах.

-- Etcd широко используется в различных проектах, таких как Kubernetes, CoreOS, OpenShift, и других, благодаря своей способности обеспечивать надежное хранение данных и возможность автоматического обнаружения и восстановления отказов. Etcd также часто используется в современных системах управления конфигурацией и оркестрации контейнеров.

-- Балансировщики нагрузки, такие как HAProxy и PgBouncer, играют важную роль в обеспечении высокой доступности, масштабируемости и управлении нагрузкой в распределенных системах. Вот краткое описание их назначения и различий:

-- HAProxy:
-- HAProxy - это программное обеспечение для балансировки нагрузки и проксирования TCP/HTTP-трафика. Он используется для распределения запросов от клиентов между несколькими серверами (например, веб-серверами) для обеспечения высокой доступности, увеличения производительности и устранения единой точки отказа. HAProxy также обладает функциями мониторинга состояния серверов и автоматического перенаправления трафика в случае сбоев.

-- PgBouncer:
-- PgBouncer - это прокси-сервер для PostgreSQL, который предназначен для управления соединениями к базе данных PostgreSQL. Он позволяет эффективно масштабировать соединения к базе данных, уменьшая нагрузку на сервер базы данных и улучшая производительность. PgBouncer может обрабатывать множество клиентских соединений, предоставляя им пул соединений к базе данных и управляя их жизненным циклом.

-- Различия:
-- Основное различие между HAProxy и PgBouncer заключается в их предназначении и функциональности. HAProxy предназначен для балансировки нагрузки и проксирования трафика между серверами приложений, тогда как PgBouncer предназначен для управления соединениями к базе данных PostgreSQL. Каждый из них решает свои специфические задачи в распределенной системе, обеспечивая высокую доступность, масштабируемость и оптимизацию производительности.

-- ; Эта статья представляет собой пошаговое руководство по созданию высокодоступной архитектуры кластера PostgreSQL с использованием Patroni и HAProxy.

-- ; Patroni — это пакет Python с открытым исходным кодом, который управляет конфигурацией Postgres. 
-- ; Его можно настроить для выполнения таких задач, как репликация, резервное копирование и восстановление.

-- ; Etcd — это отказоустойчивое распределенное хранилище ключей и значений, используемое для хранения состояния кластера Postgres. 
-- ; Используя Patroni, все узлы Postgres используют etcd для поддержания работоспособности кластера Postgres. 
-- ; В производственной среде имеет смысл использовать кластер etcd большего размера, чтобы отказ одного узла etcd не влиял на серверы Postgres.

-- ; После настройки кластера Postgres нам нужен способ подключения к главному серверу независимо от того, какой из серверов в кластере является ведущим. 
-- ; Здесь в дело вступает HAProxy. Все клиенты/приложения Postgres будут подключаться к HAProxy, который обеспечит подключение к главному узлу в кластере.

-- ; HAProxy — это высокопроизводительный балансировщик нагрузки с открытым исходным кодом и обратный прокси-сервер для приложений TCP и HTTP. 
-- ; HAProxy можно использовать для распределения нагрузки и повышения производительности веб-сайтов и приложений.


-- Machine: node1, IP: <node1_ip>, Role: Postgresql, Patroni
-- Machine: node2, IP: <node2_ip>, Role: Postgresql, Patroni
-- Machine: node3, IP: <node3_ip>, Role: Postgresql, Patroni
-- Machine: etcdnode, IP: <etcdnode_ip>, Role: etcd
-- Machine: haproxynode, IP: <haproxynode_ip>, Role: HA Proxy


-- 'yc' в составе Яндекс.Облако CLI для управления облачными ресурсами в Яндекс.Облако
https://cloud.yandex.com/en/docs/cli/quickstart

-- Подключаемся к Яндекс.Облако и выполняем конфигурацию окружения с помощью команды:
yc init

-- Проверяем установленную версию 'yc' (рекомендуется последняя доступная версия):
yc version

-- Список географических регионов и зон доступности для размещения VM:
yc compute zone list
yc config set compute-default-zone ru-central1-a
yc config get compute-default-zone

-- Далее будем использовать географический регион ‘ru-central1’ и зону доступности 'ru-central1-a'.

-- Список доступных типов дисков:
yc compute disk-type list

-- Далее будем использовать тип диска ‘network-hdd’.

-- Создаем сетевую инфраструктуру для VM:

yc vpc network create \
    --name otus-net \
    --description "otus-net" \

yc vpc network list

yc vpc subnet create \
    --name otus-subnet \
    --range 192.168.0.0/24 \
    --network-name otus-net \
    --description "otus-subnet" \

yc vpc subnet list

-- Устанавливаем ВМ:
yc compute instance create \
    --name otus-vm \
    --hostname otus-vm \
    --cores 2 \
    --memory 4 \
    --create-boot-disk size=15G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts \
    --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 \
    --ssh-key ~/.ssh/yc_key.pub \

yc compute instances show otus-vm
yc compute instances list

-- Подключаемся к ВМ:
ssh -i ~/.ssh/yc_key yc-user@158.160.115.220

-- Удаляем ВМ и сети:
yc compute instance delete otus-vm
yc vpc subnet delete otus-subnet
yc vpc network delete otus-net



yc compute instance create \
    --name otus-vm-node1 \
    --hostname otus-vm-node1 \
    --cores 2 \
    --memory 4 \
    --create-boot-disk size=15G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts \
    --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 \
    --ssh-key ~/.ssh/yc_key.pub \

yc compute instance create \
    --name otus-vm-node2 \
    --hostname otus-vm-node2 \
    --cores 2 \
    --memory 4 \
    --create-boot-disk size=15G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts \
    --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 \
    --ssh-key ~/.ssh/yc_key.pub \

yc compute instance create \
    --name otus-vm-node3 \
    --hostname otus-vm-node3 \
    --cores 2 \
    --memory 4 \
    --create-boot-disk size=15G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts \
    --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 \
    --ssh-key ~/.ssh/yc_key.pub \

yc compute instance create \
    --name otus-vm-etcdnode \
    --hostname otus-vm-etcdnode \
    --cores 2 \
    --memory 4 \
    --create-boot-disk size=15G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts \
    --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 \
    --ssh-key ~/.ssh/yc_key.pub \

yc compute instance create \
    --name otus-vm-haproxynode \
    --hostname otus-vm-haproxynode \
    --cores 2 \
    --memory 4 \
    --create-boot-disk size=15G,type=network-hdd,image-folder-id=standard-images,image-family=ubuntu-2004-lts \
    --network-interface subnet-name=otus-subnet,nat-ip-version=ipv4 \
    --ssh-key ~/.ssh/yc_key.pub \



-- ; Step 1 –  Setup otus-vm-node1, otus-vm-node2, otus-vm-node3:
```bash
sudo apt update && sudo hostnamectl set-hostname otus-vm-node1 && sudo apt install net-tools && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-14 && sudo systemctl stop postgresql && sudo ln -s /usr/lib/postgresql/14/bin/* /usr/sbin/ && sudo apt -y install python python3-pip && sudo apt install python3-testresources && sudo pip3 install --upgrade setuptools && sudo pip3 install psycopg2-binary && sudo apt install libpq-dev python3-dev && sudo pip3 install psycopg2 && sudo pip3 install patroni && sudo pip3 install python-etcd

sudo apt update && sudo hostnamectl set-hostname otus-vm-node2 && sudo apt install net-tools && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-14 && sudo systemctl stop postgresql && sudo ln -s /usr/lib/postgresql/14/bin/* /usr/sbin/ && sudo apt -y install python python3-pip && sudo apt install python3-testresources && sudo pip3 install --upgrade setuptools && sudo pip3 install psycopg2-binary && sudo apt install libpq-dev python3-dev && sudo pip3 install psycopg2 && sudo pip3 install patroni && sudo pip3 install python-etcd

sudo apt update && sudo hostnamectl set-hostname otus-vm-node3 && sudo apt install net-tools && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-14 && sudo systemctl stop postgresql && sudo ln -s /usr/lib/postgresql/14/bin/* /usr/sbin/ && sudo apt -y install python python3-pip && sudo apt install python3-testresources && sudo pip3 install --upgrade setuptools && sudo pip3 install psycopg2-binary && sudo apt install libpq-dev python3-dev && sudo pip3 install psycopg2 && sudo pip3 install patroni && sudo pip3 install python-etcd
```
-- ; Step 2 –  Setup etcdnode:

>sudo apt update && sudo hostnamectl set-hostname etcdnode && sudo apt install net-tools && sudo apt -y install etcd 

; Step 3 – Setup haproxynode:

>sudo apt update && sudo hostnamectl set-hostname haproxynode && sudo apt install net-tools && sudo apt -y install haproxy

-- ; Step 4 – Configure etcd on the etcdnode: 
```bash
sudo nano /etc/default/etcd   
ip addr show

1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether d0:0d:ed:43:c1:c2 brd ff:ff:ff:ff:ff:ff
    inet 192.168.0.31/24 brd 192.168.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::d20d:edff:fe43:c1c2/64 scope link 
       valid_lft forever preferred_lft forever


ETCD_LISTEN_PEER_URLS="http://192.168.0.15:2380"
ETCD_LISTEN_CLIENT_URLS="http://localhost:2379,http://62.84.125.70:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://192.168.0.15:2380"
ETCD_INITIAL_CLUSTER="default=http://192.168.0.15:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://62.84.125.70:2379"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_ENABLE_V2="true"

sudo systemctl restart etcd 

sudo systemctl status etcd

curl http://192.168.0.15:2380/members
```

-- ; Step 5 – Configure Patroni on the node1, on the node2 and on the node3:
```bash
ip addr show

sudo nano /etc/patroni.yml

scope: postgres
namespace: /db/
name: otus-vm-node1

restapi:
    listen: 51.250.5.141:8008
    connect_address: 151.250.5.141:8008

etcd:
    host: 192.168.0.15:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 127.0.0.1/32 scram-sha-256
  - host replication replicator 51.250.5.141/0 scram-sha-256
  - host all all 0.0.0.0/0 scram-sha-256

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb

postgresql:
  listen: 51.250.5.141:5432
  connect_address: 51.250.5.141:5432
  data_dir: /data/patroni
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: 123
    superuser:
      username: postgres
      password: 123
  parameters:
      unix_socket_directories: '.'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false



scope: postgres
namespace: /db/
name: otus-vm-node2

restapi:
    listen: 192.168.0.24:8008
    connect_address: 192.168.0.24:8008

etcd:
    host: 192.168.0.31:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 127.0.0.1/32 scram-sha-256
  - host replication replicator 192.168.0.38/0 scram-sha-256
  - host replication replicator 192.168.0.24/0 scram-sha-256
  - host replication replicator 192.168.0.6/0 scram-sha-256
  - host all all 0.0.0.0/0 scram-sha-256

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb

postgresql:
  listen: 192.168.0.24:5432
  connect_address: 192.168.0.24:5432
  data_dir: /data/patroni
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: 123
    superuser:
      username: postgres
      password: 123
  parameters:
      unix_socket_directories: '.'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false



scope: postgres
namespace: /db/
name: otus-vm-node3

restapi:
    listen: 192.168.0.6:8008
    connect_address: 192.168.0.6:8008

etcd:
    host: 192.168.0.31:2379

bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:

  initdb:
  - encoding: UTF8
  - data-checksums

  pg_hba:
  - host replication replicator 127.0.0.1/32 scram-sha-256
  - host replication replicator 192.168.0.38/0 scram-sha-256
  - host replication replicator 192.168.0.24/0 scram-sha-256
  - host replication replicator 192.168.0.6/0 scram-sha-256
  - host all all 0.0.0.0/0 scram-sha-256

  users:
    admin:
      password: admin
      options:
        - createrole
        - createdb

postgresql:
  listen: 192.168.0.6:5432
  connect_address: 192.168.0.6:5432
  data_dir: /data/patroni
  pgpass: /tmp/pgpass
  authentication:
    replication:
      username: replicator
      password: 123
    superuser:
      username: postgres
      password: 123
  parameters:
      unix_socket_directories: '.'

tags:
    nofailover: false
    noloadbalance: false
    clonefrom: false
    nosync: false


sudo mkdir -p /data/patroni && sudo chown postgres:postgres /data/patroni && sudo chmod 700 /data/patroni && sudo nano /etc/systemd/system/patroni.service

[Unit]
Description=High availability PostgreSQL Cluster
After=syslog.target network.target

[Service]
Type=simple
User=postgres
Group=postgres
ExecStart=/usr/local/bin/patroni /etc/patroni.yml
KillMode=process
TimeoutSec=30
Restart=no

[Install]
WantedBy=multi-user.targ
```

-- ; Step 6 – Start Patroni service on the node1, on the node2 and on the node3:
```bash
sudo systemctl start patroni
sudo systemctl status patroni
```

-- ; Step 7 – Configuring HA Proxy on the node haproxynode: 
```bash
sudo nano /etc/haproxy/haproxy.cfg

Replace its context with this:

global
        maxconn 100
        log     127.0.0.1 local2

defaults
        log global
        mode tcp
        retries 2
        timeout client 30m
        timeout connect 4s
        timeout server 30m
        timeout check 5s

listen stats
    mode http
    bind *:7000
    stats enable
    stats uri /

listen postgres
    bind *:5000
    option httpchk
    http-check expect status 200
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions
    server otus-vm-node1 192.168.0.38:5432 maxconn 100 check port 8008
    server otus-vm-node2 192.168.0.24:5432 maxconn 100 check port 8008
    server otus-vm-node3 192.168.0.6:5432 maxconn 100 check port 8008


sudo systemctl restart haproxy

sudo systemctl status haproxy

sudo pg_ctlcluster 14 main start
```

-- ; Step 8 – Testing High Availability Cluster Setup of PostgreSQL:
```bash
ip addr show

http://<haproxynode_ip>:7000/>
```
-- ; Simulate node1 crash:

>sudo systemctl stop patroni

-- ; In this case, the second Postgres server is promoted to master.

-- ; Step 9 – Connect Postgres clients to the HAProxy IP address:
```bash
psql -h 192.168.0.11 -p 5000 -U postgres

dmi@dmi-mac ~ % psql -h 192.168.1.115 -p 5000 -U postgres
Password for user postgres: 
psql (12.4)
Type "help" for help.

postgres=# 

dmi@dmi-mac ~ % psql -h 192.168.1.115 -p 5000 -U some_db
Password for user some_user: 
psql (12.4)
Type "help" for help.

some_db=>

dmi@node1:~$ patronictl -c /etc/patroni.yml list
+ Cluster: postgres (6871178537652191317) ---+----+-----------+
| Member | Host          | Role    | State   | TL | Lag in MB |
+--------+---------------+---------+---------+----+-----------+
| node1  | 192.168.1.139 | Replica | running |  2 |         0 |
| node2  | 192.168.1.110 | Leader  | running |  2 |           |
| node3  | 192.168.1.146 | Replica | running |  2 |         0 |
+--------+---------------+---------+---------+----+-----------+
dmi@node1:~$ 
```

-- ; Step 10 – Failover test:
-- ; On one of the nodes run:

>sudo systemctl stop patroni

# Patroni.
___
1.[Как мы построили надёжный кластер PostgreSQL на Patroni](https://habr.com/ru/companies/vk/articles/452846/ "Как мы построили надёжный кластер PostgreSQL на Patroni")

2.[Patroni 2.0: New features – Patroni on pure Raft](https://www.dbi-services.com/blog/patroni-2-0-new-features-patroni-on-pure-raft/ "Patroni 2.0: New features – Patroni on pure Raft")

3.[patroni](https://github.com/zalando/patroni "patroni")

4.[otus-patroni](https://github.com/lalbrekht/otus-patroni "otus-patroni")