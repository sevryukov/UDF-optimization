CREATE VIEW rndView
AS
SELECT RAND() rndResult;


CREATE FUNCTION dbo.RandomString(@length INT) RETURNS VARCHAR(255)
AS
BEGIN
  DECLARE @chars NVARCHAR(62), @result NVARCHAR(255)
  SET @chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  SET @result = ''
  WHILE LEN(@result) < @length
    SET @result += SUBSTRING(@chars, CONVERT(int, (select rndResult from rndView) * 62) + 1, 1)
  RETURN @result
END


CREATE FUNCTION dbo.RandomEmail(@domain VARCHAR(100)) RETURNS VARCHAR(255)
AS
BEGIN
  RETURN dbo.RandomString(10) + '@' + @domain
END


CREATE FUNCTION dbo.RandomDate() RETURNS DATETIME
AS
BEGIN
  RETURN DATEADD(DAY, CAST((select rndResult from rndView) * 3650 * -1 AS INT), GETDATE())
END


CREATE FUNCTION dbo.RandomBit()
RETURNS bit
AS
BEGIN
  RETURN CASE WHEN (select rndResult from rndView) >= 0.5 THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END
END


CREATE FUNCTION dbo.RandomPrice() RETURNS DECIMAL(8, 2)
AS
BEGIN
  RETURN CAST((select rndResult from rndView) * 10000 AS DECIMAL(8, 2))
END


CREATE FUNCTION dbo.RandomInt(@max INT) RETURNS INT
AS
BEGIN
  RETURN CAST((select rndResult from rndView) * @max AS INT) + 1
END


DECLARE @analize_cnt INT = 0;
WHILE @analize_cnt < 100
BEGIN
  INSERT INTO [dbo].[Analiz] (
    [IS_GROUP],
    [MATERIAL_TYPE],
    [CODE_NAME],
    [FULL_NAME],
    [ID_ILL],
    [Text_Norm],
    [Price],
    [NormText],
    [UnNormText]
  )
  VALUES (
    dbo.RandomBit(),
    dbo.RandomInt(100),
    dbo.RandomString(10),
    dbo.RandomString(50),
    dbo.RandomInt(1000),
    dbo.RandomString(50),
    dbo.RandomPrice(),
    dbo.RandomString(200),
    dbo.RandomString(200)
  )
  SET @analize_cnt = @analize_cnt + 1
END


DECLARE @Employee_cnt INT = 0;
WHILE @Employee_cnt < 1000
BEGIN
  INSERT INTO [dbo].[Employee] (
    [Login_Name],
    [Name],
    [Patronymic],
    [Surname],
    [Email],
    [Post],
    [CreateDate],
    [UpdateDate],
    [EraseDate],
    [Archived],
    [IS_Role],
    [Role]
  )
  VALUES (
    dbo.RandomString(10),
    dbo.RandomString(10),
    dbo.RandomString(10),
    dbo.RandomString(10),
    dbo.RandomEmail('example.com'),
    dbo.RandomString(10),
    dbo.RandomDate(),
    dbo.RandomDate(),
    dbo.RandomDate(),
    dbo.RandomBit(),
    dbo.RandomBit(),
    dbo.RandomInt(5)
  )
  SET @Employee_cnt = @Employee_cnt + 1
END


DECLARE @Organization_cnt INT = 0;
WHILE @Organization_cnt < 500
BEGIN
  INSERT INTO [dbo].[Organization] (
    [ORG_NAME],
    [TEMPLATE_FN],
    [Id_PrintTemplate],
    [Email],
    [SecondEmail],
    [Fax],
    [SecondFax]
  )
  VALUES (
    dbo.RandomString(50),
    dbo.RandomString(50),
    dbo.RandomInt(10),
    dbo.RandomEmail('example.com'),
    dbo.RandomEmail('example.com'),
    dbo.RandomString(15),
    dbo.RandomString(15)
  )
  SET @Organization_cnt = @Organization_cnt + 1
END



DECLARE @Status_cnt smallint = 1;
WHILE @Status_cnt <= 10
BEGIN
  INSERT INTO [dbo].[WorkStatus] ([StatusName])
  VALUES (dbo.RandomString(50));
  SET @Status_cnt = @Status_cnt + 1;
END


DECLARE @SelectType_cnt int = 1;
WHILE @SelectType_cnt <= 10
BEGIN
  INSERT INTO [dbo].[SelectType] ([SelectType])
  VALUES (dbo.RandomString(30));
  SET @SelectType_cnt = @SelectType_cnt + 1;
END



DECLARE @TemplateType_cnt int = 1;
WHILE @TemplateType_cnt <= 10
BEGIN
  INSERT INTO [dbo].[TemplateType] ([Comment])
  VALUES (dbo.RandomString(50));
  SET @TemplateType_cnt = @TemplateType_cnt + 1;
END




DECLARE @Work_cnt int;
SET @Work_cnt = 1;
WHILE @Work_cnt <= 1000
BEGIN
  INSERT INTO [dbo].[Works] (
    [IS_Complit],
    [CREATE_Date],
    [Close_Date],
    [Id_Employee],
    [ID_ORGANIZATION],
    [Comment],
    [Print_Date],
    [Org_Name],
    [Part_Name],
    [Org_RegN],
    [Material_Type],
    [Material_Get_Date],
    [Material_Reg_Date],
    [MaterialNumber],
    [Material_Comment],
    [FIO],
    [PHONE],
    [EMAIL],
    [Is_Del],
    [Id_Employee_Del],
    [DelDate],
    [Price],
    [ExtRegN],
    [MedicalHistoryNumber],
    [DoctorFIO],
    [DoctorPhone],
    [OrganizationFax],
    [OrganizationEmail],
    [DoctorEmail],
    [StatusId],
    [SendToOrgDate],
    [SendToClientDate],
    [SendToDoctorDate],
    [SendToFax],
    [SendToApp]
  )
  VALUES (
    dbo.RandomBit(), -- IS_Complit
    dbo.RandomDate(), -- CREATE_Date
    dbo.RandomDate(), -- Close_Date
    dbo.RandomInt(1000), -- Id_Employee
    dbo.RandomInt(500), -- ID_ORGANIZATION
    dbo.RandomString(15), -- Comment
    dbo.RandomDate(), -- Print_Date
    dbo.RandomString(15), -- Org_Name
    dbo.RandomString(15), -- Part_Name
    dbo.RandomInt(10000), -- Org_RegN
    dbo.RandomInt(100), -- Material_Type
    dbo.RandomDate(), -- Material_Get_Date
    dbo.RandomDate(), -- Material_Reg_Date
    CAST(RAND() * 100 AS decimal(8, 2)), -- MaterialNumber
    dbo.RandomString(15), -- Material_Comment
    dbo.RandomString(15), -- FIO
    dbo.RandomString(15), -- PHONE
    dbo.RandomEmail('example.com'), -- EMAIL
    dbo.RandomBit(), -- Is_Del
    NULL, -- Id_Employee_Del
    NULL, -- DelDate
    CAST(RAND() * 10000 AS decimal(8, 2)), -- Price
    dbo.RandomString(15), -- ExtRegN
    dbo.RandomString(15), -- MedicalHistoryNumber
    dbo.RandomString(15), -- DoctorFIO
    dbo.RandomString(15), -- DoctorPhone
    dbo.RandomEmail('example.com'), -- OrganizationFax
    dbo.RandomEmail('example.com'), -- OrganizationEmail
    dbo.RandomEmail('example.com'), -- DoctorEmail
    dbo.RandomInt(10), -- StatusId
    dbo.RandomDate(), -- SendToOrgDate
    dbo.RandomDate(), -- SendToClientDate
    dbo.RandomDate(), -- SendToDoctorDate
    dbo.RandomDate(), -- SendToFax
    dbo.RandomDate()-- SendToApp
  );
  SET @Work_cnt = @Work_cnt + 1;
END



DECLARE @WorkItem_cnt int;
SET @WorkItem_cnt = 1;
WHILE @WorkItem_cnt <= 1000
BEGIN
  INSERT INTO [dbo].[WorkItem] (
    [CREATE_DATE],
    [Is_Complit],
    [Close_Date],
    [Id_Employee],
    [ID_ANALIZ],
    [Id_Work],
    [Is_Print],
    [Is_Select],
    [Is_NormTextPrint],
    [Price],
    [Id_SelectType]
  )
  VALUES (
    dbo.RandomDate(), -- CREATE_DATE
    dbo.RandomBit(), -- Is_Complit
    NULL, -- Close_Date
    dbo.RandomInt(1000), -- Id_Employee)
    dbo.RandomInt(100), -- ID_ANALIZ
    dbo.RandomInt(1000), -- Id_Work
    dbo.RandomBit(), -- Is_Print
    dbo.RandomBit(), -- Is_Select
    dbo.RandomBit(), -- Is_NormTextPrint
    CAST((select rndResult from rndView) * 10000 AS decimal(8, 2)), -- Price
    dbo.RandomInt(10) -- Id_SelectType
  );
  SET @WorkItem_cnt = @WorkItem_cnt + 1;
END






select
	top 3000 *
from
	dbo.F_WORKS_LIST()

	
	
	
WITH WorkCompleteCTE(work_cte_id, complit, not_complit) as 
(
	SELECT
		workitem_cte.id_work as work_cte_id,
		SUM(case workitem_cte.is_complit when 1 then 1 else 0 end) as complit,
		SUM(case workitem_cte.is_complit when 0 then 1 else 0 end) as not_complit
    FROM workitem AS workitem_cte
    WHERE id_analiz not in (select id_analiz from analiz where is_group = 1)
    GROUP BY workitem_cte.id_work
)
SELECT
  Works.Id_Work,
  Works.CREATE_Date,
  Works.MaterialNumber,
  Works.IS_Complit,
  Works.FIO,
  convert(varchar(10), works.CREATE_Date, 104 ) as D_DATE,
--  dbo.F_WORKITEMS_COUNT_BY_ID_WORK(works.Id_Work,0) as WorkItemsNotComplit,
--  dbo.F_WORKITEMS_COUNT_BY_ID_WORK(works.Id_Work,1) as WorkItemsComplit,
  work_complete_cte.not_complit as WorkItemsNotComplit,
  work_complete_cte.complit as WorkItemsComplit,
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
 inner join WorkCompleteCTE work_complete_cte on (work_complete_cte.work_cte_id = Works.Id_Work)
where
 WORKS.IS_DEL <> 1
 order by id_work desc -- works.MaterialNumber desc	
	