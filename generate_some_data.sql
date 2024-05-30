
/****** Generate data (1) ******/

--  Generate data for table Employee
SET IDENTITY_INSERT Employee ON
INSERT INTO Employee (ID_EMPLOYEE, SURNAME, NAME, PATRONYMIC, LOGIN_NAME) VALUES
(1, 'Иванов', 'Иван', 'Иванович', 'ivanov_ii'),
(2, 'Петрова', 'Петра', 'Петровна', 'petrova_pp'),
(3, 'Сидоров', 'Петр', 'Алексеевич', 'sidorov_pa'),
(4, 'Кузнецова', 'Анна', 'Владимировна', 'kuznetsova_av'),
(5, 'Попов', 'Дмитрий', 'Андреевич', 'popov_da'),
(6, 'Дмитриевский', 'Дмитрий', 'Димитриевич', 'dmitrievskiy_dd');

SET IDENTITY_INSERT Employee OFF 

-- Generate data for table WorkStatus
SET IDENTITY_INSERT WorkStatus  ON
INSERT INTO WorkStatus (StatusID, StatusName) VALUES
(1, 'Новый'),
(2, 'В работе'),
(3, 'Завершен'),
(4, 'Отменен');
SET IDENTITY_INSERT WorkStatus OFF 

-- Generate data for table Works
SET IDENTITY_INSERT Works ON
INSERT INTO Works (Id_Work, CREATE_Date, MaterialNumber, IS_Complit, FIO, Id_Employee, StatusId, Print_Date) VALUES
(1, '2023-01-01', 12345.00, 0, 'Дмитриевский Д.Д.', 1, 1, NULL),
(2, '2023-02-02', 23456.00, 1, 'Петрова П.П.', 2, 2, NULL),
(3, '2023-03-03', 34567.00, 0, 'Сидоров П.А.', 3, 1, NULL),
(4, '2023-04-04', 45678.00, 0, 'Кузнецова А.В.', 4, 2, NULL),
(5, '2023-05-05', 56789.00, 1, 'Попов Д.А.', 5, 3, '2023-05-10'),
(6, '2023-06-06', 67890.00, 0, 'Иванов И.И.', 1, 1, NULL),
(7, '2023-07-07', 78901.00, 1, 'Петрова П.П.', 2, 3, '2023-07-15'),
(8, '2023-08-08', 89012.00, 0, 'Сидоров П.А.', 3, 2, NULL),
(9, '2023-09-09', 90123.00, 1, 'Кузнецова А.В.', 4, 3, '2023-09-20'),
(10, '2023-10-10', 10123.00, 0, 'Попов Д.А.', 5, 1, NULL);
SET IDENTITY_INSERT Wrks OFF 

-- Generate data for table WorkItems
INSERT INTO WorkItem (Id_Work, Id_Analiz, IS_Complit, Is_Print, Is_Select) VALUES
(1, 1, 0, 0, 0),
(1, 2, 0, 0, 1),
(1, 3, 0, 0, 0),
(2, 4, 1, 1, 0),
(2, 5, 1, 1, 1),
(2, 6, 0, 0, 0),
(3, 7, 0, 0, 0),
(3, 8, 1, 1, 1),
(3, 9, 0, 0, 0),
(4, 10, 1, 1, 0),
(4, 11, 1, 1, 0),
(4, 12, 0, 0, 0),
(5, 13, 1, 1, 0),
(5, 14, 1, 1, 1),
(5, 15, 0, 0, 0),
(6, 16, 0, 0, 0),
(6, 17, 0, 0, 0),
(6, 18, 0, 0, 0),
(7, 19, 1, 1, 0),
(7, 20, 1, 1, 0),
(7, 21, 0, 0, 0),
(8, 22, 0, 0, 0),
(8, 23, 1, 1, 0),
(8, 24, 0, 0, 1),
(9, 25, 1, 1, 0),
(9, 26, 1, 1, 0),
(9, 27, 0, 1, 0),
(10, 28, 0, 0, 0),
(10, 29, 0, 0, 0),
(10, 30, 0, 0, 0);
