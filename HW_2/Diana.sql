/*
1.	Рассчитать выручку компании в разрезе: Год – Месяц – Выручка компании. Представленные данные отсортировать: Год, Месяц
*/

select year(dateId) as years, month(dateId) as months, sum(salesRub) as revenueofmonth
FROM distributor.singleSales
group by year(dateId), month(dateId)
order by years, months

/*
5.	Разделить все компании на три сегмента: 
    a.	Очень давно не покупали – не было покупок более 365 дней от текущей даты
    b.	Давно не покупали – не было покупок более 180 дней от текущей даты
    c.	Не покупали – не было покупок более 90 дней от текущей даты
    Текущею дату задать следующим образом: система должна брать существующею сегодня дату и смещать ее на 8 лет назад.
*/
SELECT DISTINCT companyName, 'очень давно не покупали'
FROM distributor.singleSales
WHERE DATEDIFF(DAY, dateId, DATEADD(YEAR, -8, GETDATE())) >= 365
UNION ALL
SELECT DISTINCT companyName, 'давно не покупали'
FROM distributor.singleSales
WHERE DATEDIFF(DAY, dateId, DATEADD(YEAR, -8, GETDATE())) between 180 and 365
UNION ALL
SELECT DISTINCT companyName, 'не покупали' 
FROM distributor.singleSales
WHERE DATEDIFF(DAY, dateId, DATEADD(YEAR, -8, GETDATE())) between 90 and 180

/*
9.	Найдите все компании, у которых в наименование в начале стоит «ООО», без учета регистра и пробелов вначале
*/

select distinct companyName
from distributor.singleSales
where replace(lower(companyName), ' ', '') like (N'ооо%')
order by companyName

/*
3.	Рассчитать выручку компании в разрезе: Филиал – Дата начало месяца – Товарная категория – выручка компании. 
Представление данных отсортировать: Филиал, Дата начало месяца, Товарная категория.
*/
SELECT branchName, StartOfMonth, category, sum(salesRub) AS revenue
FROM (
    select branchName, DATEADD(month, DATEDIFF(month, 0, dateId), 0) AS StartOfMonth, category, salesRub
    FROM distributor.singleSales
    WHERE branchName is not Null) AS i
GROUP by branchName, StartOfMonth, category
ORDER by branchName, StartOfMonth, category

/*
7.	Рассчитать выручку компании в разрезе: Менеджер – Бренд – выручка компании. 
Представленные данные отсортировать: Менеджер, Бренд.
*/

SELECT salesManagerId, brand, sum(salesRub) as 'выручка компании'
FROM distributor.sales as s
JOIN distributor.item as i
on i.itemId = s.itemId 
WHERE salesManagerId is not NULL and brand is not NULL 
GROUP BY salesManagerId, brand
ORDER by salesManagerId, brand



/*
15.	Определить долю вклада Топ 3 брендов в выручку компании без учета времени, т. е. за всю историю работы компании.
*/

SELECT top (3) brand, revenueBrand, revenueBrand/sum(revenueBrand) over(partition by 1) as dolya
FROM(   
    SELECT brand, sum(salesRub) AS revenueBrand
    from distributor.singleSales
    GROUP BY brand
    ) as B
order by revenueBrand DESC

/*
19.	Вывести среднюю месячную динамику продаж, по выручке за предыдущие три месяца по менеджерам, 
для периода год – месяц или отдельно «Дата начало месяца». Т. е. если сейчас 2013-01-01, 
то я хочу видеть среднюю выручку по менеджерам за 2012-10-01, 2012-11-01,2012-12-01

*/
select salesManagerId, StartOfMonth, sales, avg(sales) over(partition by salesManagerId order by salesManagerId, StartOfMonth rows BETWEEN 3 preceding and 1 preceding)
from(
    select salesManagerId, DATEADD(month, DATEDIFF(month, 0, dateId), 0) AS StartOfMonth, sum(salesRub) as sales
    from distributor.sales
    where salesManagerId is not NULL
    group by DATEADD(month, DATEDIFF(month, 0, dateId), 0) , salesManagerId
    ) as a

/*
23.	Рассчитать долю загрузки складов для каждого года – месяца.
DATEADD(month, DATEDIFF(month, 0, dateId), 0) AS StartOfMonth
*/

select a.*, a.volumeofitems/b.sizeBranch as dolyaofbranch
from(
    select branchId, years, months, sum(volumeofitem) as volumeofitems
    from (
        select b.branchId, year(b.dateId) as years, MONTH(b.dateId) as months, c.volume*b.remains/c.boxPacking as volumeofitem
        from distributor.remains as b
        join distributor.attributesItem as c
        on c.itemId = b.itemId
        where volume is not NULL) as a
    group by branchId, years, months 
    ) as a
join distributor.branch as b
on b.branchId = a.branchId
order by branchId, years, months

/*
27.	Рассчитать долю продаж эксклюзивного товара к общему, в разрезе каждого Год-Месяца (или дата начало месяца). 
Только для категории обои.
*/
select *, month_sales_item/sum(month_sales_item) over (PARTITION by years, months) as dolya_of_month_sales
from (
    select distinct year(dateId) as years, MONTH(dateId) as months, a.itemId, sum (salesRub) as month_sales_item
    from distributor.sales as a
    join distributor.item as b
    on b.itemId = a.itemId
    where b.category = 'Обои'
    and b.exclusive = 'Да'
    group by year(dateId), MONTH(dateId), a.itemId) as a


    select top(10) itemId, sum(salesRub)
    from distributor.sales
    group by itemId
    order by sum(salesRub) desc