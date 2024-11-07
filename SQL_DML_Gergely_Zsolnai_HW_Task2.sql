--TASK 2

--1. Create table_to_delete
 CREATE TABLE table_to_delete AS
               SELECT 'veeeeeeery_long_string' || x AS col
               FROM generate_series(1,(10^7)::int) x; 
-- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)
COMMIT;
--2. Lookup how much space this table consumes with the following query:

SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%'; 
--302msec
COMMIT;
--3. 
DELETE FROM table_to_delete
               WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; 
-- removes 1/3 of all rows

--a) DELETE 3333333 
--   Query returned successfully in 16 secs 212 msec.

--b) Lookup how much space this table consumes after previous DELETE;
SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';
--103 msec
"16858"	"public"	"table_to_delete"	6.666325e+06	602611712	0	8192	602603520	"575 MB"	"0 bytes"	"8192 bytes"	"575 MB"

--c)  Perform the following command (if you're using DBeaver, press Ctrl+Shift+O to observe server output (VACUUM results)): 
               --VACUUM FULL VERBOSE table_to_delete;

VACUUM FULL VERBOSE table_to_delete;

--INFO:  vacuuming "public.table_to_delete"
--INFO:  "public.table_to_delete": found 0 removable, 6666667 nonremovable row versions in 73536 pages
--VACUUM

--Query returned successfully in 8 secs 464 msec.

--d) Check space consumption of the table once again and make conclusions;
--The deletion took 16 seconds, so it took a while when it finished. It did not save us much extra storage space, 
--and deletion was slow. But after VACUUM FULL VERBOSE, the deletion took half of the time, and made a lot of free
--storage space, but it did not delete any, it just saved us a lot of free space.

--e) Recreate ‘table_to_delete’ table;

CREATE TABLE table_to_delete AS
	SELECT 
		'veeeeeeery_long_string' || x AS col
	FROM 
		generate_series(1,(10^7)::int) x;

--I couldn't recreate the table, because it already exists. I did not delete the table

--4. Issue the following TRUNCATE operation:

TRUNCATE table_to_delete;
--a) Note how much time it takes to perform this TRUNCATE statement.
--It took 604 msec

--b) Compare with previous results and make conclusion.
--It took way less time to delete the data, so TRUNCATE is faster. Also it also clears storage space. 
--SO we get the same result as with DELETE and VACUUM, just you get the result with one command, and it is
--faster!

--c) Check space consumption of the table once again and make conclusions;
--"16845"	"public"	"table_to_delete"	-1	8192	0	8192	0	"8192 bytes"	"0 bytes"	"8192 bytes"	"0 bytes"
--We got fully free storage space, so with TRUNCATE, we cleared the table
--Efficient: Faster, and more efficient than DELETE.
--We do not need VACUUM

--5. Hand over your investigation's results to your trainer. The results must include:
--a) Space consumption of ‘table_to_delete’ table before and after each operation;
DROP TABLE IF EXISTS table_to_delete;
--"16858"	"public"	"table_to_delete"	-1	602464256	0	8192	602456064	"575 MB"	"0 bytes"	"8192 bytes"	"575 MB"
--Table contains 575 MB
--After DELETE command, we did not free any space, it is the same, 575 MB.
--After VACUUM FULL VERBOSE it compressed to half its original size, 383 MB.
--After TRUNCATE command deleted all the data, and did free all the space, table size is 0 bytes.

--b) Duration of each operation (DELETE, TRUNCATE)
--Creating table took 23 secs 899 msec.
--DELETE command took 22 sec 387 msec
--VACUUM FULL VERBOSE command took 12 sec 589 msec
--TRUNCATE command returned in 98 msec, very very fast command