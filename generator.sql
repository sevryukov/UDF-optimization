--Analiz
DECLARE @i INT = 1;

WHILE @i <= 100
BEGIN
    INSERT INTO dbo.Analiz (
        IS_GROUP,
        MATERIAL_TYPE,
        CODE_NAME,
        FULL_NAME,
        ID_ILL,
        Text_Norm,
        Price,
        NormText,
        UnNormText
    )
    VALUES (
        CAST(ROUND(RAND(), 0) AS BIT),
        ROUND(RAND() * 10, 0),
        'CODE_NAME' + CAST(@i AS VARCHAR(10)),
        'FULL_NAME' + CAST(@i AS VARCHAR(10)),
        ROUND(RAND() * 100, 0),
        'Text_Norm' + CAST(@i AS VARCHAR(10)),
        ROUND(RAND() * 1000000, 0),
        'NormText' + CAST(@i AS VARCHAR(10)),
        'UnNormText' + CAST(@i AS VARCHAR(10))
    );

    SET @i = @i + 1;
END;
GO

-- Employee
DECLARE @a INT = 1;

WHILE @a <= 100
BEGIN
    INSERT INTO dbo.Employee (
        Login_Name,
        Name,
        Patronymic,
        Surname,
        Email,
        Post,
        CreateDate,
        UpdateDate,
        EraseDate,
        Archived,
        IS_Role,
        Role
    )
    VALUES (
        'login' + CAST(@a AS VARCHAR(10)),
        'Name' + CAST(@a AS VARCHAR(10)),
        'Patronymic' + CAST(@a AS VARCHAR(10)),
        'Surname' + CAST(@a AS VARCHAR(10)),
        'email' + CAST(@a AS VARCHAR(10)) + '@example.com',
        'Post' + CAST(@a AS VARCHAR(10)),
        GETDATE(),
        NULL,
        NULL,
        0,
        0,
        NULL
    );

    SET @a = @a + 1;
END;
GO

-- TemplateTyp
DECLARE @b INT = 1;
WHILE @b <= 100
BEGIN
    INSERT INTO TemplateType (TemlateVal, Comment)
    VALUES ('Template Val ' + CAST(@b AS VARCHAR), 'Comment ' + CAST(@b AS VARCHAR));
    SET @b = @b + 1;
END;
GO

-- PrintTemplate
DECLARE @n INT = 1;
WHILE @n <= 100
BEGIN
    INSERT INTO PrintTemplate (TemplateName, CreateDate, Ext, Comment, TemplateBody, Id_TemplateType)
    VALUES ('Template Name ' + CAST(@n AS VARCHAR), GETDATE(), '.ext', 'Comment ' + CAST(@n AS VARCHAR), 
            0x, @n % 100 + 1);
    SET @n = @n + 1;
END;
GO

DECLARE @m INT = 1;
WHILE @m <= 50
BEGIN
    INSERT INTO Organization (ORG_NAME, TEMPLATE_FN, Id_PrintTemplate, Email, SecondEmail, Fax, SecondFax)
    VALUES ('Org Name ' + CAST(@m AS VARCHAR), 'Template FN ' + CAST(@m AS VARCHAR), @m % 100 + 1, 
            'email' + CAST(@m AS VARCHAR) + '@example.com', 'secondemail' + CAST(@m AS VARCHAR) + '@example.com', 
            '123456789' + CAST(@m AS VARCHAR), '987654321' + CAST(@m AS VARCHAR));
    SET @m = @m + 1;
END;
GO

-- SelectType
DECLARE @p INT = 1;
WHILE @p <= 10
BEGIN
    INSERT INTO SelectType (SelectType)
    VALUES ('Select Type ' + CAST(@p AS VARCHAR));
    SET @p = @p + 1;
END;
GO

-- Works
DECLARE @i INT = 1;

WHILE @i <= 100
BEGIN
    INSERT INTO dbo.Works (
        IS_Complit,
        CREATE_Date,
        Close_Date,
        Id_Employee,
        ID_ORGANIZATION,
        Comment,
        Print_Date,
        Org_Name,
        Part_Name,
        Org_RegN,
        Material_Type,
        Material_Get_Date,
        Material_Reg_Date,
        MaterialNumber,
        Material_Comment,
        FIO,
        PHONE,
        EMAIL,
        Is_Del,
        Id_Employee_Del,
        DelDate,
        Price,
        ExtRegN,
        MedicalHistoryNumber,
        DoctorFIO,
        DoctorPhone,
        OrganizationFax,
        OrganizationEmail,
        DoctorEmail,
        StatusId,
        SendToOrgDate,
        SendToClientDate,
        SendToDoctorDate,
        SendToFax,
        SendToApp
    )
    VALUES (
        CAST(ROUND(RAND(), 0) AS BIT),
        DATEADD(day, ROUND(RAND() * 365, 0), '2022-01-01'),
        DATEADD(day, ROUND(RAND() * 365, 0), '2022-01-01'),
        ROUND(RAND() * 100, 0),
        ROUND(RAND() * 100, 0),
        'Comment ' + CAST(@i AS VARCHAR(10)),
        DATEADD(day, ROUND(RAND() * 365, 0), '2022-01-01'),
        'Org_Name ' + CAST(@i AS VARCHAR(10)),
        'Part_Name ' + CAST(@i AS VARCHAR(10)),
        ROUND(RAND() * 1000000, 0),
        ROUND(RAND() * 10, 0),
        DATEADD(day, ROUND(RAND() * 365, 0), '2022-01-01'),
        DATEADD(day, ROUND(RAND() * 365, 0), '2022-01-01'),
        ROUND(RAND() * 1000000, 0),
        'Material_Comment ' + CAST(@i AS VARCHAR(10)),
        'FIO ' + CAST(@i AS VARCHAR(10)),
        'PHONE ' + CAST(@i AS VARCHAR(10)),
        'EMAIL' + CAST(@i AS VARCHAR(10)) + '@example.com',
        CAST(ROUND(RAND(), 0) AS BIT),
        ROUND(RAND() * 100, 0),
        DATEADD(day, ROUND(RAND() * 365, 0), '2022-01-01'),
        ROUND(RAND() * 1000000, 0),
        'ExtRegN ' + CAST(@i AS VARCHAR(10)),
        'MedicalHistoryNumber ' + CAST(@i AS VARCHAR(10)),
        'DoctorFIO ' + CAST(@i AS VARCHAR(10)),
        'DoctorPhone ' + CAST(@i AS VARCHAR(10)),
        'OrganizationFax ' + CAST(@i AS VARCHAR(10)),
        'OrganizationEmail ' + CAST(@i AS VARCHAR(10)),
        'DoctorEmail' + CAST(@i AS VARCHAR(10)) + '@example.com',
        ROUND(RAND() * 10, 0),
        DATEADD(day, ROUND(RAND() * 365, 0), '2022-01-01'),
        DATEADD(day, ROUND(RAND() * 365, 0), '2022-01-01'),
        DATEADD(day, ROUND(RAND() * 365, 0), '2022-01-01'),
        DATEADD(day, ROUND(RAND() * 365, 0), '2022-01-01'),
        DATEADD(day, ROUND(RAND() * 365, 0), '2022-01-01')
    );

    SET @i = @i + 1;
END;
GO

--WorkItem
DECLARE @z INT = 1;

WHILE @z <= 100
BEGIN
    INSERT INTO dbo.WorkItem (
        CREATE_DATE,
        Is_Complit,
        Close_Date,
        Id_Employee,
        ID_ANALIZ,
        Id_Work,
        Is_Print,
        Is_Select,
        Is_NormTextPrint,
        Price,
        Id_SelectType
    )
    VALUES (
        DATEADD(day, ROUND(RAND() * 365, 0), '2022-01-01'),
        CAST(ROUND(RAND(), 0) AS BIT),
        DATEADD(day, ROUND(RAND() * 365, 0), '2022-01-01'),
        ROUND(RAND() * 100, 0),
        ROUND(RAND() * 100, 0),
        ROUND(RAND() * 100, 0),
        CAST(ROUND(RAND(), 0) AS BIT),
        CAST(ROUND(RAND(), 0) AS BIT),
        CAST(ROUND(RAND(), 0) AS BIT),
        ROUND(RAND() * 1000000, 0),
        ROUND(RAND() * 10, 0)
    );

    SET @z = @z + 1;
END;
GO

