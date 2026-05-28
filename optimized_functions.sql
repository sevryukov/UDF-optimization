-- ==================================================
-- Анализ проблем оригинальной функции F_WORKS_LIST
-- ==================================================
-- 1. Оригинальная функция использует скалярные функции F_WORKITEMS_COUNT_BY_ID_WORK
--    и F_EMPLOYEE_FULLNAME для КАЖДОЙ строки заказа (row-by-row).
-- 2. F_WORKITEMS_COUNT_BY_ID_WORK вызывается дважды на заказ (is_complit = 0 и 1),
--    что приводит к многократным отдельным запросам к таблице WorkItem.
-- 3. F_EMPLOYEE_FULLNAME выполняет дополнительный запрос к Employee для каждого заказа.
-- 4. Такой подход крайне неэффективен при большом количестве заказов (50k+),
--    так как время выполнения растёт линейно, а не за счёт множественной обработки.
--
-- Оптимизация:
--   - Заменяем скалярные функции на CTE с группировкой (один проход по WorkItem).
--   - Исключаем групповые анализы (Analiz.is_group = 1) – как в оригинальной логике.
--   - Формируем FULL_NAME через прямой JOIN с Employee и очисткой лишних символов,
--     при пустом результате используем Login_Name.
--   - Все расчёты делаем за один проход на основе множеств (set-based).
-- ==================================================

ALTER FUNCTION [dbo].[F_WORKS_LIST] ()
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
    -- CTE: считаем количество невыполненных / выполненных позиций
    -- исключая групповые анализы (is_group = 1)
    WITH WorkItemCounts AS (
        SELECT 
            wi.Id_Work,
            SUM(CASE WHEN wi.Is_Complit = 0 THEN 1 ELSE 0 END) AS NotComplit,
            SUM(CASE WHEN wi.Is_Complit = 1 THEN 1 ELSE 0 END) AS Complit
        FROM dbo.WorkItem wi
        WHERE wi.Id_Analiz NOT IN (SELECT a.Id_Analiz FROM dbo.Analiz a WHERE a.Is_Group = 1)
        GROUP BY wi.Id_Work
    )
    INSERT INTO @RESULT
    SELECT 
        w.Id_Work,
        w.CREATE_Date,
        w.MaterialNumber,
        w.IS_Complit,
        w.FIO,
        CONVERT(varchar(10), w.CREATE_Date, 104) AS D_DATE,
        ISNULL(wic.NotComplit, 0) AS WorkItemsNotComplit,
        ISNULL(wic.Complit, 0) AS WorkItemsComplit,
        -- Формируем FULL_NAME аналогично оригиналу
        COALESCE(
            NULLIF(
                RTRIM(REPLACE(
                    ISNULL(e.Surname, '') + ' ' +
                    UPPER(LEFT(ISNULL(e.Name, ''), 1)) + '. ' +
                    UPPER(LEFT(ISNULL(e.Patronymic, ''), 1)) + '.',
                    '. .', ''
                )),
            ''),
            e.Login_Name
        ) AS FULL_NAME,
        w.StatusId,
        ws.StatusName,
        CASE 
            WHEN w.Print_Date IS NOT NULL 
              OR w.SendToClientDate IS NOT NULL 
              OR w.SendToDoctorDate IS NOT NULL 
              OR w.SendToOrgDate IS NOT NULL 
              OR w.SendToFax IS NOT NULL 
            THEN 1 
            ELSE 0 
        END AS Is_Print
    FROM dbo.Works w
    LEFT JOIN dbo.WorkStatus ws ON w.StatusId = ws.StatusID
    LEFT JOIN dbo.Employee e ON w.Id_Employee = e.Id_Employee
    LEFT JOIN WorkItemCounts wic ON w.Id_Work = wic.Id_Work
    WHERE w.IS_DEL <> 1
    ORDER BY w.Id_Work DESC;
    RETURN;
END;
GO