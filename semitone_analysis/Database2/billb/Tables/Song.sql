CREATE TABLE [billb].[Song] (
    [Song_ID]                 INT             NOT NULL,
    [Title]                   NVARCHAR (1000) NOT NULL,
    [Artist]                  NVARCHAR (1000) NULL,
    [chart_date]              DATE            NULL,
    [Billboard_Peak_Position] INT             NULL,
    [Chrod_Progression]       NVARCHAR (MAX)  NULL,
    [Semitone_Progression]    NVARCHAR (MAX)  NULL
);

