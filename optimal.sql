-- Содержимое файла Create objects.sql

CREATE TABLE Works (
    WorkID INT PRIMARY KEY,
    WorkName NVARCHAR(255),
    DateCreated DATETIME
);

CREATE TABLE WorkItem (
    WorkItemID INT PRIMARY KEY,
    WorkID INT,
    ItemDescription NVARCHAR(255),
    FOREIGN KEY (WorkID) REFERENCES Works(WorkID)
);

CREATE TABLE Analiz (
    AnalizID INT PRIMARY KEY,
    WorkItemID INT,
    AnalysisResult NVARCHAR(255),
    FOREIGN KEY (WorkItemID) REFERENCES WorkItem(WorkItemID)
);

CREATE TABLE Employee (
    EmployeeID INT PRIMARY KEY,
    EmployeeName NVARCHAR(255)
);

-- Пример функции для получения списка работ
CREATE FUNCTION dbo.F_WORKS_LIST()
RETURNS TABLE
AS
RETURN (
    SELECT w.WorkID, w.WorkName, w.DateCreated
    FROM Works w
);
