## Задача 1-го уровня
Проанализировать скрипт функции получения списка заказов и связанные с ней объекты, перечислить выявленные недочёты и потенциальные проблемы производительности.

---

## Анализ скрипта функции

Выпишем отдельно функцию (`F_WORKS_LIST()`) из запроса `select top 3000 * from dbo.F_WORKS_LIST()` и последовательно проанализируем ее:

```sql
-- Функция dbo.F_WORKS_LIST является Multi-Statement Table Valued Function (MSTVF) и имеет соответствующие проблемы:
-- MSTVF использует внутреннюю табличную переменную (@RESULT) - SQL Server может работать с табличными переменными хуже, чем с обычными таблицами, особенно при больших объемах данных [https://www.geeksforgeeks.org/sql/multi-statement-table-valued-function-in-sql-server/]
-- Вызов select top 3000 * from dbo.F_WORKS_LIST() не означает, что SQL Server обработает только 3000 строк. Функция сначала полностью заполняет @RESULT TABLE через INSERT INTO @RESULT и только после этого внешний запрос применяет TOP 3000 [https://www.sqlshack.com/sql-server-multi-statement-table-valued-functions/]
-- MSTVF может ухудшать работу оптимизатора SQL Server, поскольку логика скрыта внутри функции и возвращается через табличную переменную [https://www.geeksforgeeks.org/sql/multi-statement-table-valued-function-in-sql-server/]
-- Для функции это особенно критично, потому что внутри нее дополнительно выполняются сортировка, джоин, агрегаты... Из-за полного выполнения MSTVF перед возвратом результата растут CPU, логика чтения, использование памяти.

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

        -- Внутри основного SELECT вызываются скалярные пользователские функции - функции вызываются для каждой строки, построчно

        -- F_WORKITEMS_COUNT_BY_ID_WORK вызывается дважды для каждой строки [см. ниже про саму функцию]

        dbo.F_WORKITEMS_COUNT_BY_ID_WORK(Works.Id_Work, 0)
            AS WorkItemsNotComplit,

        dbo.F_WORKITEMS_COUNT_BY_ID_WORK(Works.Id_Work, 1)
            AS WorkItemsComplit,

        -- [см. ниже]
        dbo.F_EMPLOYEE_FULLNAME(Works.Id_Employee)
            AS EmployeeFullName,

        Works.StatusId,

        WorkStatus.StatusName,

        -- Несколько проверок - вычисление для каждой строки
        CASE
            WHEN (Works.Print_Date IS NOT NULL)
              OR (Works.SendToClientDate IS NOT NULL)
              OR (Works.SendToDoctorDate IS NOT NULL)
              OR (Works.SendToOrgDate IS NOT NULL)
              OR (Works.SendToFax IS NOT NULL)
            THEN 1
            ELSE 0
        END AS Is_Print

    FROM Works

    LEFT OUTER JOIN WorkStatus
        ON Works.StatusId = WorkStatus.StatusID

    WHERE Works.IS_DEL <> 1

    -- Сортировка внутри функции
    -- Если нет индекса на поле Id_Work, то необъодимо прочитать всю таблицу целиком
    ORDER BY Id_Work DESC
    -- works.MaterialNumber DESC

    RETURN
END
```

Отдельные компоненты:

```sql
CREATE FUNCTION [dbo].[F_WORKITEMS_COUNT_BY_ID_WORK] (@id_work int, @is_complit bit)
RETURNS int
AS
BEGIN
-- количество готовых / не готовых анализов для заказа

    -- Повторное сканирование WorkItem - для каждого заказа таблица читается повторно
    declare @result int
    -- Множество отдельных count без группировки
    select @result = count(*) from workitem
    -- Несмотря на наличие индекса функция вызывается для каждой строки отдельно - приводит к огромному количеству повторных операций
    where id_work = @id_work
    -- не является групповым
    and id_analiz 

    -- Подзапрос выполняется многократно, он вычисляется при каждом вызове функции
	not in 
		(select id_analiz 
		from analiz where is_group = 1)
     
	and is_complit = @is_complit

    Return @result
END
```

```sql
CREATE FUNCTION [dbo].[F_EMPLOYEE_FULLNAME] (@ID_EMPLOYEE INT)
RETURNS VARCHAR(101)
AS
BEGIN
  DECLARE @RESULT VARCHAR(101)

  -- Вложенный вызов функции
  SET @ID_EMPLOYEE = COALESCE(@ID_EMPLOYEE, dbo.F_EMPLOYEE_GET())

  IF @ID_EMPLOYEE = -1
     SET @RESULT = ''
  ELSE
    SELECT @RESULT = SURNAME + ' ' + UPPER(SUBSTRING(NAME, 1, 1)) + '. ' +
    UPPER(SUBSTRING(PATRONYMIC, 1, 1)) + '.' FROM Employee
    WHERE ID_EMPLOYEE = @ID_EMPLOYEE
  SET @RESULT = RTRIM (REPLACE(@RESULT, '. .', ''))
  
  IF @RESULT = ''
    -- Повторные запросы к Employee
	SELECT @RESULT = LOGIN_NAME FROM Employee Where Id_Employee = @ID_Employee
  RETURN @RESULT
END
```

## Анализ запроса

```sql
select top 3000 * from dbo.F_WORKS_LIST()
```

1. `TOP` применяется после полного выполнения функции. Так как `F_WORKS_LIST()` является MSTVF, то SQL Server:
- полностью выполняет функцию
- полностью заполняет @RESULT
- затем применяет TOP 3000

То есть даже при необходимости вернуть только 3000 строк будут обработаны все записи таблицы `Works`.

2. `SELECT` - передаются все столбцы, даже если клиенту часть не нужна

## Анализ тестового запроса

`performance_check.sql`

```text
 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 1 ms, elapsed time = 2 ms.
           
-----------
       3000

(1 rows affected)
Table '#AD59FB47'. Scan count 1, logical reads 266, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 4995 ms,  elapsed time = 5039 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
Elapsed time (DMV): 5045 ms

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 1 ms, elapsed time = 1 ms.
Microsoft SQL Server 2005 XML Showplan                                                                                                                                                                                                                          
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
<ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.564" Build="16.0.4252.3"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT * FROM dbo.F_WORKS_LIST() WHERE ID_WORK &lt;= 3000" StatementId="1" Stateme

(1 rows affected)
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.
```

Из результатов выполнения:
- CPU time ~ 5 секунд
- elapsed time ~ 5 секунд
- logical reads: 266
- Итоговая выборка: 3000 строк

Проблемы:
- высокая CPU - скалярные функции и построчная обработка
- основное время - вычисления
- по плану выполнения функция выполнилась полностью (все строки), а фильтр `WHERE ID_WORK <= 3000` применился только после

Если все обобщить:
- MSTVF
- TOP и WHERE не ограничивают выполнение функции
- основная стоимость это вычисления внутри пользовательских функций
- производительность линейно зависит от объема таблицы `Works`
