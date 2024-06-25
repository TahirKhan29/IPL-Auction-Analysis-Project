CREATE DATABASE IPL_PROJECT;
USE IPL_PROJECT;
SELECT COUNT(*) FROM ipl_ball;
SELECT COUNT(*) FROM ipl_matches;

ALTER TABLE ipl_matches RENAME COLUMN date TO match_date;

SELECT DISTINCT venue FROM ipl_matches;
SELECT COUNT(DISTINCT venue) FROM ipl_matches;

SELECT * FROM ipl_matches;
SELECT * FROM ipl_ball;

SELECT 
DISTINCT SUBSTRING(match_date,7,4)
FROM ipl_matches
;




# Q1) Your first priority is to get 2-3 players with high S.R who have faced at least 500 balls.
# And to do that you have to make a list of 10 players you want to bid in the auction so that 
# when you try to grab them in auction you should not pay the amount greater than you have in the purse for a particular player

SELECT batsman ,
SUM(batsman_runs) AS total_runs,
COUNT(batsman) AS total_balls ,
ROUND((SUM(batsman_runs)/COUNT(batsman)) * 100,2) AS strike_rate
FROM ipl_ball
GROUP BY batsman
HAVING COUNT(batsman) >= 500
ORDER BY strike_rate DESC
LIMIT 10;






# Q2) Now you need to get 2-3 players with good Average who have played more than 2 ipl seasons.
# And to do that you have to make a list of 10 players you want to bid in the auction so that when you try 
# to grab them in auction you should not pay the amount greater than you have in the purse for a particular player.

SELECT 
B.batsman,
COUNT(DISTINCT SUBSTRING(M.match_date, 7, 4)) AS seasons_played,
SUM(B.batsman_runs) AS total_runs,
COUNT(*) AS total_balls,
SUM(CASE WHEN B.is_wicket = 1 AND B.batsman = B.player_dismissed THEN 1 ELSE 0 END) AS dismissals,
ROUND((SUM(B.batsman_runs) / NULLIF(SUM(CASE WHEN B.is_wicket = 1 AND B.batsman = B.player_dismissed THEN 1 ELSE 0 END), 0)),2) AS average
FROM ipl_ball AS B
INNER JOIN ipl_matches AS M ON B.id = M.id
GROUP BY B.batsman
HAVING COUNT(*) >= 500  AND COUNT(DISTINCT SUBSTRING(M.match_date, 7, 4)) > 2 
ORDER BY average DESC
LIMIT 10;  







# Q3) Now you need to get 2-3 Hard-hitting players who have scored most runs in boundaries 
# and have played more the 2 ipl season. To do that you have to make a list of 10 players you want 
# to bid in the auction so that when you try to grab them in auction you should not pay the amount greater
# than you have in the purse for a particular player.

SELECT B.batsman , 
B.batting_team ,
COUNT(DISTINCT SUBSTRING(M.match_date, 7, 4)) AS seasons_played, 
SUM(B.batsman_runs) AS total_runs,
SUM(CASE WHEN B.batsman_runs IN (4,6) THEN 1 ELSE 0 END ) AS total_boundaries
FROM ipl_ball AS B
INNER JOIN ipl_matches AS M ON B.id = M.id
GROUP BY B.batsman , B.batting_team
HAVING COUNT(DISTINCT SUBSTRING(M.match_date, 7, 4)) > 2 AND SUM(CASE WHEN B.batsman_runs IN (4,6) THEN 1 ELSE 0 END ) > 0
ORDER BY total_boundaries DESC
LIMIT 10;








# Q4) Your first priority is to get 2-3 bowlers with good economy who have bowled at least 500 balls
# in IPL so far.To do that you have to make a list of 10 players you want to bid in the auction 
# so that when you try to grab them in auction you should not pay the amount greater than you have in the purse for a particular player

SELECT bowler , 
ROUND(SUM(total_runs) * 6.0 / (SUM(`over`) + SUM(ball) / 6.0) * 10,2) AS economy_rate
FROM ipl_ball
GROUP BY bowler
HAVING COUNT(bowler) > 500
ORDER BY economy_rate
LIMIT 10;







# Q5) Now you need to get 2-3 bowlers with the best strike rate and who have bowled at
# least 500 balls in IPL so far.To do that you have to make a list of 10 players you want
# to bid in the auction so that when you try to grab them in auction you should not pay
# the amount greater than you have in the purse for a particular player.


SELECT bowler , 
SUM(total_runs) AS runs_given,
SUM(total_balls)/6 AS overs_bowled,
SUM(CASE WHEN is_wiclet = 1 THEN 1 ELSE 0  END) AS total_wickets ,
SUM(total_balls)/SUM(CASE WHEN is_wiclet = 1 THEN 1 ELSE 0  END) AS strike_rate
FROM 
(
SELECT 
SUM(batsman_runs) AS total_runs,
COUNT(ball) AS total_balls , 
SUM(CASE WHEN dismissal_kind IN ('caught','bowled','lbw') THEN 1 ELSE 0 END) AS total_wickets
FROM ipl_ball
WHERE extras_type NOT IN  ('wides' , 'noballs')
GROUP BY bowler ,id
) AS new_stats
GROUP BY bowler
HAVING COUNT(total_balls) > 500
ORDER BY strike_rate ASC
LIMIT 10;











# Q6) Now you need to get 2-3 All rounders with the best batting as well as
# bowling strike rate and who have faced at least 500 balls in IPL so far and
# have bowled minimum 300 balls. To do that you have to make a list of 10 players
# you want to bid in the auction so that when you try to grab them in auction you
# should not pay the amount greater than you have in the purse for a particular player.


WITH 
Batsman_stats AS (
SELECT batsman , 
SUM(batsman_runs) AS total_runs,
COUNT(*) AS balls_faced
FROM ipl_ball
GROUP BY batsman
HAVING COUNT(*) >= 500
) , 

Bowler_stats AS (
SELECT bowler , 
COUNT(*) AS balls_bowled , 
SUM(CASE WHEN dismissal_kind IN ('caught', 'bowled', 'lbw')THEN 1 ELSE 0 END) AS total_wickets
FROM ipl_ball
GROUP BY bowler
HAVING COUNT(*) >= 300
) , 

Allrounder_stats AS (
SELECT 
A.batsman , 
A.total_runs ,
A.balls_faced ,
B.balls_bowled , 
B.total_wickets , 
(Cast(A.total_runs As Decimal) *100 / Nullif(A.balls_faced, 0)) As batting_strike_rate,
(CAST(B.balls_bowled AS Decimal) / Nullif(B.total_wickets, 0)) As bowling_strike_rate

FROM Batsman_stats AS A
JOIN Bowler_stats AS B
ON A.batsman = B.bowler
)

SELECT 
batsman , 
batting_strike_rate AS batting_SR , 
bowling_strike_rate AS bowling_SR
FROM Allrounder_stats
ORDER BY batting_SR DESC , bowling_SR ASC
LIMIT 10;





# ADDITIONAL QUESTION
# 1) Get the count of cities that have hosted an IPL match - Cities count: 33
SELECT * FROM ipl_ball;
SELECT * FROM ipl_matches;

SELECT DISTINCT CITY FROM ipl_matches;
SELECT COUNT(DISTINCT CITY) FROM ipl_matches;



# 2) Create table deliveries_v02 with all the columns of the table ‘deliveries’ and an additional
# column ball_result containing values boundary, dot or other depending on the total_run
CREATE TABLE deliveries_v02 AS
SELECT *,CASE 
WHEN total_runs >= 4 THEN 'Boundary'
WHEN total_runs = 0 THEN 'Dot'
WHEN total_runs = 0 AND is_wicket = 1 THEN 'Wicket'
ELSE 'Others'
END AS ball_result
FROM ipl_ball;

SELECT * FROM deliveries_v02;




# Q3)  Write a query to fetch the total number of boundaries and dot balls from the deliveries_v02 table
SELECT ball_result , 
COUNT(ball_result)
FROM deliveries_v02
WHERE ball_result NOT IN ('Others')
GROUP BY ball_result;


# Q4) Write a query to fetch the total number of boundaries scored by each team from
# the deliveries_v02 table and order it in descending order of the number of boundaries scored
SELECT 
batting_team ,
SUM(CASE WHEN ball_result = 'Boundary' THEN 1 ELSE 0 END) AS total_boundaries
FROM deliveries_v02
GROUP BY batting_team
ORDER BY total_boundaries DESC;


# Q5) Write a query to fetch the total number of dot balls bowled by each team
# and order it in descending order of the total number of dot balls bowled
SELECT 
bowling_team ,
SUM(CASE WHEN ball_result = 'Dot' THEN 1 ELSE 0 END) AS total_dots
FROM deliveries_v02
GROUP BY bowling_team
ORDER BY total_dots DESC;


# Q6) Write a query to fetch the total number of dismissals by dismissal kinds where dismissal kind is not NA
SELECT 
dismissal_kind , 
COUNT(dismissal_kind) 
FROM deliveries_v02
WHERE dismissal_kind NOT IN ('NA') AND  dismissal_kind IS NOT NULL
GROUP BY dismissal_kind
ORDER BY COUNT(dismissal_kind) DESC;

# Q7) Write a query to get the top 5 bowlers who conceded maximum extra runs from the deliveries table
SELECT 
bowler , 
SUM(extra_runs) AS total_extras
FROM ipl_ball
GROUP BY bowler
ORDER BY total_extras DESC 
LIMIT 5;


# Q8) Write a query to create a table named deliveries_v03 with all the columns of deliveries_v02
# table and two additional column (named venue and match_date) of venue and date from table matches



CREATE TABLE deliveries_v03 AS 
SELECT A.* ,B.venue , B.match_date as match_date
FROM deliveries_v02 AS A
JOIN ipl_matches AS B ON A.id = B.id;

SELECT * FROM deliveries_v03;


# Q9) Write a query to fetch the total runs scored for each venue and order it in the descending order of total runs scored.
SELECT 
venue , 
SUM(batsman_runs) AS total_run_scored
FROM deliveries_v03
GROUP BY venue 
ORDER BY total_run_scored DESC;



# Q10) Write a query to fetch the year-wise total runs scored at Eden Gardens and order it in the descending order of total runs scored.
Select 
Extract(Year from match_date) AS Years,
Sum(total_runs) As total_runs_scored
FROM deliveries_v03
WHERE venue = 'Eden Gardens'
Group By Years
Order by total_runs_scored Desc;
