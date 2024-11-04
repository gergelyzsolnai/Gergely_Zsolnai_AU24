--TASK 1
--1. Inserting my top 3 movies 
--2. Inserting my top 3 movies with their data
--3. Inserting the actors and film_id and actor_id to the film_actor table
--4. Inserting movies to the inventory table
--I do the 4 tasks all at once, because i need their ids 
ROLLBACK;
BEGIN;

WITH my_top_films AS (
	INSERT INTO film (title, description, release_year, language_id, rental_duration, rental_rate,
						length, replacement_cost, rating, last_update)
	VALUES ('The Godfather', 'The aging patriarch of an organized crime dynasty transfers control of his clandestine empire to his reluctant son.',
			1972, 1, 1, 4.99, 175, 19.99, 'R', CURRENT_DATE),
			('The Shawshank Redemption', 'A banker convicted of uxoricide forms a friendship over a quarter century with a hardened convict, while maintaining his innocence and trying to remain hopeful through simple compassion.',
			1994, 1, 2, 9.99, 142, 29.99, 'R', CURRENT_DATE),
			('Meet Joe Black', 'Death, who takes the form of a young man killed in an accident, asks a media mogul to act as his guide to teach him about life on Earth and, in the process, he falls in love with the mogul''s daughter.',
			1998, 1, 3, 19.99, 178, 29.99, 'PG', CURRENT_DATE)
	RETURNING film_id, title
),
my_top_actors AS(
	INSERT INTO actor (first_name, last_name, last_update)
	VALUES 	
		('Marlon', 'Brando', CURRENT_DATE),
		('Al', 'Pacino', CURRENT_DATE),
		('Tim', 'Robbins', CURRENT_DATE),
		('Morgan', 'Freeman', CURRENT_DATE),
		('Brad', 'Pitt', CURRENT_DATE),
		('Anthony', 'Hopkins', CURRENT_DATE)
	RETURNING actor_id, first_name, last_name
), 
my_top_film_actor AS (
	INSERT INTO film_actor (film_id, actor_id, last_update)
		SELECT mtf.film_id, actor_id, CURRENT_DATE
		FROM my_top_films mtf
		JOIN my_top_actors mta 
		ON (mtf.title = 'The Godfather' AND mta.first_name = 'Marlon' AND mta.last_name = 'Brando')
		OR (mtf.title = 'The Godfather' AND mta.first_name = 'AL' AND mta.last_name = 'Pacino')
		OR (mtf.title = 'The Shawshank Redemption' AND mta.first_name = 'Tim' AND mta.last_name = 'Robbins')
		OR (mtf.title = 'The Shawshank Redemption' AND mta.first_name = 'Morgan' AND mta.last_name = 'Freeman')
		OR (mtf.title = 'Meet Joe Black' AND mta.first_name = 'Brad' AND mta.last_name = 'Pitt')
		OR (mtf.title = 'Meet Joe Black' AND mta.first_name = 'Anthony' AND mta.last_name = 'Hopkins')
	WHERE NOT EXISTS (
		SELECT 1 FROM film_actor fa
		WHERE mtf.film_id = fa.film_id AND mta.actor_id = fa.actor_id
	)
	RETURNING film_id, actor_id
)

INSERT INTO inventory (film_id, store_id)
	SELECT film_id, 2
	FROM
	my_top_films mtf
	WHERE NOT EXISTS (
	SELECT 1 FROM inventory i
	WHERE mtf.film_id = i.film_id AND i.store_id = 2
	)
RETURNING inventory_id;

COMMIT;

--I had to insert the movies and actor together, because i needed their film_id, and actor_id to grab them, 
--and insert them to the film_actor table. 
--I didn't want to hardcode, so i used Returning: 
-- - for film_id and title together, because it will be needed for film_actor and inventory table. 
-- - for actor_id, first_name, and last_name, because i needed them for film_actor table
--I Used Begin, because i had to do the inserting all at once, but step-by-step, and the Commit for saving
--purposes.
--WHERE NOT EXISTS checks if the same ids (film_id with actor_id) and (film_id and store_id) combined are already in the database
--And the end i start my last insertion to the inventory table, using the film_id, inserting to store_id 2.
--I check if there is any film_id and store_id combined together and exists in the database. 
		
--5. Updating a customer to my datas: 87-id
UPDATE customer
SET
	first_name = 'Gergely',
	last_name = 'Zsolnai',
	email = 'zsolnai.gergely84@gmail.com'
WHERE 
	customer_id = 87;
	
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
			customer_id = 87
		);

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

ROLLBACK;
BEGIN;

WITH fav_movies_inv AS (
    SELECT 
        i.inventory_id, 
        f.title,
		f.rental_rate
    FROM 
        inventory i
    JOIN 
        film f ON i.film_id = f.film_id
    WHERE 
        f.title IN ('The Godfather', 'The Shawshank Redemption', 'Meet Joe Black')
        AND i.store_id = 2
),

my_rentals AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, last_update)
    SELECT
        CASE 
            WHEN fmi.title = 'The Godfather' THEN TIMESTAMP '2017-02-15 13:45:21.914+01'
            WHEN fmi.title = 'The Shawshank Redemption' THEN TIMESTAMP '2017-02-15 13:46:21.914+01'
            WHEN fmi.title = 'Meet Joe Black' THEN TIMESTAMP '2017-02-15 13:46:21.914+01'
        END AS rental_date,
        fmi.inventory_id,
        87 AS customer_id,
        2 AS staff_id,
        CURRENT_DATE
    FROM fav_movies_inv fmi
    RETURNING rental_id, inventory_id, rental_date
)

INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 
    87 AS customer_id,
    2 AS staff_id,
    mr.rental_id,
	fmi.rental_rate AS amount,
    mr.rental_date AS payment_date
FROM 
    my_rentals mr
JOIN 
    fav_movies_inv fmi ON mr.inventory_id = fmi.inventory_id;

COMMIT;

--I made the fav_movies_inv CTE to get the inventory_id, title, (and rental_rate, which i need in the end) which i used in my_rentals
--table, which i want to insert in CTE. I get the rental_id, and rental_date for my inserted payment table.
--I use the rental_id, and rental_date for payment_date and i use the rental_rates' of the movies, so i can
--get the amount.