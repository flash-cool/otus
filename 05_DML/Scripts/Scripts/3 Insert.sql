select *
from public.actor
where first_name like 'Tes%';

INSERT INTO public.actor
(first_name, last_name, last_update)
values ('Test', 'Test', default);

INSERT INTO public.actor
(actor_id, first_name, last_name, last_update)
VALUES(default, 'Test', 'Test', now()),
	  (default, 'Test2', 'Test2', '2023-01-12');	 
	 
INSERT INTO public.actor
VALUES(default,  'Test', 'Test', now());

INSERT INTO public.actor(first_name, last_name)
VALUES('Test10', 'Test10');

-- fail
INSERT INTO public.actor
VALUES('Test', 'Test', now());

INSERT INTO public.actor
(first_name, last_name, last_update)
VALUES('Test11', 'Test11', default),
('Test12', 'Test12', default)
returning actor_id, first_name;

----
drop table if exists film2;

create table film2 as 
select *
from film;

drop table if exists film2;

select * into film2
from film;
---

drop table if exists film_and_actors;

create table film_and_actors as 
select actor.actor_id, actor.first_name, actor.last_name, film.film_id, film.title as film_title
from actor
	join film_actor
		on film_actor.actor_id = actor.actor_id
	join film 
		on film.film_id = film_actor.film_id
where film.film_id IN (3,25,188);

select * from film_and_actors

insert into film_and_actors
(actor_id, first_name, last_name, film_id, film_title)
select actor.actor_id, actor.first_name, actor.last_name, film.film_id, film.title
from actor
	join film_actor
		on film_actor.actor_id = actor.actor_id
	join film 
		on film.film_id = film_actor.film_id
where film.film_id IN (150);


insert into film_and_actors
(actor_id, first_name, last_name, film_id, film_title)
select actor.actor_id, actor.first_name, actor.last_name, film.film_id, film.title
from actor
	join film_actor
		on film_actor.actor_id = actor.actor_id
	join film 
		on film.film_id = film_actor.film_id
where film.film_id IN (200)
returning actor_id, first_name;

alter table film_and_actors ADD PRIMARY key (actor_id, film_id);

select count(*)
select *
from film_and_actors;

insert into film_and_actors
(actor_id, first_name, last_name, film_id, film_title)
select actor.actor_id, actor.first_name, actor.last_name, film.film_id, film.title
from actor
	join film_actor
		on film_actor.actor_id = actor.actor_id
	join film 
		on film.film_id = film_actor.film_id
where film.film_id IN (200, 201)
on conflict do nothing
returning actor_id, first_name;

select *
from film_and_actors;

alter table film_and_actors add column updated TIMESTAMP;

select count(*)
from film_and_actors
where updated is not null;

insert into film_and_actors
(actor_id, first_name, last_name, film_id, film_title)
select actor.actor_id, actor.first_name, actor.last_name, film.film_id, film.title
from actor
	join film_actor
		on film_actor.actor_id = actor.actor_id
	join film 
		on film.film_id = film_actor.film_id
where film.film_id IN (200, 202)
on conflict (actor_id, film_id)  do 
update 
	set updated = NOW()
returning actor_id, first_name;

select count(*)
from film_and_actors
where updated is not null;

delete from public.actor
where first_name like 'Test%';

drop table if exists film2;
drop table if exists film_and_actors;
