-- Netflix Project: data preparation for Tableau
-- Source table: netflix (see NETFLIX_PROJECT.sql)



-- 1. Main table: one row per title
CREATE OR REPLACE VIEW netflix_clean AS
SELECT show_id, type, title, release_year, description,
       CASE WHEN rating ILIKE '%min' THEN NULL ELSE rating END AS rating,
       TO_DATE(TRIM(date_added), 'Month DD, YYYY') AS date_added,
       EXTRACT(YEAR FROM TO_DATE(TRIM(date_added), 'Month DD, YYYY'))::int AS year_added,
       CASE WHEN type = 'Movie' AND COALESCE(duration, rating) ~ '^[0-9]+ min'
            THEN SPLIT_PART(COALESCE(duration, rating), ' ', 1)::int END AS minutes,
       CASE WHEN type = 'TV Show' THEN SPLIT_PART(duration, ' ', 1)::int END AS seasons,
       (director IS NOT NULL) AS has_director
FROM netflix;

-- 2. One row per title per country
CREATE OR REPLACE VIEW netflix_country AS
SELECT show_id, TRIM(UNNEST(STRING_TO_ARRAY(country, ','))) AS country
FROM netflix WHERE country IS NOT NULL;

-- 3. One row per title per genre
CREATE OR REPLACE VIEW netflix_genre AS
SELECT show_id, TRIM(UNNEST(STRING_TO_ARRAY(listed_in, ','))) AS genre
FROM netflix;

-- 4. One row per title per actor
CREATE OR REPLACE VIEW netflix_cast AS
SELECT show_id, TRIM(UNNEST(STRING_TO_ARRAY(casts, ','))) AS actor
FROM netflix WHERE casts IS NOT NULL;

-- 5. One row per title per director
CREATE OR REPLACE VIEW netflix_director AS
SELECT show_id, TRIM(UNNEST(STRING_TO_ARRAY(director, ','))) AS director
FROM netflix WHERE director IS NOT NULL;



--CHECKING IF THE VIEWS WORK PROPERRLY OR NOT:
SELECT * FROM netflix_clean LIMIT 10;
SELECT COUNT(*) FROM netflix_clean;                
SELECT COUNT(*) FROM netflix_clean WHERE minutes IS NULL AND type='Movie';  
SELECT * FROM netflix_genre LIMIT 10;


SELECT * FROM netflix_director
