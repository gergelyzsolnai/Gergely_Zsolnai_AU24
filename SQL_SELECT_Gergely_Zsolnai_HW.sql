--PART 1
--All animation movies released between 2017 and 2019 with rate more than 1, alphabetical
SELECT 
f.title, 
f.release_year, 
f.rental_rate
FROM 
film f
INNER JOIN film_category fc ON f.film_id = fc.film_id
INNER JOIN category c ON fc.category_id = c.category_id
WHERE 
UPPER(c.name) = 'ANIMATION' 
AND f.release_year BETWEEN 2017 AND 2019
AND f.rental_rate > 1
ORDER BY 
f.title ASC;

--COMMENT: I joined the film_category to find the film_id. It finds the film_id and also its' category_id. 
--I joined the category table by the category_id. I search for the Animation category name by c.name, 
--between 2017 and 2019 on the f.release_year, and also i filtered that i only need those movies, which rental_rate is above 1$.

--The revenue earned by each rental store since March 2017 (columns: address and address2 – as one column, revenue)
SELECT 
a.address_id, 
a.address,
st.store_id,
SUM(p.amount) AS revenue
FROM 
address a
JOIN staff st ON a.address_id = st.address_id
JOIN rental r ON st.staff_id = r.staff_id
JOIN payment p ON r.rental_id = p.rental_id
WHERE 
p.payment_date >= '2017-03-01'
GROUP BY 
a.address_id,
st.store_id
ORDER BY 
revenue DESC;

--COMMENT: Honestly, i am confused. I don't think it's good solution either. One store_id has to have
--only 1 address_id, but it is not the same address_id that the staff used.  

--Top-5 actors by number of movies (released since 2015) they took part in 
--(columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
SELECT 
a.actor_id,
a.first_name, 
a.last_name, 
COUNT(f.film_id) AS number_of_movies 
FROM 
actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
WHERE 
f.release_year >= 2015
GROUP BY 
a.actor_id,
a.first_name, 
a.last_name
ORDER BY 
number_of_movies DESC 
LIMIT 5;

--Number of Drama, Travel, Documentary per year 
--(columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), 
--sorted by release year in descending order. Dealing with NULL values is encouraged)

SELECT 
f.release_year, 
COUNT(CASE WHEN c.name = 'Drama' THEN 1 END) AS number_of_drama_movies,
COUNT(CASE WHEN c.name = 'Travel' THEN 1 END) AS number_of_travel_movies,
COUNT(CASE WHEN c.name = 'Documentary' THEN 1 END) AS number_of_documentary_movies
FROM 
film f
INNER JOIN film_category fc ON f.film_id = fc.film_id
INNER JOIN category c ON fc.category_id = c.category_id
WHERE 
c.name IN('Drama', 'Travel', 'Documentary')
GROUP BY 
f.release_year
ORDER BY 
f.release_year DESC;

--For each client, display a list of horrors that he had ever rented (in one column, separated by commas), 
--and the amount of money that he paid for it

SELECT 
cr.first_name || ' ' || cr.last_name AS client_name, 
STRING_AGG(DISTINCT f.title, ', ') AS horror_movies, 
SUM(p.amount) AS amount_paid
FROM 
category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN customer cr ON r.customer_id = cr.customer_id
JOIN payment p ON cr.customer_id = p.customer_id 
AND r.rental_id = p.rental_id
JOIN film f ON i.film_id = f.film_id
WHERE 
UPPER(c.name) = 'HORROR'
GROUP BY 
cr.first_name, 
cr.last_name;

--I joined a lot of tables together, because i had to get the customers and their rentals, and payments, but 
--first of all, i needed to get the Horror category filtered, so i needed to join film_category table too.
--I had to do a combined join payment and custumer by the custumer_id, so i fix the customer and 
--i search for the rental_id, which connects to the payment table where it finds only that rental_id.

--PART 2
--1. Which three employees generated the most revenue in 2017? They should be awarded a bonus for their 
--outstanding performance. 
--Assumptions: 
	--staff could work in several stores in a year, please indicate which store the staff worked in 
	--(the last one);
	--if staff processed the payment then he works in the same store; 
	--take into account only payment_date

WITH 
laststore 
AS (
SELECT 
staff.staff_id, 
staff.store_id, 
MAX(p.payment_date) last_payment_date
FROM 
staff
JOIN payment p ON staff.staff_id = p.staff_id
WHERE 
p.payment_date BETWEEN '2017-01-01' AND '2017-12-31'
GROUP BY 
staff.staff_id, 
staff.store_id
)

SELECT 
staff.first_name || ' ' || staff.last_name AS full_name, 
l.store_id AS store,
SUM(p.amount) AS revenue
FROM 
laststore l
JOIN staff ON l.staff_id = staff.staff_id
JOIN payment p ON staff.staff_id = p.staff_id
WHERE 
l.store_id = staff.store_id
GROUP BY 
staff.first_name,
staff.last,
l.store_id
ORDER BY revenue DESC
LIMIT 3;

--I used CTE so i can filter only the last payment by the MAX(p.payment_date) in an other place, and i can reference for these results
--so i will get their last store, where they got payment so they worked last in that store, and i will 
--filter only those payments where they accepted payments.

--2. Which 5 movies were rented more than others (number of rentals), and what's the expected age of 
--the audience for these movies? 
--To determine expected age please use 'Motion Picture Association film rating system

SELECT 
f.title AS movie_name, 
COUNT(r.rental_id) AS rentals, 
f.rating AS mpa_rating_system,
CASE 
WHEN f.rating = 'G' THEN 'General Audiences'
WHEN f.rating = 'PG' THEN 'Parental Guidance Suggested'
WHEN f.rating = 'PG-13' THEN '13+'
WHEN f.rating = 'R' THEN 'Restricted'
WHEN f.rating = 'NC-17' THEN '18+'
ELSE 
'Not Rated'
END AS 
expected_age
FROM 
film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY 
f.title, 
mpa_rating_system
ORDER BY 
rentals DESC
LIMIT 5;

--I joined the inventory and the rental tables, because i needed to count the rentals of a movie. 
--I chose CTL to get the restrictions of the codes of Motion Picture Association film rating system.
--I did not write exact ages, becasue i did not find it completely accurate. But i write here: 
--G is for general ages, PG is below 13 and need a parental guide, R is restricted for under 17, only with adults.
--I left Else for "Not rated" categories. I grouped by the movie title, and the mpa_rating_system so i aggregarate
--them. Ordering by the rental counts, which i did with COUNT(r.rental_id)

--Part 3. Which actors/actresses didn't act for a longer period of time than the others? 
--The task can be interpreted in various ways, and here are a few options:
--V1: gap between the latest release_year and current year per each actor;

SELECT 
a.first_name || ' ' || a.last_name AS actor_name, 
EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS year_gap
FROM 
actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
GROUP BY 
a.first_name,
a.last_name
ORDER BY 
year_gap DESC
LIMIT 10;

--I had to join actor, film_actor and film tables, because i had to find the movies' released years and
--link the actor to the movie, and also i get the actors' names. 
--The Extrat method i get the year from todays' date and i subtract the newest movie year. I get the year_gap.
--I get it by the MAX(f.release_year). I find the latest movie year. I group by the actor_name, and 
--i order by the year_gap.

--V2: gaps between sequential films per each actor; 

WITH
actor_movies
AS
(
SELECT
a.actor_id AS actor_id,
a.first_name || ' '|| a.last_name AS actor_name,
f.film_id AS film_id,
f.title AS title,
f.release_year AS release_year
FROM
actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
),

ordered_movies 
AS
(
SELECT
am1.actor_id,
am1.actor_name,
am1.title AS previous_movie,
am1.release_year AS previous_year,
am2.title AS last_movie,
am2.release_year AS last_year
FROM
actor_movies am1
LEFT JOIN actor_movies am2 ON am1.actor_id = am2.actor_id
AND (am2.release_year > am1.release_year
OR (am2.release_year = am1.release_year AND am2.film_id > am1.film_id))
WHERE NOT EXISTS 
(
SELECT 
am3.film_id
FROM 
actor_movies am3
WHERE 
am3.actor_id = am1.actor_id
AND (am3.release_year > am1.release_year AND am3.release_year < am2.release_year)
OR (am3.release_year = am1.release_year AND am3.film_id > am1.film_id AND am3.film_id < am2.film_id)
)
)

SELECT
actor_id,
actor_name,
(last_year - previous_year) AS seq_year_gap
FROM 
ordered_movies
WHERE 
last_year IS NOT NULL
GROUP BY
ordered_movies.actor_id,
ordered_movies.actor_name,
seq_year_gap
ORDER BY
seq_year_gap DESC;

--COMMENT: I made actor_movies and ordered_movies tables to make the movies into order, and also to get the 
--released years (previous_year, and last year). I had to make 2 self joins to get to the conclusion of which
--movie was last, and one before, and thats how i got the years of movies, and the years of
--previous movies' years. After i calculated the seq_year_gap, and i ordered by it.