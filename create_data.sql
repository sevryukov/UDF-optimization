--1
-- Employee data
INSERT INTO dbo.Employee (Login_Name, Name, Patronymic, Surname, Email, Post, CreateDate, UpdateDate, EraseDate, Archived, IS_Role, Role)
SELECT 
    'login' + CAST(number AS VARCHAR), 
    'Name' + CAST(number AS VARCHAR), 
    'Patronymic' + CAST(number AS VARCHAR), 
    'Surname' + CAST(number AS VARCHAR), 
    'email' + CAST(number AS VARCHAR) + '@example.com', 
    'Post' + CAST(number AS VARCHAR),
    GETDATE(), 
    NULL, 
    NULL, 
    0, 
    0, 
    NULL
FROM master.dbo.spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 100;  

-- Organization data
INSERT INTO dbo.Organization (ORG_NAME, TEMPLATE_FN, Email, SecondEmail, Fax, SecondFax)
SELECT 
    'OrgName' + CAST(number AS VARCHAR),
    'TemplateName' + CAST(number AS VARCHAR),
    'org' + CAST(number AS VARCHAR) + '@example.com',
    'org2' + CAST(number AS VARCHAR) + '@example.com',
    '123456' + CAST(number AS VARCHAR),
    '654321' + CAST(number AS VARCHAR)
FROM master.dbo.spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 50;  

-- Analiz data
INSERT INTO dbo.Analiz (IS_GROUP, MATERIAL_TYPE, CODE_NAME, FULL_NAME, ID_ILL, Text_Norm, Price, NormText, UnNormText)
SELECT 0, 1, 
    'Code' + CAST(number AS VARCHAR), 
    'Analysis' + CAST(number AS VARCHAR), 
    NULL, 
    'Normal', 
    10.00, 
    'Normal range', 
    'Abnormal range'
FROM master.dbo.spt_values
WHERE type = 'P' AND number BETWEEN 1 AND 10;  

----------------------------------------------------------------------------------------------------------------------

--2
-- 使用循环插入 50,000 条测试数据到 Works 表，并为每个订单创建 3 个 WorkItem
DECLARE @count int = 1;
DECLARE @minEmployeeID int, @maxEmployeeID int, @minOrganizationID int, @maxOrganizationID int, @minAnalizID int, @maxAnalizID int;

SELECT @minEmployeeID = MIN(Id_Employee), @maxEmployeeID = MAX(Id_Employee) FROM dbo.Employee;
SELECT @minOrganizationID = MIN(ID_ORGANIZATION), @maxOrganizationID = MAX(ID_ORGANIZATION) FROM dbo.Organization;
SELECT @minAnalizID = MIN(ID_ANALIZ), @maxAnalizID = MAX(ID_ANALIZ) FROM dbo.Analiz;

WHILE @count <= 50000
BEGIN
    DECLARE @currentWorkID int;
    INSERT INTO dbo.Works
    (
        IS_Complit, CREATE_Date, Close_Date, Id_Employee, ID_ORGANIZATION, Comment, Print_Date, Org_Name, Part_Name,
        Org_RegN, Material_Type, Material_Get_Date, Material_Reg_Date, MaterialNumber, Material_Comment, FIO, PHONE,
        EMAIL, Is_Del, Id_Employee_Del, DelDate, Price, ExtRegN, MedicalHistoryNumber, DoctorFIO, DoctorPhone, OrganizationFax,
        OrganizationEmail, DoctorEmail, StatusId, SendToOrgDate, SendToClientDate, SendToDoctorDate, SendToFax, SendToApp
    )
    VALUES
    (
        0, DATEADD(day, -(@count % 365), GETDATE()), NULL, 
        ROUND(((@maxEmployeeID - @minEmployeeID) * RAND() + @minEmployeeID), 0), 
        ROUND(((@maxOrganizationID - @minOrganizationID) * RAND() + @minOrganizationID), 0),
        'Test comment', NULL, 'Test Org', 'Test Part', @count, 1, GETDATE(), GETDATE(), 1000.00, 'Test material comment',
        'Test FIO', '1234567890', 'test@email.com', 0, NULL, NULL, 100.00, 'ExtRegN', 'MedicalHistory123', 'Doctor FIO',
        '123-456-7890', '123-456-7890', 'org@email.com', 'doc@email.com', 1, NULL, NULL, NULL, NULL, NULL
    );
    SET @currentWorkID = SCOPE_IDENTITY();
    
    --  every Work in  WorkItem
    DECLARE @itemCount int = 1;
    WHILE @itemCount <= 3
    BEGIN
        INSERT INTO dbo.WorkItem
        (
            CREATE_DATE, Is_Complit, Close_Date, Id_Employee, ID_ANALIZ, Id_Work, Is_Print, Is_Select, Is_NormTextPrint, Price, Id_SelectType
        )
        VALUES
        (
            GETDATE(), 0, NULL, 
            ROUND(((@maxEmployeeID - @minEmployeeID) * RAND() + @minEmployeeID), 0),
            ROUND(((@maxAnalizID - @minAnalizID) * RAND() + @minAnalizID), 0),
            @currentWorkID, 1, 0, 1, 10.00, NULL
        );
        SET @itemCount = @itemCount + 1;
    END;
    SET @count = @count + 1;
END


-------------------------------------------------------------------------------------------------------------------
--3.SQL select 3000 random rows from Works table
DECLARE @StartTime datetime, @EndTime datetime;

SET @StartTime = GETDATE();

SELECT TOP 3000 *
FROM dbo.Works
ORDER BY NEWID();

SET @EndTime = GETDATE();

SELECT DATEDIFF(millisecond, @StartTime, @EndTime) AS ExecutionTimeMilliseconds;
