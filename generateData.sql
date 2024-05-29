-- Генерация данных для таблицы Employee
INSERT INTO dbo.Employee (Login_Name, Name, Patronymic, Surname, Email, Post)
SELECT 
    'login' + CAST(n AS VARCHAR(10)), 
    'Name' + CAST(n AS VARCHAR(10)), 
    'Patronymic' + CAST(n AS VARCHAR(10)), 
    'Surname' + CAST(n AS VARCHAR(10)), 
    'email' + CAST(n AS VARCHAR(10)) + '@example.com', 
    'Post' + CAST(n AS VARCHAR(10))
FROM (SELECT TOP 100 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM master.dbo.spt_values) AS numbers;

-- Генерация данных для таблицы Organization
INSERT INTO dbo.Organization (ORG_NAME, TEMPLATE_FN, Email, SecondEmail, Fax, SecondFax)
SELECT 
    'OrgName' + CAST(n AS VARCHAR(10)),
    'TemplateName' + CAST(n AS VARCHAR(10)),
    'org' + CAST(n AS VARCHAR(10)) + '@example.com',
    'org2' + CAST(n AS VARCHAR(10)) + '@example.com',
    '123456' + CAST(n AS VARCHAR(10)),
    '654321' + CAST(n AS VARCHAR(10))
FROM (SELECT TOP 50 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM master.dbo.spt_values) AS numbers;

-- Генерация данных для таблицы Analiz
INSERT INTO dbo.Analiz (IS_GROUP, MATERIAL_TYPE, CODE_NAME, FULL_NAME, Text_Norm, Price, NormText, UnNormText)
SELECT 0, 1, 
    'Code' + CAST(n AS VARCHAR(10)), 
    'Analysis' + CAST(n AS VARCHAR(10)), 
    'Normal', 
    10.00, 
    'Normal range', 
    'Abnormal range'
FROM (SELECT TOP 10 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM master.dbo.spt_values) AS numbers;

-- Генерация данных для таблиц Works и WorkItem
DECLARE @count INT = 1;
WHILE @count <= 50000
BEGIN
    DECLARE @WorkID INT;

    INSERT INTO dbo.Works (IS_Complit, CREATE_Date, Id_Employee, ID_ORGANIZATION, Material_Type, MaterialNumber, FIO, StatusId)
    SELECT 
        0, 
        DATEADD(day, -(@count % 365), GETDATE()), 
        (SELECT TOP 1 Id_Employee FROM dbo.Employee ORDER BY NEWID()),
        (SELECT TOP 1 ID_ORGANIZATION FROM dbo.Organization ORDER BY NEWID()),
        1,
        1000.00,
        'Test FIO ' + CAST(@count AS VARCHAR(10)),
        1
    ;

    SET @WorkID = SCOPE_IDENTITY();

    INSERT INTO dbo.WorkItem (CREATE_DATE, Is_Complit, Id_Employee, ID_ANALIZ, Id_Work)
    SELECT TOP 3
        GETDATE(), 
        0,
        (SELECT TOP 1 Id_Employee FROM dbo.Employee ORDER BY NEWID()),
        (SELECT TOP 1 ID_ANALIZ FROM dbo.Analiz ORDER BY NEWID()),
        @WorkID
    FROM dbo.Analiz;
	
    SET @count = @count + 1;
END;

-- Замер времени выполнения запроса
DECLARE @StartTime DATETIME = GETDATE();

SELECT TOP 3000 *
FROM dbo.Works
ORDER BY NEWID();

DECLARE @EndTime DATETIME = GETDATE();
SELECT DATEDIFF(millisecond, @StartTime, @EndTime) AS ExecutionTimeMilliseconds;
