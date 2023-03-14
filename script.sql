DROP VIEW IF EXISTS cities_distinct CASCADE;
DROP TABLE IF EXISTS users_temp, contries, states, users, cities, airport_temp, airports, companies;

CREATE TEMPORARY TABLE users_temp (
  gender TEXT,
  givenname TEXT,
  surname TEXT ,
  streetaddress TEXT ,
  city TEXT ,
  state TEXT ,
  statefull TEXT ,
  zipcode TEXT ,
  countryfull TEXT ,
  telephonenumber TEXT ,
  telephonecountrycode int,
  birthday TEXT,
  age int NOT NULL,
  tropicalzodiac TEXT,
  occupation TEXT,
  company TEXT,
  vehicle TEXT ,
  bloodtype TEXT,
  kilograms NUMERIC,
  centimeters NUMERIC
);

CREATE TABLE contries(
  id   SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL
);

CREATE TABLE states(
  id        SERIAL PRIMARY KEY,
  uf        VARCHAR(2) NOT NULL,
  name      VARCHAR(255) NOT NULL,
  contry_id INTEGER,
  FOREIGN KEY(contry_id) REFERENCES contries(id)
);


CREATE TABLE cities(
  id SERIAL PRIMARY KEY,
  name      VARCHAR(255),
  zipcode   VARCHAR(255),
  state_id  INTEGER,
  FOREIGN KEY(state_id) REFERENCES states(id)
);

CREATE TABLE companies(
  ID SERIAL PRIMARY KEY,
  name VARCHAR(255)
);

CREATE TABLE users(
  id          SERIAL       PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  lastname    VARCHAR(255) NOT NULL,
  age         INT          NOT NULL,
  birthday    VARCHAR(255) NOT NULL,
  kilograms   NUMERIC      NOT NULL,
  city_id     INTEGER,
  company_id  INTEGER,
  FOREIGN KEY(city_id) REFERENCES cities(id),
  FOREIGN KEY(company_id) REFERENCES companies(id)
);


COPY users_temp   FROM 'D:\fakenames.csv' DELIMITER ',' CSV HEADER;

--- inset date for contries using select
INSERT INTO contries(name)
SELECT
  DISTINCT countryfull as name 
FROM users_temp;

--- INSERT DATA FOR STATES USING SELECT 
INSERT INTO states(uf, name, contry_id)
SELECT DISTINCT state as uf, statefull as name,(
  SELECT id as contry_id FROM contries where name = 'Brazil'
)
FROM users_temp;


INSERT INTO companies(name)
SELECT
 DISTINCT company
FROM users_temp;

CREATE VIEW cities_distinct AS
	SELECT DISTINCT city as name, zipcode, state as uf 
	FROM users_temp;


INSERT INTO cities(name, zipcode, state_id)
SELECT cities_distinct.name, cities_distinct.zipcode, (
	SELECT id AS state_id FROM states WHERE uf = cities_distinct.uf
) FROM cities_distinct;


DELETE FROM cities
WHERE id IN 
(SELECT id
    FROM 
        (SELECT id,
         ROW_NUMBER() OVER( PARTITION BY name
        ORDER BY id, name ) AS row_num
        FROM cities ) t
        WHERE t.row_num > 1 );


--- INSERT DATA FOR USERS USING SELECT 
INSERT INTO users(name, lastname, age, birthday, kilograms, city_id, company_id)
SELECT
  givenname as name,
  surname as lastname,
  age,
  birthday,
  kilograms,
  (
    SELECT id as city_id FROM cities where cities.name = users_temp.city
  ),
  (
    SELECT id as company_id FROM companies where companies.name = users_temp.company
  )
FROM users_temp;
