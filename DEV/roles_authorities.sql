--создаем новую роль и разрешаем ей доступ к БД--
CREATE ROLE test LOGIN;
--присваиваем различные права доступа к таблицам--
GRANT SELECT, INSERT, UPDATE ON country TO test;
GRANT SELECT (country_id, natural_resources_id), UPDATE (supply, income) ON  export TO test;
GRANT SELECT ON reserve TO test;
--работаем с правами доступа к представлениям--
CREATE VIEW export_natural_resource_v AS
(SELECT natural_resource."name", TO_CHAR(unit_price::numeric,'999G999G999') AS unit_price, 
TO_CHAR(SUM(export.income::numeric),'999G999G999G999') AS total_income FROM export
JOIN natural_resource ON export.natural_resource_id = natural_resource.id
GROUP BY(natural_resource.id))
CREATE VIEW natural_resource_v AS
(select name, mineral_type, unit_price FROM natural_resource)
GRANT SELECT ON natural_resource_v TO test;

CREATE ROLE natural_resource_update;
GRANT UPDATE (unit_price) ON natural_resource_v TO natural_resource_update; 
--добавляем пользователя в новую группу--
GRANT natural_resource_update TO test; 

--тестируем--
SELECT * FROM export_natural_resource_v; 
SELECT * FROM natural_resource_v;
UPDATE natural_resource_v SET mineral_type='цветные металлы' 
WHERE name='песок';
UPDATE natural_resource_v SET unit_price=unit_price+1000::money
WHERE name='железная руда'
RETURNING *;
