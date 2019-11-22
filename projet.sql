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
	nb_tickets_vendus INTEGER NOT NULL DEFAULT 0, -- <==== NE PAS OUBLIER lors de l'insert : nb_tickets_disponibles = projet.salles(capacite)
	nb_concerts INTEGER NOT NULL DEFAULT 0,

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
	email VARCHAR(100) UNIQUE NOT NULL CHECK(email VARCHAR(100) UNIQUE NOT NULL CHECK(email SIMILAR TO '[0-9a-zA-Z.#éèà%+]@[0-9a-zA-Z.#éèà%+].[0-9a-zA-Z.#éèà%+]'),
	nom_utilisateur VARCHAR(100) UNIQUE NOT NULL CHECK(nom_utilisateur <> ''),
	mot_de_passe VARCHAR(100) NOT NULL CHECK(mot_de_passe <> ''),
	sel VARCHAR(255) NOT NULL
);

CREATE TABLE projet.reservation_tickets(
	id_reservation SERIAL,
	id_evenement INTEGER NOT NULL REFERENCES projet.evenements(id_evenement),
	id_client INTEGER NOT NULL REFERENCES projet.clients(id_client),
	nb_tickets_reserves INTEGER NOT NULL CHECK (nb_tickets_reserves BETWEEN 1 AND 4), -- PAS  SUFFISANT VERIFIER EN +
	PRIMARY KEY(id_evenement, id_reservation)
);

#TRIGGERS

CREATE OR REPLACE FUNCTION projet.trigger_reservation () RETURNS TRIGGER AS $$
DECLARE
	record RECORD;
BEGIN
	#Si le client a déjà réservé des tickets pour un autre événement se déroulant à la même date.
	IF EXISTS(SELECT * FROM projet.reservations r, projet.evenements e
			WHERE r.id_evenement = e.id_evenement)
		RAISE 'client a deja reserve pour un evenement a la meme date';
	END IF;

	#Si le nombre de tickets demandés est plus grand que le nombre de tickets encore disponibles pour cet événement
	IF (NEW.nb_tickets > (SELECT SUM(r.nb_tickets) - s.capacite FROM projet.reservations r, projet.evenements e, projet.salles s
				WHERE r.id_evenement = e.id_evenement AND e.id_salle = s.id_salle))
		RAISE 'pas assez de clients disponibles';
	ENF IF;

	#Si le nombre total de tickets réservés par le cilent pour l'événement est supérieur à 4
	IF (NEW.nb_tickets + (SELECT SUM(r.nb_tickets) FROM projet.reservations r
			WHERE r.id_evenement = NEW.id_evenement) > 4)
		RAISE 'trop de tickets';
	END IF;

	#Si l'événement ne contient pas encore de concert (événement pas finalisé)
	IF NOT EXISTS(SELECT * FROM projet.concerts c, reservations r
			WHERE r.id_evenement = c.id_evenement)
		RAISE 'cet evenement n'a pas encore de concert';
	END IF;

	#Si l'événement est déjà passé
	IF (NOW() > (SELECT e.date FROM projet.evenements WHERE e.id_evenement = NEW.id_evenement))
		RAISE 'evenement deja passe';
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_reservation AFTER INSERT ON projet.reservations
	FOR EACH ROW EXECUTE PROCEDURE; //TODO