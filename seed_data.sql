USE UDFOptimization;
GO

SET NOCOUNT ON;
GO

DELETE FROM dbo.WorkItem;
DELETE FROM dbo.Works;
DELETE FROM dbo.Organization;
DELETE FROM dbo.Analiz;
DELETE FROM dbo.Employee;
DELETE FROM dbo.WorkStatus;
DELETE FROM dbo.SelectType;
GO

/* WorkStatus: ID 1..5 */
SET IDENTITY_INSERT dbo.WorkStatus ON;
INSERT INTO dbo.WorkStatus (StatusID, StatusName)
VALUES
    (1, 'New'),
    (2, 'In progress'),
    (3, 'Ready'),
    (4, 'Sent'),
    (5, 'Closed');
SET IDENTITY_INSERT dbo.WorkStatus OFF;
GO

/* SelectType: ID 1..3 */
SET IDENTITY_INSERT dbo.SelectType ON;
INSERT INTO dbo.SelectType (Id_SelectType, SelectType)
VALUES
    (1, 'Regular'),
    (2, 'Urgent'),
    (3, 'Repeat');
SET IDENTITY_INSERT dbo.SelectType OFF;
GO

/* Employee: ID 1..20 */
SET IDENTITY_INSERT dbo.Employee ON;

;WITH nums AS (
    SELECT TOP (20)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT INTO dbo.Employee
(
    Id_Employee,
    Login_Name,
    Name,
    Patronymic,
    Surname,
    Email,
    Post,
    CreateDate,
    Archived,
    IS_Role,
    Role
)
SELECT
    n,
    CONCAT('employee', n),
    CONCAT('Name', n),
    CONCAT('Patronymic', n),
    CONCAT('Surname', n),
    CONCAT('employee', n, '@test.local'),
    'Lab worker',
    GETDATE(),
    0,
    0,
    0
FROM nums;

SET IDENTITY_INSERT dbo.Employee OFF;
GO

/* Organization: ID 1..100 */
SET IDENTITY_INSERT dbo.Organization ON;

;WITH nums AS (
    SELECT TOP (100)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT INTO dbo.Organization
(
    ID_ORGANIZATION,
    ORG_NAME,
    Email,
    Fax
)
SELECT
    n,
    CONCAT('Organization ', n),
    CONCAT('org', n, '@test.local'),
    CONCAT('+7900000', RIGHT(CONCAT('0000', n), 4))
FROM nums;

SET IDENTITY_INSERT dbo.Organization OFF;
GO

/* Analiz: ID 1..500 */
SET IDENTITY_INSERT dbo.Analiz ON;

;WITH nums AS (
    SELECT TOP (500)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Analiz
(
    ID_ANALIZ,
    IS_GROUP,
    MATERIAL_TYPE,
    CODE_NAME,
    FULL_NAME,
    ID_ILL,
    Text_Norm,
    Price,
    NormText,
    UnNormText
)
SELECT
    n,
    CASE WHEN n % 20 = 0 THEN 1 ELSE 0 END,
    n % 5,
    CONCAT('A', n),
    CONCAT('Analysis ', n),
    NULL,
    'Normal',
    CAST(100 + (n % 400) AS DECIMAL(8, 2)),
    'Normal text',
    'Abnormal text'
FROM nums;

SET IDENTITY_INSERT dbo.Analiz OFF;
GO

/* Works: 50 000 заказов, ID 1..50000 */
SET IDENTITY_INSERT dbo.Works ON;

;WITH nums AS (
    SELECT TOP (50000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.Works
(
    Id_Work,
    IS_Complit,
    CREATE_Date,
    Close_Date,
    Id_Employee,
    ID_ORGANIZATION,
    Comment,
    Print_Date,
    Org_Name,
    Part_Name,
    Org_RegN,
    Material_Type,
    Material_Get_Date,
    Material_Reg_Date,
    MaterialNumber,
    Material_Comment,
    FIO,
    PHONE,
    EMAIL,
    Is_Del,
    Id_Employee_Del,
    DelDate,
    Price,
    ExtRegN,
    MedicalHistoryNumber,
    DoctorFIO,
    DoctorPhone,
    OrganizationFax,
    OrganizationEmail,
    DoctorEmail,
    StatusId,
    SendToOrgDate,
    SendToClientDate,
    SendToDoctorDate,
    SendToFax,
    SendToApp
)
SELECT
    n,
    CASE WHEN n % 4 = 0 THEN 1 ELSE 0 END,
    DATEADD(DAY, -(n % 365), GETDATE()),
    CASE WHEN n % 4 = 0 THEN DATEADD(DAY, -(n % 365) + 1, GETDATE()) ELSE NULL END,
    ((n - 1) % 20) + 1,
    ((n - 1) % 100) + 1,
    CONCAT('Comment for work ', n),
    CASE WHEN n % 10 = 0 THEN DATEADD(DAY, -(n % 365) + 2, GETDATE()) ELSE NULL END,
    CONCAT('Organization ', ((n - 1) % 100) + 1),
    NULL,
    NULL,
    n % 5,
    DATEADD(DAY, -(n % 365), GETDATE()),
    DATEADD(DAY, -(n % 365), GETDATE()),
    CAST(n AS DECIMAL(8, 2)),
    NULL,
    CONCAT('Patient ', n),
    CONCAT('+7900', RIGHT(CONCAT('0000000', n), 7)),
    CONCAT('patient', n, '@test.local'),
    CASE WHEN n % 100 = 0 THEN 1 ELSE 0 END,
    NULL,
    NULL,
    CAST(500 + (n % 3000) AS DECIMAL(8, 2)),
    CONCAT('EXT', n),
    CONCAT('MH', n),
    CONCAT('Doctor ', ((n - 1) % 50) + 1),
    CONCAT('+7911', RIGHT(CONCAT('0000000', n), 7)),
    CONCAT('+7922', RIGHT(CONCAT('0000000', n), 7)),
    CONCAT('org', ((n - 1) % 100) + 1, '@test.local'),
    CONCAT('doctor', ((n - 1) % 50) + 1, '@test.local'),
    CAST(((n - 1) % 5) + 1 AS SMALLINT),
    CASE WHEN n % 15 = 0 THEN DATEADD(DAY, -(n % 365) + 2, GETDATE()) ELSE NULL END,
    CASE WHEN n % 12 = 0 THEN DATEADD(DAY, -(n % 365) + 2, GETDATE()) ELSE NULL END,
    CASE WHEN n % 18 = 0 THEN DATEADD(DAY, -(n % 365) + 2, GETDATE()) ELSE NULL END,
    CASE WHEN n % 25 = 0 THEN DATEADD(DAY, -(n % 365) + 2, GETDATE()) ELSE NULL END,
    CASE WHEN n % 30 = 0 THEN DATEADD(DAY, -(n % 365) + 2, GETDATE()) ELSE NULL END
FROM nums;

SET IDENTITY_INSERT dbo.Works OFF;
GO

/* WorkItem: 150 000 элементов заказов, по 3 на каждый заказ */
SET IDENTITY_INSERT dbo.WorkItem ON;

;WITH nums AS (
    SELECT TOP (150000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.WorkItem
(
    ID_WORKItem,
    CREATE_DATE,
    Is_Complit,
    Close_Date,
    Id_Employee,
    ID_ANALIZ,
    Id_Work,
    Is_Print,
    Is_Select,
    Is_NormTextPrint,
    Price,
    Id_SelectType
)
SELECT
    n,
    DATEADD(DAY, -(n % 365), GETDATE()),
    CASE WHEN n % 2 = 0 THEN 1 ELSE 0 END,
    CASE WHEN n % 2 = 0 THEN DATEADD(DAY, -(n % 365) + 1, GETDATE()) ELSE NULL END,
    ((n - 1) % 20) + 1,
    ((n - 1) % 500) + 1,
    ((n - 1) / 3) + 1,
    1,
    CASE WHEN n % 3 = 0 THEN 1 ELSE 0 END,
    1,
    CAST(100 + (n % 400) AS DECIMAL(8, 2)),
    ((n - 1) % 3) + 1
FROM nums;

SET IDENTITY_INSERT dbo.WorkItem OFF;
GO

/* Обновим счётчики identity на будущее */
DBCC CHECKIDENT ('dbo.WorkStatus', RESEED, 5);
DBCC CHECKIDENT ('dbo.SelectType', RESEED, 3);
DBCC CHECKIDENT ('dbo.Employee', RESEED, 20);
DBCC CHECKIDENT ('dbo.Organization', RESEED, 100);
DBCC CHECKIDENT ('dbo.Analiz', RESEED, 500);
DBCC CHECKIDENT ('dbo.Works', RESEED, 50000);
DBCC CHECKIDENT ('dbo.WorkItem', RESEED, 150000);
GO

SELECT 'Employee' AS table_name, COUNT(*) AS rows_count FROM dbo.Employee
UNION ALL
SELECT 'WorkStatus', COUNT(*) FROM dbo.WorkStatus
UNION ALL
SELECT 'SelectType', COUNT(*) FROM dbo.SelectType
UNION ALL
SELECT 'Organization', COUNT(*) FROM dbo.Organization
UNION ALL
SELECT 'Analiz', COUNT(*) FROM dbo.Analiz
UNION ALL
SELECT 'Works', COUNT(*) FROM dbo.Works
UNION ALL
SELECT 'WorkItem', COUNT(*) FROM dbo.WorkItem;
GO
