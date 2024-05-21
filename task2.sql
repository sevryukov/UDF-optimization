CREATE OR ALTER FUNCTION [dbo].[F_WORKS_LIST] (
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
BEGIN
    INSERT INTO @result
    SELECT TOP 3000
        Works.Id_Work,
        Works.CREATE_Date,
        Works.MaterialNumber,
        Works.IS_Complit,
        Works.FIO,
        CONVERT(varchar(10), works.CREATE_Date, 104 ) AS D_DATE,
        COUNT(CASE WHEN WorkItem.is_complit = 0 THEN 1 ELSE NULL END) AS WorkItemsNotComplit,
        COUNT(CASE WHEN WorkItem.is_complit = 1 THEN 1 ELSE NULL END) AS WorkItemsComplit,
        RTRIM(REPLACE(Employee.SURNAME + ' ' + UPPER(SUBSTRING(Employee.NAME, 1, 1)) + '. ' + UPPER(SUBSTRING(Employee.PATRONYMIC, 1, 1)) + '.', '. .', '')) AS EmployeeFullName,
        Works.StatusId,
        WorkStatus.StatusName,
        CASE
            WHEN (Works.Print_Date IS NOT NULL) OR
                 (Works.SendToClientDate IS NOT NULL) OR
                 (Works.SendToDoctorDate IS NOT NULL) OR
                 (Works.SendToOrgDate IS NOT NULL) OR
                 (Works.SendToFax IS NOT NULL)
            THEN 1
            ELSE 0
        END AS Is_Print  
    FROM
        Works
    LEFT JOIN Employee ON (Works.Id_Employee = Employee.Id_Employee)
    LEFT JOIN WorkItem ON (Works.Id_Work = WorkItem.Id_Work)
    LEFT JOIN WorkStatus ON (Works.StatusId = WorkStatus.StatusID)
    WHERE
        WORKS.IS_DEL <> 1
    ORDER BY
        Works.Id_Work DESC -- works.MaterialNumber desc
    RETURN
END

