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
    
    
    /*22.	У нас есть правило, если клиент:
a.	Купил товар первый раз и до этого ни разу не покупал, то ему присваиваться статус – Новый
b.	Покупает товар хотя бы раз в два месяца, то ему присваивается статус: Постоянный
c.	Если он не купил товар хотя бы раз за два месяца, то ему присваиваться статус: потенциально ушедший
d.	Если он не купил товар хотя бы раз за 4 месяца, то ему присваиваться статус: Ушедший
Необходимо собрать таблицу, в которой на каждый месяц, для каждой компании будет проставлен один из 4 статусов. Дату в таблице сделать как «Дата начало месяца».
*/
select startMonth, companyName, 'Новый' as stat --поиск новых
from(
select ISNULL(companyName, 'иные') as companyName, DATEADD(day, 1, EOMONTH(dateId)) as startMonth, rank() over (partition by companyName order by DATEADD(day, 1, EOMONTH(dateId))) as row
from distributor.singleSales
group by companyName, DATEADD(day, 1, EOMONTH(dateId))) as a
where row = 1

union

select startMonth, companyName, stat = case 
                                        when last_sale > 2 and last_sale <= 4  then 'потенциально ушедший'
                                        when last_sale > 4 then 'ушедший'
                                        end
                                        --мы считаем что для каждого месяца важны продажи за предыдущие месяцы а не прошлые, 
                                        --то есть если он является 'ушедшим' на какую-то дату, то это не значит что и в слежущие четыре месяца он ничего не покупал
from(
    select startMonth, companyName, datediff(month, lag(startMonth, 1, startMonth) over (partition by companyName order by startMonth), startMonth) as last_sale
    from(
        select ISNULL(companyName, 'иные') as companyName, DATEADD(day, 1, EOMONTH(dateId)) as startMonth, 
                rank() over (partition by companyName order by DATEADD(day, 1, EOMONTH(dateId))) as row
        from distributor.singleSales
        group by companyName, DATEADD(day, 1, EOMONTH(dateId))) as b) as c
where last_sale > 2

union

select *
from(
    select startMonth, companyName, stat = case 
                    when max(last_sale) over (partition by companyName order by startMonth rows between unbounded PRECEDING and CURRENT ROW) between 1 and 2 then 'постоянный'
                    end --мы присваем статус постоянного если компания все время что покупает у нас соответсвует условия постоянного
                    --однождый потеряв, уже не вернуть 
    from(
        select companyName, startMonth, datediff(month, lag(startMonth, 1, startMonth) over (partition by companyName order by startMonth), startMonth) as last_sale
        from(
            select ISNULL(companyName, 'иные') as companyName, DATEADD(day, 1, EOMONTH(dateId)) as startMonth
            from distributor.singleSales
            group by companyName, DATEADD(day, 1, EOMONTH(dateId))) as b
        ) as f
    ) as g
where stat is not NULL
order by startMonth, companyName

--26.	Вывести долю занимающих в продажах, различных фабрик. 
--Если в товаре фабрика не указана, сделать замену на «иные» и так же вывести в долях. Нужно вывести как за весь период, 
--так и в разрезе Год – Месяц (или дата начало месяца)

select fabrics, years, months, salesRub/sum(salesRub) over (partition by years, months) as dolya_month_sales, (sum(salesRub) over (partition by fabrics))/(sum(salesRub) over (partition by 1))  as dolya_total_sales
from(
    select fabrics, years, months, sum(salesRub) as salesRub
        from(
            select salesRub , ISNULL(fabrica, 'иные') as fabrics, year(dateId) as years, MONTH(dateId) as months
            from distributor.singleSales as a
            left outer join distributor.item as b
            on b.itemId = a.itemId) as c
    group by fabrics, years, months) as d
order by fabrics, years, months
