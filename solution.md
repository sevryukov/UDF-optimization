# Решение: оптимизация `dbo.F_WORKS_LIST()`

Клиентский запрос: `select top 3000 * from dbo.F_WORKS_LIST()`.  
Целевой объём: ~50 000 заказов, в среднем ~3 элемента на заказ.

---

## Задача 1-го уровня. Выявленные недочёты и проблемы производительности

### 1. Скалярные UDF в SELECT — главный узкий место

В теле `F_WORKS_LIST` для **каждой** строки `Works` вызываются:

| Вызов | Что делает |
|-------|------------|
| `dbo.F_WORKITEMS_COUNT_BY_ID_WORK(id, 0)` | `COUNT(*)` по `WorkItem` + подзапрос к `Analiz` |
| `dbo.F_WORKITEMS_COUNT_BY_ID_WORK(id, 1)` | то же ещё раз |
| `dbo.F_EMPLOYEE_FULLNAME(Id_Employee)` | выборка из `Employee` (+ возможный вызов `F_EMPLOYEE_GET`) |

Скалярные UDF в SQL Server (особенно до совместимости с inlining) выполняются **построчно** (RBAR). Оптимизатор почти не видит их содержимое, план не может «слить» логику в set-based JOIN/агрегацию.

При 50 000 неудалённых заказов это порядка:

- **100 000** проходов по `WorkItem` (два счётчика на заказ);
- **50 000** обращений к `Employee`.

Клиентский `TOP 3000` **не помогает**: функция сначала заполняет табличную переменную `@RESULT` **всеми** подходящими строками, и только потом внешний `SELECT TOP 3000` обрезает результат.

### 2. `F_WORKITEMS_COUNT_BY_ID_WORK`: антипаттерн `NOT IN` и двойной проход

```sql
and id_analiz not in (select id_analiz from analiz where is_group = 1)
and is_complit = @is_complit
```

Проблемы:

- подзапрос к `Analiz` выполняется в контексте UDF на каждый вызов;
- `NOT IN` хуже, чем `NOT EXISTS` / `LEFT JOIN ... WHERE ... IS NULL` / `JOIN` с фильтром `IS_GROUP = 0`;
- для готовых и неготовых элементов делается **два отдельных** `COUNT` вместо одного прохода с условной агрегацией (`SUM(CASE WHEN ...)`).

Индекс `XIF5WorkItem (Id_Work)` есть, но без `Is_Complit` / покрытия он не закрывает запрос оптимально; фильтрация по `id_analiz` всё равно тянет данные анализов.

### 3. `F_EMPLOYEE_FULLNAME`: лишняя логика и повторные чтения

- При `NULL` вызывается `F_EMPLOYEE_GET()` → поиск по `SYSTEM_USER` в `Employee` — для списка заказов это лишний и неожиданный side-effect.
- Формирование ФИО через строковые операции в UDF вместо JOIN к `Employee` (или использования уже существующей computed-колонки `FULL_NAME`, пусть и с другим форматом).
- При пустом результате — **второй** SELECT по той же таблице за `LOGIN_NAME`.
- Возможны `NULL` в середине конкатенации (`SURNAME + ' ' + ...`), если поля `NULL` вопреки DEFAULT.

### 4. Табличная переменная `@RESULT`

- Нет статистики → оптимизатор часто считает «1 строку», что ухудшает планы при последующем использовании.
- Нет индексов на табличной переменной (в старых версиях) → `ORDER BY id_work DESC` внутри INSERT дорого на больших объёмах.
- Весь набор пишется в tempdb-структуру табличной переменной, затем читается снаружи.

### 5. Фильтр и сортировка по `Works`

```sql
WHERE WORKS.IS_DEL <> 1
ORDER BY id_work desc
```

- На `IS_DEL` **нет индекса** → возможен полный scan `Works`.
- `IS_DEL <> 1` вместо `IS_DEL = 0` мешает SARGability при bit/`NULL` (и менее явно отражает семантику «не удалён»).
- Сортировка по PK `Id_Work` сама по себе хороша (кластерный индекс), но из‑за фильтра и отсутствия covering/filtered index план может быть неоптимальным.
- Нет FK/индекса, явно связывающего `Works.StatusId` → `WorkStatus` (JOIN по статусу без гарантированного индекса на FK со стороны Works; у `WorkStatus` PK есть).

### 6. Нерелевантные / слабые индексы для этого сценария

Есть индексы на `Works(Id_Employee)`, `Works(ID_ORGANIZATION)`, `Works(Id_Employee_Del)` — для списка заказов почти не нужны.  
Критичных для списка нет:

- `(IS_DEL, Id_Work DESC)` или filtered index `WHERE IS_DEL = 0`;
- covering по полям, отдаваемым в список;
- составной по `WorkItem(Id_Work, Is_Complit)` / include `ID_ANALIZ`.

### 7. Прочие замечания по качеству кода

- В `RETURNS TABLE` колонка названа `FULL_NAME`, в SELECT — alias `EmployeeFullName` (путаница имён).
- `D_DATE` как `varchar(10)` через `CONVERT(..., 104)` — форматирование на стороне БД, лишняя CPU-работа; лучше отдавать `datetime` клиенту.
- `F_WORKS_LIST` без параметров: нельзя передать `@Top`, фильтр по дате и т.д. — приложение вынуждено тянуть «всё через UDF».
- Многоколоночный CASE для `Is_Print` читает 5 nullable datetime — приемлемо по CPU, но при covering-индексе эти поля должны попасть в INCLUDE, иначе key lookup.

**Итог уровня 1:** основная причина медленной загрузки — построчные скалярные UDF + материализация полного списка в табличную переменную до применения `TOP 3000`.

---

## Задача 2-го уровня. Оптимизация без изменения структуры БД

Ограничение: не создавать новые таблицы/столбцы/триггеры/индексы как «обязательную» схему. Допускается **переписать функцию** (тело/логику запросов) — это правка программного объекта, а не структуры данных.

Цель: `SELECT TOP 3000 * FROM dbo.F_WORKS_LIST()` за **1–2 секунды** на ~50k заказов / ~3 позиции.

### Идея

1. Убрать вызовы `F_WORKITEMS_COUNT_BY_ID_WORK` и `F_EMPLOYEE_FULLNAME`.
2. Считать счётчики **одним** set-based JOIN + условной агрегацией.
3. ФИО сотрудника — через `LEFT JOIN Employee`.
4. Ограничить объём **внутри** функции (`TOP 3000`), чтобы не строить полный `@RESULT` на 50k строк.
5. Заменить `NOT IN (групповые анализы)` на `JOIN`/`EXISTS` с `IS_GROUP = 0` (или `<> 1`).

### Предлагаемая реализация `F_WORKS_LIST`

```sql
CREATE OR ALTER FUNCTION [dbo].[F_WORKS_LIST] ()
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
  INSERT INTO @RESULT
  SELECT TOP (3000)
    w.Id_Work,
    w.CREATE_Date,
    w.MaterialNumber,
    w.IS_Complit,
    w.FIO,
    CONVERT(varchar(10), w.CREATE_Date, 104) AS D_DATE,
    ISNULL(agg.WorkItemsNotComplit, 0) AS WorkItemsNotComplit,
    ISNULL(agg.WorkItemsComplit, 0) AS WorkItemsComplit,
    CASE
      WHEN e.Id_Employee IS NULL THEN ''
      ELSE RTRIM(REPLACE(
             e.Surname + ' ' +
             UPPER(SUBSTRING(e.Name, 1, 1)) + '. ' +
             UPPER(SUBSTRING(e.Patronymic, 1, 1)) + '.',
             '. .', ''))
    END AS FULL_NAME,
    w.StatusId,
    ws.StatusName,
    CASE
      WHEN w.Print_Date IS NOT NULL
        OR w.SendToClientDate IS NOT NULL
        OR w.SendToDoctorDate IS NOT NULL
        OR w.SendToOrgDate IS NOT NULL
        OR w.SendToFax IS NOT NULL
      THEN CAST(1 AS bit)
      ELSE CAST(0 AS bit)
    END AS Is_Print
  FROM Works AS w
  LEFT JOIN WorkStatus AS ws
    ON w.StatusId = ws.StatusID
  LEFT JOIN Employee AS e
    ON e.Id_Employee = w.Id_Employee
  LEFT JOIN (
    SELECT
      wi.Id_Work,
      SUM(CASE WHEN wi.Is_Complit = 0 THEN 1 ELSE 0 END) AS WorkItemsNotComplit,
      SUM(CASE WHEN wi.Is_Complit = 1 THEN 1 ELSE 0 END) AS WorkItemsComplit
    FROM WorkItem AS wi
    INNER JOIN Analiz AS a
      ON a.ID_ANALIZ = wi.ID_ANALIZ
     AND ISNULL(a.IS_GROUP, 0) = 0   -- не групповой анализ
    GROUP BY wi.Id_Work
  ) AS agg ON agg.Id_Work = w.Id_Work
  WHERE w.Is_Del = 0
  ORDER BY w.Id_Work DESC;

  RETURN;
END
GO
```

### Почему этого достаточно для 1–2 сек

| Было | Стало |
|------|--------|
| ~2×N скалярных COUNT по WorkItem | Один `GROUP BY Id_Work` |
| N вызовов UDF ФИО | Один `LEFT JOIN Employee` |
| Материализация всех ~50k строк | `TOP 3000` внутри функции |
| `NOT IN` + повторный scan Analiz в UDF | Один `INNER JOIN Analiz` с фильтром |

На 50k заказов / ~150k work items один hash/stream aggregate + join обычно укладывается в доли секунды–пару секунд даже без новых индексов (имеющийся `XIF5WorkItem(Id_Work)` и PK `Analiz` помогают).

### Замечания по совместимости с приложением

- Сигнатура и набор колонок `@RESULT` сохранены — клиентский `SELECT TOP 3000 * FROM dbo.F_WORKS_LIST()` менять не нужно.
- Поведение `F_EMPLOYEE_FULLNAME` при `Id_Employee IS NULL` (подстановка текущего пользователя через `F_EMPLOYEE_GET`) **намеренно не воспроизводится**: для списка заказов это выглядит как баг; ФИО берётся только по `Works.Id_Employee`. Если нужна 100% идентичность — можно оставить узкий вызов UDF только для `NULL`, но это редко нужно.
- Fallback на `LOGIN_NAME` при «пустом» ФИО можно добавить `CASE`/`COALESCE`, если это реально используется в данных.

### Опционально (всё ещё без новых таблиц/столбцов)

Если после переписывания функции всё ещё > 2 сек, **создание индексов** формально меняет физическую структуру, но не логическую модель данных. Имеет смысл (часто принимают как допустимое для уровня 2):

```sql
CREATE NONCLUSTERED INDEX IX_Works_IsDel_IdWork
  ON dbo.Works (Is_Del, Id_Work DESC)
  INCLUDE (CREATE_Date, MaterialNumber, IS_Complit, FIO, StatusId,
           Id_Employee, Print_Date, SendToClientDate, SendToDoctorDate,
           SendToOrgDate, SendToFax);

CREATE NONCLUSTERED INDEX IX_WorkItem_IdWork_IsComplit
  ON dbo.WorkItem (Id_Work, Is_Complit)
  INCLUDE (ID_ANALIZ);
```

Без индексов set-based переписывание функции обычно уже даёт целевые 1–2 сек; индексы — запас прочности.

### Альтернатива: inline TVF

Ещё быстрее (оптимизатор встраивает функцию в план внешнего запроса):

```sql
CREATE OR ALTER FUNCTION dbo.F_WORKS_LIST_INLINE()
RETURNS TABLE
AS
RETURN
(
  SELECT TOP (3000) ... -- тот же SELECT, что выше
);
```

Минус: если приложение жёстко вызывает именно `F_WORKS_LIST`, нужна замена тела существующей multi-statement TVF или переименование на стороне БД с synonym — зависит от ограничений курса. Для задания достаточно `CREATE OR ALTER` multi-statement с set-based телом.

### Генератор тестовых данных (для проверки)

```sql
-- статусы
INSERT INTO WorkStatus (StatusName) VALUES ('New'), ('InProgress'), ('Done');

-- сотрудники
DECLARE @i int = 1;
WHILE @i <= 20
BEGIN
  INSERT INTO Employee (Login_Name, Name, Patronymic, Surname, Archived, IS_Role)
  VALUES ('user' + CAST(@i AS varchar(10)), 'Name', 'Patr', 'Surname' + CAST(@i AS varchar(10)), 0, 0);
  SET @i += 1;
END;

-- анализы (не групповые)
SET @i = 1;
WHILE @i <= 50
BEGIN
  INSERT INTO Analiz (IS_GROUP, CODE_NAME, FULL_NAME)
  VALUES (0, 'A' + CAST(@i AS varchar(10)), 'Analiz ' + CAST(@i AS varchar(10)));
  SET @i += 1;
END;

-- 50000 заказов
SET @i = 1;
WHILE @i <= 50000
BEGIN
  INSERT INTO Works (IS_Complit, Id_Employee, FIO, Is_Del, StatusId, MaterialNumber)
  VALUES (0, (@i % 20) + 1, 'Patient ' + CAST(@i AS varchar(10)), 0, (@i % 3) + 1, @i);
  SET @i += 1;
END;

-- ~3 workitem на заказ
INSERT INTO WorkItem (Is_Complit, ID_ANALIZ, Id_Work, Is_Print, Is_Select)
SELECT
  CASE WHEN v.n = 1 THEN 1 ELSE 0 END,
  (w.Id_Work % 50) + 1,
  w.Id_Work,
  1, 0
FROM Works w
CROSS JOIN (VALUES (1),(2),(3)) v(n);
```

Замер:

```sql
SET STATISTICS TIME ON;
SELECT TOP 3000 * FROM dbo.F_WORKS_LIST();
SET STATISTICS TIME OFF;
```

### Использование LLM (промпты)

Промпт 1 (анализ):

> Проанализируй multi-statement TVF `F_WORKS_LIST` в MS SQL Server и связанные скалярные функции `F_WORKITEMS_COUNT_BY_ID_WORK`, `F_EMPLOYEE_FULLNAME`. Клиент делает `SELECT TOP 3000 * FROM dbo.F_WORKS_LIST()` на ~50 000 заказов. Перечисли проблемы производительности и почему TOP не спасает.

Промпт 2 (оптимизация без смены схемы):

> Перепиши `F_WORKS_LIST` без вызовов скалярных UDF: set-based подсчёт готовых/неготовых WorkItem (исключая IS_GROUP=1), JOIN к Employee и WorkStatus, TOP 3000 внутри функции. Сигнатуру таблицы результата не меняй. Объясни, почему это уложится в 1–2 секунды.

Промпт 3 (уровень 3):

> Какие минусы у денормализации счётчиков WorkItem в Works, материализованных view, триггеров и дополнительных индексов для этого списка заказов?

---

## Задача 3-го уровня. Структурные изменения: недостатки и риски

Если set-based переписывания функции недостаточно или нужны дальнейшие ускорения, типичные структурные шаги и их цена:

### 1. Денормализация счётчиков в `Works`

Например, столбцы `WorkItemsComplit`, `WorkItemsNotComplit`, поддержка триггерами на `WorkItem` / `Analiz`.

**Минусы:**

- риск рассинхрона при прямых UPDATE/bulk load / отключённых триггерах;
- усложнение логики записи, отладки, миграций;
- триггеры увеличивают длительность каждой вставки/смены статуса анализа;
- при частых обновлениях `WorkItem` — contention на строках `Works`;
- изменение `IS_GROUP` у анализа требует массового пересчёта связанных заказов.

### 2. Отдельная таблица-кэш / summary (`WorksListCache`)

**Минусы:** дублирование данных, необходимость ETL/триггеров/job’ов обновления, eventual consistency, дополнительное место на диске, усложнение бэкапов и прав доступа.

### 3. Индексированное (материализованное) представление

**Минусы:**

- жёсткие ограничения SQL Server на schema-bound indexed views (детерминизм, типы JOIN, агрегаты);
- накладные расходы на DML по базовым таблицам;
- сложность сопровождения при эволюции схемы `WorkItem`/`Analiz`.

### 4. Много «широких» covering-индексов под один экран

**Минусы:** замедление INSERT/UPDATE/DELETE, рост БД, более долгие rebuild/reorganize, риск выбора оптимизатором неоптимального индекса для других запросов.

### 5. Замена TVF на хранимую процедуру

**Минусы:** ломает текущий контракт приложения (`SELECT ... FROM dbo.F_WORKS_LIST()`), если клиент нельзя менять — неприемлемо. Процедура удобнее для параметров/`OPTION`/`RECOMPILE`, но это уже изменение API.

### 6. Computed persisted columns / смена типов (`D_DATE`, флаги печати)

**Минусы:** увеличение размера строки, время на rebuild таблицы, необходимость регрессионного тестирования всех отчётов, читающих те же поля.

### 7. Партиционирование `Works` / `WorkItem`

**Минусы:** избыточно для 50k строк, операционная сложность (sliding window, aligned indexes), выгода почти нулевая на таком объёме.

---

## Рекомендуемый порядок внедрения

1. **Сначала** — set-based переписывание `F_WORKS_LIST` + `TOP` внутри (уровень 2): максимальный эффект, минимальный риск для модели данных.
2. **При необходимости** — точечные индексы под фильтр/JOIN списка.
3. **Только если** профиль нагрузки на запись низкий, а чтение списка критично и объёмы вырастут на порядки — рассматривать денормализацию/кэш с пониманием рисков из уровня 3.

Ожидаемый результат после шага 1: время `SELECT TOP 3000 * FROM dbo.F_WORKS_LIST()` на описанном объёме — в пределах **1–2 секунд** без изменения таблиц.
