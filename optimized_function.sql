USE UDFOptimization;
GO

ALTER FUNCTION [dbo].[F_WORKS_LIST]()
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
BEGIN
    ;WITH TopWorks AS
    (
        SELECT TOP (3000)
            w.Id_Work,
            w.CREATE_Date,
            w.MaterialNumber,
            w.IS_Complit,
            w.FIO,
            w.Id_Employee,
            w.StatusId,
            w.Print_Date,
            w.SendToClientDate,
            w.SendToDoctorDate,
            w.SendToOrgDate,
            w.SendToFax
        FROM dbo.Works w
        WHERE w.IS_DEL <> 1
        ORDER BY w.Id_Work DESC
    ),
    WorkItemCounts AS
    (
        SELECT
            wi.Id_Work,
            SUM(CASE WHEN wi.Is_Complit = 0 THEN 1 ELSE 0 END) AS WorkItemsNotComplit,
            SUM(CASE WHEN wi.Is_Complit = 1 THEN 1 ELSE 0 END) AS WorkItemsComplit
        FROM dbo.WorkItem wi
        INNER JOIN TopWorks tw
            ON tw.Id_Work = wi.Id_Work
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.Analiz a
            WHERE a.ID_ANALIZ = wi.ID_ANALIZ
              AND a.IS_GROUP = 1
        )
        GROUP BY wi.Id_Work
    )
    INSERT INTO @RESULT
    (
        ID_WORK,
        CREATE_Date,
        MaterialNumber,
        IS_Complit,
        FIO,
        D_DATE,
        WorkItemsNotComplit,
        WorkItemsComplit,
        FULL_NAME,
        StatusId,
        StatusName,
        Is_Print
    )
    SELECT
        tw.Id_Work,
        tw.CREATE_Date,
        tw.MaterialNumber,
        tw.IS_Complit,
        tw.FIO,
        CONVERT(varchar(10), tw.CREATE_Date, 104) AS D_DATE,
        ISNULL(wic.WorkItemsNotComplit, 0) AS WorkItemsNotComplit,
        ISNULL(wic.WorkItemsComplit, 0) AS WorkItemsComplit,
        RTRIM(
            e.Surname + ' ' +
            UPPER(SUBSTRING(e.Name, 1, 1)) + '. ' +
            UPPER(SUBSTRING(e.Patronymic, 1, 1)) + '.'
        ) AS FULL_NAME,
        tw.StatusId,
        ws.StatusName,
        CAST(
            CASE
                WHEN tw.Print_Date IS NOT NULL
                  OR tw.SendToClientDate IS NOT NULL
                  OR tw.SendToDoctorDate IS NOT NULL
                  OR tw.SendToOrgDate IS NOT NULL
                  OR tw.SendToFax IS NOT NULL
                THEN 1
                ELSE 0
            END AS bit
        ) AS Is_Print
    FROM TopWorks tw
    LEFT JOIN WorkItemCounts wic
        ON wic.Id_Work = tw.Id_Work
    LEFT JOIN dbo.Employee e
        ON e.Id_Employee = tw.Id_Employee
    LEFT JOIN dbo.WorkStatus ws
        ON ws.StatusID = tw.StatusId;

    RETURN;
END;
GO