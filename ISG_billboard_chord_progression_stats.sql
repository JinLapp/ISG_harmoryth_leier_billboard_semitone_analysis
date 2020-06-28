/****** Skript to create chord progression statistics (progressions of four chords) ******/

/************ put 4 consequtive chords in a row */
SELECT 
		scp.[SCP_ID]
      ,scp.[Song_ID]
      ,scp.[Time_Start]
      ,scp.[Time_End]
      ,scp.[Chord]
      ,scp.[Chord_Preceding]
      ,scp.[Semitone_Interval_Preceding]
      ,scp.[Semitone_Interval_Delta]
      ,scp.[Semitone_Interval] 
	  ,scp.Semitone_Interval_Delta delta_1
	  ,last_value(scp.Semitone_Interval_Delta) over 
			(partition by scp.Song_ID 
			 order by scp.Time_Start asc rows between  current row and 1  following ) delta_2
	  ,last_value(scp.Semitone_Interval_Delta) over 
			(partition by scp.Song_ID 
			 order by scp.Time_Start asc rows between  current row and 2  following ) delta_3
	  ,last_value(scp.Semitone_Interval_Delta) over 
			(partition by scp.Song_ID 
			 order by scp.Time_Start asc rows between  current row and 3 following ) delta_4
	, ROW_NUMBER() over (partition by song_id order by time_start desc) rowsCnt -- inverted index per song
into #t4ChordsProgressions
 FROM [testDB].[billb].[Song_Chord_Progression] scp
 where scp.Semitone_Interval_Delta != 0 -- rows where chord and preceding chord are identical will be deleted
 order by song_id asc , Time_Start asc



/*********************** keep only distinct chord progressions per song ****************/

select t.Song_ID, delta_1, delta_2,delta_3
into #t3DistinctChordsProgressions
from  #t4ChordsProgressions t
where t.rowsCnt >= 4 -- delete the last 3 rows of chords of a song (because those can't build a set of 4 chords any more)
group by t.Song_ID, delta_1, delta_2,delta_3
order by t.Song_ID, delta_1, delta_2,delta_3

/*********************** count distinct chord progressions ****************/

select delta_1, delta_2,delta_3, count(*) cnt 
--into #tSearchProgressions
from #t3DistinctChordsProgressions t
group by delta_1, delta_2,delta_3
order by count(*) desc


/*********************** search for specific chord progressions ****************/
select * from 
#tSearchProgressions t
where 
t.delta_1 = 8 and
t.delta_2 = 7 and
t.delta_3 = 5





select sum(cnt) from 
#tSearchProgressions t