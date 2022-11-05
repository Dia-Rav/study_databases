
/*

5.	Разделить все компании на три сегмента: 
    a.	Очень давно не покупали – не было покупок более 365 дней от текущей даты
    b.	Давно не покупали – не было покупок более 180 дней от текущей даты
    c.	Не покупали – не было покупок более 90 дней от текущей даты
    Текущею дату задать следующим образом: система должна брать существующею сегодня дату и смещать ее на 8 лет назад.
*/
SELECT DISTINCT companyName as 'очень давно не покупали'
FROM distributor.singleSales
WHERE DATEDIFF(DAY, dateId, DATEADD(YEAR, -8, GETDATE())) >= 365

SELECT DISTINCT companyName as 'давно не покупали'
FROM distributor.singleSales
WHERE DATEDIFF(DAY, dateId, DATEADD(YEAR, -8, GETDATE())) >= 180

SELECT DISTINCT companyName as 'не покупали'
FROM distributor.singleSales
WHERE DATEDIFF(DAY, dateId, DATEADD(YEAR, -8, GETDATE())) >= 90

/*

13.	Рассчитать выручку компании в разрезе: Филиал – Дата начало месяца – Товарная категория – выручка компании. 
Представление данных отсортировать: Филиал, Дата начало месяца, Товарная категория.
*/
SELECT branchName, StartOfMonth, category, sum(salesRub) AS revenue
FROM (
    select branchName, DATEADD(month, DATEDIFF(month, 0, dateId), 0) AS StartOfMonth, category, salesRub
    FROM distributor.singleSales) AS i
GROUP by branchName, StartOfMonth, category
ORDER by branchName, StartOfMonth, category

/*
17.	Рассчитать выручку компании в разрезе: Менеджер – Бренд – выручка компании. 
Представленные данные отсортировать: Менеджер, Бренд.
*/

SELECT salesManagerId, brand, sum(salesRub) as 'выручка компании'
FROM distributor.sales as s
JOIN distributor.item as i
on i.itemId = s.itemId 
GROUP BY salesManagerId, brand
ORDER by salesManagerId, brand


/*
25.	Определить долю вклада Топ 3 брендов в выручку компании без учета времени, т. е. за всю историю работы компании.
*/

SELECT brand, revenueBrand, revenueBrand/sum(revenueBrand) over(partition by 1) as dolya
FROM(   
    SELECT brand, sum(salesRub) AS revenueBrand
    from distributor.singleSales
    GROUP BY brand
    ) as B
order by revenueBrand DESC

<<<<<<< HEAD:HW_2/Diana_5_9_13.sql
/*
29.	Вывести среднюю месячную динамику продаж, по выручке за предыдущие три месяца по менеджерам, 
для периода год – месяц и отдельно «Дата начало месяца». Т. е. если сейчас 2013-01-01, 
то я хочу видеть среднюю выручку по менеджерам за 2012-10-01, 2012-11-01,2012-12-0129.
Вывести среднюю месячную динамику продаж, по выручке за предыдущие три месяца по менеджерам, 
для периода год – месяц и отдельно «Дата начало месяца». 
Т. е. если сейчас 2013-01-01, то я хочу видеть среднюю выручку по менеджерам за 2012-10-01, 2012-11-01,2012-12-01

33.	Рассчитать долю загрузки складов для каждого года – месяца.

37.	Рассчитать долю продаж эксклюзивного товара к общему, в разрезе каждого Год-Месяца (или дата начало месяца). 
Только для категории обои.
*/
=======
>>>>>>> dad1b5672d8e9112f0e9ae298c805457d29c542c:HW_2/Diana_5_13_17_25.sql
