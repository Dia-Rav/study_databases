--5.	Рассчитать кол-во уникальных чеков

SELECT COUNT (distinct checkId) as '№5 кол-во уникальных чеков'
FROM distributor.singleSales
WHERE branchName = 'Екатеринбург' and dateId BETWEEN '2014-01-01' and '2014-01-31'

--9.	Отсортировать данные по убыванию продаж в чеках, со следующими условиями

SELECT fullname as 'Менеджер',  sum(salesRub) as sumSales
FROM distributor.singleSales
WHERE branchName = 'Екатеринбург' and dateId BETWEEN '2014-01-01' and '2014-01-31'
group by checkId
ORDER BY sumSales DESC

--13.	Получить информацию о № чека с максимальной суммой платежа, по следующим условиям

SELECT TOP 1 checkId as '№ чека с максимальной суммой платежа', sum(salesRub) as sumSales
FROM distributor.singleSales
WHERE branchName = 'Екатеринбург' and dateId BETWEEN '2014-01-01' and '2014-01-31'
group by checkId
ORDER BY sumSales DESC

--17.	Сколько обслуживает клиентов каждый менеджер со следующими условиями

SELECT fullname as 'Менеджер', COUNT(distinct checkId)
FROM distributor.singleSales
WHERE branchName = 'Екатеринбург' and dateId BETWEEN '2014-01-01' and '2014-01-31'
GROUP BY  fullname

--21.	Какой менеджер, принес максимальную выручку в филиале за определенный месяц

SELECT TOP 1 fullname as 'Менеджер', sum(salesRub) as 'Sum of sales'
FROM distributor.singleSales
WHERE branchName = 'Екатеринбург' and dateId BETWEEN '2014-01-01' and '2014-01-31'
GROUP BY  fullname
ORDER BY 'Sum of sales' DESC

--25.	Найти с помощью неточного поиска, следующие наименования компании  (пусть будет ремонт)


select top 10* 
from distributor.singleSales
where companyName like '%РЕМОНТ%'



--29.	Рассчитать среднее кол-во артикулов в чеке, в разрезе выделенного менеджера, по следующим условиями
SELECT  AVG(Counting) as 'Среднее количество артикулов в чеке'
FROM (
        SELECT COUNT(itemId) as 'Counting', checkId
        FROM distributor.singleSales
        WHERE branchName = 'Екатеринбург' and dateId BETWEEN '2014-01-01' and '2014-01-31' and fullname = 'Наумов Сергей'
        GROUP BY checkId
    ) 
    as NEW_avg

--33.	Найти сумму продаж по менеджерам, со следующими условиями

SELECT fullname as 'Менеджер', sum(salesRub) as 'Sum of sales'
FROM distributor.singleSales
WHERE branchName = 'Екатеринбург' and dateId BETWEEN '2014-01-01' and '2014-01-31'
GROUP BY  fullname
ORDER BY 'Sum of sales' DESC

