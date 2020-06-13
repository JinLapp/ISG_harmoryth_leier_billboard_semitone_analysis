CREATE TABLE [billb].[Song_Chord_Progression] (
    [SCP_ID]                      INT             IDENTITY (1, 1) NOT NULL,
    [Song_ID]                     INT             NOT NULL,
    [Time_Start]                  DECIMAL (10, 3) NULL,
    [Time_End]                    DECIMAL (10, 3) NULL,
    [Chord]                       NVARCHAR (50)   NULL,
    [Chord_Preceding]             NVARCHAR (50)   NULL,
    [Semitone_Interval]           INT             NULL,
    [Semitone_Interval_Preceding] INT             NULL,
    [Semitone_Interval_Delta]     INT             NULL
);

