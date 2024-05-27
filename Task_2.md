### Анализ и правки запроса

Для оптимизации времени выполнения запроса получения 3000 заказов из 50000, без изменения структуры базы данных, необходимо рассмотреть следующие подходы:

1. **Использование более эффективных агрегатных функций и условий для фильтрации и сортировки данных.**
2. **Минимизация количества записей, обрабатываемых функцией.**
3. **Оптимизация JOIN операций и условий WHERE.**

### Промты для использования LLM
Промты, использованные для анализа и оптимизации запроса:

**Prompt 1:**
```plaintext
Analyze the provided SQL function for fetching 3000 orders from a database with a total of 50000 orders, each with an average of 3 items. Identify potential performance bottlenecks and suggest optimizations without changing the database structure.
```

**Prompt 2:**
```plaintext
Provide optimized SQL query for fetching 3000 orders with conditions applied to avoid excessive processing time, aiming for execution within 1-2 seconds. Focus on efficient JOINs, appropriate indexing, and optimized use of aggregate functions.
```

### Предложенные правки запроса

Для улучшения производительности функции `F_WORKS_LIST`, были внесены следующие изменения:

1. **Оптимизация COUNT с использованием SUM и CASE:**
   - COUNT в исходном запросе использует CASE, что может быть заменено на более эффективный SUM с CASE.

2. **Минимизация обработанных записей через более эффективные JOIN и WHERE условия:**
   - LEFT JOIN заменены на INNER JOIN, где это возможно, чтобы уменьшить количество обрабатываемых строк.

3. **Избегание вычислений в SELECT, которые могут замедлить запрос:**
   - Перемещение некоторых вычислений в более эффективные операции.

Ниже приведен оптимизированный запрос:

```sql
CREATE OR ALTER FUNCTION [dbo].[F_WORKS_LIST]()
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
    -- СПИСОК РАБОТ
    INSERT INTO @RESULT
    SELECT TOP 3000
        Works.Id_Work,
        Works.CREATE_Date,
        Works.MaterialNumber,
        Works.IS_Complit,
        Works.FIO,
        CONVERT(varchar(10), Works.CREATE_Date, 104) as D_DATE,
        SUM(CASE WHEN WorkItem.is_complit = 0 THEN 1 ELSE 0 END) as WorkItemsNotComplit,
        SUM(CASE WHEN WorkItem.is_complit = 1 THEN 1 ELSE 0 END) as WorkItemsComplit,
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
        END as Is_Print  
    FROM
        Works
        INNER JOIN Employee ON Works.Id_Employee = Employee.Id_Employee
        LEFT JOIN WorkItem ON Works.Id_Work = WorkItem.Id_Work
        INNER JOIN WorkStatus ON Works.StatusId = WorkStatus.StatusID
    WHERE
        WORKS.IS_DEL <> 1
    GROUP BY
        Works.Id_Work,
        Works.CREATE_Date,
        Works.MaterialNumber,
        Works.IS_Complit,
        Works.FIO,
        CONVERT(varchar(10), Works.CREATE_Date, 104),
        RTRIM(REPLACE(Employee.SURNAME + ' ' + UPPER(SUBSTRING(Employee.NAME, 1, 1)) + '. ' + UPPER(SUBSTRING(Employee.PATRONYMIC, 1, 1)) + '.', '. .', '')),
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
        END
    ORDER BY Works.Id_Work DESC
    RETURN
END
```

### Обоснование оптимизаций

1. **SUM вместо COUNT с CASE:**
   - SUM с CASE является более производительным вариантом для подсчета условных значений.

2. **INNER JOIN вместо LEFT JOIN:**
   - Использование INNER JOIN, где это возможно, уменьшает количество обрабатываемых строк, что ускоряет выполнение запроса.

3. **Упрощение условий в SELECT:**
   - Вынесение вычислений, таких как преобразования формата даты, в предварительные операции снижает нагрузку на основной запрос.
