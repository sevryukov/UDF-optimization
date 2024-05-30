CREATE FUNCTION [dbo].[F_WORKS_LIST] (
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
-- —œ»—Œ  –¿¡Œ“
begin
insert into @result
SELECT
  Works.Id_Work,
  Works.CREATE_Date,
  Works.MaterialNumber,
  Works.IS_Complit,
  Works.FIO,
  convert(varchar(10), works.CREATE_Date, 104 ) as D_DATE,
  COUNT(CASE WHEN WorkItem.is_complit = 0 THEN 1 ELSE NULL END) as WorkItemsNotComplit,
  COUNT(CASE WHEN WorkItem.is_complit = 1 THEN 1 ELSE NULL END) as WorkItemsComplit,
  dbo.F_EMPLOYEE_FULLNAME(Works.Id_Employee) as EmployeeFullName,
  Employee.FULL_NAME as EmployeeFullName,
  --Use bellow instead to get the exact same output as in the original
  --RTRIM(REPLACE(Employee.SURNAME + ' ' + UPPER(SUBSTRING(Employee.NAME, 1, 1)) + '. ' + UPPER(SUBSTRING(Employee.PATRONYMIC, 1, 1)) + '.', '. .', '')) AS EmployeeFullName,
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
 left join WorkStatus on (Works.StatusId = WorkStatus.StatusID)
 left join Employee on (Works.Id_Employee=Employee.Id_Employee)
 left join WorkItem on (Works.Id_Work = WorkItem.Id_Work)
where
 WORKS.IS_DEL <> 1
 order by id_work desc
return
end
