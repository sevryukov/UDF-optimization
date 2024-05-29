CREATE FUNCTION [dbo].[F_WORKS_LIST] ()
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
    INSERT INTO @result
    SELECT
        w.Id_Work,
        w.CREATE_Date,
        w.MaterialNumber,
        w.IS_Complit,
        w.FIO,
        CONVERT(varchar(10), w.CREATE_Date, 104) as D_DATE,
        wi_not_complit.WorkItemsNotComplit,
        wi_complit.WorkItemsComplit,
        RTRIM(REPLACE(ISNULL(e.Surname + ' ' + UPPER(SUBSTRING(e.Name, 1, 1)) + '. ' + UPPER(SUBSTRING(e.Patronymic, 1, 1)) + '.', e.LOGIN_NAME), '. .', '')) as EmployeeFullName,
        w.StatusId,
        ws.StatusName,
        CASE
            WHEN (w.Print_Date IS NOT NULL) OR (w.SendToClientDate IS NOT NULL) OR (w.SendToDoctorDate IS NOT NULL) OR (w.SendToOrgDate IS NOT NULL) OR (w.SendToFax IS NOT NULL)
            THEN 1
            ELSE 0
        END as Is_Print
    FROM Works w
    LEFT JOIN WorkStatus ws ON w.StatusId = ws.StatusID
    LEFT JOIN Employee e ON w.Id_Employee = e.Id_Employee
    LEFT JOIN (
        SELECT id_work, COUNT(*) as WorkItemsNotComplit
        FROM workitem
        WHERE is_complit = 0
        AND id_analiz NOT IN (SELECT id_analiz FROM analiz WHERE is_group = 1)
        GROUP BY id_work
    ) wi_not_complit ON wi_not_complit.id_work = w.Id_Work
    LEFT JOIN (
        SELECT id_work, COUNT(*) as WorkItemsComplit
        FROM workitem
        WHERE is_complit = 1
        AND id_analiz NOT IN (SELECT id_analiz FROM analiz WHERE is_group = 1)
        GROUP BY id_work
    ) wi_complit ON wi_complit.id_work = w.Id_Work
    WHERE w.IS_DEL <> 1
    ORDER BY w.id_work DESC
    RETURN
END
GO