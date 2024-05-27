### Анализ скрипта функции получения списка заказов и связанные с ней объекты

Для анализа скрипта и выявления потенциальных проблем производительности мы рассмотрим основные функции и таблицы, использованные в скрипте. 

#### Проблемы и недостатки

1. **Функция `F_EMPLOYEE_FULLNAME`**
    - **Описание:** Формирует ФИО сотрудника, объединяя строки и манипулируя символами.
    - **Проблема:** Использование стандартного оператора объединения строк вместо функции `CONCAT`. Использование `CONCAT` может улучшить читаемость и потенциально производительность.
    - **Предложение:** 
      ```sql
      CREATE FUNCTION dbo.F_EMPLOYEE_FULLNAME (@Id_Employee INT)
      RETURNS VARCHAR(255)
      AS
      BEGIN
          DECLARE @FullName VARCHAR(255)
          SELECT @FullName = CONCAT(LastName, ' ', FirstName, ' ', MiddleName)
          FROM dbo.Employee
          WHERE EmployeeID = @Id_Employee
          RETURN @FullName
      END
      ```

2. **Индексы**
    - **Описание:** При фильтрации используется `Id_Employee`, но на этой колонке может отсутствовать индекс.
    - **Проблема:** Отсутствие индекса на `Id_Employee` может привести к медленным запросам.
    - **Предложение:** Создать индекс:
      ```sql
      CREATE INDEX IDX_Employee_Id_Employee ON dbo.Employee(EmployeeID);
      ```

3. **Функция `F_EMPLOYEE_GET`**
    - **Описание:** Возвращает данные сотрудника по его идентификатору.
    - **Проблема:** Не обрабатывает случаи, когда пользователь не найден.
    - **Предложение:** Добавить обработку случаев, когда пользователь не найден:
      ```sql
      CREATE FUNCTION dbo.F_EMPLOYEE_GET (@Id_Employee INT)
      RETURNS TABLE
      AS
      RETURN (
          SELECT EmployeeID, LastName, FirstName, MiddleName
          FROM dbo.Employee
          WHERE EmployeeID = @Id_Employee
      );
      ```

4. **Функция `F_WORKS_LIST`**
    - **Описание:** Возвращает список заказов, ссылаясь на функции `F_WORKITEMS_COUNT_BY_ID_WORK` и `F_EMPLOYEE_FULLNAME`.
    - **Проблема:** Вызов функций для каждой строки результирующей таблицы может существенно снизить производительность.
    - **Предложение:** Избегать использования скалярных функций в SELECT, использовать `JOIN` для получения данных:
      ```sql
      CREATE FUNCTION dbo.F_WORKS_LIST()
      RETURNS TABLE
      AS
      RETURN (
          SELECT 
              w.WorkID,
              w.WorkName,
              w.WorkDate,
              e.EmployeeName,
              (SELECT COUNT(*) FROM dbo.WorkItem wi WHERE wi.WorkID = w.WorkID) AS WorkItemCount
          FROM 
              dbo.Works w
              JOIN dbo.Employee e ON w.EmployeeID = e.EmployeeID
      );
      ```

5. **Типы данных**
    - **Описание:** Использование полей с типом `VARCHAR` большого размера.
    - **Проблема:** Может негативно влиять на производительность запросов.
    - **Предложение:** Оптимизировать длины полей `VARCHAR` в зависимости от реальной необходимости, например:
      ```sql
      ALTER TABLE dbo.Employee
      ALTER COLUMN LastName VARCHAR(100);
      ALTER TABLE dbo.Employee
      ALTER COLUMN FirstName VARCHAR(100);
      ALTER TABLE dbo.Employee
      ALTER COLUMN MiddleName VARCHAR(100);
      ```

6. **Функция `F_EMPLOYEE_GET`**
    - **Описание:** Функция становится лишней при изменении `F_EMPLOYEE_FULLNAME` или при обращении напрямую к таблице `Employee`.
    - **Проблема:** Дублирование логики и ненужное усложнение.
    - **Предложение:** Избегать использования функции `F_EMPLOYEE_GET` и обращаться напрямую к таблице `Employee`.
