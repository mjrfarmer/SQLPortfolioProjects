CREATE TABLE marveldc (
title varchar(255),
studio varchar(255),
rate decimal(2,1),
metascore int,
runtime int,
releaseYear int,
budget bigint,
openingweekendUSA bigint,
grossUSA bigint,
grossWorldwide bigint);

select * 
from marveldc; 

-- count the number of movies by studio 
select count(title), studio
from marveldc
group by studio;

-- order all movies by rate (desc)
select * 
from marveldc
order by rate desc;

-- order movies by worst rating
select title, rate, grossworldwide
from marveldc
order by rate;

-- return 5 lowest rated movies overall
select title, rate
from marveldc
order by rate
limit 5;

-- return 5 highest rated movies overall
select title, studio, rate
from marveldc
order by rate desc
limit 5;

-- return top 5 movies by opening weekend
select title, studio, rate, openingweekendUSA
from marveldc
order by openingweekendUSA desc
limit 5;

-- fetch avg opening weekend revenue by studio
select studio, avg(openingweekendUSA)
from marveldc
group by studio;

-- fetch top 5 movies accruing the most profit
select title, studio, rate, grossworldwide - budget as total_profit
from marveldc
order by total_profit desc
limit 5;

-- sum of the gross revenue worldwide for all movies at each studio
select studio, sum(grossworldwide) as total_gross
from marveldc
group by studio;

-- avg gross revenue worldwide for each studio
select studio, avg(grossworldwide) as avg_gross
from marveldc
group by studio;

-- avg movie rating for each studio
select studio, avg(rate) as avg_rate
from marveldc
group by studio;

-- avg movie metascore for each studio
select studio, avg(metascore) as avg_score
from marveldc
group by studio;

-- fetch highest gross revenue worldwide from each studio
select studio, max(grossworldwide)
from marveldc
group by studio;

-- return title, rating, and budget for highest grossing movie from each studio 
select mdc.title, mdc.rate, mdc.budget, mdc.studio, mdc.grossworldwide
from marveldc mdc, 
	(select studio, max(grossworldwide) as maxgross
	from marveldc
	group by studio) maxresults
where mdc.grossworldwide = maxresults.maxgross;

-- fixing data entry mistake
update marveldc
set budget = 200000000
where title = 'Black Widow';

-- return total profit for each movie and rank by profit for each studio
select title, studio, budget, grossworldwide, grossworldwide - budget as total_profit,
rank() over(partition by studio order by grossworldwide - budget) as profit_rank
from marveldc;

-- returns the max worldwide gross revenue generated for each studio
select *,
max(grossUSA) over(partition by studio) as max_grossUSA
from marveldc;

-- return movie with highest domestic gross revenue from each studio 
select mdc.title, mdc.rate, mdc.studio, mdc.grossUSA
from marveldc mdc, 
	(select studio, max(grossUSA) as max_grossUSA
	from marveldc
	group by studio) maxresults
where mdc.grossUSA = maxresults.max_grossUSA;

-- assign row number to each row
select *,
row_number() over() as row_n
from marveldc;

-- order the movies from each studio by their rating, return row number for each movie in each studio
select *,
row_number() over(partition by studio order by rate desc) as row_n
from marveldc;

-- find the top 5 movies by rating in each studio
select * from (
	select *,
	row_number() over(partition by studio order by rate desc) as row_n
	from marveldc) as sub
where sub.row_n < 6;

-- top 5 movies by gross worlwide for each studio using rank function
with ranked as (
	select *, 
	rank() over(partition by studio order by grossworldwide desc) as movie_rnk
	from marveldc
)
select *
from ranked
where movie_rnk < 6;

-- calculate return on investment for each movie (as percent)
select title, studio, rate, (grossworldwide - budget)/budget*100 as ROI
from marveldc
order by ROI;

-- fecth movies where ROI > 100
select * from (
	select title, studio, rate, (grossworldwide - budget)/budget*100 as ROI
	from marveldc
	order by ROI) as roi_table
where ROI > 100;

-- fecth the number of movies from each studio where ROI > 100
select studio, count(*) from (
	select title, studio, rate, (grossworldwide - budget)/budget*100 as ROI
	from marveldc
	order by ROI) as roi_table
where ROI > 100
group by studio;

-- average return on investment for each studio (as percent)
select studio, (sum(grossworldwide)-sum(budget))/sum(budget)*100 as avg_ROI
from marveldc
group by studio;


