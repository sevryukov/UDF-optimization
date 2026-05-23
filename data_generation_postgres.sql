/*
    Генерация тестовых данных для PostgreSQL-версии задания.

    Цель:
    - 50 000 записей в works;
    - в среднем 3 элемента заказа на каждый заказ;
    - 150 000 записей в workitem;
    - справочники employees, analiz, workstatus, organization и прочие таблицы
      заполняются минимально достаточными данными.

    Запускать после создания схемы:

        psql -U postgres -d udf_optimization -f generate_test_data_postgres.sql

    Скрипт можно запускать повторно: в начале выполняется truncate ... restart identity cascade.
*/

begin;

-- Очищаем таблицы в порядке, безопасном для внешних ключей.
truncate table
    workitem,
    works,
    organization,
    printtemplate,
    templatetype,
    selecttype,
    employee,
    analiz,
    workstatus
restart identity cascade;

-- ============================================================
-- Справочник статусов заказов
-- ============================================================

insert into workstatus (statusname)
values
    ('Создан'),
    ('В работе'),
    ('Готов'),
    ('Отправлен клиенту'),
    ('Закрыт');

-- ============================================================
-- Справочник типов выбора
-- ============================================================

insert into selecttype (selecttype)
values
    ('Обычный'),
    ('Срочный'),
    ('Повторный');

-- ============================================================
-- Типы шаблонов и шаблоны печати
-- ============================================================

insert into templatetype (temlateval, comment)
select
    'TYPE_' || gs,
    'Тип шаблона ' || gs
from generate_series(1, 5) as gs;

insert into printtemplate
(
    templatename,
    createdate,
    ext,
    comment,
    templatebody,
    id_templatetype
)
select
    'Шаблон печати ' || gs,
    now() - (gs || ' days')::interval,
    'docx',
    'Тестовый шаблон ' || gs,
    decode('', 'hex'),
    ((gs - 1) % 5) + 1
from generate_series(1, 20) as gs;

-- ============================================================
-- Организации
-- ============================================================

insert into organization
(
    org_name,
    template_fn,
    id_printtemplate,
    email,
    secondemail,
    fax,
    secondfax
)
select
    'Организация ' || gs,
    'template_' || gs || '.docx',
    ((gs - 1) % 20) + 1,
    'org' || gs || '@example.test',
    'org' || gs || '_second@example.test',
    '+7000000' || lpad(gs::text, 4, '0'),
    '+7111111' || lpad(gs::text, 4, '0')
from generate_series(1, 100) as gs;

-- ============================================================
-- Сотрудники
--
-- Первый сотрудник получает login_name = current_user, чтобы f_employee_get()
-- гарантированно находила текущего пользователя PostgreSQL.
-- ============================================================

insert into employee
(
    login_name,
    name,
    patronymic,
    surname,
    email,
    post,
    createdate,
    updatedate,
    erasedate,
    archived,
    is_role,
    role
)
select
    case
        when gs = 1 then current_user
        else 'employee_' || gs
    end as login_name,
    'Имя' || gs,
    'Отчество' || gs,
    'Фамилия' || gs,
    'employee' || gs || '@example.test',
    case
        when gs % 5 = 0 then 'Администратор'
        when gs % 5 = 1 then 'Лаборант'
        when gs % 5 = 2 then 'Врач'
        when gs % 5 = 3 then 'Оператор'
        else 'Менеджер'
    end,
    now() - (gs || ' days')::interval,
    now() - ((gs % 10) || ' days')::interval,
    null,
    false,
    false,
    gs % 4
from generate_series(1, 100) as gs;

-- ============================================================
-- Спецификации исследований
--
-- Часть анализов помечается как групповая: is_group = true.
-- Функция подсчета workitem должна исключать такие анализы.
-- ============================================================

insert into analiz
(
    is_group,
    material_type,
    code_name,
    full_name,
    id_ill,
    text_norm,
    price,
    normtext,
    unnormtext
)
select
    (gs % 10 = 0) as is_group,
    (gs % 7) + 1,
    'AN_' || lpad(gs::text, 4, '0'),
    'Исследование ' || gs,
    gs % 50,
    'Норма ' || gs,
    round((100 + random() * 900)::numeric, 2),
    'Расширенный текст нормы ' || gs,
    'Расширенный текст отклонения от нормы ' || gs
from generate_series(1, 200) as gs;

-- ============================================================
-- Заказы works: 50 000 строк
-- ============================================================

insert into works
(
    is_complit,
    create_date,
    close_date,
    id_employee,
    id_organization,
    comment,
    print_date,
    org_name,
    part_name,
    org_regn,
    material_type,
    material_get_date,
    material_reg_date,
    materialnumber,
    material_comment,
    fio,
    phone,
    email,
    is_del,
    id_employee_del,
    deldate,
    price,
    extregn,
    medicalhistorynumber,
    doctorfio,
    doctorphone,
    organizationfax,
    organizationemail,
    doctoremail,
    statusid,
    sendtoorgdate,
    sendtoclientdate,
    sendtodoctordate,
    sendtofax,
    sendtoapp
)
select
    (gs % 4 = 0) as is_complit,
    now() - ((50000 - gs) || ' minutes')::interval as create_date,
    case when gs % 4 = 0 then now() - ((50000 - gs - 30) || ' minutes')::interval else null end as close_date,
    ((gs - 1) % 100) + 1 as id_employee,
    ((gs - 1) % 100) + 1 as id_organization,
    'Комментарий к заказу ' || gs,
    case when gs % 5 = 0 then now() - ((50000 - gs) || ' minutes')::interval else null end as print_date,
    'Организация ' || (((gs - 1) % 100) + 1),
    'Подразделение ' || ((gs % 20) + 1),
    gs,
    ((gs % 7) + 1)::smallint,
    now() - ((50000 - gs + 60) || ' minutes')::interval,
    now() - ((50000 - gs + 30) || ' minutes')::interval,
    round((1000 + gs / 100.0)::numeric, 2),
    'Комментарий к материалу ' || gs,
    'Пациент ' || gs,
    '+7999' || lpad((gs % 10000000)::text, 7, '0'),
    'patient' || gs || '@example.test',
    (gs % 100 = 0) as is_del,
    case when gs % 100 = 0 then ((gs - 1) % 100) + 1 else null end as id_employee_del,
    case when gs % 100 = 0 then now() else null end as deldate,
    round((500 + random() * 4500)::numeric, 2),
    'EXT-' || gs,
    'MH-' || gs,
    'Врач ' || ((gs % 50) + 1),
    '+7888' || lpad((gs % 10000000)::text, 7, '0'),
    '+7777' || lpad((gs % 10000000)::text, 7, '0'),
    'org' || (((gs - 1) % 100) + 1) || '@example.test',
    'doctor' || ((gs % 50) + 1) || '@example.test',
    ((gs - 1) % 5) + 1,
    case when gs % 11 = 0 then now() - ((50000 - gs) || ' minutes')::interval else null end,
    case when gs % 13 = 0 then now() - ((50000 - gs) || ' minutes')::interval else null end,
    case when gs % 17 = 0 then now() - ((50000 - gs) || ' minutes')::interval else null end,
    case when gs % 19 = 0 then now() - ((50000 - gs) || ' minutes')::interval else null end,
    case when gs % 23 = 0 then now() - ((50000 - gs) || ' minutes')::interval else null end
from generate_series(1, 50000) as gs;

-- ============================================================
-- Элементы заказа workitem: 150 000 строк
--
-- На каждый заказ создается ровно 3 элемента.
-- Это соответствует условию: среднее количество элементов в заказе равно 3.
-- ============================================================

insert into workitem
(
    create_date,
    is_complit,
    close_date,
    id_employee,
    id_analiz,
    id_work,
    is_print,
    is_select,
    is_normtextprint,
    price,
    id_selecttype
)
select
    w.create_date + ((item_no * 5) || ' minutes')::interval,
    ((w.id_work + item_no) % 2 = 0) as is_complit,
    case
        when ((w.id_work + item_no) % 2 = 0)
            then w.create_date + ((item_no * 10) || ' minutes')::interval
        else null
    end as close_date,
    ((w.id_work + item_no - 1) % 100) + 1 as id_employee,
    ((w.id_work * 3 + item_no - 1) % 200) + 1 as id_analiz,
    w.id_work,
    true as is_print,
    false as is_select,
    true as is_normtextprint,
    round((100 + random() * 900)::numeric, 2) as price,
    ((item_no - 1) % 3) + 1 as id_selecttype
from works w
cross join generate_series(1, 3) as item_no;

-- Обновляем статистику, чтобы планировщик PostgreSQL видел актуальные объемы таблиц.
analyze;

commit;

-- ============================================================
-- Быстрая проверка объемов данных
-- ============================================================

select 'works' as table_name, count(*) as rows_count from works
union all
select 'workitem', count(*) from workitem
union all
select 'analiz', count(*) from analiz
union all
select 'employee', count(*) from employee;

-- ============================================================
-- Проверка основного запроса из задания в PostgreSQL-форме
-- ============================================================

select *
from f_works_list()
limit 3000;
