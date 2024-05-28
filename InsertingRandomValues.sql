-- Создание таблицы PrintTemplate (если она еще не создана)
IF OBJECT_ID('dbo.PrintTemplate', 'U') IS NULL
BEGIN
  CREATE TABLE [dbo].[PrintTemplate] (
    [Id] INT PRIMARY KEY IDENTITY(1,1),
    [TemplateName] VARCHAR(50)
  );

  -- Вставка тестовых данных в PrintTemplate
  DECLARE @PrintTemplate_cnt INT = 0;
  DECLARE @tempString VARCHAR(255);
  
  WHILE @PrintTemplate_cnt < 10
  BEGIN
    EXEC dbo.RandomString 50, @tempString OUTPUT
    INSERT INTO [dbo].[PrintTemplate] ([TemplateName])
    VALUES (@tempString);
    SET @PrintTemplate_cnt = @PrintTemplate_cnt + 1;
  END;
END;

-- Получение существующих значений для внешних ключей
DECLARE @existingPrintTemplateIds TABLE (Id INT);
DECLARE @existingAnalizIds TABLE (Id INT);
DECLARE @existingSelectTypeIds TABLE (Id INT);
DECLARE @existingOrganizationIds TABLE (Id INT);

-- Заполнение таблиц существующими значениями
INSERT INTO @existingPrintTemplateIds (Id)
SELECT Id_PrintTemplate FROM dbo.PrintTemplate;

INSERT INTO @existingAnalizIds (Id)
SELECT ID_ANALIZ FROM dbo.Analiz;

INSERT INTO @existingSelectTypeIds (Id)
SELECT Id_SelectType FROM dbo.SelectType;

INSERT INTO @existingOrganizationIds (Id)
SELECT ID_ORGANIZATION FROM dbo.Organization;

-- Вставка данных в таблицу Analiz
DECLARE @analize_cnt INT = 0;
DECLARE @tempBit BIT;
DECLARE @tempInt INT;
DECLARE @tempPrice DECIMAL(8, 2);
WHILE @analize_cnt < 100
BEGIN
  EXEC dbo.RandomBit @tempBit OUTPUT
  EXEC dbo.RandomInt 100, @tempInt OUTPUT
  EXEC dbo.RandomString 10, @tempString OUTPUT
  EXEC dbo.RandomPrice @tempPrice OUTPUT
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
    @tempBit,
    @tempInt,
    @tempString,
    @tempString,
    @tempInt,
    @tempString,
    @tempPrice,
    @tempString,
    @tempString
  )
  SET @analize_cnt = @analize_cnt + 1
END;

-- Вставка данных в таблицу Employee
DECLARE @Employee_cnt INT = 0;
DECLARE @tempEmail VARCHAR(255);
DECLARE @tempDate DATETIME;
WHILE @Employee_cnt < 1000
BEGIN
  EXEC dbo.RandomString 10, @tempString OUTPUT
  EXEC dbo.RandomEmail 'example.com', @tempEmail OUTPUT
  EXEC dbo.RandomDate @tempDate OUTPUT
  EXEC dbo.RandomBit @tempBit OUTPUT
  EXEC dbo.RandomInt 5, @tempInt OUTPUT
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
    @tempString,
    @tempString,
    @tempString,
    @tempString,
    @tempEmail,
    @tempString,
    @tempDate,
    @tempDate,
    @tempDate,
    @tempBit,
    @tempBit,
    @tempInt
  )
  SET @Employee_cnt = @Employee_cnt + 1
END;

-- Вставка данных в таблицу Organization
DECLARE @Organization_cnt INT = 0;

WHILE @Organization_cnt < 500
BEGIN
  EXEC dbo.RandomString 50, @tempString OUTPUT
  EXEC dbo.RandomEmail 'example.com', @tempEmail OUTPUT

  -- Получение случайного Id_PrintTemplate из существующих значений
  SELECT TOP 1 @tempInt = Id_PrintTemplate FROM PrintTemplate ORDER BY NEWID();

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
    @tempString,
    @tempString,
    @tempInt,
    @tempEmail,
    @tempEmail,
    @tempString,
    @tempString
  )
  SET @Organization_cnt = @Organization_cnt + 1
END;

-- Вставка данных в таблицу WorkStatus
DECLARE @Status_cnt SMALLINT = 1;
WHILE @Status_cnt <= 10
BEGIN
  EXEC dbo.RandomString 50, @tempString OUTPUT
  INSERT INTO [dbo].[WorkStatus] ([StatusName])
  VALUES (@tempString);
  SET @Status_cnt = @Status_cnt + 1;
END;

-- Вставка данных в таблицу SelectType
DECLARE @SelectType_cnt INT = 1;
WHILE @SelectType_cnt <= 10
BEGIN
  EXEC dbo.RandomString 30, @tempString OUTPUT
  INSERT INTO [dbo].[SelectType] ([SelectType])
  VALUES (@tempString);
  SET @SelectType_cnt = @SelectType_cnt + 1;
END;

-- Вставка данных в таблицу TemplateType
DECLARE @TemplateType_cnt INT = 1;
WHILE @TemplateType_cnt <= 10
BEGIN
  EXEC dbo.RandomString 50, @tempString OUTPUT
  INSERT INTO [dbo].[TemplateType] ([Comment])
  VALUES (@tempString);
  SET @TemplateType_cnt = @TemplateType_cnt + 1;
END;

-- Вставка данных в таблицу Works
DECLARE @Work_cnt INT = 1;

WHILE @Work_cnt <= 1000
BEGIN
  EXEC dbo.RandomBit @tempBit OUTPUT
  EXEC dbo.RandomDate @tempDate OUTPUT
  EXEC dbo.RandomInt 1000, @tempInt OUTPUT
  EXEC dbo.RandomString 15, @tempString OUTPUT

  -- Получение случайного ID_ORGANIZATION из существующих значений
  DECLARE @tempOrgId INT;
  SELECT TOP 1 @tempOrgId = ID_ORGANIZATION FROM Organization ORDER BY NEWID();

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
    @tempBit,
    @tempDate,
    @tempDate,
    @tempInt,
    @tempOrgId,
    @tempString,
    @tempDate,
    @tempString,
    @tempString,
    @tempInt,
    @tempInt,
    @tempDate,
    @tempDate,
    @tempInt,
    @tempString,
    @tempString,
    @tempString,
    @tempString,
    @tempBit,
    NULL,
    NULL,
    @tempPrice,
    @tempString,
    @tempString,
    @tempString,
    @tempString,
    @tempString,
    @tempString,
    @tempString,
    @tempInt,
    @tempDate,
    @tempDate,
    @tempDate,
    @tempDate,
    @tempDate
  );
  SET @Work_cnt = @Work_cnt + 1;
END;

-- Вставка данных в таблицу WorkItem
DECLARE @WorkItem_cnt INT = 1;
DECLARE @tempAnalizId INT;
DECLARE @tempSelectTypeId INT;

WHILE @WorkItem_cnt <= 1000
BEGIN
  EXEC dbo.RandomDate @tempDate OUTPUT
  EXEC dbo.RandomBit @tempBit OUTPUT
  EXEC dbo.RandomInt 1000, @tempInt OUTPUT
  EXEC dbo.RandomPrice @tempPrice OUTPUT

  -- Получение случайных Id_Analiz и Id_SelectType из существующих значений
  SELECT TOP 1 @tempAnalizId = Id FROM @existingAnalizIds ORDER BY NEWID();
  SELECT TOP 1 @tempSelectTypeId = Id FROM @existingSelectTypeIds ORDER BY NEWID();

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
    @tempDate,
    @tempBit,
    @tempDate,
    @tempInt,
    @tempAnalizId,
    @tempInt,
    @tempBit,
    @tempBit,
    @tempBit,
    @tempPrice,
    @tempSelectTypeId
  );
  SET @WorkItem_cnt = @WorkItem_cnt + 1;
END;