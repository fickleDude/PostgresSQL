--1--
/*Создаем функцию для форматирования записи типа полезного ископаемого 
в виде "тип, ед.изм. " для представления natural_resource_v:*/
CREATE OR REPLACE FUNCTION mineral_type_name(
    mineral_type text,
    measurement text
) RETURNS text
AS $$
SELECT mineral_type || ', ' ||
left(split_part(measurement, ' ', 1), 1) || '. ' ||
       CASE WHEN split_part(measurement, ' ', 2) != ''
           THEN ' ' || left(split_part(measurement, ' ', 2), 1) || '. '
           ELSE ''
       END;
$$ IMMUTABLE LANGUAGE sql;

CREATE OR REPLACE VIEW natural_resource_v AS
(SELECT name, mineral_type_name(mineral_type, measurement) AS mineral_type, unit_price FROM natural_resource)

--2--
/*Создаем функцию для добавления пункта добычи полезного искомаемого:*/
CREATE OR REPLACE FUNCTION add_reserve(
    v_natural_resource_name text, 
    v_transfer_point_name text, 
    v_extract_method text, 
	v_annual_extraction bigint DEFAULT 0
) RETURNS integer
AS $$
DECLARE
    v_natural_resource_id integer;
	v_transfer_point_id integer;
	v_reserve_id integer;
	ret integer DEFAULT null;
BEGIN
	SELECT natural_resource.id FROM natural_resource INTO v_natural_resource_id
	WHERE natural_resource.name = v_natural_resource_name;
	IF v_natural_resource_id IS null THEN
		RAISE NOTICE 'Resource with name % not present in the table!', v_natural_resource_name;
		RETURN ret;
	END IF;
	RAISE NOTICE 'Resource id = %', v_natural_resource_id;
	SELECT transfer_point.id FROM transfer_point INTO v_transfer_point_id 
	WHERE transfer_point.name = v_transfer_point_name;
	IF v_transfer_point_id IS null THEN
		RAISE NOTICE 'Transfer point with name % not present in the table!', v_transfer_point_name;
		RETURN ret;
	END IF;
	RAISE NOTICE 'Transfer id = %', v_transfer_point_id;
	SELECT reserve.id FROM reserve INTO v_reserve_id 
	WHERE transfer_point_id = v_transfer_point_id AND natural_resource_id = v_natural_resource_id;
	CASE
		WHEN v_reserve_id is null THEN
			INSERT INTO reserve(natural_resource_id, transfer_point_id, extract_method, annual_extraction)
				VALUES (v_natural_resource_id, v_transfer_point_id, v_extract_method, v_annual_extraction)
				RETURNING reserve.id into strict ret;
			RAISE NOTICE 'Inserted reserve with id = %', ret;
		ELSE
			RAISE NOTICE 'Relationship with natural_resource_id = %  and transfer_point_id = % 
			already exists!', v_natural_resource_id, v_transfer_point_id;
			return ret;
    END CASE;
	return ret;
END;
$$ VOLATILE LANGUAGE plpgsql;

--3--
/*Создаем процедуру, которая обновляет рыночную цену за единицу добычи полезного ископаемого и 
изменяет значение прибыли, в соответствии с рыночной стоимостью, для стран, в которые это ископаемое поставляется:*/
CREATE PROCEDURE update_unit_price(
	v_price money, 
	v_natural_resource_name text 
) 
AS $$
DECLARE
	export_cur CURSOR(id integer) FOR SELECT income, supply FROM export 
	WHERE export.natural_resource_id = export_cur.id FOR UPDATE;
	v_natural_resource_id integer;
BEGIN
	select natural_resource.id from natural_resource into v_natural_resource_id
	where natural_resource.name = v_natural_resource_name;
	if v_natural_resource_id is null then
		RAISE NOTICE 'Resource with name % not present in the table!', v_natural_resource_name;
		return;
	ELSE
		UPDATE natural_resource SET unit_price = unit_price + v_price;
		RAISE NOTICE 'Updated % price!', v_natural_resource_name;
	end if;
    FOR export IN export_cur(v_natural_resource_id) LOOP
        UPDATE export SET income = income + v_price * supply
        WHERE CURRENT OF export_cur;
    END LOOP;
	if FOUND then
		RAISE NOTICE 'Income successfully updated!';
	end if; 
END;
$$ LANGUAGE plpgsql;

