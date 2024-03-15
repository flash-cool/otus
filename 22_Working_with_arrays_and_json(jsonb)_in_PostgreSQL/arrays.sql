-- Данный скрипт на языке PL/pgSQL используется для обработки данных в базе данных PostgreSQL. Он выполняет следующие действия:
-- 1. Выбирает данные из представлений v_Person_all и v_personstate, фильтруя их по определенным условиям.
-- 2. Группирует данные и формирует массивы server_id_arr_del и personevn_id_arr_del.
-- 3. Затем в цикле проходится по каждой записи и удаляет соответствующие записи в базе данных из таблицы dbo.personevn.
--
--Массивы в данном скрипте используются для хранения нескольких значений server_id и personevn_id, которые затем используются в циклах для выполнения операций удаления записей из базы данных для каждого person_id.
--
--Таким образом, использование массивов позволяет обрабатывать данные более эффективно и компактно, что упрощает выполнение множества операций над набором данных.

do $$
declare
	_r record;
	p_person_id int8;
	_personevn_id int8;
	p_server_id int8;
	p_id int8;
	_server_id int8;
begin
	for _r in (    
	        with dat as (
	            select pa.server_id, pa.person_id, pa.personevn_id, pa.person_ednum, row_number() over(partition by ps.lpu_id, pa.personevnclass_id, pa.person_id order by pa.personevn_id desc) as rn, dense_rank() over(order by 					 ps.lpu_id, pa.personevnclass_id, pa.person_id  asc) as grp_rn
	            from v_Person_all as pa
	            inner join v_personstate as ps on ps.person_id = pa.person_id and ps.personevn_id = ps.personevn_id
	            where pa.personevnclass_id = 16 and pa.person_id in (select distinct person_id from dbo.v_PersonPolisEdNum where PersonPolisEdNum_ednum in 
							('1989689747000118', '1987689731000027', '1991889780000076', '1992779723000094'))
	            ), c as (
	            select  person_id, array_agg(server_id) as server_id_arr, array_agg(personevn_id) as personevn_id_arr, array_agg(person_ednum) as person_ednum_arr
	            from dat as d
	            where d.grp_rn in (select grp_rn from dat where rn > 1)    
	            group by person_id
	            ), d as (
	            select person_id, server_id_arr[2:] as server_id_arr_del, personevn_id_arr[2:] as personevn_id_arr_del
	            from c
	            limit 2000   -- пачка
	            )
	            select row_number() over() as id, person_id, server_id_arr_del , personevn_id_arr_del, (select count(1) from d) as cnt_person
	            from d     
	        ) 
	loop
	         
    		p_person_id = _r.person_id;
    		p_id = _r.id;
	         
	  	foreach _personevn_id in array (_r.personevn_id_arr_del) 
	  	loop
	    		foreach _server_id in array (_r.server_id_arr_del) 
	    		loop
	         
	             delete from dbo.personevn where 
	             	person_id = p_person_id,
	                	server_id = _server_id,
	                	personevn_id = _personevn_id,
	                	pmuser_id = '1';
	                      
            end loop;
        end loop;
	 
        raise notice 'Обработано (%/%): person_id=%', p_id, _r.cnt_person, p_person_id;
	         
	end loop;
end;
$$ language plpgsql;   