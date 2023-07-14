#!/bin/bash

# Connect to the PostgreSQL instance using DATABASE_URL
psql "$DATABASE_URL" <<EOF
\set ON_ERROR_STOP

-- Run app.sql script
\i app.sql

-- Import data from app.csv
\copy people(survived,"passengerClass",name,sex,age,"siblingsOrSpousesAboard","parentsOrChildrenAboard",fare)
FROM './app.csv'
DELIMITER ','
CSV HEADER;

EOF