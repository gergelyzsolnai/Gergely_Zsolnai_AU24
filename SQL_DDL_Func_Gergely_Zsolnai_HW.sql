--Task 1. Create a view
--drop view sales_revenue_by_category_qtr;


CREATE OR REPLACE VIEW public.sales_revenue_by_category_qtr as
with valid_data as (
	select 
		LOWER(c.name) as film_category,
		sum(p.amount) as total_sales_revenue_by_year,
		SUM(case
				when extract(quarter from p.payment_date) = extract(quarter from current_date)
					then p.amount
				else 0	
		end
		) as total_sales_revenue_by_quarter
	from
		public.category c
	join
		public.film_category fc on c.category_id = fc.category_id
	join
		public.film f on fc.film_id = f.film_id
	join
		public.inventory i on f.film_id = i.film_id
	join
		public.rental r on i.inventory_id = r.inventory_id
	join 
		public.payment p on r.rental_id = p.rental_id
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
	
create OR REPLACE function public.get_sales_revenue_by_category_qtr(input_DATE DATE)
returns table (
	film_category text,
	total_sales_revenue_by_year NUMERIC,
	total_sales_revenue_by_quarter NUMERIC)
as $$
begin
	IF input_DATE IS NULL                       --i mixed input_country from the 3rd task
		THEN RAISE EXCEPTION 'You did not write a valid date';
	END IF;
	return QUERY
	select 
		LOWER(c.name) as film_category,
		sum(p.amount) as total_sales_revenue_by_year,
		SUM(case
				when extract(quarter from p.payment_date) = extract(quarter from input_DATE)
					then p.amount
				else 0	
		end
		) as total_sales_revenue_by_quarter
	from
		public.category c
	join
		public.film_category fc on c.category_id = fc.category_id
	join
		public.film f on fc.film_id = f.film_id
	join
		public.inventory i on f.film_id = i.film_id
	join
		public.rental r on i.inventory_id = r.inventory_id
	join 
		public.payment p on r.rental_id = p.rental_id
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

--DROP FUNCTION most_popular_films_by_countries(text[]);

create OR REPLACE function public.most_popular_films_by_countries(input_country text[])
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
		distinct on UPPER((cy.country)) UPPER(cy.country)::TEXT as Country, 
		f.title::VARCHAR(200) as Film, 
		count(r.rental_id)::numeric as Rents,
		f.rating::public.mpaa_rating as Rating,
		l.name::VARCHAR(100) as Language,
		f.length::Integer as Length,
		f.release_year::Integer as Release_year
	from 
		public.film f
	join public.inventory i on f.film_id = i.film_id 
	join public.language l on f.language_id = l.language_id
	join public.rental r on i.inventory_id = r.inventory_id 
	join public.customer c on r.customer_id = c.customer_id 
	join public.address a on c.address_id = a.address_id 
	join public.city ci on a.city_id = ci.city_id 
	join public.country cy on ci.country_id = cy.country_id 
	WHERE 
		UPPER(cy.country) = any(array(select upper(input_country))))
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
--DROP FUNCTION IF EXISTS films_in_stock_by_title(TEXT);

CREATE OR REPLACE FUNCTION films_in_stock_by_title(input_title TEXT)
RETURNS TABLE (
    Row_num INTEGER,
    Film_title TEXT,
    Language TEXT,
    Customer_name TEXT,
    Rental_date TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        CAST(
            (SELECT COUNT(*)
             FROM public.film sub_film
             WHERE sub_film.film_id <= f.film_id
               AND LOWER(sub_film.title) LIKE LOWER('%' || input_title || '%')
            ) AS INTEGER
        ) AS Row_num,
        f.title AS Film_title,
        l.name::TEXT AS Language,
        COALESCE(
            (SELECT 
                CONCAT(c.first_name, ' ', c.last_name)
             FROM 
                rental r
             INNER JOIN 
                customer c ON r.customer_id = c.customer_id
             WHERE 
                r.inventory_id IN (
                    SELECT inventory_id
                    FROM inventory
                    WHERE film_id = f.film_id
                )
             ORDER BY 
                r.rental_date DESC
             LIMIT 1
            ), 'N/A'
        ) AS Customer_name,
        COALESCE(
            (SELECT 
                r.rental_date::TIMESTAMP
             FROM 
                rental r
             WHERE 
                r.inventory_id IN (
                    SELECT inventory_id
                    FROM inventory
                    WHERE film_id = f.film_id
                )
             ORDER BY 
                r.rental_date DESC
             LIMIT 1
            ), NULL
        ) AS Rental_date
    FROM
        public.film f
    INNER JOIN
        public.language l ON f.language_id = l.language_id
    WHERE
        NOT EXISTS (
            SELECT
                1
            FROM
                public.rental r
            WHERE
                r.inventory_id IN (
                    SELECT inventory_id
                    FROM inventory
                    WHERE film_id = f.film_id
                )
                AND r.return_date IS NULL
        )
        AND LOWER(f.title) LIKE LOWER('%' || input_title || '%')
    GROUP BY
        f.film_id, f.title, l.name
    ORDER BY
        row_num;
END;
$$ LANGUAGE plpgsql;

--select * from films_in_stock_by_title('love');

--5. task:
--DROP FUNCTION IF EXISTS new_movie(TEXT, INT, TEXT);

CREATE OR REPLACE FUNCTION public.new_movie(
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
		public.language
    WHERE LOWER(name) = LOWER(input_language)
    LIMIT 1;
    IF language_id2 IS NULL THEN
        INSERT INTO public.language(name)
        VALUES (input_language)
        RETURNING language_id INTO language_id2;
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM public.film 
			WHERE LOWER(title) = LOWER(input_title) AND release_year = input_release_year
    ) THEN
        INSERT INTO public.film(title, release_year, language_id, rental_rate, rental_duration, replacement_cost)
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
        FROM public.film
        WHERE LOWER(title) = LOWER(input_title) AND release_year = input_release_year
        LIMIT 1;
    END IF;
    RETURN film_id2;
END;
$$ LANGUAGE plpgsql;

--select * from new_movie('Lilo', 2024, 'English');