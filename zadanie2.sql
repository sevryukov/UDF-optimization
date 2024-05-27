CREATE FUNCTION [dbo].[F_WORKS_LIST] () 
RETURNS @RESULT TABLE 
( 
    ID_WORK INT, 
    CREATE_Date DATETIME, 
    MaterialNumber DECIMAL(8,2), 
    IS_Complit BIT, 
    FIO VARCHAR(255), 
    D_DATE VARCHAR(10), 
    WorkItemsNotComplit INT, 
    WorkItemsComplit INT, 
    FULL_NAME VARCHAR(101), 
    StatusId SMALLINT, 
    StatusName VARCHAR(255), 
    Is_Print BIT 
) 
AS 
-- СПИСОК РАБОТ 
BEGIN 
    INSERT INTO @RESULT
    SELECT 
        Works.Id_Work, 
        Works.CREATE_Date, 
        Works.MaterialNumber, 
        Works.IS_Complit, 
        Works.FIO, 
        CONVERT(VARCHAR(10), Works.CREATE_Date, 104) AS D_DATE, 
        (SELECT COUNT(*) FROM WorkItems WHERE Id_Work = Works.Id_Work AND IsComplit = 0) AS WorkItemsNotComplit, 
        (SELECT COUNT(*) FROM WorkItems WHERE Id_Work = Works.Id_Work AND IsComplit = 1) AS WorkItemsComplit, 
        dbo.F_EMPLOYEE_FULLNAME(Works.Id_Employee) AS EmployeeFullName, 
        Works.StatusId, 
        WorkStatus.StatusName, 
        CASE
            WHEN Works.Print_Date IS NOT NULL OR Works.SendToClientDate IS NOT NULL OR Works.SendToDoctorDate IS NOT NULL OR Works.SendToOrgDate IS NOT NULL OR Works.SendToFax IS NOT NULL
            THEN 1
            ELSE 0
        END AS Is_Print   
    FROM Works
    LEFT JOIN WorkStatus ON Works.StatusId = WorkStatus.StatusID
    WHERE WORKS.IS_DEL <> 1
    ORDER BY id_work DESC -- works.MaterialNumber DESC 

    RETURN
END