/*
21.	В таблицу: distributor.remains представлена информация об остатках, как : 
Филиал – Артикул товара – Дата – Остаток – СвободныйОстаток. 
Особенность заполнения данной таблицы, что если остаток на какую-то дату нулевой (для товара и филиала), 
то в таблицу он не заноситься, например: 2020-01-01 – 10шт., 2020-01-02 – 7шт. 2020-01-04 – 15 шт. 
Необходимо, восстановить пропуски в данной таблицы и дописать пропущенные значения. 
Из нашего примера: 2020-01-03 – 0 шт. Учтите, что даты складирования товара – филиала своя.*/

WITH calend as (
    select convert(date, '14/01/2014', 103) as datestart
    UNION ALL
    select dateadd(day, 1, datestart)
    from calend
    WHERE DATEADD(day, 1, datestart) <= convert(date, '25/02/2014' , 103)
)
SELECT datestart
FROM calend
    

declare @mindate date
SET @mindate = convert(date, (select min (dateId) from distributor.remains), 103)

declare @maxdate date 
SET @maxdate = convert(date, '15/02/2014', 103)
--(select max (dateId) from distributor.remains)

select f.branchId, f.itemId, f.dateId, ISNULL(remains, 0 ) as remain
from(
    select c.branchId, c.itemId, c.dateId, d.remains
    from (
        select distinct branchId, itemId, b.dateId 
        from distributor.remains as a
        cross join( --пары склад-товар размножаем на все даты. получается что все товары, которые бывали на этом складе теперь есть каждый день
            select DISTINCT dateId --создаем календарь, ограничиваясь датами, которые есть в remain (то есть не больше и не меньше)
            FROM distributor.singleSales
            where dateId BETWEEN @mindate and @maxdate) 
            as b) 
            as c
    left outer join (--теперь заполняем наши склад-товар-дата известными остатками (неизвестные становятся null)
        select branchId, itemId, dateId, remains
        from distributor.remains ) as d
    on d.branchId = c.branchId and d.itemId = c.itemId and d.dateId = c.dateId) as f
join (--вспоминаем что товар может храниться не все время, то есть его в какой-то момент перестают закупать или только с какого-то года начали закупать
--находим эти крайние даты на основе данных таблицы remains 
    select distinct branchId, itemId, FIRST_VALUE (dateId) over (PARTITION by branchId, itemId order by  branchId, itemId, dateId ROWS UNBOUNDED PRECEDING) as first_storage,
        last_value (dateId) over (PARTITION by branchId, itemId order by  branchId, itemId, dateId ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) as last_storage 
    from distributor.remains
) as g
on f.branchId = g.branchId and f.itemId = g.itemId
where f.dateId between first_storage and last_storage
order by  f.branchId, f.itemId, f.dateId