/** 
Используйте OUTER APPLY вместо вызова функции F_WORKITEMS_COUNT_BY_ID_WORK.

OUTER APPLY вычисляет количество завершенных и незавершенных рабочих элементов 
для каждого заказа непосредственно в запросе, избегая необходимости вызывать 
функцию F_WORKITEMS_COUNT_BY_ID_WORK один раз для каждой строки запроса.

Встроенная функция F_EMPLOYEE_FULLNAME.

Вставьте логику функции F_EMPLOYEE_FULLNAME непосредственно в основной запрос, 
сократив количество обращений к функции за счет встраивания полного имени 
сотрудника в оператор SELECT.
**/



CREATE OR ALTER FUNCTION [dbo].[F_WORKS_LIST] ()
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
BEGIN
    INSERT INTO @result
    SELECT TOP 3000
        W.Id_Work,
        W.CREATE_Date,
        W.MaterialNumber,
        W.IS_Complit,
        W.FIO,
        CONVERT(VARCHAR(10), W.CREATE_Date, 104) AS D_DATE,
        WI.WorkItemsNotComplit,
        WI.WorkItemsComplit,
        RTRIM(REPLACE(E.SURNAME + ' ' + UPPER(SUBSTRING(E.NAME, 1, 1)) + '. ' +
            UPPER(SUBSTRING(E.PATRONYMIC, 1, 1)) + '.', '. .', '')) AS FULL_NAME,
        W.StatusId,
        WS.StatusName,
        CASE
            WHEN (W.Print_Date IS NOT NULL) OR
                 (W.SendToClientDate IS NOT NULL) OR
                 (W.SendToDoctorDate IS NOT NULL) OR
                 (W.SendToOrgDate IS NOT NULL) OR
                 (W.SendToFax IS NOT NULL)
            THEN 1
            ELSE 0
        END AS Is_Print
    FROM
        Works AS W
    LEFT JOIN Employee AS E ON W.Id_Employee = E.Id_Employee
    LEFT JOIN WorkStatus AS WS ON W.StatusId = WS.StatusID
    OUTER APPLY
    (
        SELECT
            COUNT(CASE WHEN is_complit = 0 THEN 1 ELSE NULL END) AS WorkItemsNotComplit,
            COUNT(CASE WHEN is_complit = 1 THEN 1 ELSE NULL END) AS WorkItemsComplit
        FROM WorkItem
        WHERE Id_Work = W.Id_Work
    ) AS WI
    WHERE
        W.IS_DEL = 0
    ORDER BY
        W.Id_Work DESC;

    RETURN;
END;
GO



SET STATISTICS TIME ON;


SELECT * FROM dbo.F_WORKS_LIST();


SET STATISTICS TIME OFF;


