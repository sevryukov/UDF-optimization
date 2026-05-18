-- Prompt:
-- Сгенерируй оптимизированный вариант функций с заменой в существующей БД в соответствии с выявленными проблемами оптимизации:
-- {task1.md}
-- Напиши только код.

USE udf_optimization;
GO

IF OBJECT_ID('dbo.F_EMPLOYEE_FULLNAME') IS NOT NULL
    DROP FUNCTION dbo.F_EMPLOYEE_FULLNAME;
GO

CREATE OR ALTER FUNCTION dbo.F_EMPLOYEE_FULLNAME
(
    @ID_EMPLOYEE INT
)
RETURNS VARCHAR(101)
AS
BEGIN
    DECLARE @RESULT VARCHAR(101);

    IF @ID_EMPLOYEE IS NULL
        SET @ID_EMPLOYEE = dbo.F_EMPLOYEE_GET();

    IF @ID_EMPLOYEE = -1
        RETURN '';

    SELECT
        @RESULT =
            CASE
                WHEN NULLIF(
                        RTRIM(
                            REPLACE(
                                SURNAME + ' '
                                + UPPER(LEFT(NAME, 1)) + '. '
                                + UPPER(LEFT(PATRONYMIC, 1)) + '.',
                                '. .',
                                ''
                            )
                        ),
                        ''
                     ) IS NOT NULL
                THEN RTRIM(
                        REPLACE(
                            SURNAME + ' '
                            + UPPER(LEFT(NAME, 1)) + '. '
                            + UPPER(LEFT(PATRONYMIC, 1)) + '.',
                            '. .',
                            ''
                        )
                     )
                ELSE LOGIN_NAME
            END
    FROM dbo.Employee
    WHERE Id_Employee = @ID_EMPLOYEE;

    RETURN ISNULL(@RESULT, '');
END;
GO

IF OBJECT_ID('dbo.F_WORKITEMS_COUNT_BY_ID_WORK') IS NOT NULL
    DROP FUNCTION dbo.F_WORKITEMS_COUNT_BY_ID_WORK;
GO

CREATE OR ALTER FUNCTION dbo.F_WORKITEMS_COUNT_BY_ID_WORK
(
    @id_work INT,
    @is_complit BIT
)
RETURNS INT
AS
BEGIN
    DECLARE @result INT;

    SELECT
        @result = COUNT_BIG(1)
    FROM dbo.WorkItem wi
    LEFT JOIN dbo.Analiz a
        ON a.ID_ANALIZ = wi.ID_ANALIZ
       AND a.IS_GROUP = 1
    WHERE wi.Id_Work = @id_work
      AND wi.Is_Complit = @is_complit
      AND a.ID_ANALIZ IS NULL;

    RETURN ISNULL(@result, 0);
END;
GO

IF OBJECT_ID('dbo.F_WORKS_LIST') IS NOT NULL
    DROP FUNCTION dbo.F_WORKS_LIST;
GO

CREATE OR ALTER FUNCTION dbo.F_WORKS_LIST()
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

    INSERT INTO @RESULT
    SELECT
        w.Id_Work,
        w.CREATE_Date,
        w.MaterialNumber,
        w.IS_Complit,
        w.FIO,

        CONVERT(VARCHAR(10), w.CREATE_Date, 104) AS D_DATE,

        ISNULL(wc.WorkItemsNotComplit, 0),
        ISNULL(wc.WorkItemsComplit, 0),

        ISNULL(
            emp.EmployeeFullName,
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

    LEFT JOIN dbo.WorkStatus ws
        ON ws.StatusID = w.StatusId

    LEFT JOIN dbo.Employee e
        ON e.Id_Employee = w.Id_Employee

    LEFT JOIN
    (
        SELECT
            wi.Id_Work,

            SUM(
                CASE
                    WHEN wi.Is_Complit = 0
                    THEN 1
                    ELSE 0
                END
            ) AS WorkItemsNotComplit,

            SUM(
                CASE
                    WHEN wi.Is_Complit = 1
                    THEN 1
                    ELSE 0
                END
            ) AS WorkItemsComplit

        FROM dbo.WorkItem wi

        LEFT JOIN dbo.Analiz a
            ON a.ID_ANALIZ = wi.ID_ANALIZ
           AND a.IS_GROUP = 1

        WHERE a.ID_ANALIZ IS NULL
        GROUP BY wi.Id_Work

    ) wc
        ON wc.Id_Work = w.Id_Work

    OUTER APPLY
    (
        SELECT
            NULLIF(
                RTRIM(
                    REPLACE(
                        e.Surname + ' '
                        + UPPER(LEFT(e.Name, 1)) + '. '
                        + UPPER(LEFT(e.Patronymic, 1)) + '.',
                        '. .',
                        ''
                    )
                ),
                ''
            ) AS EmployeeFullName
    ) emp

    WHERE w.IS_DEL <> 1

    ORDER BY w.Id_Work DESC;

    RETURN;
END;
GO