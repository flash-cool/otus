-- Более новая версия не содержит бинарники предыдущих, при создании кластера pg_createcluster 13 main
-- т.е. если мы хотеим иметь на сервере несколько кластеров разных версий, нужно скачивать их бинарники.
-- Соответственно чтобы обновиться с 15 на 16 версию, нужны бинарники обоих.
-- Кластеры друг другу не мешают, у них разные директории и разные порты. Независимо друг от друга он могут включаться и выключаться.

-- установим 14 Постгрес
```bash
sudo apt update && sudo apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && 
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-14
sudo -u postgres psql -p 5432
```
-- поставим 15 ПГ
```bash
sudo apt update && sudo apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && 
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-15
```
pg_lsclusters
-- попробуем создать кластер на предыдущей версии
```bash
pg_createcluster 13 main 
sudo apt install -y postgresql-13
pg_lsclusters
```
-- И мы хотим обновить 13 кластер до 15.
```bash
sudo apt update && sudo apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && 
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-15
```
>sudo apt install -y postgresql-13

>pg_lsclusters

>pg_upgradecluster 13 main

-- Для всех утилить есть мануал man pg_upgradecluster к примеру.
-- Для того чтобы открыть доступ во вне, нам нужно соответственно создать пользователя и пароль.

>sudo -u postgres psql

-- зададим пароль
```sql
CREATE ROLE testpass PASSWORD 'testpass' LOGIN;
CREATE DATABASE otus;
exit
```
>sudo -u postgres psql -p 5433 -U testpass -h localhost -d postgres -W

-- Мы не можем зайти, т.к. мы не задали маску подсети пользователя в pg_hba.conf
-- До 15 версии были права на схему public и можно было создавать и менять объекты.

-- переименуем старый кластер
>sudo pg_renamecluster 13 main main13

-- заапдейтим версию кластера
>sudo pg_upgradecluster 13 main13

>pg_lsclusters

-- обратите внимание, что старый кластер остался. Давайте удалим его
```bash
sudo pg_dropcluster 13 main13
sudo -u postgres psql -p 5433
sudo -u postgres psql -p 5433 -U testpass -h localhost -d postgres -W
```
-- Мы создали пользователя и пароль в версии 13 и обновляем кластер до 15

-- обратите внимание, что старый кластер остался. Давайте удалим его
>sudo pg_dropcluster 13 main13

-- зададим маску подсети, откуда разрешен доступ
>sudo cat /etc/postgresql/15/main13/pg_hba.conf

-- scram-sha-256
-- for all users on localhost
>sudo nano /etc/postgresql/15/main13/pg_hba.conf


-- Нажмите клавиши Ctrl+O.
-- В терминале появится сообщение «WriteOut». Введите имя файла, которое хотите дать сохраняемому файлу.
-- Нажмите Enter, чтобы сохранить файл.
-- Если вы хотите покинуть редактор, нажмите Ctrl+X.
-- Если мы изменим вид шифрования с версии md5 на scram-sha-256 (которая поддерживается 15й версией пг), то у нас будет ошибка аутентификации.
-- Чтобы сенить тип шифрования на более современный, необходимо пользователю сменить пароль.


-- md5
-- for all users on localhost
>sudo nano /etc/postgresql/15/main13/pg_hba.conf

>sudo pg_ctlcluster 15 main13 reload

-- ok
>sudo -u postgres psql -p 5433 -U testpass -h localhost -d postgres -W

```sql
ALTER USER testpass PASSWORD 'testpass';
exit
```
-- change back to scram-sha-256
```bash
sudo nano /etc/postgresql/15/main13/pg_hba.conf
sudo pg_ctlcluster 15 main13 reload
sudo -u postgres psql -p 5433 -U testpass -h localhost -d postgres -W
```
-- Можно настроить подключение только по внутренней сети, т.е. из интернета не будет доступа.
-- Обычно открытие PostgreSQL в интернет не несет особого смысла, т.к. Обычно он должен быть за всякими файрволлами.

-- Откроем доступ извне - на каком интерфейсе мы будем слушать подключения
```bash
sudo pg_conftool 15 main13 set listen_addresses '*'
sudo nano /etc/postgresql/15/main13/postgresql.conf
sudo nano /etc/postgresql/15/main13/pg_hba.conf
sudo pg_ctlcluster 15 main13 restart
```
-- с ноута
>psql -p 5433 -U testpass -h 158.160.128.113 -d postgres -W

-- не пускает.. почему?
-- обратите внимание на порта
-- идем в VPC
```bash
sudo pg_ctlcluster 15 main13 stop
sudo pg_dropcluster 15 main13
```
-- Установка клиента PostgreSQL
```bash
sudo apt install postgresql-client
export PATH=$PATH:/usr/bin
psql --version
sudo nano /etc/postgresql/15/main13/pg_hba.conf
sudo pg_conftool 15 main13 set listen_addresses '*'
sudo pg_ctlcluster 15 main13 restart
```
-- ткрываем маску подсети пошире, это не продакт решение конечно особенно с простыми паролями, но для эксперимента пойдет.

-- уберем лишние кластера
```bash
pg_lsclusters
sudo pg_ctlcluster 15 main stop && sudo pg_dropcluster 15 main
sudo pg_ctlcluster 15 main13 stop && sudo pg_dropcluster 15 main13
```
-- docker
-- полное руководство на Хабре, кто любит поосновательнее 
-- https://habr.com/ru/post/310460/
-- поставим докер
-- https://docs.docker.com/engine/install/ubuntu/
> curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh && rm get-docker.sh && sudo usermod -aG docker $USER && newgrp docker

-- 1. Создаем docker-сеть: 
>sudo docker network create pg-net

-- 2. подключаем созданную сеть к контейнеру сервера Postgres:
>sudo docker run --name pg-server --network pg-net -e POSTGRES_PASSWORD=postgres -d -p 5432:5432 -v /var/lib/postgres:/var/lib/postgresql/data postgres:15

-- 3. Запускаем отдельный контейнер с клиентом в общей сети с БД: 
>sudo docker run -it --rm --network pg-net --name pg-client postgres:15 psql -h pg-server -U postgres

-- 4. Проверяем, что подключились через отдельный контейнер:
```bash
sudo docker ps -a
sudo docker stop 058b4dcc8b36
sudo docker rm 058b4dcc8b36
psql -h localhost -U postgres -d postgres
```
-- с ноута
>psql -p 5432 -U postgres -h 158.160.128.113 -d postgres -W

-- подключение без открытия порта наружу
```bash
sudo docker run --name pg-server --network pg-net -e POSTGRES_PASSWORD=postgres -d -v /var/lib/postgres:/var/lib/postgresql/data postgres:15
sudo docker run -it --rm --network pg-net --name pg-client postgres:15 psql -h pg-server -U postgres
```
-- минимальный запуск
>sudo docker run --name pg-server -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:15

-- зайти внутрь контейнера
>sudo docker exec -it pg-server bash -> df

-- установить VIM & NANO
-- внутри контейнера ubuntu)
```bash
cat /proc/version
apt-get update
apt-get install vim nano -y
psql -U postgres
show hba_file;
show config_file;
show data_directory;
sudo docker ps
sudo docker stop
```
-- рестарт контейнера после смерти
>docker run -d --restart unless-stopped/always

-- docker compose
>sudo apt install docker-compose -y

-- используем утилиту защищенного копирования по сети
```bash
scp -i ~/.ssh/yc_key /mnt/c/Users/kimu/docker-compose.yml otus@158.160.128.113:/home/otus/
cat docker-compose.yml
sudo docker-compose up -d
```
-- password - secret
>sudo -u postgres psql -h localhost -p 5433

-- почему нет старой БД?
```bash
sudo su
cd /var/lib/docker/volumes/otus_pg_project/_data
ls -la
```

# Ссылки
___
1.[Полное практическое руководство по Docker: с нуля до кластера на AWS](https://habr.com/ru/articles/310460/ "Полное практическое руководство по Docker: с нуля до кластера на AWS")

2.[Обновление PostgreSQL в Linux](https://itdraft.ru/2022/11/22/obnovlenie-postgresql-v-linux/ "Обновление PostgreSQL в Linux")