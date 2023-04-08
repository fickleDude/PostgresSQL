--1--
/*Создаем INSTEAD OF триггер для обновления объема 
поставок в таблице export через представление export_v:*/
CREATE VIEW export_v AS
    SELECT country.name as country, natural_resource.name as natural_resource, export.supply, export.income
    FROM export
	JOIN natural_resource on natural_resource_id = natural_resource.id
	JOIN country on country_id = country.id;
	
CREATE OR REPLACE FUNCTION export_v_update_supply() RETURNS trigger
AS $$
DECLARE
    natural_resource_var int;
	country_var int;
BEGIN
	IF (NEW.supply < 0) THEN
		RAISE EXCEPTION 'supply cannot be negative';
		RETURN NULL;
	END IF;
	
	SELECT id INTO natural_resource_var
	FROM natural_resource
	WHERE name = OLD.natural_resource;
	
	SELECT id INTO country_var
	FROM country
	WHERE name = OLD.country;
	
    UPDATE export
    SET supply = NEW.supply
    WHERE natural_resource_id = natural_resource_var
	and country_id = country_var;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER export_v_upd_supply_trigger
INSTEAD OF UPDATE ON export_v
FOR EACH ROW EXECUTE FUNCTION export_v_update_supply();

--2--
/*Создаем вспомагательную таблицу и AFTER триггер 
для ведения аудита по таблице export:*/
CREATE TABLE export_history(LIKE export);
ALTER TABLE export_history
    ADD alter_date timestamp,
    ADD operation text;

CREATE OR REPLACE FUNCTION export_audit() RETURNS trigger
AS $$
    BEGIN
        IF (TG_OP = 'DELETE') THEN
            INSERT INTO export_history SELECT OLD.*, now(), 'DELETE';
            RETURN OLD;
        ELSIF (TG_OP = 'UPDATE') THEN
            INSERT INTO export_history SELECT NEW.*, now(),'UPDATE';
            RETURN NEW;
        ELSIF (TG_OP = 'INSERT') THEN
            INSERT INTO export_history SELECT NEW.*, now(),'INSERT';
            RETURN NEW;
        END IF;
        RETURN NULL; -- возвращаемое значение для триггера AFTER игнорируется
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER export_audit
AFTER INSERT OR UPDATE OR DELETE ON export
    FOR EACH ROW EXECUTE PROCEDURE export_audit();

