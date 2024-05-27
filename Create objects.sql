/****** Object:  UserDefinedFunction [dbo].[F_EMPLOYEE_FULLNAME]    Script Date: 28.04.2024 19:21:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[F_EMPLOYEE_FULLNAME] ( 
       @ID_EMPLOYEE INT 
) 
RETURNS VARCHAR(101) 
AS 
BEGIN 
  DECLARE @RESULT VARCHAR(101) 
  IF @ID_EMPLOYEE IS NULL 
     SET @ID_EMPLOYEE = dbo.F_EMPLOYEE_GET()
  SELECT @RESULT = COALESCE(SURNAME + ' ' + UPPER(SUBSTRING(NAME, 1, 1)) + '. ' + UPPER(SUBSTRING(PATRONYMIC, 1, 1) + '.', LOGIN_NAME), '') 
  FROM Employee 
  WHERE ID_EMPLOYEE = @ID_EMPLOYEE
  SET @RESULT = RTRIM(REPLACE(@RESULT, '. .', '')) 
  
  IF @RESULT = ''
	SELECT @RESULT = LOGIN_NAME FROM Employee Where Id_Employee = @ID_Employee
  RETURN @RESULT
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

CREATE FUNCTION [dbo].[F_WORKITEMS_COUNT_BY_ID_WORK] (
@id_work int,
@is_complit bit
)
RETURNS int
AS
BEGIN
-- количество готовых / не готовых анализов для заказа
     declare @result int
     select @result = count(ID_WORKItem) from workitem
     where id_work = @id_work
     -- не является групповым
     and id_analiz 
	 not in 
		 (select id_analiz 
		 from analiz where is_group = 1)
     
	 and is_complit = @is_complit

     Return @result
END
GO
/****** Object:  UserDefinedFunction [dbo].[F_WORKS_LIST]    Script Date: 28.04.2024 19:21:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[F_WORKS_LIST] (
)
RETURNS @RESULT TABLE
(
ID_WORK INT,
CREATE_Date DATETIME,
MaterialNumber DECIMAL(8,2),
IS_Complit BIT,
FIO VARCHAR(255),
D_DATE varchar(10),
WorkItemsNotComplit int,
WorkItemsComplit int,
FULL_NAME VARCHAR(101),
StatusId smallint,
StatusName VARCHAR(255),
Is_Print bit
)
AS
-- СПИСОК РАБОТ
begin
insert into @result
SELECT
  Works.Id_Work,
  Works.CREATE_Date,
  Works.MaterialNumber,
  Works.IS_Complit,
  Works.FIO,
  convert(varchar(10), works.CREATE_Date, 104 ) as D_DATE,
  dbo.F_WORKITEMS_COUNT_BY_ID_WORK(works.Id_Work,0) as WorkItemsNotComplit,
  dbo.F_WORKITEMS_COUNT_BY_ID_WORK(works.Id_Work,1) as WorkItemsComplit,
  dbo.F_EMPLOYEE_FULLNAME(Works.Id_Employee) as EmployeeFullName,
  Works.StatusId,
  WorkStatus.StatusName,
  case
      when (Works.Print_Date is not null) or
      (Works.SendToClientDate is not null) or
      (works.SendToDoctorDate is not null) or
      (Works.SendToOrgDate is not null) or
      (Works.SendToFax is not null)
      then 1
      else 0
  end as Is_Print  
FROM
 Works
 left outer join WorkStatus on (Works.StatusId = WorkStatus.StatusID)
where
 WORKS.IS_DEL <> 1
 order by id_work desc -- works.MaterialNumber desc
return
end

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
