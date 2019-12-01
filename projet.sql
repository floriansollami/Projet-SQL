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
	email VARCHAR(100) UNIQUE NOT NULL CHECK(email SIMILAR TO '[0-9a-zA-Z]*(.[0-9a-zA-Z]*)*@[0-9a-zA-Z]*(.[0-9a-zA-Z]*)*'),
	nom_utilisateur VARCHAR(100) UNIQUE NOT NULL CHECK(nom_utilisateur <> ''),
	mot_de_passe VARCHAR(100) NOT NULL CHECK(mot_de_passe <> ''),
	sel VARCHAR(255) NOT NULL
);

CREATE TABLE projet.reservations(
	id_reservation SERIAL,
	id_evenement INTEGER NOT NULL REFERENCES projet.evenements(id_evenement),
	id_client INTEGER NOT NULL REFERENCES projet.clients(id_client),
	nb_tickets_reserves INTEGER NOT NULL DEFAULT 0 CHECK (nb_tickets_reserves BETWEEN 1 AND 4), -- PAS  SUFFISANT VERIFIER EN +
	PRIMARY KEY(id_evenement, id_reservation)
);

----------------------------------------------------------------------------------------------------------------------------------------


-- AJOUTER FESTIVAL
CREATE OR REPLACE FUNCTION projet.ajouter_festival(projet.festivals.nom%TYPE) 
RETURNS projet.festivals.id_festival%TYPE 
AS $$
DECLARE 
       nom_festival ALIAS FOR $1;
			 
       no_festival INTEGER; 
BEGIN
     INSERT INTO projet.festivals VALUES (DEFAULT, nom_festival) RETURNING id_festival INTO no_festival;
     
     RETURN no_festival;
END ; 
$$ LANGUAGE plpgsql;


-- AJOUTER SALLE
CREATE OR REPLACE FUNCTION projet.ajouter_salle(
	projet.salles.nom%TYPE,
	projet.salles.ville%TYPE,
	projet.salles.capacite%TYPE
) 
RETURNS projet.salles.id_salle%TYPE 
AS $$
DECLARE 
       nom_salle ALIAS FOR $1;
	     ville_salle ALIAS FOR $2;
	     capacite_salle ALIAS FOR $3;
			 
       no_salle INTEGER; 
BEGIN
     INSERT INTO projet.salles VALUES (DEFAULT, nom_salle, ville_salle, capacite_salle) RETURNING id_salle INTO no_salle;
     
     RETURN no_salle;
END ; 
$$ LANGUAGE plpgsql;

-- AJOUTER EVENEMENT 
CREATE OR REPLACE FUNCTION projet.ajouter_evenement(
	projet.evenements.nom%TYPE, 
	projet.evenements.date_evenement%TYPE,
	projet.evenements.prix%TYPE,
	projet.evenements.id_festival%TYPE,
	projet.evenements.id_salle%TYPE
) 

RETURNS projet.evenements.id_evenement%TYPE 
AS $$
DECLARE 
       nom_evenement ALIAS FOR $1;
       date ALIAS FOR $2;
			 prix_evenement ALIAS FOR $3;
	     no_festival ALIAS FOR $4;
	     no_salle ALIAS FOR $5;
			 
       no_evenement INTEGER; 
BEGIN
     INSERT INTO projet.evenements 
		 VALUES (DEFAULT, nom_evenement, date, prix_evenement, no_festival, no_salle, DEFAULT, DEFAULT) 
	   RETURNING id_evenement INTO no_evenement;
     
     RETURN no_evenement;
END ; 
$$ LANGUAGE plpgsql;


-- AJOUTER ARTISTE
CREATE OR REPLACE FUNCTION projet.ajouter_artiste(projet.artistes.nom%TYPE, projet.artistes.nationalite%TYPE) 
RETURNS projet.artistes.id_artiste%TYPE 
AS $$
DECLARE 
       nom_artiste ALIAS FOR $1;
       nationalite_artiste ALIAS FOR $2;
			 
       no_artiste INTEGER; 
BEGIN
     INSERT INTO projet.artistes VALUES (DEFAULT, nom_artiste, nationalite_artiste, DEFAULT) RETURNING id_artiste INTO no_artiste;

     RETURN no_artiste;
END ; 
$$ LANGUAGE plpgsql;


-- AJOUTER CONCERT
CREATE OR REPLACE FUNCTION projet.ajouter_concert(
	projet.concerts.heure_debut%TYPE, 
	projet.concerts.id_evenement%TYPE,
	projet.concerts.id_artiste%TYPE
	) 
RETURNS projet.concerts.id_concert%TYPE 
AS $$
DECLARE 
       heure_debut_concert ALIAS FOR $1;
       no_evenement ALIAS FOR $2;
	     no_artiste ALIAS FOR $3;

       no_concert INTEGER; 
BEGIN
     INSERT INTO projet.concerts VALUES (DEFAULT, heure_debut_concert, no_evenement, no_artiste) 
	   RETURNING id_concert INTO no_concert;
     
     RETURN no_concert;
END ; 
$$ LANGUAGE plpgsql;

-- AJOUTER CLIENT
CREATE OR REPLACE FUNCTION projet.ajouter_client(
	projet.clients.email%TYPE, 
	projet.clients.nom_utilisateur%TYPE,
	projet.clients.mot_de_passe%TYPE,
	projet.clients.sel%TYPE
) 
RETURNS projet.clients.id_client%TYPE 
AS $$
DECLARE 
       email_client ALIAS FOR $1;
       nom_utilisateur_client ALIAS FOR $2;
	     mot_de_passe_client ALIAS FOR $3;
	     sel_client ALIAS FOR $4;

       no_client INTEGER; 
BEGIN
     INSERT INTO projet.clients VALUES (DEFAULT, email_client, nom_utilisateur_client, mot_de_passe_client, sel_client) 
	   RETURNING id_client INTO no_client;
     
     RETURN no_client;
END ; 
$$ LANGUAGE plpgsql;

-- AJOUTER RESERVATION
CREATE OR REPLACE FUNCTION projet.ajouter_reservation(
	projet.reservations.id_evenement%TYPE, 
	projet.reservations.id_client%TYPE,
	projet.reservations.nb_tickets_reserves%TYPE
) 
RETURNS projet.reservations.id_reservation%TYPE 
AS $$
DECLARE 
       no_evenement ALIAS FOR $1;
       no_client ALIAS FOR $2;
			 tickets_reserves ALIAS FOR $3;

       no_reservation INTEGER; 
BEGIN
     INSERT INTO projet.reservations VALUES (DEFAULT, no_evenement, no_client, tickets_reserves) 
	   RETURNING id_reservation INTO no_reservation;
     
     RETURN no_reservation;
END ; 
$$ LANGUAGE plpgsql;



SELECT projet.ajouter_festival('BRUSSELS SUMMER FESTIVAL') AS id_festival;
SELECT projet.ajouter_salle('SALLE 001', 'Bruxelles', 25000) AS id_salle;
SELECT projet.ajouter_evenement('ANGELE EN FOLIE', '2019-12-28', 60, NULL, 1) AS id_evenement;
SELECT projet.ajouter_artiste('Angele', NULL) AS id_artiste;
SELECT projet.ajouter_concert('17:00:00', 1, 1) AS id_concert;
SELECT projet.ajouter_client('floriansollami@hotmail.fr', 'fsollam15', 'azerty', 'sel') AS id_client;
SELECT projet.ajouter_reservation(1, 1, 2) AS id_reservation;


--Visualiser la liste  des artistes triés par nombre de tickets réservés
CREATE OR REPLACE FUNCTION projet.visualiser_artistes () RETURNS INTEGER AS $$
DECLARE 
BEGIN
	SELECT *
	FROM projet.artistes a
	ORDER BY a.nb_tickets_reserves
	RETURN 1;
END;
$$ LANGUAGE plpgsql;

--Afficher evenements entre 2 dates données
CREATE OR REPLACE FUNCTION projet.afficher_evenements (projet.evenements.date%TYPE, projet.evenements.date%TYPE) RETURNS INTEGER AS $$
DECLARE
	date_1 ALIAS FOR $1;
	date_2 ALIAS FOR $2;
BEGIN
	SELECT e.nom, e.date_evenement, s.nom, f.nom, e.nb_tickets_vendus
	FROM projet.evenements e LEFT OUTER JOIN festivals f ON e.id_festival = f.id_festival, salles s
	WHERE (e.date_evenement > date_1 AND e.date_evenement < date_2) AND s.id_salle = e.id_salle
	ORDER BY e.date_evenement ASC
	RETURN 1;
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------------
#TRIGGERS

CREATE OR REPLACE FUNCTION projet.trigger_reservation () RETURNS TRIGGER AS $$
DECLARE
	old_nb_tickets_evenements INTEGER;
	old_nb_tickets_artistes INTEGER;
	record RECORD;
BEGIN
	--Si le client a déjà réservé des tickets pour un autre événement se déroulant à la même date.
	IF EXISTS(SELECT * FROM projet.reservations r, projet.evenements e
			WHERE r.id_evenement = e.id_evenement)
		RAISE 'client a deja reserve pour un evenement a la meme date';
	END IF;

	--Si le nombre de tickets demandés est plus grand que le nombre de tickets encore disponibles pour cet événement
	IF (NEW.nb_tickets > (SELECT SUM(r.nb_tickets) - s.capacite FROM projet.reservations r, projet.evenements e, projet.salles s
				WHERE r.id_evenement = e.id_evenement AND e.id_salle = s.id_salle))
		RAISE 'pas assez de clients disponibles';
	ENF IF;

	--Si le nombre total de tickets réservés par le cilent pour événement est supérieur à 4
	IF (NEW.nb_tickets + (SELECT SUM(r.nb_tickets) FROM projet.reservations r
			WHERE r.id_evenement = NEW.id_evenement) > 4)
		RAISE 'trop de tickets';
	END IF;

	--Si événement ne contient pas encore de concert (événement pas finalisé)
	IF NOT EXISTS(SELECT * FROM projet.concerts c, reservations r
			WHERE r.id_evenement = c.id_evenement)
		RAISE 'cet evenement na pas encore de concert';
	END IF;

	--Si l'événement est déjà passé
	IF (NOW() > (SELECT e.date FROM projet.evenements WHERE e.id_evenement = NEW.id_evenement))
		RAISE 'evenement deja passe';
	END IF;

	--UPDATE du nombre de tickets reserves pour un événement
	old_nb_tickets_evenements:=(SELECT e.nb_tickets_vendus FROM projet.evenements e
					WHERE e.id_evenement = NEW.id_evenement)
	UPDATE(projet.evenements) SET nb_tickets_reserves = old_nb_tickets_evenements+NEW.nb_tickets_reserves WHERE id_evenement=NEW.id_evenement

	--UPDATE du nombre de tickets total pour un artiste
	old_nb_tickets_artistes:=(SELECT a.nb_tickets_reserves FROM projet.artistes a
					WHERE e.id_evenement = NEW.id_evenement)
	UPDATE(projet.evenements) SET nb_tickets_reserves = old_nb_tickets_artistes+NEW.nb_tickets_reserves WHERE id_evenement=NEW.id_evenement


END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER projet.trigger_reservation AFTER INSERT ON projet.reservations
	FOR EACH ROW EXECUTE PROCEDURE; //TODO
