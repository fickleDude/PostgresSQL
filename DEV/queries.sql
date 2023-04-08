--1--
/*Для каждого из пунктов, для полезных ископаемых, расчитаваемых в тоннах, 
вывести стоимость единицы добычи и долю стоимости добычи данного ископаемого 
от общей стоимости добычи на данном пункте:*/
SELECT transfer_point.name, natural_resource.name, reserve.unit_cost AS cost,
ROUND(reserve.unit_cost::numeric / (SUM(reserve.unit_cost) OVER (PARTITION BY transfer_point.name)::numeric), 2) 
FROM reserve 
JOIN natural_resource ON natural_resource.id = reserve.natural_resource_id
JOIN transfer_point ON transfer_point.id = reserve.transfer_point_id
WHERE LOWER(measurement) NOT IN (SELECT regexp_split_to_table(measurement, '^[т | p | t].*'))

--2--
/*Вывести максимальный объем поставок и максимальный объем 
добычи для каждого из способов добычи:*/
WITH max_extraction AS (
SELECT extract_method AS method, annual_extraction AS extraction,
DENSE_RANK() OVER (PARTITION BY extract_method ORDER BY annual_extraction DESC) AS max_annual_extraction,
reserve.natural_resource_id AS id								  
FROM reserve)
SELECT DISTINCT max_extraction.method, 
TO_CHAR(max_extraction.extraction,'9G999G999') AS max_extraction,
TO_CHAR(FIRST_VALUE(supply) OVER (PARTITION BY max_extraction.method ORDER BY supply DESC),'9G999G999') AS max_supply  
FROM export
JOIN max_extraction ON max_extraction.id = export.natural_resource_id
WHERE max_annual_extraction = 1

--3--
/*Вывести 3 природных ресурса, у которых количество запасов 
превышает объем поставок в большей степени:*/  
SELECT natural_resource.name, SUM(b.diff) FROM natural_resource, 
(SELECT ABS(deposit - supply) AS diff, export.natural_resource_id AS id  
FROM reserve, export
WHERE export.natural_resource_id = reserve.natural_resource_id
AND deposit > supply) AS b
WHERE b.id = natural_resource.id
GROUP BY (natural_resource.name)
ORDER BY SUM(b.diff) DESC
LIMIT 3 

--4--
/*Удаляем пробелы в указании единиц измерения природных ресурсов:*/
UPDATE natural_resource SET measurement = TRIM(' ' FROM measurement)
RETURNING *;

--5--
/*Добавляем страну, если ее еще нет в таблице стран:*/
INSERT INTO country (name)
SELECT 
    'France'
WHERE NOT EXISTS (
    SELECT name FROM country WHERE name = 'France'
)
RETURNING *;

--6--
/*Увеличиваем количество персонала на 100 человек 
в пункте транспортировки с минимальной пропускной способностью:*/
UPDATE transfer_point SET staff = staff + 100 
WHERE id IN (SELECT id FROM transfer_point
WHERE capacity IN (SELECT MIN(capacity) FROM transfer_point))
RETURNING *;
