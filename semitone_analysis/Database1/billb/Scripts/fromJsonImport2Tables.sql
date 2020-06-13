
/*
extract infromation from TAble [OLE DB-Ziel]

1. run script etlJsonBillboardData_ExampleSet
-- create database
-- create table
-- run insert commands

2. 
-- create schema
-- create tables (code: see project billb/tables)
-- relational DB solution
--- rund insert commands
-- graph DB solution
--- rund insert commands
*/


if(db_id('testDB') is null)
	begin
	create database testDB;
	end ;
go

create schema billb ;
go 




/*=================== fill relational DB solution ======================*/

------------- insert song Info from json strings -------------
insert into billb.Song (Song_ID,Title,Artist,chart_date,Billboard_Peak_Position )
select convert(int,id), title,artist ,convert(date,chart_date,102), convert(int,peak_rank)
from [dbo].[OLE DB-Ziel]
	cross apply openjson([Spalte 0])
	with
		(
		sandbox nvarchar(max) as json ,
		chord nvarchar(max) as json,
		file_metadata nvarchar(max) as json) as x
	cross apply openjson(sandbox, '$')
		with
		(
		chart_date nvarchar(max) '$.chart_date',
		peak_rank nvarchar(max) '$.peak_rank',
		actual_rank nvarchar(max) '$.actual_rank',
		target_rank nvarchar(max) '$.target_rank',
		id nvarchar(max) '$.id'
		)
	cross apply openjson(file_metadata,'$')
		with 
		(
		title nvarchar(max) '$.title',
		artist nvarchar(max) '$.artist'
		)
; 
go

------------------- insert chord data into chord_progession_table ----------------

insert into billb.Song_Chord_Progression (Song_ID,Time_Start,Time_End,Chord,Semitone_Interval)
select 
convert(int,id), convert(decimal(10,3), chordstart),convert(decimal(10,3), chordend),chord1, 
case	
	when chord1 like '%C:%' then 1
	when chord1 like '%C#:%' then 2
	when chord1 like '%Db:%' then 2
	when chord1 like '%D:%' then 3
	when chord1 like '%D#:%' then 4
	when chord1 like '%Eb:%' then 4
	when chord1 like '%E:%' then 5
	when chord1 like '%Fb:%' then 5
	when chord1 like '%F:%' then 6
	when chord1 like '%F#:%' then 7
	when chord1 like '%Gb:%' then 7
	when chord1 like '%G:%' then 8
	when chord1 like '%G#:%' then 9
	when chord1 like '%Ab:%' then 9
	when chord1 like '%A:%' then 10
	when chord1 like '%A#:%' then 11
	when chord1 like '%Bb:%' then 11
	when chord1 like '%B:%' then 12
	when chord1 like '%Cb:%' then 12
	else 0 end step
--select *
from [dbo].[OLE DB-Ziel]
cross apply openjson([Spalte 0])
	with
	(
	sandbox nvarchar(max) as json ,
	chord nvarchar(max) as json
	) as x
cross apply openjson(sandbox, '$')
	with
	(
	id nvarchar(max) '$.id'
	)
cross apply openjson(chord, '$')
	with
	([data] nvarchar(max) as json )
	cross apply openjson([data],'$') 
		with
		(
		chordstart nvarchar(max) '$.start.value',
		chordend nvarchar(max) '$.end.value',
		chord1 nvarchar(max) '$.label.value'
		)
order by convert(int,id), convert(decimal(10,3), chordstart)
		;

go

-------------- complete song_progression Table with Info for chord_progression calculations ---------------

update scp
set 
	scp.Chord_Preceding =  	scp2.Chord_Preceding ,
	scp.Semitone_Interval_Preceding =  scp2.Semitone_Interval_Preceding
from billb.Song_Chord_Progression scp
inner join ( select scp.SCP_ID, 
	Chord_Preceding =  first_value(scp.Chord) over (partition by scp.Song_ID order by scp.Time_Start asc rows between 1 preceding and current row) ,
	Semitone_Interval_Preceding =  first_value(scp.Semitone_Interval) over (partition by scp.Song_ID order by scp.Time_Start asc rows between 1 preceding and current row) 
	from billb.Song_Chord_Progression scp ) scp2 on scp.SCP_ID = scp2.SCP_ID
; 

-------------- calculate the number of semitones between 2 consecutive chords ---------------

update scp
set scp.Semitone_Interval_Delta = case 
	when scp.Semitone_Interval > scp.Semitone_Interval_Preceding then scp.Semitone_Interval - scp.Semitone_Interval_Preceding
	when scp.Semitone_Interval < scp.Semitone_Interval_Preceding then 12 - scp.Semitone_Interval_Preceding + scp.Semitone_Interval 
	else 0 end 
from billb.Song_Chord_Progression scp



-------------------- concat all chords and semitone intervals in 1 String each per song ------------------

update s
set s.Chrod_Progression = scp.chprg,
s.Semitone_Progression = scp.semiprg
from 
(select song_id,
STRING_AGG(convert(varchar(10),scp.Chord),'-') chprg, 
STRING_AGG(convert(varchar(10),Semitone_Interval_Delta),'-') semiprg
from  
billb.Song_Chord_Progression scp
where 
scp.Semitone_Interval_Delta != 0
group by scp.Song_ID ) scp
inner join billb.Song s on scp.Song_ID = s.song_id


---------------------- search semi-tone-interval string vor specific chord progressions --------------

select * from billb.Song s where semitone_progression like '%9-8-2%'


/*=================== fill graph DB solution ======================*/

/*
Nodes and Edges: 
NODE: each chord in a song is considered as NODE
Edge: each transition from one chord to another it considered as edge w/ specific weight: the semitone interval

Thus, a song is modelled as one graph with a sucession of chord-nodes and semitone edged in between
*/
--------------- fill node Table --------------------------
insert into  billb.Song_Chord_Progression_node (SCP_ID,Song_ID,Time_Start,Time_End,Chord,Chord_Preceding
	,Semitone_Interval,Semitone_Interval_Preceding,Semitone_Interval_Delta)
select SCP_ID,Song_ID,Time_Start,Time_End,Chord,Chord_Preceding
	,Semitone_Interval,Semitone_Interval_Preceding,Semitone_Interval_Delta
from billb.Song_Chord_Progression


------------- fill edge table -------------------------
--truncate table billb.progresses
insert into billb.progresses ($from_id, $to_id, interval)
select 
scp_prec.$node_id col1,scp_fol.$node_id col2, scp_fol.Semitone_Interval_Delta
from billb.Song_Chord_Progression_node scp_prec
inner join billb.Song_Chord_Progression_node scp_fol 
on scp_prec.Song_ID = scp_fol.Song_ID
and scp_prec.Time_End = scp_fol.Time_Start
where scp_prec.Semitone_Interval_Delta != 0
order by scp_prec.scp_id





------------------ query edge Table für vi-(8)->IV-(7)->I-(7)->V      ------

select * from billb.song_chord_progression scp
inner join 
(SELECT top 100
scp_0.song_id song_id0,
scp_0.scp_id scp_id0,
scp_1.song_id song_id1,
scp_2.scp_id scp_id1,
scp_0.chord chord0,p0.interval int0,scp_1.chord ch1,p1.interval int1, scp_2.chord ch2, p2.interval int2, scp_3.chord ch3, p3.interval int3,scp_4.chord ch4
FROM 
billb.Song_Chord_Progression_node scp_0, 
billb.Song_Chord_Progression_node scp_1, 
billb.Song_Chord_Progression_node scp_2, 
billb.Song_Chord_Progression_node scp_3, 
billb.Song_Chord_Progression_node scp_4, 
billb.progresses p0,
billb.progresses p1,
billb.progresses p2,
billb.progresses p3
WHERE MATCH(scp_0-(p0)->scp_1-(p1)->scp_2-(p2)->scp_3-(p3)->scp_4)
AND p1.interval = 8
AND p2.interval = 7
and p3.interval = 7
) t on t.scp_id1 = scp.scp_id