---------------------------------------------------------------------------------------
		INSERT into TransferredPoints (id, CheckingPeer, CheckedPeer, PointsAmount) ---
values ((select max(id)+1 from TransferredPoints), 'Sofia', 'Slava', '1');          ---
---------------------------------------------------------------------------------------

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
--Part3 ex1

CREATE OR REPLACE FUNCTION TransferedPoints_v1()
RETURNS TABLE(Peer1 VARCHAR, Peer2 VARCHAR, "PointsAmount" BIGINT) AS $$
begin
	create or replace view table1 as 
		(SELECT CheckingPeer AS peer1, CheckedPeer AS Peer2, SUM(PointsAmount) FROM TransferredPoints
		GROUP BY CheckingPeer, CheckedPeer);
	RETURN QUERY
	WITH table2 AS (
		SELECT
			table1.Peer1  AS Peer1,
			table1.Peer2 as Peer2,
			 table1.sum AS sum
		FROM table1
		where table1.Peer1 > table1.Peer2
		union all
		SELECT
			 table1.Peer2  AS Peer1,
			 table1.Peer1  AS Peer2,
			 table1.sum*-1  AS sum
		FROM table1
		where table1.Peer1 <= table1.Peer2
	)
	SELECT * FROM table2;
   
	
END;
$$ LANGUAGE plpgsql;
---------------------------------------------------------------------------------
select * from TransferedPoints_v1() where peer1 = 'Slava' or peer2 = 'Slava'; ---
---------------------------------------------------------------------------------

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
------ex2
--drop FUNCTION if exists completed_xp();
CREATE OR REPLACE FUNCTION completed_xp()
RETURNS TABLE(Peer VARCHAR, "Task" VARCHAR, "XP" int)
AS $$
BEGIN
RETURN QUERY	
WITH tablexp
	AS (
		select distinct Checks.peer , task, xpamount as xp
		FROM verter, Checks, xp
		where Checks.id = verter."Check" and verter."Check" =xp."Check" 
		and Checks.id = xp."Check" and state = '1'
	)	
	
SELECT tablexp.peer, tablexp.task, xp  FROM tablexp;
END;
$$ LANGUAGE plpgsql;

---------------------------------
select * from completed_xp(); ---
---------------------------------

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
-----ex3
--drop FUNCTION if exists hardWorking("day" DATE);
CREATE OR REPLACE FUNCTION hardWorking("day" DATE)
RETURNS TABLE("Peer" VARCHAR) 
AS $$
BEGIN
RETURN QUERY
	 
    (SELECT distinct peer from timetracking
    WHERE "Date" = "day" AND State = '2'
    GROUP by timetracking.peer)
		except
    (SELECT peer from timetracking
    WHERE "Date" = "day" AND State = '2' and "Time" < '23:59:59'
    GROUP by timetracking.peer);
END;
$$ LANGUAGE plpgsql;
--------------------------------------------
SELECT * FROM hardWorking('2021-10-31'); ---
--------------------------------------------

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
-----ex4
--drop FUNCTION if exists PeerPointsChange();
CREATE OR REPLACE FUNCTION PeerPointsChange()
	RETURNS TABLE("Peer" VARCHAR, PointsChange NUMERIC) AS $$
	BEGIN
	RETURN QUERY
	WITH 
		checktables as (
			(SELECT checkingpeer as peer, sum(pointsamount) as sum from transferredpoints t
      		GROUP by checkingpeer)
				union all
    		(SELECT checkedpeer as peer, sum(pointsamount)*-1 from transferredpoints t
			GROUP by checkedpeer))
    select peer, sum(sum) from checktables
    group by peer
    order by sum desc;     
END;
$$ LANGUAGE plpgsql;
--------------------------------------------------------------
SELECT * FROM PeerPointsChange() where "Peer" = 'Slava';   ---
SELECT * FROM PeerPointsChange();                          ---
--------------------------------------------------------------

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
-----ex5
----------for version 1------------
create or replace view t1 
as (
	select t.peer1 as peer, sum(t."PointsAmount") from TransferedPoints_v1() t
	group by peer1
		union all 
	select t.peer2 as peer, sum(t."PointsAmount")*-1 from TransferedPoints_v1() t
	group by peer2
);
-----------------------------------
select peer, sum(sum) from t1   ---
	--where peer = 'Slava'      ---
	group by peer               ---
	order by sum desc;          ---
                                ---
select peer, sum(sum) from t1   ---
	where peer = 'Slava'        ---
	group by peer               ---
	order by sum desc;          ---
-----------------------------------

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
-----ex6
--drop view if exists t2 cascade;

create or replace view t2 
as (
	select "Date", task, count (task) as counter from checks
	group by "Date", task
	order by "Date"
	);
create or replace view t3 
as (
	select max(counter), "Date", task from t2 
	group by "Date", task
	order by "Date"
	);
--------------------------------
select "Date", task from t3; ---
--------------------------------

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
--------ex07
--drop function if exists blokExecution1();

create or replace function blokExecution1("block" varchar)
returns table (peer varchar, day date)
as $$
declare adress_import int := length($1);
declare sumblock int:=(
				select count(*) from tasks 
				where title~$1 
						and length(title) = adress_import+1
						);
begin	
return QUERY
with t6 as (
		select count(*), checks.peer, max("Date"), count(distinct task) as sumc 
		from checks
		where task~$1 and length(task) = adress_import+1
		group by  checks.peer
		)

select t6.peer, max as "day" from t6
where sumc = sumblock;
end;
$$ LANGUAGE plpgsql;
-----------------------------------------
select * from blokExecution1('CPP');  ---
select * from blokExecution1('C');    ---
-----------------------------------------

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
--------ex08
create OR REPLACE FUNCTION recomendation() 
RETURNS TABLE (peer VARCHAR,recommendedpeer VARCHAR)
AS $$ 
BEGIN 
	RETURN QUERY 
	WITH t1 AS (
  			(select nickname,peer2 AS friend
  			FROM peers, friends
    		where nickname = peer1 )
    			union all
    		(select nickname,peer1 AS friend
  			FROM peers, friends
    		where nickname = peer2)
			),
		t2 AS (
 	 		select nickname, COUNT(r.recommendedpeer) AS counter, r.recommendedpeer
  			from t1, recommendations r
  			where t1.friend = r.peer 
				and t1.nickname != r.recommendedpeer
  			GROUP BY nickname, r.recommendedpeer),
		t3 AS (
  			select nickname, MAX(counter) AS max_count from t2
  			GROUP by nickname
			)
  
	select t2.nickname AS Peer, t2.RecommendedPeer from t2, t3
  where t2.nickname = t3.nickname AND t2.counter = t3.max_count;
END;
$$ LANGUAGE plpgsql;
---------------------------------
select * from recomendation();---
---------------------------------

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
--------ex09

--drop function if exists bloks(character varying,character varying);

create or replace function bloks("block1" varchar, "block2" varchar)
returns table (StartedBlock1 numeric,
				StartedBlock2 numeric,
				 StartedBothBlocks numeric,
				  DidntStartAnyBlock numeric)

as $$
declare all_peers int := (select count(*) from peers);
declare peers_b1 int := (with  tt as ((select peer from checks where task~$1))
											select count(*)from tt);
declare peers_b2 int := (with  tt as ((select peer from checks where task~$2))
											select count(*)from tt);
declare peers_b2_b1 int := (with  tt as ((select peer from checks where task~$1)
											intersect all  
										(select peer from checks where task~$2))
											select count(*)from tt);
declare peers_not_b2_b1 int := all_peers - ((peers_b1+peers_b2)-peers_b2_b1);

declare a float := peers_b1::float*100/all_peers::float;
declare b float := peers_b2::float*100/all_peers::float;
declare c float := peers_b2_b1::float*100/all_peers::float;
declare d float := peers_not_b2_b1::float*100/all_peers::float;
begin	
return QUERY 

select round(a::numeric , 2),
	   round(b::numeric , 2),
	   round(c::numeric , 2),
	   round(d::numeric , 2);
end;
$$ LANGUAGE plpgsql;
-----------------------------------------
select * from bloks('CPP1', 'CPP2');  ---
select * from bloks('C1', 'C1');      ---
-----------------------------------------

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
--------ex10
-----------------------------------------------------------------------
set datestyle='ISO, DMY';                                           ---
INSERT into Checks (id, Peer, Task, "Date")                         ---
values ((select max(id)+1 from p2p), 'Irina', 'N1', '09-03-2023');  ---
INSERT into P2P (id, "Check", CheckingPeer, State, "Time")          ---
values ((select max(id)+1 from P2P),                                ---
		(select max(id) from checks), 'Irina', '1', '08:58:06');    ---
                                                                    ---
INSERT into Checks (id, Peer, Task, "Date")                         ---
values ((select max(id)+1 from p2p), 'Sofia', 'N1', '18-11-2023');  ---
INSERT into P2P (id, "Check", CheckingPeer, State, "Time")          ---
values ((select max(id)+1 from P2P),                                ---
		(select max(id) from Checks), 'Sofia', '2', '08:58:06');    ---
-----------------------------------------------------------------------		

--drop function if exists sumcChecks(status status_review);

create or replace function sumcChecks(status1 status_review, status2 status_review)
returns integer
AS $$
declare sum_p integer;
begin
	with tb as (
		select distinct peers.nickname, P2P.state, peers.birthday, checks."Date" 
		from checks, p2p, peers
		where (P2P.state = $1 or P2P.state = $2) 
			  and peers.nickname = checks.peer 
			  and (EXTRACT(DAY FROM peers.birthday) = EXTRACT(DAY FROM checks."Date")
              AND EXTRACT(MONTH FROM peers.birthday) = EXTRACT(MONTH FROM checks."Date"))
			  and p2p."Check" = checks.id 
      	group by peers.nickname, P2P.state, peers.birthday, checks."Date")
select count(*)from tb into sum_p;
return sum_p;     
end;
$$ LANGUAGE plpgsql;
---------------------------------
--drop function if exists sumcchecksbirhday();
create or replace function sumcChecksbirhday()
returns table (SuccessfulChecks numeric, UnsuccessfulChecks numeric)
as $$
declare all_p integer:=sumcChecks('1', '2');
declare sac_p integer:=sumcChecks('1', '1');
declare fail_p integer := sumcChecks('2', '2');
declare a numeric := sac_p::numeric*100/all_p::numeric;
declare b numeric := fail_p::numeric*100/all_p::numeric;
begin
	--raise notice '****%**%**%*', all_p, sac_p::numeric*100/all_p::numeric, fail_p::numeric*100/all_p::numeric;
return QUERY 
	select round(a, 2),
	   	   round(b , 2);
	end;
$$ LANGUAGE plpgsql;
--------------------------------------
select * from sumcChecksbirhday(); ---
--------------------------------------

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
--------ex11

create or replace function exe_task (ex1 varchar, ex2 varchar, ex3 varchar)
returns table (peer varchar(20))
as $$
begin
RETURN QUERY
	((select checks.peer from verter, checks
	where verter.state = '1'
	and verter."Check" = verter.id 
	and task = $1
	group by state, checks.peer, task)	
		intersect all	
	(select checks.peer from verter, checks
	where verter.state = '1'
	and verter."Check" = verter.id 
	and task = $2
	group by state, checks.peer, task)
	)
		except all	
	(
	select checks.peer from verter, checks
	where verter.state = '1'
	and verter."Check" = verter.id 
	and task = $3
	group by state, checks.peer, task);
END;
$$ LANGUAGE plpgsql;
----------------------------------------------
select * from exe_task('C1', 'C2', 'N1');  ---
select * from exe_task('C1', 'C2', 'C3');  ---
----------------------------------------------

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
--------ex12

CREATE OR REPLACE FUNCTION NumberTasks() 
RETURNS TABLE("Task" VARCHAR, "PrevCount" INT) 
AS $$
declare maximum integer;
begin
	select count(*) from tasks into maximum;
	RETURN QUERY
	WITH RECURSIVE RecurceTask AS (
		SELECT Title, 0 AS PrevCount FROM Tasks
		WHERE ParentTask = 'None'
			UNION ALL
		SELECT t.Title, RecurceTask.PrevCount + 1 FROM Tasks t		
		INNER JOIN RecurceTask ON t.ParentTask = RecurceTask.Title
		where RecurceTask.PrevCount + 1 < maximum+1	)
	SELECT distinct Title::varchar AS Task, min(PrevCount)+1::INT
	FROM RecurceTask
	group by Title;
END;
$$ LANGUAGE plpgsql;
--------------------------------
select * from NumberTasks(); ---
-------------------------------- 

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
--------ex13
--DROP FUNCTION IF EXISTS luckyDays(n INT);
--DROP FUNCTION IF EXISTS luckyDays1();
CREATE OR REPLACE FUNCTION luckyDays1()

RETURNS TABLE(id int, "Date" DATE, state status_review, "Time" time)
AS $$
begin
	CREATE OR replace view table_union as (
    SELECT checks.id, "Date", state, "Time"
    FROM checks, p2p where checks.id = "Check"
             UNION 
    SELECT checks.id, checks."Date", state, "Time"
    FROM checks, verter where checks.id = "Check"
    );
   end;
   $$ LANGUAGE plpgsql; 
  
  CREATE OR REPLACE FUNCTION luckyDays(n INT)
  RETURNS TABLE(lucky_day DATE)
 as $$
select * from luckyDays1();
    WITH
    startscheck AS (
    SELECT checks.id, maxxp, "Date", "Time"
      FROM checks, p2p, tasks
     WHERE state = '0' and checks.id = "Check" and task = title
    ),
    resultcheck AS (
    SELECT DISTINCT  on (id) *  FROM luckyDays1()
     ORDER BY id, "Time" desc

    ),
    goodday AS (
    SELECT resultcheck."Date", 
    	   sum(case WHEN resultcheck.state = '1'
    	   		AND xp.xpamount::numeric*100/startscheck.maxxp >= 80
               THEN 1 ELSE 0 END) 
      OVER checksuccess AS dayluck
      FROM startscheck, resultcheck
           LEFT JOIN xp ON xp."Check" = resultcheck.id
           where startscheck.id = resultcheck.id AND startscheck."Date" = resultcheck."Date"
    WINDOW checksuccess AS (PARTITION BY startscheck."Date"
     ORDER BY startscheck."Time" ASC ROWS BETWEEN n-1 PRECEDING AND CURRENT ROW)
    )
    SELECT "Date" AS lucky_day
      FROM goodday
      where dayluck >= n
     GROUP BY "Date";
$$ LANGUAGE SQL;
--------------------------------
SELECT * FROM luckyDays(1);  ---
SELECT * FROM luckyDays(2);  ---
--------------------------------

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
--------ex14

--drop function if exists peermaxxp() ;

CREATE OR REPLACE FUNCTION PeerMaxXP() 
RETURNS TABLE("Peer" VARCHAR, "XP" BIGINT) 
AS $$
declare maximum integer;
begin
	create or replace view oneres as (
		select peer, task, max(xpamount) as xpamount 
		from checks, xp where "Check"= checks.id 
		group by peer, task
		);
	create or replace view twores as (
		select peer, sum(xpamount::integer) as xp 
		from oneres 
		group by peer
		);
select max(xp) from twores into maximum;
RETURN QUERY	
	select * from twores where XP = maximum; 
--drop view twores;
--drop view oneres;

END;
$$ LANGUAGE plpgsql;
--------------------------------
select * from PeerMaxXP() ; ---
-------------------------------- 

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
--------ex15

--drop function if exists camebefore (times TIME, counter INT);
CREATE OR REPLACE FUNCTION camebefore (times TIME, counter INT)
RETURNS TABLE (Peer VARCHAR)
AS $$
BEGIN
	RETURN QUERY
		with t as (
			SELECT TimeTracking.Peer, count(*) FROM TimeTracking
			where TimeTracking."Time" < times
			GROUP BY TimeTracking.Peer
			)
		select t.peer from t
		where count >=counter;
END;
$$ LANGUAGE PLPGSQL;
--------------------------------------------
SELECT * FROM camebefore('06:06:06', 5); ---
SELECT * FROM camebefore('16:06:06', 6); ---
--------------------------------------------

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
--------ex16

--drop function if exists ExitPeer (times Date, counter INT);

CREATE OR REPLACE FUNCTION ExitPeer (times Date, counter INT)
RETURNS TABLE (Peer VARCHAR)
AS $$
BEGIN
	RETURN QUERY
		with t as (SELECT TimeTracking.peer, count(*)
    	FROM Peers        
        INNER JOIN TimeTracking
        	ON (TimeTracking.Peer = Peers.Nickname)    
    WHERE (state = '2') AND ("Date" < $1)
    GROUP BY TimeTracking.Peer
	    )
	select t.peer from t
	where count >$2;
END;
$$ LANGUAGE PLPGSQL;
--------------------------------------------
SELECT * FROM ExitPeer('2020-01-27', 2); ---
SELECT * FROM ExitPeer('2020-01-02', 0); ---
--------------------------------------------

----------------------------------------------------
--///////////////////////////////////////////////////
-----------------------------------------------------
--------ex17
create or replace function to_month(integer) returns varchar as
$$
    select to_char(to_timestamp(to_char($1, '999'), 'MM'), 'Month');
$$ language sql;

CREATE OR replace view anycame  as (
        select peer, count(*), EXTRACT(MONTH FROM t."Date") 
		from timetracking t, peers
        where EXTRACT(MONTH FROM t."Date") = EXTRACT(MONTH FROM peers.birthday) 
		and peers.nickname = t.peer and state = '1' 
        group by peer, EXTRACT(MONTH FROM t."Date")order by EXTRACT(MONTH FROM t."Date"));
CREATE OR replace view table_anycame as ( select sum(count), extract as month from anycame group by month);
CREATE OR replace view AnyCamEearly  as (
        select peer, count(*), EXTRACT(MONTH FROM t."Date") 
		from timetracking t, peers
        where EXTRACT(MONTH FROM t."Date") = EXTRACT(MONTH FROM peers.birthday) 
		and peers.nickname = t.peer and state = '1' and t."Time" < '12:00:00'
        group by peer, EXTRACT(MONTH FROM t."Date")order by EXTRACT(MONTH FROM t."Date"));
CREATE OR replace view table2AnyCamEearly as ( select sum(count) as sum2, extract as month 
		from AnyCamEearly group by month);
 
 		select to_month (table_anycame.month::integer)AS month, 
			round((sum2::numeric * 100 / sum), 0) as EarlyEntries
 		from table2AnyCamEearly, table_anycame 
		where table2AnyCamEearly.month = table_anycame.month
 		order by table_anycame.month

-------------------------end-------------------------------------------