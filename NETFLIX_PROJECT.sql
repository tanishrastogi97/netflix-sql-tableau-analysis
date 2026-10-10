-- Netflix Project

CREATE TABLE netflix
(
   show_id VARCHAR(6),
   type    VARCHAR(10),  
   title   VARCHAR(150),
   director VARCHAR(208), 
   casts 	    VARCHAR(1000),
   country  VARCHAR(150),
   date_added VARCHAR(50),
   release_year INT,
   rating VARCHAR(10),
   duration VARCHAR(15),
   listed_in VARCHAR(100),
   description VARCHAR(250)
);

SELECT * FROM netflix;

SELECT COUNT(*) as total_content
FROM netflix;


-- 20 Business Problems:


--1. Count the number of Movies vs TV Shows

SELECT
    type,COUNT(*) as total_content
FROM netflix
GROUP BY type;

--Insight: Movies make up 69.6% of the catalog (6,131 titles) and TV Shows 30.4% (2,676).


--2. Find the most common rating for movies and TV shows

with tbl as (
SELECT 
    type,
	rating,
	COUNT(*),
	RANK () OVER (PARTITION BY type ORDER BY COUNT(*) DESC) as ranking
FROM netflix
GROUP BY 1,2
ORDER BY 1,3 DESC
)
SELECT 
    type,
	rating,
	count	
FROM tbl	
WHERE ranking=1;

--Insights: TV-MA is the most common rating for both Movies (2,062) and TV Shows (1,145).


--3. List all movies released in a specific year (e.g., 2020).

SELECT 
    title,release_year
FROM netflix
WHERE type = 'Movie' AND release_year=2020 ; 

--Insights: 517 movies were released in 2020.


--4. Find the top 5 countries with the most content on Netflix

SELECT
   TRIM(UNNEST(STRING_TO_ARRAY(country,','))) AS new_country,
   COUNT(show_id) as total_content
FROM netflix   
GROUP BY new_country
ORDER BY total_content DESC
LIMIT 5;   

--Insights: The US has the most titles (3,690), followed by India (1,046), the UK (806),
--Canada (445) and France (393). Co-productions count toward each country involved.


--5. Identify the longest movie.

SELECT title, duration
FROM netflix
WHERE type = 'Movie' AND duration IS NOT NULL
ORDER BY SPLIT_PART(duration, ' ', 1)::int DESC
LIMIT 1;

--Insights: The longest movie is Black Mirror: Bandersnatch at 312 minutes.


--6. Find the content added in the last 8 years

SELECT *
FROM netflix
WHERE
    TO_DATE (date_added, 'Month DD,YYYY') >= CURRENT_DATE - INTERVAL '8 years' ;

--Insights: 5,817 titles (about 66% of the catalog) were added in the last 8 years(as of run date).
--The dataset ends in September 2021, so this window only covers additions from October 2018 onward.


--7. Find all the movies/TV Shows by director 'Rajiv Chilaka'

SELECT 
    *
FROM netflix	
WHERE director ILIKE '%Rajiv Chilaka%'; 

--Insights: Rajiv Chilaka has 22 titles on Netflix, all of them movies released between 2009 and 2019.
--Most are Chhota Bheem films.


--8.  List all the TV Shows with more than 5 seasons.

SELECT
    * 
FROM netflix
WHERE 
  type = 'TV Show'
  AND
  SPLIT_PART(duration, ' ',1)::numeric > 5 ;

--Insights: Only 99 of 2,676 TV shows (3.7%) have more than 5 seasons.
--67% of TV shows (1,793) have just one season.


--9.  Count the number of content in each genre

SELECT
	 TRIM(UNNEST(STRING_TO_ARRAY(listed_in,','))) as genre,
	 COUNT(Show_id)
FROM netflix
GROUP BY 1 ;

--Insights: The catalog spans 42 genres. International Movies (2,752), Dramas (2,427)
--and Comedies (1,674) are the biggest. A title can count toward several genres.



--10. For titles produced in only India, find the number of titles added to Netflix each year and each year's percentage share of India's total content.
--    Return the year with the highest number of additions. 

SELECT
    EXTRACT(YEAR FROM TO_DATE(TRIM(date_added), 'Month DD, YYYY'))::int AS year,
    COUNT(*) AS yearly_content,
    ROUND(COUNT(*)::numeric
          / (SELECT COUNT(*) FROM netflix WHERE country = 'India')::numeric * 100, 2)
          AS pct_of_india_content
FROM netflix
WHERE country = 'India'
GROUP BY 1
ORDER BY yearly_content DESC
LIMIT 1;

--Insights: Among titles made only in India (972), 2018 had the most additions with 333 titles,
--34.3% of the total. Additions then fell to 203 in 2019 and 189 in 2020.
--Note: the percentage is each year's share of India's titles



--11.  List all movies that are documentaries.

SELECT *
FROM netflix
WHERE
  type = 'Movie'
  AND
  listed_in ILIKE '%Documentaries%' ;

--Insights: 869 movies are documentaries, about 9.9% of the catalog.

  

--12.   Find all content without a director

SELECT *
FROM netflix
WHERE
  director IS NULL ;

--Insights: 2,634 titles (29.9%) have no director listed. 2,446 of them are TV Shows,
--so about 91% of TV shows have no director, versus 188 missing among 6,131 movies.  



--13. Find in how many movies/TV Shows has actor 'Salman Khan' appesared in last 13 years?

SELECT * FROM netflix
WHERE 
   casts ILIKE ('%Salman Khan%')
   AND
   release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 13 ;

--Insights: Salman Khan appears in 2 titles released in the last 13 years: Prem Ratan Dhan Payo (2015)
--and Paharganj (2019)(as on run date). He appears in 20 titles overall, and most were released before 2013.



--14. Find the top 10 actors who have appeared in the highest number of movies produced in India.

SELECT 
	TRIM(UNNEST(STRING_TO_ARRAY(casts, ','))) as actors,
	COUNT(*) as total_content
FROM netflix
WHERE country ILIKE '%India%'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10 ;

--Insights: Anupam Kher appears in the most Indian titles (40), followed by Shah Rukh Khan (34)
--and Naseeruddin Shah (31). Akshay Kumar and Om Puri follow with 29 each. The top 10 runs down to Ajay Devgn with 21.



--15. Categorize the content based on the presence of the keywords 'kill' and 'violence' in the description
-- field.Label content containing these keywords as 'Bad' and all other content as 'Good'.
-- Count how many items fall into each category.

SELECT
    CASE
        WHEN description ILIKE 'kill%'     OR description ILIKE '% kill%'
          OR description ILIKE 'violence%' OR description ILIKE '% violence%'
        THEN 'Bad_Content'
        ELSE 'Good_Content'
    END AS category,
    COUNT(*) AS total_content
FROM netflix
GROUP BY 1;

--15. Insights: 272 titles (3.1%) mention "kill" or "violence" in the description, and 8,535 (96.9%) do not.
--It means the dataset is dominated by non violent and good content. 



--16. How many titles were added per year, and what is the year-over-year growth percentage?

WITH tbl AS (
  SELECT EXTRACT(YEAR FROM TO_DATE(TRIM(date_added), 'Month DD, YYYY'))::int AS year_added,
         COUNT(*) AS titles
  FROM netflix
  WHERE date_added IS NOT NULL
  GROUP BY 1
)
SELECT year_added, titles,
       ROUND(100.0 * (titles - LAG(titles) OVER (ORDER BY year_added))
             / NULLIF(LAG(titles) OVER (ORDER BY year_added), 0), 1) AS yoy_growth_pct
FROM tbl
ORDER BY year_added;

--Insights:Additions exploded between 2015 and 2017 and peaked in 2019 at 2,016 titles.
--Growth then slowed sharply (from +176.9% in 2017 to +22.3% in 2019) and turned negative in 2020.
--Note: 2021 is a partial year.


--17. For each year, what share of newly added content is Movies vs. TV Shows?

SELECT EXTRACT(YEAR FROM TO_DATE(TRIM(date_added), 'Month DD, YYYY'))::int AS year_added,
       COUNT(*) AS total,
       ROUND(100.0 * SUM(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END) / COUNT(*), 1) AS movie_pct,
       ROUND(100.0 * SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) / COUNT(*), 1) AS tv_pct
FROM netflix
WHERE date_added IS NOT NULL
GROUP BY 1
ORDER BY 1;

--Insights:Movies are 69.6% of the catalog (6,131 movies vs. 2,676 TV shows).
--Movie share peaked at 75.0% in 2018, then fell each year, while TV share rose from 25.0% to 33.7% by 2021.
--This points to a gradual rebalancing toward series content, which typically keeps viewers subscribed longer.
--Years before 2016 have too few titles to draw conclusions from.



--18. What is the average gap between release_year and the year a title was added to Netflix? Has it shrunk over time?

SELECT year_added,
       ROUND(AVG(year_added - release_year), 1) AS avg_gap_years
FROM (
  SELECT EXTRACT(YEAR FROM TO_DATE(TRIM(date_added), 'Month DD, YYYY'))::int AS year_added,
         release_year
  FROM netflix
  WHERE date_added IS NOT NULL
) 
GROUP BY year_added
ORDER BY year_added;

--Insights:The average gap between a title's release and its arrival on Netflix grew from 1.3 years (2015) to 5.8 years (2021), with an overall average of 4.69 years.
--Titles added in later years were, on average, older when they arrived.



--19.What are the top 3 genres in each of the top 5 content-producing countries?

WITH exploded AS (
  SELECT show_id, TRIM(c) AS country, TRIM(g) AS genre
  FROM netflix,
       UNNEST(STRING_TO_ARRAY(country, ',')) AS c,
       UNNEST(STRING_TO_ARRAY(listed_in, ',')) AS g
  WHERE country IS NOT NULL AND TRIM(c) <> ''
),
top5 AS (
  SELECT country,
         COUNT(DISTINCT show_id) AS total_titles,
         ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT show_id) DESC) AS country_rank
  FROM exploded
  GROUP BY country
  ORDER BY total_titles DESC
  LIMIT 5
),
ranked AS (
  SELECT e.country, t.country_rank, t.total_titles, e.genre,
         COUNT(*) AS cnt,
         DENSE_RANK() OVER (PARTITION BY e.country ORDER BY COUNT(*) DESC) AS genre_rank
  FROM exploded e
  JOIN top5 t ON e.country = t.country
  GROUP BY e.country, t.country_rank, t.total_titles, e.genre
)
SELECT country_rank, country, total_titles, genre_rank, genre, cnt
FROM ranked
WHERE genre_rank <= 3
ORDER BY country_rank, genre_rank;

--Insights:The US has more than three times the titles of second-place India, and leans on dramas, comedies and documentaries.
--India is dominated by international movies and dramas, while Canada stands out for children and family content.
--Dramas appear in the top 3 for all five countries, making it the most universal genre.


--20. Which directors have worked across the most distinct genres?

WITH tbl AS (
  SELECT TRIM(dir) AS director, TRIM(g) AS genre
  FROM netflix,
       UNNEST(STRING_TO_ARRAY(director, ',')) AS dir,
       UNNEST(STRING_TO_ARRAY(listed_in, ',')) AS g
  WHERE director IS NOT NULL
)
SELECT director, COUNT(DISTINCT genre) AS genres_covered
FROM tbl
GROUP BY director
ORDER BY genres_covered DESC
LIMIT 10;

--Insights:Martin Scorsese and Anurag Kashyap have worked in the most genres, 9 each. Five more directors have worked in 8 genres.
--Five of the top seven directors are Indian.
--This only counts titles that list a director, which is about 70% of the catalog.
      
  
	

   
	
	


	


