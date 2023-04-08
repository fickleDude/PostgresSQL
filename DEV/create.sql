CREATE TABLE natural_resource (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  mineral_type TEXT,
  measurement TEXT,
  unit_price MONEY DEFAULT 0 
	CONSTRAINT "positive_unit_price" CHECK (unit_price >= 0::money)
);

CREATE TABLE transfer_point (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  staff INT DEFAULT 0,
  capacity BIGINT DEFAULT 0
);

CREATE TABLE reserve (
  id SERIAL PRIMARY KEY,
  transfer_point_id INT REFERENCES transfer_point ON DELETE CASCADE,
  natural_resource_id INT REFERENCES natural_resource ON DELETE CASCADE,
  deposit BIGINT DEFAULT 0,
  annual_extraction BIGINT DEFAULT 0,
  extract_method TEXT,
  unit_cost MONEY DEFAULT 0 
	CONSTRAINT "positive_unit_cost" CHECK (unit_cost >= 0::money),
	CONSTRAINT "unique_natural_resource_transfer_point" UNIQUE (natural_resource_id, transfer_point_id)
);

CREATE TABLE country (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL
);

CREATE TABLE export (
  natural_resource_id INT REFERENCES natural_resource ON DELETE CASCADE,
  country_id INT REFERENCES country ON DELETE CASCADE,
  supply BIGINT DEFAULT 0,
  income MONEY DEFAULT 0,
  PRIMARY KEY(natural_resource_id, country_id),
	CONSTRAINT "positive_income" CHECK (income >= 0::money)
);
