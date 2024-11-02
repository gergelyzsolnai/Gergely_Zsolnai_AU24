--TASK 1
--1. inserting my 3 fav movies.
INSERT INTO film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating)
	VALUES ('The Godfather', 'The aging patriarch of an organized crime dynasty transfers control of his clandestine empire to his reluctant son.',
			1972, 1, 1, 4.99, 175, 19.99, 'R'),
			('The Shawshank Redemption', 'A banker convicted of uxoricide forms a friendship over a quarter century with a hardened convict, while maintaining his innocence and trying to remain hopeful through simple compassion.',
			1994, 1, 2, 9.99, 142, 29.99, 'R'),
			('Meet Joe Black', 'Death, who takes the form of a young man killed in an accident, asks a media mogul to act as his guide to teach him about life on Earth and, in the process, he falls in love with the mogul''s daughter.',
			1998, 1, 3, 19.99, 178, 29.99, 'PG')
	ON CONFLICT DO NOTHING
	RETURNING film_id;
COMMIT;

--I did not use film_ids, because it generates new ones.


--2. insterting 6 actors
INSERT INTO actor (first_name, last_name)
	VALUES ('Marlon', 'Brando'),
			('Al', 'Pacino'),
			('Tim', 'Robbins'),
			('Morgan', 'Freeman'),
			('Brad', 'Pitt'),
			('Anthony', 'Hopkins')
	ON CONFLICT DO NOTHING
	RETURNING actor_id;

--I did not use film_ids, because it generates new ones.

--3. Make connections between film and actor tables:
INSERT INTO film_actor (actor_id, film_id)
SELECT 
	actor.actor_id, 
	film.film_id
FROM 
	actor
JOIN film 	ON (film.title = 'The Godfather' AND actor.first_name = 'Marlon' AND actor.last_name = 'Brando')
           	OR (film.title = 'The Godfather' AND actor.first_name = 'Al' AND actor.last_name = 'Pacino')
           	OR (film.title = 'The Shawshank Redemption' AND actor.first_name = 'Tim' AND actor.last_name = 'Robbins')
           	OR (film.title = 'The Shawshank Redemption' AND actor.first_name = 'Morgan' AND actor.last_name = 'Freeman')
           	OR (film.title = 'Meet Joe Black' AND actor.first_name = 'Brad' AND actor.last_name = 'Pitt')
           	OR (film.title = 'Meet Joe Black' AND actor.first_name = 'Anthony' AND actor.last_name = 'Hopkins')
ON CONFLICT DO NOTHING;

--4. Adding movies to inventory:
INSERT INTO inventory (film_id, store_id)
SELECT 
	film_id, 
	2
FROM
	film
WHERE title IN ('The Godfather', 'The Shawshank Redemption', 'Meet Joe Black')
RETURNING inventory_id;
			
--5. Updating a customer to my datas: 87-id
UPDATE customer
	SET
		first_name = 'Gergely',
		last_name = 'Zsolnai',
		email = 'zsolnai.gergely84@gmail.com'
	WHERE customer_id = 87;
	
--6. Removing any records related to me (as a customer) from all tables except 'Customer' and 'Inventory'
BEGIN;
DELETE 
FROM 
	payment
WHERE 
	rental_id IN (
	SELECT 
		rental_id
	FROM
		rental
	WHERE
		customer_id = 87);

DELETE 
FROM 
	rental
WHERE 
	customer_id = 87;
COMMIT;

--I had to do it that way, because I couldn't delete one-by-one, because these 2 tables' records were
--linked together by their foreign keys. Had to do it together.

--7. Rent you favorite movies from the store they are in and pay for them (add corresponding records to the 
--database to represent this activity) 
--(Note: to insert the payment_date into the table payment, you can create a new partition 
--(see the scripts to install the training database ) or add records for the first half of 2017)

INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, last_update)
			VALUES 	('2017-02-14 13:45:21.914+01', 4582, 87, 2, current_date),
					('2017-02-14 13:46:21.914+01', 4583, 87, 2, current_date),
					('2017-02-14 13:46:21.914+01', 4584, 87, 2, current_date)
			RETURNING rental_id;

INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date, last_update)
			VALUES 	(87, 2, 32296, 4.99, '2017-02-14 13:45:21.914+01', current_date),
					(87, 2, 32297, 9.99, '2017-02-14 13:46:21.914+01', current_date),
					(87, 2, 32298, 19.99, '2017-02-14 13:46:21.914+01', current_date)
			RETURNING payment_id;

--I had to insert the new records to these 2 tables. Rental table, because we needed the rental datas
--The payment table, because i paid for the rented movies. I used the newly generated inventory_ids, and rental_ids.

