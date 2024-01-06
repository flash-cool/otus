**Генерируем ключ**
>ssh-keygen -t rsa -b 2048

**Подключаемся с ключём**
>ssh -i ~/.ssh/gc_key kimu-dev@34.171.5.81

**Сгенерировать ssh-key:**
```bash
cd ~
cd .ssh
ssh-keygen -t rsa -b 2048
name ssh-key: yc_key
chmod 600 ~/.ssh/yc_key.pub
ls -lh ~/.ssh/
cat ~/.ssh/yc_key.pub # в Windows C:\Users\<имя_пользователя>\.ssh\yc_key.pub
```
**Подключение к VM:**
>ssh -i ~/.ssh/yc_key otus@158.160.132.34

**Установка Postgres в UBUNTU:**
>sudo apt update && sudo apt upgrade -y -q && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - && sudo apt-get update && sudo apt -y install postgresql-15

**Проверить службу PG**
>pg_lsclusters

**Подключится к PG локально**
>sudo -u postgres psql

**Удалить кластер PG**
>sudo apt remove postgresql-15


***Ссылки из первого занятия***
___
1.[PostgreSQL 15:Коммитфест](https://habr.com/ru/companies/postgrespro/articles/572782/ "PostgreSQL 15:Коммитфест")

2.[Constraints в PostgreSQL](https://habr.com/ru/companies/postgrespro/articles/672004/ "Constraints в PostgreSQL")

3.[Markdown](https://htmlacademy.ru/blog/git/markdown "PostgreSQL 15:Markdown")

4.[MD для github](https://github.com/GnuriaN/format-README/blob/master/README.md "MD для github")