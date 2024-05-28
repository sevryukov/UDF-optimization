-- Insert test data into Analiz table
DECLARE @k INT = 1;
WHILE @k <= 1000
BEGIN
    INSERT INTO Analiz (IS_GROUP, MATERIAL_TYPE, CODE_NAME, FULL_NAME, ID_ILL, Text_Norm, Price, NormText, UnNormText)
    VALUES (CAST(RAND() * 2 AS BIT), FLOOR(RAND() * 10), 'Code' + CAST(@k AS VARCHAR), 'Full Name ' + CAST(@k AS VARCHAR), 
            FLOOR(RAND() * 100), 'Text Norm', RAND() * 100, 'Norm Text ' + CAST(@k AS VARCHAR), 'UnNorm Text ' + CAST(@k AS VARCHAR));
    SET @k = @k + 1;
END;
GO

-- Insert test data into Employee table
DECLARE @l INT = 1;
WHILE @l <= 100
BEGIN
    INSERT INTO Employee (Login_Name, Name, Patronymic, Surname, Email, Post, CreateDate, UpdateDate, Archived, IS_Role, Role)
    VALUES ('Login' + CAST(@l AS VARCHAR) + CONVERT(VARCHAR(36), NEWID()), 'Name' + CAST(@l AS VARCHAR), 'Patronymic' + CAST(@l AS VARCHAR), 
            'Surname' + CAST(@l AS VARCHAR), 'Email' + CAST(@l AS VARCHAR) + '@example.com', 'Post' + CAST(@l AS VARCHAR), 
            GETDATE(), GETDATE(), CAST(RAND() * 2 AS BIT), CAST(RAND() * 2 AS BIT), FLOOR(RAND() * 5));
    SET @l = @l + 1;
END;
GO

-- Insert test data into TemplateType table
DECLARE @o INT = 1;
WHILE @o <= 100
BEGIN
    INSERT INTO TemplateType (TemlateVal, Comment)
    VALUES ('Template Val ' + CAST(@o AS VARCHAR), 'Comment ' + CAST(@o AS VARCHAR));
    SET @o = @o + 1;
END;
GO

-- Insert test data into PrintTemplate table
DECLARE @n INT = 1;
WHILE @n <= 100
BEGIN
    INSERT INTO PrintTemplate (TemplateName, CreateDate, Ext, Comment, TemplateBody, Id_TemplateType)
    VALUES ('Template Name ' + CAST(@n AS VARCHAR), GETDATE(), '.ext', 'Comment ' + CAST(@n AS VARCHAR), 
            0x, @n % 100 + 1);
    SET @n = @n + 1;
END;
GO

-- Insert test data into Organization table
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

-- Insert test data into SelectType table
DECLARE @p INT = 1;
WHILE @p <= 10
BEGIN
    INSERT INTO SelectType (SelectType)
    VALUES ('Select Type ' + CAST(@p AS VARCHAR));
    SET @p = @p + 1;
END;
GO

-- Insert test data into Works table
DECLARE @w INT = 1;
WHILE @w <= 50000
BEGIN
    INSERT INTO Works (CREATE_Date, MaterialNumber, IS_Complit, FIO, Id_Employee, StatusId)
    VALUES (GETDATE(), RAND() * 1000, CAST(RAND() * 2 AS BIT), 'FIO ' + CAST(@w AS VARCHAR), @w % 100 + 1, @w % 10 + 1);
    SET @w = @w + 1;
END;
GO

-- Insert test data into WorkItem table
DECLARE @j INT = 1;
WHILE @j <= 150000
BEGIN
    INSERT INTO WorkItem (id_work, id_analiz, is_complit)
    VALUES (@j % 50000 + 1, @j % 1000 + 1, CAST(RAND() * 2 AS BIT));
    SET @j = @j + 1;
END;
GO
