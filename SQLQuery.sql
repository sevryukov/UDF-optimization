/** 
Задача 2
Чтобы оптимизировать работу по быстрому поиску 3 000 заказов из 50 000:
1. используйте индексы: убедитесь, что все столбцы, используемые для фильтрации, сортировки и объединения, проиндексированы. В частности, столбцы IS_DEL, StatusId, Id_Employee в таблице Works и столбцы Id_Work, Is_Complit и ID_ANALIZ в таблице WorkItem.
2. избегайте вызовов функций: в функции F_WORKS_LIST избегайте вызовов функций F_EMPLOYEE_FULLNAME и F_WORKITEMS_COUNT_BY_ID_WORK на основе каждого заказа, что может привести к большому количеству отдельных запросов. Рассмотрите возможность встраивания этой логики в основной запрос.
3. запросы с пейджингом: если вам не нужно получить все 3 000 заказов сразу, рассмотрите возможность использования пейджинга для уменьшения объема данных в одном запросе.
4. Переписывание запросов: перепишите запрос в функции F_WORKS_LIST, чтобы использовать более эффективные операции JOIN и встроенную логику.
5. обновление статистики: убедитесь, что статистика базы данных актуальна, чтобы оптимизатор запросов мог принимать наилучшие решения по планированию запросов.
**/


CREATE FUNCTION [dbo].[F_WORKS_LIST_OPTIMIZED] ()  
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
    WITH WorkItemCounts AS (  
        SELECT  
            Id_Work,  
            SUM(CASE WHEN Is_Complit = 0 THEN 1 ELSE 0 END) AS WorkItemsNotComplit,  
            SUM(CASE WHEN Is_Complit = 1 THEN 1 ELSE 0 END) AS WorkItemsComplit  
        FROM WorkItem wi  
        INNER JOIN Analiz a ON wi.ID_ANALIZ = a.ID_ANALIZ AND a.IS_GROUP = 0  
        GROUP BY Id_Work  
    ),  
    EmployeeNames AS (  
        SELECT Id_Employee, SURNAME + ' ' + UPPER(LEFT(NAME, 1)) + '. ' + UPPER(LEFT(PATRONYMIC, 1)) + '.' AS FullName  
        FROM Employee  
    )  
    INSERT INTO @result  
    SELECT  
        w.Id_Work,  
        w.CREATE_Date,  
        w.MaterialNumber,  
        w.IS_Complit,  
        w.FIO,  
        CONVERT(varchar(10), w.CREATE_Date, 104) AS D_DATE,  
        wic.WorkItemsNotComplit,  
        wic.WorkItemsComplit,  
        en.FullName AS EmployeeFullName,  
        w.StatusId,  
        ws.StatusName,  
        CASE  
            WHEN w.Print_Date IS NOT NULL OR  
                 w.SendToClientDate IS NOT NULL OR  
                 w.SendToDoctorDate IS NOT NULL OR  
                 w.SendToOrgDate IS NOT NULL OR  
                 w.SendToFax IS NOT NULL  
            THEN 1  
            ELSE 0  
        END AS Is_Print    
    FROM Works w  
    LEFT JOIN WorkStatus ws ON w.StatusId = ws.StatusID  
    LEFT JOIN WorkItemCounts wic ON w.Id_Work = wic.Id_Work  
    LEFT JOIN EmployeeNames en ON w.Id_Employee = en.Id_Employee  
    WHERE w.IS_DEL <> 1  
    ORDER BY w.id_work DESC 
    RETURN;  
END;  
GO


/** 
Задача 3
Вот некоторые из возможных недостатков и негативных последствий:
1.	Повышенная сложность: новые объекты базы данных могут усложнить архитектуру базы данных и сделать ее более сложной для обслуживания.
2.	Проблемы с производительностью: неправильные индексы или триггеры могут привести к снижению производительности.
3.	Избыточность данных: новые столбцы или таблицы могут привести к избыточности данных, что потребует дополнительного обслуживания для обеспечения согласованности данных.
4.	Проблемы миграции: новые объекты базы данных могут потребовать дополнительного рассмотрения и обработки во время миграции или обновления базы данных.
5.	Управление привилегиями: новые объекты базы данных могут потребовать дополнительного управления привилегиями для обеспечения безопасности данных.
**/
