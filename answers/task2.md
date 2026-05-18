## Задача 2-го уровня
Предложить правки запросов без модификации структуры БД такие, что время выполнения запроса получения `3 000` заказов из `50 000` со средним количеством элементов в заказе равным `3` не будет превышать `1-2` сек.
При выполнении задания допускается использовать LLM. В случае использования LLM должны быть приведены используемые промты на русском или английском языке.

---

В соответсвии с отмеченными замечаниями в `task1.md` был составлен промпт LLM для написания оптимизированных вариантов функций (см. `update_optimization.sql`).

### 1. `F_EMPLOYEE_FULLNAME`

**Сделанные изменения:**
- `COALESCE()` заменен на явную проверку `IF @ID_EMPLOYEE IS NULL`, чтобы избежать лишней логики
- убран повторный запрос к `Employee`
- логика определения ФИО перенесена в `CASE`, чтобы не выполнять дополнительные обращения к таблице

### 2. `F_WORKITEMS_COUNT_BY_ID_WORK`

**Сделанные изменения:**
- `NOT IN` заменен на `LEFT JOIN + IS NULL`
- фильтрация групповых анализов перенесена в `JOIN`
- заменен `COUNT(*)` на `COUNT_BIG(1)` как более оптимальный вариант агрегирования
- добавлен `ISNULL(@result, 0)`

### 3. `F_WORKS_LIST`

**Сделанные изменения:**
- убраны массовые вызовы `F_WORKITEMS_COUNT_BY_ID_WORK`
- подсчет количества выполненных и невыполненных исследований перенесен в один агрегирующий подзапрос
- вместо двух скалярных функций на каждый заказ выполняется одно агрегирование для всех заказов сразу
- убраны повторные обращения к `Employee`
- оптимизировано формирование ФИО

## Сравнение результатов выполнения

Проверка на соответствие условиям задачи (данные одни и те же для обоих вариантов):

```sql
SELECT COUNT(*) AS TotalWorks FROM Works WHERE IS_DEL = 0;
```
```text
TotalWorks 
-----------
      50000
```

```sql
SELECT AVG(CAST(cnt AS FLOAT)) AS AvgItemsPerWork
FROM (
    SELECT wi.Id_Work, COUNT(*) AS cnt
    FROM WorkItem wi
    INNER JOIN Works w ON wi.Id_Work = w.Id_Work AND w.IS_DEL = 0
    GROUP BY wi.Id_Work
) t;
```
```text
AvgItemsPerWork         
------------------------
                     3.0
```

Результат выполнения `performance_check.sql` с оптимизированными функциями:

```text
 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.
           
-----------
       3000

(1 rows affected)
Table '#A3493C66'. Scan count 1, logical reads 520, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 207 ms,  elapsed time = 210 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
Elapsed time (DMV): 211 ms

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.
Microsoft SQL Server 2005 XML Showplan                                                                                                                                                                                                                          
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
<ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.564" Build="16.0.4252.3"><BatchSequence><Batch><Statements><StmtSimple StatementText="SELECT * FROM dbo.F_WORKS_LIST() WHERE ID_WORK &lt;= 3000" StatementId="1" Stateme

(1 rows affected)
SQL Server parse and compile time: 
   CPU time = 0 ms, elapsed time = 0 ms.
```
### Сравнение производительности

`Prompt:
Сделай markdown таблицу сравнения результатов:
Без оптимизации{}
Оптимизация{}
`

| Метрика                  | Без оптимизации | Оптимизация |
| ------------------------ | --------------- | ----------- |
| Возвращено строк         | 3000            | 3000        |
| Scan count               | 1               | 1           |
| Logical reads            | 520             | 520         |
| Physical reads           | 0               | 0           |
| CPU time (execution)     | 7300 ms         | 207 ms      |
| Elapsed time (execution) | 7264 ms         | 210 ms      |
| Elapsed time (DMV)       | 7268 ms         | 211 ms      |

**До оптимизации:**
- Время выполнения ~ 7 сек  

**После оптимизации:**
- Время выполнения ~ 0.2 сек  

Основной эффект достигнут за счет:

- устранения обращения на каждую строку в функциях;
- замены построчных `COUNT(*)` на агрегирование через `GROUP BY`
- удаления повторных обращений к `Employee`
- замены `NOT IN` на `JOIN`

### Итог

Без изменения структуры БД удалось:
- уменьшить время выполнения запроса с ~ 7 сек до ~ 0.2 сек
- снизить нагрузку на CPU более чем в 30 раз

Итог: требование задачи выполнено с большим запасом - целевое время **1–2 сек** не превышается.
