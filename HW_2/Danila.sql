--8
select companyName from distributor.singleSales
group by companyName
Having companyName LIKE 'ООО%' or companyName LIKE 'ООо%' or companyName LIKE 'ОоО%' or companyName LIKE 'оОО%' or companyName LIKE 'Ооо%' or companyName LIKE 'оОо%' or companyName LIKE 'ооО%' or companyName LIKE'ооо%'

--2
select branchName as 'Филиал', 
DATEADD(day, 1, EOMONTH(dateId)) as 'Дата начала месяца', 
 sum(salesRub) as 'Выручка компании'
from (select distinct dateId, salesRub, b.branchName 
from distributor.sales as a
left join distributor.branch as b
on a.branchId = b.branchId) as d
group by branchName, EOMONTH(dateId)
order by branchName, EOMONTH(dateId)
 

--6. Определить топ 3 бренда, дающий наибольший вклад в выручку компании за 2013 год. 
select top 3 brand,year(dateId) as год
from distributor.item
join distributor.sales on distributor.item.itemId=distributor.sales.itemId
where year(dateId)=2013 and brand is not null
group by brand, year(dateId)
order by sum(salesRub)

--10/20

SELECT branchName, DATEADD(day, 1, EOMONTH(f.dateId)) as 'Дата начала месяца', sum(net_profit) as 'net profit', brand
fROM(
SELECT branchName, b.dateId, b.brand, b.itemId, b.salesRub, b.value, b.DDP,
CASE
WHEN b.value is null then b.salesRub - b.DDP
ELSE b.salesRub - b.DDP * b.value
END as net_profit
from(select branchName, brand,s.checkId, s.itemId, s.dateId, s.salesRub,d.currency1, d.DDP, c.value
from distributor.sales as s
inner join (select t.*
from(select p.itemId, p.DDP, p.monthId, p.yearId, p.currency1, 
ROW_NUMBER() over(partition by itemId, p.dates order by p.currency1) as rn
    from
        (select DISTINCT ddp.DDP, ddp.itemId, ddp.yearId*100 + ddp.monthId as dates, ddp.monthId, ddp.yearId, CASE
        When currencyPurchase like 'E%'then 'EUR'
        WHEN currencyPurchase like 'R%'then 'RUB'
        WHEN currencyPurchase like '%-%'then 'RUB'
        WHEN currencyPurchase like 'G%'then 'GBP'
        WHEN currencyPurchase like 'U%'then 'USD'
        WHEN currencyPurchase is null then 'RUB'
        else TRIM(currencyPurchase)
        end as currency1
        from distributor.ddp
        where ddp.DDP is not null) as p) as t
where t.rn = 1) as d
on s.itemId = d.itemId and d.monthId = month(s.dateId) and d.yearId = year(s.dateId)
left join distributor.currency as c
on s.dateId = c.dateId and d.currency1 = c.currency
left join distributor.branch on distributor.branch.branchId=s.branchId
left join distributor.item on distributor.item.itemId=s.itemId
) as b ) as f
where brand is not NULL
group by branchName, EOMONTH(f.dateId), brand
order by branchName, EOMONTH(f.dateId), [net profit] desc


-- 14.   Определить топ 3 лучших товаров по выручке для каждого бренда с учетом временного интервала год.
select a.* 
from(select year(s.dateId) as years, i.brand,i.itemName,sum(s.salesRub) as revenue, 
ROW_NUMBER() over(partition by year(s.dateId),brand order by sum(s.salesRub) DESC) as rn
from distributor.item as i
INNER join distributor.sales as s on i.itemId=s.itemId
where i.brand is not null
group by i.brand,i.itemName, year(s.dateId)) as a
where a.rn<4
order by a.years, a.brand, a.revenue DESC

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