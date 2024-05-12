CREATE OR ALTER FUNCTION [dbo].[F_WORKS_LIST] (
)
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
-- СПИСОК РАБОТ
begin
insert into @result
SELECT TOP 3000
  Works.Id_Work,
  Works.CREATE_Date,
  Works.MaterialNumber,
  Works.IS_Complit,
  Works.FIO,
  convert(varchar(10), works.CREATE_Date, 104 ) as D_DATE,
  -- dbo.F_WORKITEMS_COUNT_BY_ID_WORK(works.Id_Work,0) as WorkItemsNotComplit,
  COUNT(CASE WHEN WorkItem.is_complit = 0 THEN 1 ELSE NULL END) as WorkItemsNotComplit,
  -- dbo.F_WORKITEMS_COUNT_BY_ID_WORK(works.Id_Work,1) as WorkItemsComplit,
  COUNT(CASE WHEN WorkItem.is_complit = 1 THEN 1 ELSE NULL END) as WorkItemsComplit,
  -- dbo.F_EMPLOYEE_FULLNAME(Works.Id_Employee) as EmployeeFullName,
  RTRIM(REPLACE(Employee.SURNAME + ' ' + UPPER(SUBSTRING(Employee.NAME, 1, 1)) + '. ' + UPPER(SUBSTRING(Employee.PATRONYMIC, 1, 1)) + '.', '. .', '')) AS EmployeeFullName,
  Works.StatusId,
  WorkStatus.StatusName,
  case
      when (Works.Print_Date is not null) or
      (Works.SendToClientDate is not null) or
      (works.SendToDoctorDate is not null) or
      (Works.SendToOrgDate is not null) or
      (Works.SendToFax is not null)
      then 1
      else 0
  end as Is_Print  
FROM
 Works
left join Employee on (Works.Id_Employee = Employee.Id_Employee)
left join WorkItem on (Works.Id_Work = WorkItem.Id_Work)
left join WorkStatus on (Works.StatusId = WorkStatus.StatusID)
where
 	WORKS.IS_DEL <> 1
order by Works.Id_Work desc -- works.MaterialNumber desc
return
end