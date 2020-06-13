CREATE TABLE [billb].[Song_Chord_Progression_node] (
    [SCP_ID]                      INT             NOT NULL,
    [Song_ID]                     INT             NOT NULL,
    [Time_Start]                  DECIMAL (10, 3) NULL,
    [Time_End]                    DECIMAL (10, 3) NULL,
    [Chord_rank]                  INT             NULL,
    [Chord]                       NVARCHAR (50)   NULL,
    [Chord_Preceding]             NVARCHAR (50)   NULL,
    [Semitone_Interval]           INT             NULL,
    [Semitone_Interval_Preceding] INT             NULL,
    [Semitone_Interval_Delta]     INT             NULL,
    PRIMARY KEY CLUSTERED ([SCP_ID] ASC),
    INDEX [GRAPH_UNIQUE_INDEX_4B1EFDF12FDB4053A191AA8F5497EE75] UNIQUE NONCLUSTERED ($node_id)
) AS NODE;

