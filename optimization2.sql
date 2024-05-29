CREATE INDEX IX_Works_DateCreated ON Works(DateCreated);
CREATE INDEX IX_WorkItem_WorkID ON WorkItem(WorkID);
CREATE INDEX IX_Analiz_WorkItemID ON Analiz(WorkItemID);

CREATE FUNCTION [dbo].[F_WORKS_LIST] ()
RETURNS @RESULT TABLE
RETURN(
    SELECT TOP 3000 w.WorkID, w.WorkName, w.DateCreated
    FROM Works w
    ORDER BY w.DateCreated DESC
);

SELECT TOP 3000 * FROM dbo.F_WORKS_LIST();


SELECT TOP 3000 w.WorkID, w.WorkName, w.DateCreated, wi.ItemDescription, a.AnalysisResult
FROM Works w
JOIN WorkItem wi ON w.WorkID = wi.WorkID
JOIN Analiz a ON wi.WorkItemID = a.WorkItemID
ORDER BY w.DateCreated DESC;