CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
SELECT uuid_generate_v4();

CREATE TABLE people (
  uuid uuid DEFAULT uuid_generate_v4 (),
  survived INT NOT NULL,
  "passengerClass" INT NOT NULL,
  name VARCHAR(255) NOT NULL,
  sex VARCHAR(255) NOT NULL,
  age REAL NOT NULL,
  "siblingsOrSpousesAboard" INT NOT NULL,
  "parentsOrChildrenAboard" INT NOT NULL,
  fare REAL NOT NULL
);

COPY people(survived,"passengerClass",name,sex,age,"siblingsOrSpousesAboard","parentsOrChildrenAboard",fare)
FROM '/docker-entrypoint-initdb.d/titanic_app.csv'
DELIMITER ','
CSV HEADER;
