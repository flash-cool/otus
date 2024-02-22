# Виды индексов. Работа с индексами и оптимизация запросов 
_____

- Цели
  - Знать и уметь применять основные виды индексов PostgreSQL.
    - Строить и анализировать план выполнения запроса.
	  - Уметь оптимизировать запросы с использованием индексов.
  
1.***Создать индекс к какой-либо из таблиц вашей БД***
```sql
indexdz=# CREATE INDEX ON index_test_table(random_num);
CREATE INDEX
indexdz=# ANALYZE index_test_table;
ANALYZE
```
2.***Прислать текстом результат команды explain, в которой используется данный индекс.***
```sql
indexdz=# EXPLAIN SELECT * FROM index_test_table WHERE random_num = 150;
                                               QUERY PLAN
--------------------------------------------------------------------------------------------------------
 Index Scan using index_test_table_random_num_idx on index_test_table  (cost=0.29..8.31 rows=1 width=7)
   Index Cond: (random_num = 150)
(2 rows)

```
>Для поиска используется Index Scan по созданному индексу random_num_idx

3.***Реализовать индекс для полнотекстового поиска.***
```sql
indexdz=# CREATE INDEX idx_tsvector ON articles USING gin
(content_tsvector);
CREATE INDEX
indexdz=# ANALYZE articles;
ANALYZE
indexdz=# EXPLAIN SELECT title, content FROM articles WHERE content_tsvector @@
to_tsquery('english', 'PostgreSQL & full-text');
                                                  QUERY PLAN
---------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on articles  (cost=20.01..24.02 rows=1 width=86)
   Recheck Cond: (content_tsvector @@ '''postgresql'' & ''full-text'' <-> ''full'' <-> ''text'''::tsquery)
   ->  Bitmap Index Scan on idx_tsvector  (cost=0.00..20.01 rows=1 width=0)
         Index Cond: (content_tsvector @@ '''postgresql'' & ''full-text'' <-> ''full'' <-> ''text'''::tsquery)
(4 rows)
```
>Для поиска используется Index Scan по созданному индексу idx_tsvector, потом проходится ещё раз для подтверждения.

4.***Реализовать индекс на часть таблицы или индекс на поле с функцией.***
```sql
indexdz=# CREATE INDEX idx_up ON index_test_table(UPPER(random_text));
CREATE INDEX
indexdz=# ANALYZE index_test_table;
ANALYZE
indexdz=# EXPLAIN ANALYZE SELECT * FROM index_test_table WHERE UPPER(random_text) =
'D';
                                                        QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on index_test_table  (cost=24.64..499.29 rows=2110 width=7) (actual time=0.066..0.187 rows=2145 loops=1)
   Recheck Cond: (upper(random_text) = 'D'::text)
   Heap Blocks: exact=12
   ->  Bitmap Index Scan on idx_up  (cost=0.00..24.12 rows=2110 width=0) (actual time=0.059..0.059 rows=2145 loops=1)
         Index Cond: (upper(random_text) = 'D'::text)
 Planning Time: 0.119 ms
 Execution Time: 0.248 ms
(7 rows)
```
>Для поиска используется Index Scan по созданному индексу idx_up на заглавные буквы.

5.***Создать индекс на несколько полей.***
```sql
indexdz=# CREATE INDEX ON index_test_table(random_num, random_text);
CREATE INDEX
indexdz=# ANALYZE index_test_table;
ANALYZE
indexdz=# EXPLAIN SELECT * FROM index_test_table WHERE random_num <= 194 AND
random_text = 'Z';
                                                QUERY PLAN
----------------------------------------------------------------------------------------------------------
 Bitmap Heap Scan on index_test_table  (cost=6.30..13.93 rows=2 width=7)
   Recheck Cond: ((random_num <= 194) AND (random_text = 'Z'::text))
   ->  Bitmap Index Scan on index_test_table_random_num_random_text_idx  (cost=0.00..6.30 rows=2 width=0)
         Index Cond: ((random_num <= 194) AND (random_text = 'Z'::text))
(4 rows)
```
>Для поиска используется Index Scan по созданному индексу index_test_table_random_num_random_text_idx по двум столбцам.


✨Magic ✨

