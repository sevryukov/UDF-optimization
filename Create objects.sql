/****** Object:  UserDefinedFunction [dbo].[F_EMPLOYEE_FULLNAME]    Script Date: 28.04.2024 19:21:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- СМ. answers/task1.md и answers/task2.md
CREATE FUNCTION [dbo].[F_EMPLOYEE_FULLNAME] (
       @ID_EMPLOYEE INT
)
RETURNS VARCHAR(101)
AS
BEGIN
    DECLARE @RESULT VARCHAR(101);

    IF @ID_EMPLOYEE IS NULL
        SET @ID_EMPLOYEE = dbo.F_EMPLOYEE_GET();

    IF @ID_EMPLOYEE = -1
        RETURN '';

    SELECT
        @RESULT =
            CASE
                WHEN NULLIF(
                        RTRIM(
                            REPLACE(
                                SURNAME + ' '
                                + UPPER(LEFT(NAME, 1)) + '. '
                                + UPPER(LEFT(PATRONYMIC, 1)) + '.',
                                '. .',
                                ''
                            )
                        ),
                        ''
                     ) IS NOT NULL
                THEN RTRIM(
                        REPLACE(
                            SURNAME + ' '
                            + UPPER(LEFT(NAME, 1)) + '. '
                            + UPPER(LEFT(PATRONYMIC, 1)) + '.',
                            '. .',
                            ''
                        )
                     )
                ELSE LOGIN_NAME
            END
    FROM dbo.Employee
    WHERE Id_Employee = @ID_EMPLOYEE;

    RETURN ISNULL(@RESULT, '');
END
GO
/****** Object:  UserDefinedFunction [dbo].[F_EMPLOYEE_GET]    Script Date: 28.04.2024 19:21:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[F_EMPLOYEE_GET] ()
RETURNS
  INT
AS
BEGIN
-- Возвращает идентификатор текщего пользователя

  DECLARE
    @RESULT INT

  SELECT
    @RESULT = ID_EMPLOYEE
  FROM
    EMPLOYEE
  WHERE
    LOGIN_NAME = SYSTEM_USER

  RETURN
    @RESULT
END
GO
/****** Object:  UserDefinedFunction [dbo].[F_WORKITEMS_COUNT_BY_ID_WORK]    Script Date: 28.04.2024 19:21:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- СМ. answers/task1.md и answers/task2.md
CREATE FUNCTION [dbo].[F_WORKITEMS_COUNT_BY_ID_WORK] (
@id_work int,
@is_complit bit
)
RETURNS INT
AS
BEGIN
    DECLARE @result INT;

    SELECT
        @result = COUNT_BIG(1)
    FROM dbo.WorkItem wi
    LEFT JOIN dbo.Analiz a
        ON a.ID_ANALIZ = wi.ID_ANALIZ
       AND a.IS_GROUP = 1
    WHERE wi.Id_Work = @id_work
      AND wi.Is_Complit = @is_complit
      AND a.ID_ANALIZ IS NULL;

    RETURN ISNULL(@result, 0);
END
GO
/****** Object:  UserDefinedFunction [dbo].[F_WORKS_LIST]    Script Date: 28.04.2024 19:21:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- СМ. answers/task1.md и answers/task2.md
CREATE FUNCTION [dbo].[F_WORKS_LIST] (
)
RETURNS @RESULT TABLE
(
    ID_WORK INT,
    CREATE_Date DATETIME,
    MaterialNumber DECIMAL(8,2),
    IS_Complit BIT,
    FIO VARCHAR(255),
    D_DATE VARCHAR(10),
    WorkItemsNotComplit INT,
    WorkItemsComplit INT,
    FULL_NAME VARCHAR(101),
    StatusId SMALLINT,
    StatusName VARCHAR(255),
    Is_Print BIT
)
AS
BEGIN

    INSERT INTO @RESULT
    SELECT
        w.Id_Work,
        w.CREATE_Date,
        w.MaterialNumber,
        w.IS_Complit,
        w.FIO,

        CONVERT(VARCHAR(10), w.CREATE_Date, 104) AS D_DATE,

        ISNULL(wc.WorkItemsNotComplit, 0),
        ISNULL(wc.WorkItemsComplit, 0),

        ISNULL(
            emp.EmployeeFullName,
            e.Login_Name
        ) AS FULL_NAME,

        w.StatusId,
        ws.StatusName,

        CASE
            WHEN w.Print_Date IS NOT NULL
              OR w.SendToClientDate IS NOT NULL
              OR w.SendToDoctorDate IS NOT NULL
              OR w.SendToOrgDate IS NOT NULL
              OR w.SendToFax IS NOT NULL
            THEN 1
            ELSE 0
        END AS Is_Print

    FROM dbo.Works w

    LEFT JOIN dbo.WorkStatus ws
        ON ws.StatusID = w.StatusId

    LEFT JOIN dbo.Employee e
        ON e.Id_Employee = w.Id_Employee

    LEFT JOIN
    (
        SELECT
            wi.Id_Work,

            SUM(
                CASE
                    WHEN wi.Is_Complit = 0
                    THEN 1
                    ELSE 0
                END
            ) AS WorkItemsNotComplit,

            SUM(
                CASE
                    WHEN wi.Is_Complit = 1
                    THEN 1
                    ELSE 0
                END
            ) AS WorkItemsComplit

        FROM dbo.WorkItem wi

        LEFT JOIN dbo.Analiz a
            ON a.ID_ANALIZ = wi.ID_ANALIZ
           AND a.IS_GROUP = 1

        WHERE a.ID_ANALIZ IS NULL
        GROUP BY wi.Id_Work

    ) wc
        ON wc.Id_Work = w.Id_Work

    OUTER APPLY
    (
        SELECT
            NULLIF(
                RTRIM(
                    REPLACE(
                        e.Surname + ' '
                        + UPPER(LEFT(e.Name, 1)) + '. '
                        + UPPER(LEFT(e.Patronymic, 1)) + '.',
                        '. .',
                        ''
                    )
                ),
                ''
            ) AS EmployeeFullName
    ) emp

    WHERE w.IS_DEL <> 1

    ORDER BY w.Id_Work DESC;

    RETURN;
END

GO
/****** Object:  Table [dbo].[Analiz]    Script Date: 28.04.2024 19:21:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Analiz](
	[ID_ANALIZ] [int] IDENTITY(1,1) NOT NULL,
	[IS_GROUP] [bit] NULL,
	[MATERIAL_TYPE] [int] NULL,
	[CODE_NAME] [varchar](50) NULL,
	[FULL_NAME] [varchar](255) NULL,
	[ID_ILL] [int] NULL,
	[Text_Norm] [varchar](255) NULL,
	[Price] [decimal](8, 2) NULL,
	[NormText] [varchar](2048) NULL,
	[UnNormText] [varchar](2048) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_ANALIZ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Employee]    Script Date: 28.04.2024 19:21:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Employee](
	[Id_Employee] [int] IDENTITY(1,1) NOT NULL,
	[Login_Name] [varchar](50) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[Patronymic] [varchar](50) NOT NULL,
	[Surname] [varchar](50) NOT NULL,
	[Email] [varchar](50) NULL,
	[Post] [varchar](50) NULL,
	[CreateDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL,
	[EraseDate] [datetime] NULL,
	[Archived] [bit] NOT NULL,
	[IS_Role] [bit] NOT NULL,
	[Role] [int] NULL,
	[FULL_NAME]  AS (([SURNAME]+' ')+[NAME]),
PRIMARY KEY CLUSTERED 
(
	[Id_Employee] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Organization]    Script Date: 28.04.2024 19:21:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Organization](
	[ID_ORGANIZATION] [int] IDENTITY(1,1) NOT NULL,
	[ORG_NAME] [varchar](255) NULL,
	[TEMPLATE_FN] [varchar](255) NULL,
	[Id_PrintTemplate] [int] NULL,
	[Email] [varchar](255) NULL,
	[SecondEmail] [varchar](255) NULL,
	[Fax] [varchar](255) NULL,
	[SecondFax] [varchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_ORGANIZATION] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PrintTemplate]    Script Date: 28.04.2024 19:21:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PrintTemplate](
	[Id_PrintTemplate] [int] IDENTITY(1,1) NOT NULL,
	[TemplateName] [varchar](255) NULL,
	[CreateDate] [datetime] NULL,
	[Ext] [varchar](10) NULL,
	[Comment] [varchar](255) NULL,
	[TemplateBody] [image] NULL,
	[Id_TemplateType] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id_PrintTemplate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SelectType]    Script Date: 28.04.2024 19:21:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SelectType](
	[Id_SelectType] [int] IDENTITY(1,1) NOT NULL,
	[SelectType] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id_SelectType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TemplateType]    Script Date: 28.04.2024 19:21:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TemplateType](
	[Id_TemplateType] [int] IDENTITY(1,1) NOT NULL,
	[TemlateVal] [varchar](50) NULL,
	[Comment] [varchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id_TemplateType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[WorkItem]    Script Date: 28.04.2024 19:21:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkItem](
	[ID_WORKItem] [int] IDENTITY(1,1) NOT NULL,
	[CREATE_DATE] [datetime] NULL,
	[Is_Complit] [bit] NOT NULL,
	[Close_Date] [datetime] NULL,
	[Id_Employee] [int] NULL,
	[ID_ANALIZ] [int] NULL,
	[Id_Work] [int] NULL,
	[Is_Print] [bit] NOT NULL,
	[Is_Select] [bit] NOT NULL,
	[Is_NormTextPrint] [bit] NULL,
	[Price] [decimal](8, 2) NULL,
	[Id_SelectType] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID_WORKItem] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Works]    Script Date: 28.04.2024 19:21:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Works](
	[Id_Work] [int] IDENTITY(1,1) NOT NULL,
	[IS_Complit] [bit] NOT NULL,
	[CREATE_Date] [datetime] NULL,
	[Close_Date] [datetime] NULL,
	[Id_Employee] [int] NULL,
	[ID_ORGANIZATION] [int] NULL,
	[Comment] [varchar](255) NULL,
	[Print_Date] [datetime] NULL,
	[Org_Name] [varchar](50) NULL,
	[Part_Name] [varchar](50) NULL,
	[Org_RegN] [int] NULL,
	[Material_Type] [smallint] NULL,
	[Material_Get_Date] [datetime] NULL,
	[Material_Reg_Date] [datetime] NULL,
	[MaterialNumber] [decimal](8, 2) NULL,
	[Material_Comment] [varchar](255) NULL,
	[FIO] [varchar](255) NOT NULL,
	[PHONE] [varchar](50) NULL,
	[EMAIL] [varchar](255) NULL,
	[Is_Del] [bit] NOT NULL,
	[Id_Employee_Del] [int] NULL,
	[DelDate] [datetime] NULL,
	[Price] [decimal](8, 2) NULL,
	[ExtRegN] [varchar](255) NULL,
	[MedicalHistoryNumber] [varchar](255) NULL,
	[DoctorFIO] [varchar](255) NULL,
	[DoctorPhone] [varchar](255) NULL,
	[OrganizationFax] [varchar](255) NULL,
	[OrganizationEmail] [varchar](255) NULL,
	[DoctorEmail] [varchar](255) NULL,
	[StatusId] [smallint] NULL,
	[SendToOrgDate] [datetime] NULL,
	[SendToClientDate] [datetime] NULL,
	[SendToDoctorDate] [datetime] NULL,
	[SendToFax] [datetime] NULL,
	[SendToApp] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id_Work] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[WorkStatus]    Script Date: 28.04.2024 19:21:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkStatus](
	[StatusID] [smallint] IDENTITY(1,1) NOT NULL,
	[StatusName] [varchar](255) NULL,
 CONSTRAINT [PK_WorkStatus] PRIMARY KEY CLUSTERED 
(
	[StatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [XAKLoginName]    Script Date: 28.04.2024 19:21:25 ******/
CREATE UNIQUE NONCLUSTERED INDEX [XAKLoginName] ON [dbo].[Employee]
(
	[Login_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [XIF1Organization]    Script Date: 28.04.2024 19:21:25 ******/
CREATE NONCLUSTERED INDEX [XIF1Organization] ON [dbo].[Organization]
(
	[Id_PrintTemplate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [XIF1PrintTemplate]    Script Date: 28.04.2024 19:21:25 ******/
CREATE NONCLUSTERED INDEX [XIF1PrintTemplate] ON [dbo].[PrintTemplate]
(
	[Id_TemplateType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [XIF3WorkItem]    Script Date: 28.04.2024 19:21:25 ******/
CREATE NONCLUSTERED INDEX [XIF3WorkItem] ON [dbo].[WorkItem]
(
	[Id_Employee] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [XIF4WorkItem]    Script Date: 28.04.2024 19:21:25 ******/
CREATE NONCLUSTERED INDEX [XIF4WorkItem] ON [dbo].[WorkItem]
(
	[ID_ANALIZ] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [XIF5WorkItem]    Script Date: 28.04.2024 19:21:25 ******/
CREATE NONCLUSTERED INDEX [XIF5WorkItem] ON [dbo].[WorkItem]
(
	[Id_Work] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [XIF6WorkItem]    Script Date: 28.04.2024 19:21:25 ******/
CREATE NONCLUSTERED INDEX [XIF6WorkItem] ON [dbo].[WorkItem]
(
	[Id_SelectType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [XIF1Works]    Script Date: 28.04.2024 19:21:25 ******/
CREATE NONCLUSTERED INDEX [XIF1Works] ON [dbo].[Works]
(
	[Id_Employee] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [XIF2Works]    Script Date: 28.04.2024 19:21:25 ******/
CREATE NONCLUSTERED INDEX [XIF2Works] ON [dbo].[Works]
(
	[ID_ORGANIZATION] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [XIF3Works]    Script Date: 28.04.2024 19:21:25 ******/
CREATE NONCLUSTERED INDEX [XIF3Works] ON [dbo].[Works]
(
	[Id_Employee_Del] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Employee] ADD  DEFAULT (suser_sname()) FOR [Login_Name]
GO
ALTER TABLE [dbo].[Employee] ADD  DEFAULT ('') FOR [Name]
GO
ALTER TABLE [dbo].[Employee] ADD  DEFAULT ('') FOR [Patronymic]
GO
ALTER TABLE [dbo].[Employee] ADD  DEFAULT ('') FOR [Surname]
GO
ALTER TABLE [dbo].[Employee] ADD  DEFAULT ((0)) FOR [Archived]
GO
ALTER TABLE [dbo].[Employee] ADD  DEFAULT ((0)) FOR [IS_Role]
GO
ALTER TABLE [dbo].[Employee] ADD  DEFAULT ((0)) FOR [Role]
GO
ALTER TABLE [dbo].[PrintTemplate] ADD  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[WorkItem] ADD  DEFAULT (getdate()) FOR [CREATE_DATE]
GO
ALTER TABLE [dbo].[WorkItem] ADD  DEFAULT ((0)) FOR [Is_Complit]
GO
ALTER TABLE [dbo].[WorkItem] ADD  DEFAULT ((1)) FOR [Is_Print]
GO
ALTER TABLE [dbo].[WorkItem] ADD  DEFAULT ((0)) FOR [Is_Select]
GO
ALTER TABLE [dbo].[WorkItem] ADD  DEFAULT ((1)) FOR [Is_NormTextPrint]
GO
ALTER TABLE [dbo].[Works] ADD  DEFAULT ((0)) FOR [IS_Complit]
GO
ALTER TABLE [dbo].[Works] ADD  DEFAULT (getdate()) FOR [CREATE_Date]
GO
ALTER TABLE [dbo].[Works] ADD  DEFAULT (getdate()) FOR [Material_Get_Date]
GO
ALTER TABLE [dbo].[Works] ADD  DEFAULT (getdate()) FOR [Material_Reg_Date]
GO
ALTER TABLE [dbo].[Works] ADD  DEFAULT ((0)) FOR [Is_Del]
GO
ALTER TABLE [dbo].[Organization]  WITH NOCHECK ADD  CONSTRAINT [FK__Organizat__Id_Pr__14270015] FOREIGN KEY([Id_PrintTemplate])
REFERENCES [dbo].[PrintTemplate] ([Id_PrintTemplate])
GO
ALTER TABLE [dbo].[Organization] CHECK CONSTRAINT [FK__Organizat__Id_Pr__14270015]
GO
ALTER TABLE [dbo].[PrintTemplate]  WITH NOCHECK ADD  CONSTRAINT [FK__PrintTemp__Id_Te__151B244E] FOREIGN KEY([Id_TemplateType])
REFERENCES [dbo].[TemplateType] ([Id_TemplateType])
GO
ALTER TABLE [dbo].[PrintTemplate] CHECK CONSTRAINT [FK__PrintTemp__Id_Te__151B244E]
GO
ALTER TABLE [dbo].[WorkItem]  WITH NOCHECK ADD  CONSTRAINT [FK__WorkItem__ID_ANA__1F98B2C1] FOREIGN KEY([ID_ANALIZ])
REFERENCES [dbo].[Analiz] ([ID_ANALIZ])
GO
ALTER TABLE [dbo].[WorkItem] CHECK CONSTRAINT [FK__WorkItem__ID_ANA__1F98B2C1]
GO
ALTER TABLE [dbo].[WorkItem]  WITH NOCHECK ADD  CONSTRAINT [FK__WorkItem__Id_Emp__208CD6FA] FOREIGN KEY([Id_Employee])
REFERENCES [dbo].[Employee] ([Id_Employee])
GO
ALTER TABLE [dbo].[WorkItem] CHECK CONSTRAINT [FK__WorkItem__Id_Emp__208CD6FA]
GO
ALTER TABLE [dbo].[WorkItem]  WITH NOCHECK ADD  CONSTRAINT [FK__WorkItem__Id_Sel__1DB06A4F] FOREIGN KEY([Id_SelectType])
REFERENCES [dbo].[SelectType] ([Id_SelectType])
GO
ALTER TABLE [dbo].[WorkItem] CHECK CONSTRAINT [FK__WorkItem__Id_Sel__1DB06A4F]
GO
ALTER TABLE [dbo].[WorkItem]  WITH NOCHECK ADD  CONSTRAINT [FK__WorkItem__Id_Wor__1EA48E88] FOREIGN KEY([Id_Work])
REFERENCES [dbo].[Works] ([Id_Work])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[WorkItem] CHECK CONSTRAINT [FK__WorkItem__Id_Wor__1EA48E88]
GO
ALTER TABLE [dbo].[Works]  WITH NOCHECK ADD  CONSTRAINT [FK__Works__Id_Employ__2180FB33] FOREIGN KEY([Id_Employee_Del])
REFERENCES [dbo].[Employee] ([Id_Employee])
GO
ALTER TABLE [dbo].[Works] CHECK CONSTRAINT [FK__Works__Id_Employ__2180FB33]
GO
ALTER TABLE [dbo].[Works]  WITH NOCHECK ADD  CONSTRAINT [FK__Works__Id_Employ__236943A5] FOREIGN KEY([Id_Employee])
REFERENCES [dbo].[Employee] ([Id_Employee])
GO
ALTER TABLE [dbo].[Works] CHECK CONSTRAINT [FK__Works__Id_Employ__236943A5]
GO
ALTER TABLE [dbo].[Works]  WITH NOCHECK ADD  CONSTRAINT [FK__Works__ID_ORGANI__22751F6C] FOREIGN KEY([ID_ORGANIZATION])
REFERENCES [dbo].[Organization] ([ID_ORGANIZATION])
GO
ALTER TABLE [dbo].[Works] CHECK CONSTRAINT [FK__Works__ID_ORGANI__22751F6C]
GO
