CREATE PROCEDURE dbo.RandomString @length INT, @result VARCHAR(255) OUTPUT
AS
BEGIN
  DECLARE @chars NVARCHAR(62) = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  SET @result = ''
  WHILE LEN(@result) < @length
  BEGIN
    SET @result += SUBSTRING(@chars, CAST(RAND() * 62 AS INT) + 1, 1)
  END
END;
GO

CREATE PROCEDURE dbo.RandomEmail @domain VARCHAR(100), @result VARCHAR(255) OUTPUT
AS
BEGIN
  DECLARE @tempString VARCHAR(255)
  EXEC dbo.RandomString 10, @tempString OUTPUT
  SET @result = @tempString + '@' + @domain
END;
GO

CREATE PROCEDURE dbo.RandomDate @result DATETIME OUTPUT
AS
BEGIN
  SET @result = DATEADD(DAY, CAST(RAND() * 3650 * -1 AS INT), GETDATE())
END;
GO

CREATE PROCEDURE dbo.RandomBit @result BIT OUTPUT
AS
BEGIN
  SET @result = CASE WHEN RAND() >= 0.5 THEN 1 ELSE 0 END
END;
GO

CREATE PROCEDURE dbo.RandomPrice @result DECIMAL(8, 2) OUTPUT
AS
BEGIN
  SET @result = CAST(RAND() * 10000 AS DECIMAL(8, 2))
END;
GO

CREATE PROCEDURE dbo.RandomInt @max INT, @result INT OUTPUT
AS
BEGIN
  SET @result = CAST(RAND() * @max AS INT) + 1
END;
GO