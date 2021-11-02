-- these datasets were downloaded from the 120 Years of Olympic History on kaggle.com

CREATE TABLE olympics (
id int,
name varchar(255),
sex varchar(255),
age varchar(255),
height varchar(255),
weight varchar(255),
team varchar(255),
NOC varchar(255),
games varchar(255),
year int,
season varchar(255),
city varchar(255),
sport varchar(255),
event varchar(255),
medal varchar(255));

CREATE TABLE olympics_regions (
NOC varchar(255),
region varchar(255),
notes varchar(255));

select * from olympics;
select * from olympics_regions;

-- find total number of games held
select count(distinct games) as total_games
from olympics;

-- list all games and countries
select distinct games, city
from olympics;

-- find total nations represented at each game
select games, count(distinct NOC) as countries_rep
from olympics
group by games;

-- fetch countries that played in all games
with tab1 as 
(select games, oreg.region
from olympics as o
join olympics_regions as oreg
on o.NOC = oreg.NOC),
tab2 as (
select count(distinct games) as all_games
from olympics),
tab3 as (
select region, count(distinct games) as total_games
from tab1
group by region)
select * 
from tab3
join tab2
on tab2.all_games = tab3.total_games
;

-- find the sports played in all summer olympics
with tab1 as (
	select count(distinct games) as total_games
	from olympics
	where season = "Summer"
	order by games),
tab2 as (
	select distinct sport, games
	from olympics 
	where season = "Summer"
	order by games),
tab3 as (
	select sport, count(games) as no_of_games
	from tab2
	group by sport)
select * from tab3
join tab1
on tab3.no_of_games = tab1.total_games;

-- find the sports that were only played in 1 olympic game
with tab1 as(
select distinct sport, count(distinct games) no_games
from olympics
group by sport),
tab2 as (
select *
from tab1
where no_games = 1)
select * 
from tab2;

-- find total sports played in each game
select distinct games, count(distinct sport) as no_sports
from olympics
group by games
order by no_sports desc;

-- oldest athletes to win medal in desc order
select * 
from olympics
where age <> 'NA' and medal <> 'NA'
order by age desc;

-- oldest athletes to win gold medal
with tab1 as (
select *,
rank() over(order by age desc) as age_rnk
from olympics
where age <> 'NA' and medal = 'Gold'
order by age desc)
select *
from tab1 
where age_rnk = 1;

-- find percent of male and female athlethes
select 
	sum(if(sex = 'M', 1, 0))/count(sex) as percent_male,
	sum(if(sex = 'F', 1, 0))/count(sex) as percent_female
from olympics;

-- find top 5 athletes that won most gold medals
with gold1 as (
	select *
	from olympics
	where medal = "Gold"),
medal1 as (
select name, count(medal) as medalcount
from gold1
group by name
order by medalcount desc),
tab3 as (
select *, dense_rank() over(order by medalcount desc) medal_rank
from medal1)
select * 
from tab3
where medal_rank < 6;

-- find top 5 athletes that have won most medals total
with tab1 as (
select name, team, count(medal) as total_medals
from olympics
where medal <> 'NA'
group by name, team),
tab2 as (
select *,
dense_rank() over(order by total_medals desc) medal_rank
from tab1)
select * 
from tab2
where medal_rank < 6;

-- find top 5 most successful countries
select distinct region, count(medal) total_medals
from olympics oly
join olympics_regions oreg
on oly.NOC = oreg.NOC
where medal <> 'NA'
group by region
order by total_medals desc
limit 5;

-- find top 10 countries based on number of athletes at olympics
select distinct region, count(name) total_athletes
from olympics oly
join olympics_regions oreg
on oly.NOC = oreg.NOC
group by region
order by total_athletes desc
limit 10;

-- top 10 countries based on % athletes represented at olympics
select region, count(name) * 100/ sum(count(name)) over() as percent_athletes
from olympics oly
join olympics_regions oreg
on oly.NOC = oreg.NOC
group by region
order by percent_athletes desc
limit 10;

-- list total gold, silver, and bronze medals won by each country
select region,
       sum(case when medal = 'Gold' then total_medals else null end) AS gold,
       sum(case when medal = 'Silver' THEN total_medals else null end) AS silver,
       sum(case when medal = 'Bronze' THEN total_medals else null end) AS bronze
from (
	select distinct region, medal, count(medal) total_medals
	from olympics oly
	join olympics_regions oreg
	on oly.NOC = oreg.NOC
	where medal <> 'NA'
	group by region, medal) sub1
group by region
order by gold desc, silver desc, bronze desc; 

-- list the number of gold, silver, and bronze medals won by each country at each game
select games, region,
       sum(case when medal = 'Gold' then total_medals else null end) AS gold,
       sum(case when medal = 'Silver' then total_medals else null end) AS silver,
       sum(case when medal = 'Bronze' then total_medals else null end) AS bronze
from (
select games, region, medal, count(medal) total_medals
	from olympics oly
	join olympics_regions oreg
	on oly.NOC = oreg.NOC
	where medal <> 'NA'
	group by games, region, medal
	order by games) sub1
group by games, region;

-- find which country won the most gold, silver and bronze medals at each game
with temp1 as (
select games, region,
       sum(case when medal = 'Gold' then total_medals else null end) AS gold,
       sum(case when medal = 'Silver' then total_medals else null end) AS silver,
       sum(case when medal = 'Bronze' then total_medals else null end) AS bronze
from (
select games, region, medal, count(medal) total_medals
	from olympics oly
	join olympics_regions oreg
	on oly.NOC = oreg.NOC
	where medal <> 'NA'
	group by games, region, medal
	order by games) sub1
group by games, region)
select distinct games,
concat(first_value(region) over(partition by games order by gold desc), '-', first_value(gold) over(partition by games order by gold desc)) as max_gold,
concat(first_value(region) over(partition by games order by silver desc), '-', first_value(silver) over(partition by games order by silver desc)) as max_silver,
concat(first_value(region) over(partition by games order by bronze desc), '-', first_value(bronze) over(partition by games order by bronze desc)) as max_bronze
from temp1
order by games;

-- find the countries that have never won gold but have won silver or bronze
with temp1 as (
select region,
       sum(case when medal = 'Gold' then total_medals else 0 end) AS gold,
       sum(case when medal = 'Silver' then total_medals else 0 end) AS silver,
       sum(case when medal = 'Bronze' then total_medals else 0 end) AS bronze
from (
select region, medal, count(medal) total_medals
	from olympics oly
	join olympics_regions oreg
	on oly.NOC = oreg.NOC
	where medal <> 'NA'
	group by region, medal
	order by region, medal) sub1
group by region)
select *
from temp1 
where gold = 0 and (silver > 0 or bronze > 0)
order by silver desc, bronze desc;

-- find the total number of medals the USA has won in gymnastics (my favorite)
select distinct region, sport, count(medal) total_medals
from olympics oly
join olympics_regions oreg
on oly.NOC = oreg.NOC
where medal <> 'NA' and region = 'USA' and sport = 'Gymnastics'
group by region, sport;

-- find the total number of gymnastics medals the USA won in each game
select region, games, sport, count(medal) total_medals
from olympics oly
join olympics_regions oreg
on oly.NOC = oreg.NOC
where medal <> 'NA' and region = 'USA' and sport = 'Gymnastics'
group by region, games, sport
order by games;
