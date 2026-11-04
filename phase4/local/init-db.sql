-- Base locale de test (docker compose uniquement), même schéma que les phases 1 à 3.
-- La base STUDENTS et l'utilisateur sont créés par l'image mysql (variables MYSQL_*).
USE STUDENTS;

CREATE TABLE IF NOT EXISTS students (
  id      INT NOT NULL AUTO_INCREMENT,
  name    VARCHAR(255) NOT NULL,
  address VARCHAR(255) NOT NULL,
  city    VARCHAR(255) NOT NULL,
  state   VARCHAR(255) NOT NULL,
  email   VARCHAR(255) NOT NULL,
  phone   VARCHAR(100) NOT NULL,
  PRIMARY KEY (id)
);

INSERT INTO students (name, address, city, state, email, phone) VALUES
  ('Alice Martin', '1 rue de l Universite', 'Paris', 'IDF', 'alice.martin@exemple.edu', '0102030405'),
  ('Bruno Diallo', '1 rue de l Universite', 'Paris', 'IDF', 'bruno.diallo@exemple.edu', '0102030405');
