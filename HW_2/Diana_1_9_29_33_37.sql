/*
1.	Рассчитать выручку компании в разрезе: Год – Месяц – Выручка компании. Представленные данные отсортировать: Год, Месяц
*/

select year(dateId) as years, month(dateId) as months, sum(salesRub) as revenueofmonth
FROM distributor.singleSales
group by year(dateId), month(dateId)
order by years, months

/*
9.	Найдите все компании, у которых в наименование в начале стоит «ООО», без учета регистра и пробелов вначале
*/

select distinct companyName
from distributor.singleSales
where replace(lower(companyName), ' ', '') like (N'ма%')
order by companyName

/*
21.	В таблицу: distributor.remains представлена информация об остатках, как : 
Филиал – Артикул товара – Дата – Остаток – СвободныйОстаток. 
Особенность заполнения данной таблицы, что если остаток на какую-то дату нулевой (для товара и филиала), 
то в таблицу он не заноситься, например: 2020-01-01 – 10шт., 2020-01-02 – 7шт. 2020-01-04 – 15 шт. 
Необходимо, восстановить пропуски в данной таблицы и дописать пропущенные значения. 
Из нашего примера: 2020-01-03 – 0 шт. Учтите, что даты складирования товара – филиала своя.
*/

select top 50*
from distributor.remains
order by branchId, itemId, dateId

/*
29.	Вывести среднюю месячную динамику продаж, по выручке за предыдущие три месяца по менеджерам, 
для периода год – месяц или отдельно «Дата начало месяца». Т. е. если сейчас 2013-01-01, 
то я хочу видеть среднюю выручку по менеджерам за 2012-10-01, 2012-11-01,2012-12-01

*/
select fullname, StartOfMonth, sales, avg(sales) over(partition by fullname order by fullname, StartOfMonth rows BETWEEN 3 preceding and 1 preceding)
from(
    select fullname, DATEADD(month, DATEDIFF(month, 0, dateId), 0) AS StartOfMonth, sum(salesRub) as sales
    from distributor.singleSales
    where fullname is not NULL
    group by DATEADD(month, DATEDIFF(month, 0, dateId), 0) , fullname
    ) as a
    
/*
33.	Рассчитать долю загрузки складов для каждого года – месяца.
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
37.	Рассчитать долю продаж эксклюзивного товара к общему, в разрезе каждого Год-Месяца (или дата начало месяца). 
Только для категории обои.
*/
select *, month_sales_item/sum(month_sales_item) over (PARTITION by years, months) as dolya_of_month_sales
from (
    select year(dateId) as years, MONTH(dateId) as months, itemId, sum (salesRub) as month_sales_item
    from distributor.singleSales
    where category = 'Обои'
    group by year(dateId), MONTH(dateId), itemId) as a


