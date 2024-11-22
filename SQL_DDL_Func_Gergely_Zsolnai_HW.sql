--Task 1. Create a view
--drop view sales_revenue_by_category_qtr;


CREATE OR REPLACE VIEW sales_revenue_by_category_qtr as
with valid_data as (
	select 
		c.name as film_category,
		sum(p.amount) as total_sales_revenue_by_year,
		SUM(case
				when extract(quarter from p.payment_date) = extract(quarter from current_date)
					then p.amount
				else 0	
		end
		) as total_sales_revenue_by_quarter
	from
		category c
	join
		film_category fc on c.category_id = fc.category_id
	join
		film f on fc.film_id = f.film_id
	join
		inventory i on f.film_id = i.film_id
	join
		rental r on i.inventory_id = r.inventory_id
	join 
		payment p on r.rental_id = p.rental_id
	where
		extract(year from p.payment_date) = extract(year from current_date)
	group by
		c.name
	having
		sum(p.amount) > 0)
select * from valid_data;

raise exception 'There is no sales revenue for the current year or quarter';

--example: select * from sales_revenue_by_category_qtr;
--Task 2. Create a query language functions
	
--drop function get_sales_revenue_by_category_qtr(DATE);
	
create OR REPLACE function get_sales_revenue_by_category_qtr(input_DATE DATE)
returns table (
	film_category text,
	total_sales_revenue_by_year NUMERIC,
	total_sales_revenue_by_quarter NUMERIC)
as $$
begin
	IF Input_country IS NULL 
		THEN RAISE EXCEPTION 'You did not write a country name';
	END IF;
	return QUERY
	select 
		c.name as film_category,
		sum(p.amount) as total_sales_revenue_by_year,
		SUM(case
				when extract(quarter from p.payment_date) = extract(quarter from input_DATE)
					then p.amount
				else 0	
		end
		) as total_sales_revenue_by_quarter
	from
		category c
	join
		film_category fc on c.category_id = fc.category_id
	join
		film f on fc.film_id = f.film_id
	join
		inventory i on f.film_id = i.film_id
	join
		rental r on i.inventory_id = r.inventory_id
	join 
		payment p on r.rental_id = p.rental_id
	where
		extract(year from p.payment_date) = extract(year from input_DATE)
	group by
		c.name
	having
		sum(p.amount) > 0;
end;
$$ language plpgsql;

--example: select * from get_sales_revenue_by_category_qtr('2017-01-20');

--Task 3. Create procedure language functions

DROP FUNCTION most_popular_films_by_countries(text[]);

create OR REPLACE function most_popular_films_by_countries(input_country text[])
returns table (
	Country TEXT,
	Film VARCHAR(200),
	Rents numeric,
	Rating public.mpaa_rating,
	Language VARCHAR(100),
	Length Integer,
	Release_year Integer
	)
as $$
begin
	return QUERY
	select 
		distinct on(cy.country) cy.country::TEXT as Country, 
		f.title::VARCHAR(200) as Film, 
		count(r.rental_id)::numeric as Rents,
		f.rating::public.mpaa_rating as Rating,
		l.name::VARCHAR(100) as Language,
		f.length::Integer as Length,
		f.release_year::Integer as Release_year
	from 
		film f
	join inventory i on f.film_id = i.film_id 
	join language l on f.language_id = l.language_id
	join rental r on i.inventory_id = r.inventory_id 
	join customer c on r.customer_id = c.customer_id 
	join address a on c.address_id = a.address_id 
	join city ci on a.city_id = ci.city_id 
	join country cy on ci.country_id = cy.country_id 
	WHERE 
		cy.country = any(input_country)
	group by 
        cy.country, 
        f.title,
        f.rating, 
        l.name, 
        f.length, 
        f.release_year
	order by 
		cy.country,
		COUNT(r.rental_id) desc;
end;
$$ language plpgsql;		
		
--example: select * from most_popular_films_by_countries(ARRAY['Afghanistan', 'China']);

--Task 4. Create procedure language functions
drop function films_in_stock_by_title(input_title TEXT);

CREATE OR REPLACE FUNCTION films_in_stock_by_title(input_title TEXT)
RETURNS TABLE (
    Row_num INTEGER,
    Film_title VARCHAR(250),
    Language VARCHAR(100),
    Customer_name VARCHAR(250),
    Rental_date DATE,
    Available BOOLEAN
)
AS $$
BEGIN
    RETURN QUERY
    WITH LatestRentals AS (
        SELECT
            r.inventory_id,
            MAX(r.last_update) AS last_update
        FROM
            rental r
        GROUP BY
            r.inventory_id
    ),
    AvailableInventory AS (
        SELECT
            i.inventory_id,
            f.title
        FROM
            inventory i
        INNER JOIN
            film f ON f.film_id = i.film_id
        WHERE
            NOT EXISTS (
                SELECT
                    1
                FROM
                    rental r
                INNER JOIN
                    LatestRentals lr ON r.inventory_id = lr.inventory_id AND r.last_update = lr.last_update
                WHERE
                    r.return_date IS NULL
                    AND r.inventory_id = i.inventory_id
            )
    ),
    DistinctFilms AS (
        select 
			distinct f.title 
		from
			inventory i
		inner join film f on f.film_id = i.film_id 
			where not exists (
				select 
					*
				from 
					rental r
				where
					(r.inventory_id, last_update) in (
						select
							r2.inventory_id, max(r2.last_update) as last_update 
						from
							rental r2
						group by 
							r2.inventory_id
					)
		    		and r.return_date is null
		   			and r.inventory_id = i.inventory_id
			)
	)
    SELECT
        gs::INTEGER AS Row_num,
        CAST(f.title AS VARCHAR(250)) AS Film_title,
        CAST(l.name AS VARCHAR(100)) AS Language,
        CAST(c.first_name || ' ' || c.last_name AS VARCHAR(250)) AS Customer_name,
        MAX(r.rental_date)::DATE AS Rental_date,
        CASE
            WHEN ai.inventory_id IS NOT NULL THEN TRUE
            ELSE FALSE
        END AS Available
    FROM
        generate_series(1, (
            SELECT COUNT(*) 
            FROM 
				film f
            JOIN inventory i ON f.film_id = i.film_id
            JOIN language l ON f.language_id = l.language_id
            JOIN rental r ON i.inventory_id = r.inventory_id
            JOIN customer c ON r.customer_id = c.customer_id
            WHERE 
				LOWER(f.title) LIKE LOWER('%' || input_title || '%')
        	)) AS gs
    CROSS JOIN film f
    LEFT JOIN
        inventory i ON f.film_id = i.film_id
    LEFT JOIN
        language l ON f.language_id = l.language_id
    LEFT JOIN
        rental r ON i.inventory_id = r.inventory_id
    LEFT JOIN
        customer c ON r.customer_id = c.customer_id
    LEFT JOIN
        AvailableInventory ai ON ai.inventory_id = i.inventory_id
    WHERE
        LOWER(f.title) LIKE LOWER('%' || input_title || '%')
    GROUP BY
        gs, f.title, l.name, c.first_name, c.last_name, ai.inventory_id
    ORDER BY
        gs, f.title;
END;
$$ LANGUAGE plpgsql;



select * from films_in_stock_by_title('love');

--I am sorry, but distinct is not working. Please help me, i can not do it. 

--5. task:
DROP FUNCTION IF EXISTS new_movie(TEXT, INT, TEXT);

CREATE OR REPLACE FUNCTION new_movie(
    input_title TEXT, 
    input_release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT, 
    input_language TEXT DEFAULT 'Klingon'
)
RETURNS INTEGER 
AS $$
DECLARE
    language_id2 INT;
    film_id2 INT;
BEGIN
    SELECT 
		language_id
	INTO 
		language_id2
    FROM 
		language
    WHERE LOWER(name) = LOWER(input_language)
    LIMIT 1;
    IF language_id2 IS NULL THEN
        INSERT INTO language(name)
        VALUES (input_language)
        RETURNING language_id INTO language_id2;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM film 
			WHERE LOWER(title) = LOWER(input_title) AND release_year = input_release_year
    ) THEN
        INSERT INTO film(title, release_year, language_id, rental_rate, rental_duration, replacement_cost)
        SELECT 
            input_title, 
            input_release_year, 
            language_id2, 
            4.99, 
            3, 
            19.99
        RETURNING film_id INTO film_id2;
    ELSE
        SELECT film_id 
        INTO film_id2
        FROM film
        WHERE LOWER(title) = LOWER(input_title) AND release_year = input_release_year
        LIMIT 1;
    END IF;
    RETURN film_id2;
END;
$$ LANGUAGE plpgsql;

select * from new_movie('Lilo', 2024, 'English');