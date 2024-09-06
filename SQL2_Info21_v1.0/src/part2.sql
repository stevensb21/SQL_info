--DROP PROCEDURE IF EXISTS add_p2p_check2 CASCADE;
CREATE OR REPLACE PROCEDURE add_p2p_check2(checked_peer varchar, checking_peer varchar,
                                        tasks varchar, status status_review, "times" time)
AS $$
    DECLARE
        check_id integer := (SELECT MAX(ID) FROM checks) + 1;
    BEGIN
        IF status = '0' then

            INSERT INTO checks(id, peer, task, "Date")
                   VALUES ((select max(id) from checks)+1, checked_peer, tasks, now());
            INSERT INTO p2p(id, "Check", CheckingPeer, State, "Time")
			VALUES ((SELECT MAX(ID) FROM p2p) + 1,
				   (select max(id) from checks),
				   checking_peer,
				   status,
				   "times");

       
       ELSE
		INSERT INTO p2p(id, "Check", CheckingPeer, State, "Time")
		VALUES ((SELECT MAX(ID) FROM p2p) + 1,
			   (SELECT "Check"
			   FROM p2p
			   JOIN checks ON p2p."Check" = checks.id
			   WHERE p2p.checkingpeer = checking_peer AND
			   	checks.task = tasks limit 1),
			   checking_peer,
				   status,
				   "times");

        END IF;

     
    END;
$$ LANGUAGE plpgsql;
-----------------------------

CALL add_p2p_check2('Slava', 'Love', 'C1', '0', '05:43:00');
CALL add_p2p_check2('Slava', 'Love', 'C1', '1', '05:47:00');

CALL add_p2p_check2('Irina', 'Slava', 'C4', '0', '15:43:00');
CALL add_p2p_check2('Irina', 'Slava', 'C4', '2', '14:23:55');






-- TASK 2
--DROP PROCEDURE IF EXISTS add_verter_review CASCADE;

CREATE OR REPLACE PROCEDURE add_verter_review (
	IN nick_check_peer VARCHAR,
	IN taskname VARCHAR,
	IN status status_review,
	IN check_time TIME
)
LANGUAGE plpgsql
AS
$$
BEGIN
	IF (status = '0') THEN
		IF (
	(SELECT MAX(p2p."Time") FROM p2p
			JOIN checks ON p2p."Check" = checks.id
			WHERE checks.peer = nick_check_peer AND
				checks.task = taskname AND
				p2p.state = '1') IS NOT null ) THEN
			INSERT INTO verter
			VALUES ((SELECT MAX(ID) FROM verter) + 1,
				   (SELECT DISTINCT checks.id FROM p2p
				   JOIN checks ON p2p."Check" = checks.id
				   WHERE checks.peer = nick_check_peer AND
				   	checks.task = taskname AND
				   	p2p.state = '1'),
				   	status,
				   	check_time);
		ELSE
			RAISE EXCEPTION 'Error: P2P check is not completed or was failed';
		END IF;
	else 
		INSERT INTO verter
		VALUES ((SELECT MAX(ID) FROM verter) + 1,
			   (SELECT "Check" FROM verter
			   GROUP BY "Check"
			   HAVING mod(count(*), 2) = 1 limit 1),
			   status,
			   check_time) limit 1;
	END IF;
END;
$$;
call add_verter_review (
	'Vladimir',
	'N1',
	'1',
	'09:58:06'
);
call add_verter_review (
	'Vladimir',
	'N1',
	'2',
	'09:58:06'
);


-- TASK 3
--DROP FUNCTION IF EXISTS fnc_update_transferredpoints() CASCADE;

CREATE OR REPLACE FUNCTION fnc_update_transferredpoints () RETURNS TRIGGER AS
$$
BEGIN
	IF (new.state = '0') THEN
		WITH tmp AS (SELECT checks.peer AS peer FROM p2p
					JOIN checks ON p2p."Check" = checks.id
					WHERE state = '0' AND
						new."Check" = checks.id)
		UPDATE transferredpoints
		SET pointsamount = pointsamount + 1
		FROM tmp
		WHERE tmp.peer = transferredpoints.checkedpeer AND
			new.checkingpeer = transferredpoints.checkingpeer;
	END IF;
	RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trg_transferredpoints
	AFTER INSERT ON p2p FOR EACH ROW
	EXECUTE FUNCTION fnc_update_transferredpoints();

-- TASK 4
DROP FUNCTION IF EXISTS check_xp_correctness() CASCADE;

CREATE OR REPLACE FUNCTION check_xp_correctness()
    RETURNS TRIGGER AS
$$
BEGIN
	IF ((SELECT maxxp FROM checks
		JOIN tasks ON checks.task = tasks.title
		WHERE new."Check" = checks.id) < new.xpamount) THEN
		RAISE EXCEPTION 'Error: XP amount exceeds the max value';
	ELSEIF (SELECT state
		   FROM p2p
		   WHERE new."Check" = p2p."Check" AND
		   	p2p.state IN ('1', '2')) = '2' THEN
			RAISE EXCEPTION 'Error: Failure check (peer)';
	ELSEIF (SELECT state FROM verter
		   WHERE new."Check" = verter."Check" AND
		   	verter.state = '2') = '2' THEN
			RAISE EXCEPTION 'Error: Failure check (Verter)';
	END IF;
	RETURN (new.id, new."Check", new.xpamount);
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER trg_check_xp_correctness
	BEFORE INSERT ON xp FOR EACH ROW
	EXECUTE FUNCTION check_xp_correctness();