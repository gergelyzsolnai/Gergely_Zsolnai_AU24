BEGIN;
WITH my_top_films AS (
	SELECT 
		'The Godfather' as title, 
		'The aging patriarch of an organized crime dynasty transfers control of his clandestine empire to his reluctant son.' as description,
		1972 as release_year, 
		(SELECT l.language_id FROM "language" AS l WHERE l."name" = 'English') AS language_id,
		1 as rental_duration, 
		4.99 as rental_rate, 
		175 as length, 
		19.99 as replacement_cost, 
		CURRENT_DATE as last_update
		UNION ALL
	SELECT
		'The Shawshank Redemption' AS title, 
		'A banker convicted of uxoricide forms a friendship over a quarter century with a hardened convict, while maintaining his innocence and trying to remain hopeful through simple compassion.' AS description,
		1994 AS release_year, 
		(SELECT l.language_id FROM "language" AS l WHERE l."name" = 'English') AS language_id,
		2 AS rental_duration, 
		9.99 AS rental_rate, 
		142 AS length, 
		29.99 AS replacement_cost, 
		CURRENT_DATE AS last_update
		UNION ALL
	SELECT	
		'Meet Joe Black' AS title, 
		'Death, who takes the form of a young man killed in an accident, asks a media mogul to act as his guide to teach him about life on Earth and, in the process, he falls in love with the mogul''s daughter.' AS description,
		1998 AS release_year, 
		(SELECT l.language_id FROM "language" AS l WHERE l."name" = 'English') AS language_id,
		3 AS rental_duration, 
		19.99 AS rental_rate, 
		178 AS length, 
		29.99 AS replacement_cost, 
		CURRENT_DATE AS last_update
),
inserted_movies AS ( 
	INSERT INTO film (title, description, release_year, language_id, rental_duration, rental_rate,
						length, replacement_cost, last_update)
		SELECT 
			mtf.title,
			mtf.description, 
			mtf.release_year, 
			mtf.language_id, 
			mtf.rental_duration, 
			mtf.rental_rate,
			mtf.length, 
			mtf.replacement_cost, 
			mtf.last_update
		FROM 
			my_top_films mtf
		WHERE 
			NOT EXISTS (
				SELECT *
				FROM film AS f
				WHERE f.title = mtf.title AND f.release_year = mtf.release_year
			)
		RETURNING film_id, title
),
my_top_actors AS(
	SELECT 
		'Marlon' AS first_name, 
		'Brando' AS last_name, 
		CURRENT_DATE AS last_update
		UNION ALL
	SELECT
		'Al' AS first_name, 
		'Pacino' AS last_name, 
		CURRENT_DATE AS last_update
		UNION ALL
	SELECT
		'Tim' AS first_name, 
		'Robbins' AS last_name, 
		CURRENT_DATE AS last_update
		UNION ALL
	SELECT
		'Morgan' AS first_name, 
		'Freeman' AS last_name, 
		CURRENT_DATE AS last_update
		UNION ALL
	SELECT
		'Brad' AS first_name, 
		'Pitt' AS last_name, 
		CURRENT_DATE AS last_update
		UNION ALL
	SELECT
		'Anthony' AS first_name, 
		'Hopkins' AS last_name, 
		CURRENT_DATE AS last_update
), 
inserted_actors AS ( 
	INSERT INTO actor (first_name, last_name, last_update)
		SELECT 
			mta.first_name, 
			mta.last_name, 
			mta.last_update
		FROM
			my_top_actors mta
		WHERE 
			NOT EXISTS (
				SELECT *
				FROM actor AS a
				WHERE a.first_name = mta.first_name AND a.last_name = mta.last_name
			)
		RETURNING actor_id, first_name, last_name
),
my_top_film_actor AS (
	INSERT INTO film_actor (film_id, actor_id, last_update)
		SELECT 
		im.film_id, 
		ia.actor_id, 
		CURRENT_DATE
		FROM inserted_movies im
		JOIN inserted_actors ia 
		ON (im.title = 'The Godfather' AND ia.first_name = 'Marlon' AND ia.last_name = 'Brando')
		OR (im.title = 'The Godfather' AND ia.first_name = 'AL' AND ia.last_name = 'Pacino')
		OR (im.title = 'The Shawshank Redemption' AND ia.first_name = 'Tim' AND ia.last_name = 'Robbins')
		OR (im.title = 'The Shawshank Redemption' AND ia.first_name = 'Morgan' AND ia.last_name = 'Freeman')
		OR (im.title = 'Meet Joe Black' AND ia.first_name = 'Brad' AND ia.last_name = 'Pitt')
		OR (im.title = 'Meet Joe Black' AND ia.first_name = 'Anthony' AND ia.last_name = 'Hopkins')
	WHERE NOT EXISTS (
		SELECT 1 FROM film_actor fa
		WHERE im.film_id = fa.film_id AND ia.actor_id = fa.actor_id
	)
	RETURNING film_id, actor_id
),
inserted_inventory AS (
	INSERT INTO inventory (film_id, store_id)
	SELECT 
		im.film_id,
		(SELECT store_id FROM store ORDER BY store_id LIMIT 1)
	FROM
		inserted_movies im
	WHERE 
		NOT EXISTS (
		SELECT 1 FROM inventory i
	WHERE im.film_id = i.film_id AND i.store_id = (SELECT store_id FROM store ORDER BY store_id LIMIT 1)
		)
	RETURNING inventory_id
	)
SELECT * FROM inserted_inventory;
SAVEPOINT inserted_movies_actors_inventory;
COMMIT;



BEGIN;
WITH find_customer AS (
	SELECT 
		c.customer_id
	FROM
		customer c
	JOIN payment p 
		ON c.customer_id = p.customer_id
	JOIN rental r
		ON p.customer_id = r.customer_id
	GROUP BY 
		c.customer_id
	HAVING 
		COUNT(DISTINCT r.rental_id) >= 43 AND
		COUNT(DISTINCT p.payment_id)>= 43
	LIMIT 1
),
updated_customer AS (
	UPDATE customer 
	SET
		first_name = 'Gergely',
		last_name = 'Zsolnai',
		email = 'zsolnai.gergely84@gmail.com',
		address_id = (SELECT address_id 
				  	FROM address 
				  	WHERE district = 'Texas'
				  	LIMIT 1)
	WHERE 
		customer_id = (SELECT customer_id FROM find_customer)
	RETURNING customer_id
),
deleted_payments AS (
DELETE FROM 
	payment
WHERE 
	rental_id IN (
		SELECT 
			rental_id
		FROM
			rental
		WHERE
			customer_id = (SELECT customer_id FROM find_customer)
		) 
	RETURNING payment_id
),
deleted_rentals AS (
DELETE FROM
	rental
WHERE 
	customer_id = (SELECT customer_id FROM find_customer)
RETURNING rental_id
),

fav_movies_inv AS (
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
        AND i.store_id = (SELECT store_id FROM store ORDER BY store_id LIMIT 1)
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
        (SELECT customer_id FROM find_customer) AS customer_id,
        (SELECT staff_id FROM staff ORDER BY store_id LIMIT 1) AS staff_id,
        CURRENT_DATE AS last_update
    FROM fav_movies_inv fmi
    RETURNING rental_id, inventory_id, rental_date
)

INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 
    (SELECT customer_id FROM find_customer) AS customer_id,
    (SELECT staff_id FROM staff ORDER BY store_id LIMIT 1) AS staff_id,
    mr.rental_id,
	fmi.rental_rate AS amount,
    mr.rental_date AS payment_date
FROM 
    my_rentals mr
JOIN 
    fav_movies_inv fmi ON mr.inventory_id = fmi.inventory_id;
SAVEPOINT inserting_my_rentals_payments;
COMMIT;

