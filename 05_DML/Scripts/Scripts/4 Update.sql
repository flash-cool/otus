update
set
where

drop table if exists film_and_actors_stat;

create table film_and_actors_stat
(actor_id int primary key, 
film_count int, 
first_film_id int, 
last_film_id int);

insert into film_and_actors_stat
(actor_id)
select actor_id
from actor;

select * from film_and_actors_stat;

update film_and_actors_stat
set film_count = 0;




select count(*)
from film_actor
where actor_id = 1;

select * from film_and_actors_stat;

update film_and_actors_stat
set film_count = 19
where actor_id = 1;

select film_count, (select count(*)
	from film_actor as fa
	where fa.actor_id = film_and_actors_stat.actor_id)
from film_and_actors_stat 
where actor_id in (2,3,4);

update film_and_actors_stat
set film_count = (select count(*)
	from film_actor as fa
	where fa.actor_id = film_and_actors_stat.actor_id)
where actor_id in (2,3,4);

select *
from film_and_actors_stat
where film_count > 0;

alter table film_and_actors_stat add column actor_name varchar(100);

update film_and_actors_stat
set actor_name = first_name || ' ' || last_name
from actor
where film_and_actors_stat.actor_id = actor.actor_id;

update film_and_actors_stat
set film_count = fa.cnt,
	first_film_id = fa.min_film_id, 
	last_film_id = fa.max_film_id
from (select actor_id, count(*) as cnt, MIN(film_id) as min_film_id, MAX(film_id) as max_film_id
	from film_actor 
	group by actor_id)
	as fa	
where fa.actor_id = film_and_actors_stat.actor_id
returning film_and_actors_stat.actor_id, film_and_actors_stat.film_count;

select *
from film_and_actors_stat;

alter table film_and_actors_stat add column film_count2 int;

select * 
from film_and_actors_stat
where actor_id = 1;



update film_and_actors_stat
set film_count = film_count + 1,
	film_count2 = film_count
where actor_id = 1;

