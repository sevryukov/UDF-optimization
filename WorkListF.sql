SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[F_WORKS_LIST] ()
RETURNS TABLE
AS
RETURN 
(
    SELECT TOP 3000
        w.Id_Work,
        w.CREATE_Date,
        w.MaterialNumber,
        w.IS_Complit,
        w.FIO,
        CONVERT(VARCHAR(10), w.CREATE_Date, 104) AS D_DATE,
        (SELECT COUNT(*) FROM WorkItem wi WHERE wi.Id_Work = w.Id_Work AND wi.IS_Complit = 0) AS WorkItemsNotComplit,
        (SELECT COUNT(*) FROM WorkItem wi WHERE wi.Id_Work = w.Id_Work AND wi.IS_Complit = 1) AS WorkItemsComplit,
        dbo.F_EMPLOYEE_FULLNAME(w.Id_Employee) AS EmployeeFullName,
        w.StatusId,
        ws.StatusName,
        CASE 
            WHEN w.Print_Date IS NOT NULL OR w.SendToClientDate IS NOT NULL OR w.SendToDoctorDate IS NOT NULL OR w.SendToOrgDate IS NOT NULL OR w.SendToFax IS NOT NULL
            THEN 1
            ELSE 0
        END AS Is_Print
    FROM Works w
    LEFT JOIN WorkStatus ws ON w.StatusId = ws.StatusID
    WHERE w.IS_DEL <> 1
    ORDER BY w.id_Work DESC
)


GO