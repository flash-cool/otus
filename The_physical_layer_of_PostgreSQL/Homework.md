# Физический уровень PostgreSQL 
_____
1.***Поставьте на нее PostgreSQL 15 через sudo apt и проверьте что кластер запущен через sudo -u postgres pg_lsclusters***
```bash
root@pg:~# pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
2.***Зайдите из под пользователя postgres в psql и сделайте произвольную таблицу с произвольным содержимым***
```bash
root@pg:~# sudo -u postgres psql
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# create table my(name text);
CREATE TABLE
postgres=# insert into my values('yurii');
INSERT 0 1

postgres=# select * from my;
 name
-------
 yurii
(1 row)

postgres=#

```
3.***Остановите postgres например через sudo -u postgres pg_ctlcluster 15 main stop***
```bash
root@pg:~# pg_ctlcluster 15 main stop
root@pg:~# pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
4.***Создайте новый диск в VM размером 50GB***
```bash
root@pg:~# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   50G  0 disk
├─sda1   8:1    0   49G  0 part /
├─sda2   8:2    0    1K  0 part
└─sda5   8:5    0  975M  0 part [SWAP]
sdb      8:16   0   50G  0 disk
sr0     11:0    1  628M  0 rom
root@pg:~# fdisk /dev/sdb

Welcome to fdisk (util-linux 2.38.1).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS (MBR) disklabel with disk identifier 0x240fc143.

Command (m for help): g
Created a new GPT disklabel (GUID: 95E1BA03-4A1F-5146-ACC1-FB0536B79071).

Command (m for help): n
Partition number (1-128, default 1):
First sector (2048-104857566, default 2048):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-104857566, default 104855551):

Created a new partition 1 of type 'Linux filesystem' and of size 50 GiB.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.

root@pg:~# mkfs.ext4 /dev/sdb1
mke2fs 1.47.0 (5-Feb-2023)
Discarding device blocks: done
Creating filesystem with 13106688 4k blocks and 3276800 inodes
Filesystem UUID: 8d661e5e-7e37-4829-a137-2fe397217033
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208,
        4096000, 7962624, 11239424

Allocating group tables: done
Writing inode tables: done
Creating journal (65536 blocks):
done
Writing superblocks and filesystem accounting information: done

root@pg:~# mkdir /mnt/pgdir
root@pg:~# vim /etc/fstab
root@pg:~# cat /etc/fstab
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# systemd generates mount units based on this file, see systemd.mount(5).
# Please run 'systemctl daemon-reload' after making changes here.
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
# / was on /dev/sda1 during installation
UUID=c63c18f3-e18a-4a93-9b0c-d12f0ceaf889 /               ext4    errors=remount-ro 0       1
# swap was on /dev/sda5 during installation
UUID=97008cec-61f2-4923-8958-9deccb258ebf none            swap    sw              0       0
/dev/sr0        /media/cdrom0   udf,iso9660 user,noauto     0       0
/dev/sdb1       /mnt/pgdir      ext4    defaults        0 0
```
5.***Перезагрузите инстанс и убедитесь, что диск остается примонтированным***
```bash
root@pg:~# reboot
login as: root
root@172.**.**.***'s password:

Linux pg 6.1.0-16-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.67-1 (2023-12-12) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Sun Dec 24 05:53:10 2023 from 10.**.**.***

root@pg:~# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   50G  0 disk
├─sda1   8:1    0   49G  0 part /
├─sda2   8:2    0    1K  0 part
└─sda5   8:5    0  975M  0 part [SWAP]
sdb      8:16   0   50G  0 disk
└─sdb1   8:17   0   50G  0 part /mnt/pgdir
sr0     11:0    1  628M  0 rom
root@pg:~# mount | grep /mnt/pgdir
/dev/sdb1 on /mnt/pgdir type ext4 (rw,relatime)
```
6.***Сделайте пользователя postgres владельцем /mnt/data***
```bash
root@pg:~# chown -R postgres:postgres /mnt/pgdir
root@pg:~# pg_ctlcluster 15 main stop
root@pg:~# pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
```
7.***Перенесите содержимое /var/lib/postgres/15 в /mnt/data***
```bash
root@pg:~# mv /var/lib/postgresql/15 /mnt/pgdir
```
8.***Попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start***
```bash
root@pg:~# pg_ctlcluster 15 main start
Error: /var/lib/postgresql/15/main is not accessible or does not exist
```
:heavy_exclamation_mark:`Не запустился т.к. не поменяли параметр отвечающий за путь к каталогу с данными PostgreSQL.`

9.***Задание***
```
root@pg:~# vim /etc/postgresql/15/main/postgresql.conf

data_directory = '/mnt/pgdir/15/main'           # use data in another directory
```
>Поменял данный параметр, т.к. он отвечает за путь до каталога с данными PostgreSQL

10.***Попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start***
```bash
root@pg:~# pg_ctlcluster 15 main start
root@pg:~# pg_lsclusters
Ver Cluster Port Status Owner    Data directory     Log file
15  main    5432 online postgres /mnt/pgdir/15/main /var/log/postgresql/postgresql-15-main.log
```
:white_check_mark:`Получилось т.к. поменяли параметр отвечающий за путь к каталогу с данными PostgreSQL.`

11.***Зайдите через через psql и проверьте содержимое ранее созданной таблицы***
```bash
root@pg:~# sudo -u postgres psql
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# select * from my;
 name
-------
 yurii
(1 row)

```
12.***Задание со звездочкой. Небыло возможности перенести диск физически, по этому попытался примонтировать его удалённо через SSHFS***
```bash
root@pg1:~# pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 online postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
root@pg1:~# pg_ctlcluster 15 main stop
root@pg1:~# pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
15  main    5432 down   postgres /var/lib/postgresql/15/main /var/log/postgresql/postgresql-15-main.log
root@pg1:~# rm -rf /var/lib/postgresql/15/main/*
root@pg1:~# ls -lah /var/lib/postgresql/15/main/
total 8.0K
drwx------ 2 postgres postgres 4.0K Dec 24 07:47 .
drwxr-xr-x 3 postgres postgres 4.0K Dec 24 07:37 ..
root@pg1:~# sudo apt install sshfs
root@pg1:~# sudo sshfs postgres@172.**.**.***:/mnt/pgdir/15/main/ /var/lib/postgresql/15/main
sudo: unable to resolve host pg1: Name or service not known
postgres@172.**.**.***'s password:

root@pg1:~# pg_ctlcluster 15 main start
Job for postgresql@15-main.service failed because the service did not take the steps required by its unit configuration.
See "systemctl status postgresql@15-main.service" and "journalctl -xeu postgresql@15-main.service" for details.
root@pg1:~# systemctl status postgresql@15-main.service
× postgresql@15-main.service - PostgreSQL Cluster 15-main
     Loaded: loaded (/lib/systemd/system/postgresql@.service; enabled-runtime; preset: enabled)
     Active: failed (Result: protocol) since Sun 2023-12-24 07:55:24 AKST; 18s ago
   Duration: 57.291s
    Process: 11732 ExecStart=/usr/bin/pg_ctlcluster --skip-systemctl-redirect 15-main start (code=exited, status=1/FAILURE)
        CPU: 35ms
```
:heavy_exclamation_mark:`Не запустился, недостаточно прав у пользователя postgres.`

```bash
root@pg1:~# fusermount -u /var/lib/postgresql/15/main
root@pg1:~# ls -lah /var/lib/postgresql/15/main/
root@pg1:~# sudo sshfs -o allow_other postgres@172.16.2.218:/mnt/pgdir/15/main/ /var/lib/postgresql/15/main
sudo: unable to resolve host pg1: Name or service not known
postgres@172.**.**.***'s password:

root@pg1:~# pg_ctlcluster 15 main start
root@pg1:~# sudo -u postgres psql
sudo: unable to resolve host pg1: Name or service not known
could not change directory to "/root": Permission denied
psql (15.5 (Debian 15.5-1.pgdg120+1))
Type "help" for help.

postgres=# select * from my;
 name
-------
 yurii
(1 row)

postgres=# insert into my values('vladimir');
INSERT 0 1
postgres=# select * from my;
   name
----------
 yurii
 vladimir
(2 rows)
```
:white_check_mark:`Примонтировал с правами что бы и пользователь Postgre мог изменять файлы в каталоге который принадлежит ему.`

✨Magic ✨