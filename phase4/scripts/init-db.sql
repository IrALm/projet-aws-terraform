-- Schéma de la table attendue par l'application (identique à celui de la phase 1).
-- Utilisé par migrate-data.sh --init quand aucune VM de phase 1 n'est disponible.
-- Idempotent : peut être rejoué sans erreur ni perte de données.
CREATE DATABASE IF NOT EXISTS STUDENTS;
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
