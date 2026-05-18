-- Prompt:
-- Напиши SQL скрипт для генерации тестовых данных в SQL Server:
-- - 10 сотрудников (Employee)
-- - 50 000 заказов (Works)
-- - 150 000 элементов заказов (WorkItem) - примерно по 3 на каждый заказ
-- - 4 статуса (WorkStatus)
-- Используй существующую структуру БД: {Create objects.sql}

USE udf_optimization;
GO

INSERT INTO Employee (Login_Name, Name, Patronymic, Surname, Email, Post, CreateDate, Archived, IS_Role, Role)
SELECT 
    'user' + CAST(n AS VARCHAR(10)),
    'Name' + CAST(n AS VARCHAR(10)),
    'Patr' + CAST(n AS VARCHAR(10)),
    'Sur' + CAST(n AS VARCHAR(10)),
    'email' + CAST(n AS VARCHAR(10)) + '@test.com',
    'Doctor',
    GETDATE(),
    0, 0, 1
FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10)) AS T(n);
GO

INSERT INTO Analiz (IS_GROUP, MATERIAL_TYPE, CODE_NAME, FULL_NAME, Price)
SELECT 
    CASE WHEN n % 10 = 0 THEN 1 ELSE 0 END,
    n % 5,
    'CODE' + CAST(n AS VARCHAR(10)),
    'Analysis ' + CAST(n AS VARCHAR(50)),
    ROUND(RAND() * 1000, 2)
FROM (SELECT TOP 100 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as n FROM sys.objects) AS T;
GO

INSERT INTO Works (IS_Complit, CREATE_Date, Id_Employee, FIO, Is_Del, StatusId)
SELECT 
    0,
    DATEADD(day, -n, GETDATE()),
    (n % 10) + 1,
    'Patient ' + CAST(n AS VARCHAR(10)),
    0,
    1
FROM (SELECT TOP 50000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as n FROM sys.objects a CROSS JOIN sys.objects b CROSS JOIN sys.objects c) AS T;
GO

INSERT INTO WorkItem (CREATE_DATE, Is_Complit, Id_Employee, ID_ANALIZ, Id_Work, Is_Print, Is_Select)
SELECT 
    GETDATE(),
    CASE WHEN w.Id_Work % 4 = 0 THEN 1 ELSE 0 END,
    w.Id_Employee,
    (a.ID_ANALIZ % 100) + 1,
    w.Id_Work,
    0, 0
FROM Works w
CROSS JOIN (SELECT TOP 3 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as n FROM sys.objects) AS Numbers
INNER JOIN Analiz a ON a.ID_ANALIZ = (w.Id_Work + Numbers.n) % 100 + 1;
GO

INSERT INTO WorkStatus (StatusName) VALUES ('New'), ('InProgress'), ('Completed'), ('Delivered');
GO