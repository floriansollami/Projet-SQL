DROP SCHEMA IF EXISTS projet CASCADE;
CREATE SCHEMA projet;

CREATE TABLE projet.festivals(
	id_festival SERIAL PRIMARY KEY,
	nom VARCHAR(100) NOT NULL CHECK(nom <> '')
);

CREATE TABLE projet.salles(
	id_salle SERIAL PRIMARY KEY,
	nom VARCHAR(100) NOT NULL CHECK(nom <> ''),
	ville VARCHAR(100) NOT NULL CHECK(ville <> ''),
	capacite INTEGER NOT NULL CHECK(capacite > 0)
);

CREATE TABLE projet.evenements(
	id_evenement SERIAL PRIMARY KEY,
	nom VARCHAR(100) NOT NULL CHECK(nom <> ''),
	date_evenement DATE NOT NULL DEFAULT now(),
	prix NUMERIC (8, 2) NOT NULL CHECK(prix > 0),
	id_festival INTEGER NULL REFERENCES projet.festivals(id_festival),
	id_salle INTEGER NOT NULL REFERENCES projet.salles(id_salle),
	
	nb_tickets_vendus INTEGER NOT NULL, -- <==== NE PAS OUBLIER lors de l'insert : nb_tickets_disponibles = projet.salles(capacite)
	-- A RAJOUTER nb_concerts INTEGER NULL
	UNIQUE(date_evenement, id_salle)
);


CREATE TABLE projet.artistes(
	id_artiste SERIAL PRIMARY KEY,
	nom VARCHAR(100) NOT NULL CHECK(nom<>''),
	nationalite VARCHAR(100) NULL CHECK(nationalite<>''),
	nb_tickets_reserves INTEGER NOT NULL DEFAULT 0 CHECK(nb_tickets_reserves>=0)
);

CREATE TABLE projet.concerts(
	id_concert SERIAL PRIMARY KEY,
	heure_debut TIME without time zone NOT NULL, 
	id_evenement INTEGER NOT NULL REFERENCES projet.evenements(id_evenement),
    id_artiste INTEGER NOT NULL REFERENCES projet.artistes(id_artiste),
	UNIQUE(id_evenement, heure_debut)
);

CREATE TABLE projet.clients(
	id_client SERIAL PRIMARY KEY,
	email VARCHAR(100) UNIQUE NOT NULL,
	nom_utilisateur VARCHAR(100) UNIQUE NOT NULL CHECK(nom_utilisateur <> ''),
	mot_de_passe VARCHAR(100) NOT NULL CHECK(mot_de_passe<>''),
	sel VARCHAR(255) NOT NULL
);

CREATE TABLE projet.reservation_tickets(
	id_reservation SERIAL,
	id_evenement INTEGER NOT NULL REFERENCES projet.evenements(id_evenement),
	id_client INTEGER NOT NULL REFERENCES projet.clients(id_client),
	nb_tickets_reserves INTEGER NOT NULL CHECK (nb_tickets_reserves BETWEEN 1 AND 4), -- PAS  SUFFISANT VERIFIER EN +
	PRIMARY KEY(id_evenement, id_reservation)
);
