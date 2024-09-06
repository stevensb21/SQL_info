DROP TABLE IF EXISTS Peers,
Verter,
Tasks,
P2P,
TransferredPoints,
Friends,
Recommendations,
XP,
TimeTracking,
Checks;
drop procedure if exists imports(table_ text, delimite TEXT);
drop procedure if exists exports(table_ text, delimite TEXT);
DROP type IF exists status_review;
CREATE type status_review as enum ('0', '1', '2');

CREATE TABLE Peers (
 	Nickname  		VARCHAR(20) primary key,
  	Birthday 		date not null,
  	constraint uk_Nickname_id unique (Nickname)
  	);
  CREATE TABLE Tasks (
  	Title TEXT PRIMARY KEY NOT null default 'None',
	ParentTask TEXT,
	MaxXp 			INT not null default 0,
	constraint uk_Task_Checks unique (Title),
	FOREIGN KEY (ParentTask) REFERENCES Tasks (Title)
 	
);

CREATE TABLE Checks (
 	Id            integer not null primary key,
 	Peer  		  VARCHAR(20) not null,
	Task          VARCHAR(20),
	"Date" 		  date not null,

	constraint uk_Checks_Task1 unique (ID),
	constraint fk_Task_Checks foreign key (Task) references Tasks(Title),
	constraint fk_Checks_Peer foreign key (Peer) references Peers(Nickname)
	


);
CREATE TABLE P2P (
 	Id            serial primary key,
	"Check"        int not null,
 	CheckingPeer  VARCHAR(20) not null,
	State 		  status_review not null,
	"Time"	 time not  null,

	 constraint fk_P2P foreign key (CheckingPeer) references Peers(Nickname),
	 constraint fk_Checks_P2P_id foreign key ("Check") references Checks(Id)
);

CREATE TABLE Verter (
 	Id            serial primary key,
	"Check"         int not null,
	State 		  status_review not null,
	"Time"		  time not null,

	constraint fk_Checks_Verter_id foreign key ("Check") references Checks(Id)
);
CREATE TABLE XP (
	Id            serial primary key,
	"Check"         INT not null,
	XPAmount	  INT not null,

	constraint fk_Checks_XP_id foreign key ("Check") references Checks(Id)
);


CREATE TABLE TransferredPoints (
 	Id            serial primary key,
 	CheckingPeer  VARCHAR(20) not null,
	CheckedPeer   VARCHAR(20) not null,
	PointsAmount  INT not null default 0, 
	constraint fk_TransferredPoints1 foreign key (CheckingPeer) references Peers(Nickname),
	constraint fk_TransferredPoints2 foreign key (CheckedPeer) references Peers(Nickname)

);

CREATE TABLE Friends (
 	Id            serial primary key,
 	Peer1     	  VARCHAR(20) not null,
	Peer2   	  VARCHAR(20) not null,
		constraint fk_Friends1_id foreign key (Peer1) references Peers(Nickname),
	constraint fk_Friends2_id foreign key (Peer2) references Peers(Nickname)

	
);

CREATE TABLE Recommendations (
 	Id               serial primary key,
 	Peer     	     VARCHAR(20) not null,
	RecommendedPeer  VARCHAR(20) not null,
	constraint fk_Recommendations1_id foreign key (Peer) references Peers(Nickname),
	constraint fk_Recommendations2_id foreign key (RecommendedPeer) references Peers(Nickname)

);



CREATE TABLE TimeTracking (
 	Id            serial primary key,
 	Peer     	  VARCHAR(20),
	"Date"		  date not null,
	"Time" 	 	  time not null,
	State 		  status_review not null,
	constraint fk_peers_TimeTracking_id foreign key (Peer) references Peers(Nickname)

);

set datestyle='ISO, DMY'; 


create procedure imports(table_ text, delimite TEXT) as $$
--Надо решить с адресом /Users/mv/Desktop/dataset_sql/ куда закинуть таблицы  и откуда достать
-----------------------------------------------------------------------------------------------******
-----------------------------------------------------------------------------------------------|*****
declare adress_import varchar := '/Users/mv/Desktop/projects/SQL2_Info21_v1.0-1/src/dataset_sql/';
-----------------------------------------------------------------------------------------------|*****
-----------------------------------------------------------------------------------------------******
begin	
EXECUTE 
format('COPY %s from %L delimiter %L csv header;', $1, adress_import||$1||'.csv', $2);
end;
$$ LANGUAGE plpgsql;

call imports('Peers', ';');
call imports('Tasks', ';');
call imports('Checks', ';');
call imports('XP', ';');
call imports('P2P', ';');
call imports('TimeTracking', ';');
call imports('Friends', ';');
call imports('transferredpoints', ';');
call imports('Recommendations', ';');
call imports('Verter', ';');

--Добавление новых записей  в базу
INSERT into Peers (Nickname, Birthday)
values ('Love', '1986-08-14'), ('Svyat', '2009-03-25'), ('Alex', '2007-10-02'), ('Sofia', '2017-11-18'),
	   ('Slava', '1984-10-19'), ('Irina', '1962-03-09'), ('Vladimir', '1958-04-02');
INSERT into Tasks (Title, ParentTask, MaxXP)
values ('N1', 'C1', '150'), ('N2', 'N1', '200'), ('N3', 'N2', '200'), ('N4', 'N3', '250'), ('N5', 'N4', '300'), ('N6', 'N5', '350'), ('N7', 'N6', '400');
set datestyle='ISO, DMY';
INSERT into Checks (id, Peer, Task, "Date")
values ((select max(id)+1 from Checks), 'Vladimir', 'N1', '01-09-2023'), ((select max(id)+2 from Checks), 'Vladimir', 'N2', '25-09-2023'),
	   ((select max(id)+3 from Checks),  'Love', 'C1', '13-11-2023'), ((select max(id)+4 from Checks), 'Love', 'N1', '20-11-2023'),
	   ((select max(id)+5 from Checks),  'Irina', 'C1', '01-09-2023'), ((select max(id)+6 from Checks),  'Sofia', 'C1', '02-09-2023'), 
	   ((select max(id)+7 from Checks),  'Vladimir', 'C1', '13-08-2023'), ((select max(id)+8 from Checks),  'Slava', 'C1',  '1-08-2023'),
	   ((select max(id)+9 from Checks),  'Slava', 'C2', '10-08-2023'), ((select max(id)+10 from Checks),  'Slava', 'N1', '04-09-2023') ;
INSERT into P2P (id, "Check", CheckingPeer, State, "Time")
values ((select max(id)+1 from P2P), '1', 'Vladimir', '1', '08:58:06'), ((select max(id)+2 from P2P), '2', 'Vladimir', '2', '18:58:06'), 
	   ((select max(id)+3 from P2P), '1', 'Love', '1', '08:08:08'), ((select max(id)+4 from P2P), '2', 'Love', '2', '18:18:18'), 
	   ((select max(id)+5 from P2P), '4', 'Vladimir', '2', '06:06:06'), ((select max(id)+6 from P2P), '2', 'Irina', '2', '18:58:06'), 
	   ((select max(id)+7 from P2P), '1', 'Irina', '1', '04:54:06'), ((select max(id)+8 from P2P), '3', 'Vladimir', '2', '11:58:06'), 
	   ((select max(id)+9 from P2P), '1', 'Slava', '1', '08:58:06'), ((select max(id)+10 from P2P), '2', 'Slava', '2', '18:58:06') ;
INSERT into Verter (id, "Check", State, "Time")
  values ((select max(id)+1 from Verter), '1', '1', '09:58:06'), ((select max(id)+2 from Verter), '2', '2', '19:58:06'), 
  	     ((select max(id)+3 from Verter), '1', '1', '03:03:03'), ((select max(id)+4 from Verter), '2', '2', '19:19:19'),
  	     ((select max(id)+5 from Verter), '4', '2', '09:09:09'), ((select max(id)+6 from Verter), '2', '2', '18:58:06'), 
  	     ((select max(id)+7 from Verter), '1', '1', '05:54:06'), ((select max(id)+8 from Verter), '3', '2', '15:58:06'),
  	     ((select max(id)+9 from Verter), '1', '1', '05:58:06'), ((select max(id)+10 from Verter), '2', '2', '15:58:06') ;
INSERT into Friends (id, Peer1, Peer2)
values ((select max(id)+1 from friends), 'Love', 'Slava'), ((select max(id)+2 from friends), 'Love', 'Sofia'), ((select max(id)+3 from friends), 'Sofia', 'Slava'), 
	   ((select max(id)+4 from friends), 'Slava', 'Sofia'), ((select max(id)+5 from friends), 'Irina', 'Vladimir'), ((select max(id)+6 from friends), 'Sofia', 'Irina'),
	   ((select max(id)+7 from friends), 'Alex', 'Vladimir'), ((select max(id)+8 from friends), 'Irina', 'Slava');
INSERT into Recommendations (id, Peer, RecommendedPeer)
values ((select max(id)+1 from Recommendations), 'Love', 'Slava'), ((select max(id)+2 from Recommendations), 'Love', 'Sofia'),
	   ((select max(id)+3 from Recommendations), 'Sofia', 'Slava'), ((select max(id)+4 from Recommendations), 'Slava', 'Sofia'),
	   ((select max(id)+5 from Recommendations), 'Irina', 'Vladimir'), ((select max(id)+6 from Recommendations), 'Sofia', 'Irina'), 
	   ((select max(id)+7 from Recommendations), 'Alex', 'Vladimir'), ((select max(id)+8 from Recommendations), 'Irina', 'Slava');
INSERT into TransferredPoints (id, CheckingPeer, CheckedPeer, PointsAmount)
values ((select max(id)+1 from TransferredPoints), 'Love', 'Slava', '1'), ((select max(id)+2 from TransferredPoints), 'Love', 'Sofia', '1'),
	   ((select max(id)+3 from TransferredPoints), 'Sofia', 'Slava', '1'), ((select max(id)+4 from TransferredPoints), 'Slava', 'Sofia', '1'), 
	   ((select max(id)+5 from TransferredPoints), 'Irina', 'Vladimir', '1'), ((select max(id)+6 from TransferredPoints), 'Sofia', 'Irina', '1'),
	   ((select max(id)+7 from TransferredPoints), 'Alex', 'Vladimir', '1'), ((select max(id)+8 from TransferredPoints), 'Irina', 'Slava', '1');
INSERT into XP (id, "Check", XPAmount)
values ((select max(id)+1 from XP), 1, 250), ((select max(id)+2 from XP), 2, 250), ((select max(id)+3 from XP), 3, 300), ((select max(id)+4 from XP), 4, 350), 
	   ((select max(id)+5 from XP), 5, 400), ((select max(id)+6 from XP), 6, 450), ((select max(id)+7 from XP), 7, 400), ((select max(id)+8 from XP), 8, 450), 
	   ((select max(id)+9 from XP), 9, 500);
INSERT into TimeTracking (id, Peer, "Date", "Time", State)
 values ((select max(id)+1 from  TimeTracking), 'Vladimir', '01-09-2023', '08:58:06','1'), ((select max(id)+2 from  TimeTracking), 'Vladimir', '25-09-2023', '18:58:06', '2'), 
 	    ((select max(id)+3 from  TimeTracking), 'Love', '13-11-2023', '08:08:08', '1'), ((select max(id)+4 from  TimeTracking), 'Love', '20-11-2023','18:18:18', '2'),
 	    ((select max(id)+5 from  TimeTracking), 'Vladimir', '01-09-2023', '06:06:06', '2'), ((select max(id)+6 from  TimeTracking), 'Irina', '02-09-2023', '18:58:06', '2'), 
 	    ((select max(id)+7 from  TimeTracking), 'Irina', '13-08-2023', '04:54:06', '1'), ((select max(id)+8 from  TimeTracking), 'Vladimir','1-08-2023',  '11:58:06', '2'),
 	    ((select max(id)+9 from  TimeTracking), 'Slava', '10-08-2023', '08:58:06', '1'), ((select max(id)+10 from  TimeTracking), 'Slava', '04-09-2023', '18:58:06', '2') ;
 	    
 	   
 	   
 	   
 	   create procedure exports(table_ text, delimite TEXT) as $$
--Надо решить с адресом /Users/mv/Desktop/dataset_sql/ куда закинуть таблицы  и откуда достать
-----------------------------------------------------------------------------------------------******
-----------------------------------------------------------------------------------------------|*****
declare adress_export varchar := '/Users/mv/Desktop/projects/SQL2_Info21_v1.0-1/src/dataset_sql/new/';
-----------------------------------------------------------------------------------------------|*****
-----------------------------------------------------------------------------------------------******
begin	
EXECUTE 
format('COPY %s to %L delimiter %L csv header;', $1, adress_export||$1||'.csv', $2);
end;
$$ LANGUAGE plpgsql;

call exports('Peers', ';');
call exports('Tasks', ';');
call exports('Checks', ';');
call exports('XP', ';');
call exports('P2P', ';');
call exports('TimeTracking', ';');
call exports('Friends', ';');
call exports('transferredpoints', ';');
call exports('Recommendations', ';');
call exports('Verter', ';');

