USE UDFOptimization;
GO

SET NOCOUNT ON;
GO

DELETE FROM dbo.WorkItem;
DELETE FROM dbo.Works;
DELETE FROM dbo.Analiz;
DELETE FROM dbo.Employee;
DELETE FROM dbo.WorkStatus;
GO

DBCC CHECKIDENT ('dbo.WorkItem', RESEED, 0);
DBCC CHECKIDENT ('dbo.Works', RESEED, 0);
DBCC CHECKIDENT ('dbo.Analiz', RESEED, 0);
DBCC CHECKIDENT ('dbo.Employee', RESEED, 0);
DBCC CHECKIDENT ('dbo.WorkStatus', RESEED, 0);
GO

INSERT INTO dbo.WorkStatus (StatusName)
VALUES
('Создан'),
('В работе'),
('Завершён'),
('Отправлен клиенту');
GO

;WITH N AS
(
    SELECT TOP (50)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT INTO dbo.Employee
(
    Login_Name,
    Name,
    Patronymic,
    Surname,
    Email,
    Post,
    Archived,
    IS_Role
)
SELECT
    'employee_' + CAST(n AS varchar(10)),
    'Name' + CAST(n AS varchar(10)),
    'Patronymic' + CAST(n AS varchar(10)),
    'Surname' + CAST(n AS varchar(10)),
    'employee_' + CAST(n AS varchar(10)) + '@mail.ru',
    'Laborant',
    0,
    0
FROM N;
GO

;WITH N AS
(
    SELECT TOP (200)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
)
INSERT INTO dbo.Analiz
(
    IS_GROUP,
    MATERIAL_TYPE,
    CODE_NAME,
    FULL_NAME,
    Price
)
SELECT
    CASE WHEN n % 10 = 0 THEN 1 ELSE 0 END,
    n % 5,
    'A' + CAST(n AS varchar(10)),
    'Analysis ' + CAST(n AS varchar(10)),
    CAST(300 + n AS decimal(8, 2))
FROM N;
GO

;WITH N AS
(
    SELECT TOP (50000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
),
EmployeesNumbered AS
(
    SELECT
        Id_Employee,
        ROW_NUMBER() OVER (ORDER BY Id_Employee) AS rn
    FROM dbo.Employee
),
StatusesNumbered AS
(
    SELECT
        StatusID,
        ROW_NUMBER() OVER (ORDER BY StatusID) AS rn
    FROM dbo.WorkStatus
)
INSERT INTO dbo.Works
(
    IS_Complit,
    CREATE_Date,
    Close_Date,
    Id_Employee,
    MaterialNumber,
    FIO,
    PHONE,
    EMAIL,
    Is_Del,
    Price,
    StatusId,
    Print_Date,
    SendToOrgDate,
    SendToClientDate,
    SendToDoctorDate,
    SendToFax
)
SELECT
    CASE WHEN n.n % 4 = 0 THEN 1 ELSE 0 END,
    DATEADD(day, -(n.n % 365), GETDATE()),
    CASE 
        WHEN n.n % 4 = 0 
        THEN DATEADD(
            day,
            (n.n % 30),
            DATEADD(day, -(n.n % 365), GETDATE())
        ) 
        ELSE NULL 
    END,
    e.Id_Employee,
    CAST(n.n AS decimal(8, 2)),
    'Patient ' + CAST(n.n AS varchar(20)),
    '+7999000' + RIGHT('0000' + CAST(n.n AS varchar(10)), 4),
    'patient_' + CAST(n.n AS varchar(20)) + '@mail.ru',
    0,
    CAST(1000 + (n.n % 5000) AS decimal(8, 2)),
    s.StatusID,
    CASE WHEN n.n % 6 = 0 THEN GETDATE() ELSE NULL END,
    CASE WHEN n.n % 11 = 0 THEN GETDATE() ELSE NULL END,
    CASE WHEN n.n % 13 = 0 THEN GETDATE() ELSE NULL END,
    CASE WHEN n.n % 17 = 0 THEN GETDATE() ELSE NULL END,
    CASE WHEN n.n % 19 = 0 THEN GETDATE() ELSE NULL END
FROM N n
JOIN EmployeesNumbered e
    ON e.rn = ((n.n - 1) % 50) + 1
JOIN StatusesNumbered s
    ON s.rn = ((n.n - 1) % 4) + 1;
GO

;WITH EmployeesNumbered AS
(
    SELECT
        Id_Employee,
        ROW_NUMBER() OVER (ORDER BY Id_Employee) AS rn
    FROM dbo.Employee
),
AnalizNumbered AS
(
    SELECT
        ID_ANALIZ,
        ROW_NUMBER() OVER (ORDER BY ID_ANALIZ) AS rn
    FROM dbo.Analiz
)
INSERT INTO dbo.WorkItem
(
    CREATE_DATE,
    Is_Complit,
    Close_Date,
    Id_Employee,
    ID_ANALIZ,
    Id_Work,
    Is_Print,
    Is_Select,
    Is_NormTextPrint,
    Price
)
SELECT
    w.CREATE_Date,
    CASE WHEN (w.Id_Work + v.item_no) % 2 = 0 THEN 1 ELSE 0 END,
    CASE 
        WHEN (w.Id_Work + v.item_no) % 2 = 0 
        THEN GETDATE() 
        ELSE NULL 
    END,
    e.Id_Employee,
    a.ID_ANALIZ,
    w.Id_Work,
    1,
    0,
    1,
    CAST(300 + ((w.Id_Work + v.item_no) % 200) AS decimal(8, 2))
FROM dbo.Works w
CROSS JOIN (VALUES (1), (2), (3)) v(item_no)
JOIN EmployeesNumbered e
    ON e.rn = ((w.Id_Work + v.item_no - 1) % 50) + 1
JOIN AnalizNumbered a
    ON a.rn = ((w.Id_Work + v.item_no - 1) % 200) + 1;
GO

SELECT COUNT(*) AS WorksCount FROM dbo.Works;
SELECT COUNT(*) AS WorkItemCount FROM dbo.WorkItem;
SELECT COUNT(*) AS EmployeeCount FROM dbo.Employee;
SELECT COUNT(*) AS AnalizCount FROM dbo.Analiz;
SELECT COUNT(*) AS WorkStatusCount FROM dbo.WorkStatus;
GO
