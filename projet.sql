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
	nb_tickets_vendus INTEGER NOT NULL DEFAULT 0 CHECK (nb_tickets_vendus >= 0), 
	nb_concerts INTEGER NOT NULL DEFAULT 0 CHECK (nb_concerts >= 0),

	UNIQUE(date_evenement, id_salle)
);

CREATE TABLE projet.artistes(
	id_artiste SERIAL PRIMARY KEY,
	nom VARCHAR(100) NOT NULL CHECK(nom<>''),
	nationalite VARCHAR(100) NULL CHECK(nationalite<>''),
	nb_tickets_reserves INTEGER NOT NULL DEFAULT 0 CHECK(nb_tickets_reserves >= 0)
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
	nb_tickets_reserves INTEGER NOT NULL DEFAULT 0 CHECK(nb_tickets_reserves >= 0), 
	prix_total NUMERIC (8, 2) NULL CHECK(prix_total > 0),
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
     INSERT INTO projet.reservations VALUES (DEFAULT, no_evenement, no_client, tickets_reserves, NULL) 
	 RETURNING id_reservation INTO no_reservation;
     
     RETURN no_reservation;
END ; 
$$ LANGUAGE plpgsql;




----TRIGGERS---------------------------------------------------------------------


-- Un artiste ne peut pas participer à 2 évènements qui se déroulent le même jour
CREATE OR REPLACE FUNCTION projet.verifier_evenements_meme_jour() RETURNS TRIGGER   
AS $$ 
DECLARE 
      date projet.evenements.date_evenement%TYPE;
BEGIN 
     -- La date de l'évènement pour laquelle on ajoute le concert (NEW)
	 SELECT date_evenement FROM projet.evenements WHERE id_evenement = NEW.id_evenement INTO date;

	 -- Tous les autres evenements à la meme date (que celle d'ajout) de cet artiste
	 IF EXISTS (SELECT EV.id_evenement 
					FROM projet.evenements EV, projet.concerts CO 
					WHERE EV.id_evenement = CO.id_evenement
	 				AND EV.date_evenement = date AND EV.id_evenement != NEW.id_evenement
	 				AND CO.id_artiste = NEW.id_artiste) THEN
        RAISE EXCEPTION 'Attention, un artiste ne peut pas participer à 2 évènements qui se déroulent le même jour.';
	 END IF;
	 
     RETURN NEW; 
END; 
$$ LANGUAGE plpgsql; 

CREATE TRIGGER trigger_verifier_evenements_meme_jour 
BEFORE INSERT ON projet.concerts 
FOR EACH ROW  
EXECUTE PROCEDURE projet.verifier_evenements_meme_jour(); 


-- Incrémenter le nombre de concerts d'un évènement
CREATE OR REPLACE FUNCTION projet.incrementer_nb_concerts() RETURNS TRIGGER   
AS $$ 
DECLARE 
       ancien_nb_concerts projet.evenements.nb_concerts%TYPE;
BEGIN 
      SELECT nb_concerts FROM projet.evenements WHERE id_evenement = NEW.id_evenement INTO ancien_nb_concerts;
	  ancien_nb_concerts := ancien_nb_concerts + 1;
	  UPDATE projet.evenements SET nb_concerts = ancien_nb_concerts WHERE id_evenement = NEW.id_evenement;

      RETURN NEW; 
END; 
$$ LANGUAGE plpgsql; 

CREATE TRIGGER trigger_incrementer_nb_concerts 
AFTER INSERT ON projet.concerts 
FOR EACH ROW  
EXECUTE PROCEDURE projet.incrementer_nb_concerts(); 


-- Incrémenter le nombre de tickets réservés d'un artiste
CREATE OR REPLACE FUNCTION projet.incrementer_nb_tickets_reserves_artiste() RETURNS TRIGGER   
AS $$ 
DECLARE 
       record RECORD;
       ancien_nb_tickets_reserves projet.artistes.nb_tickets_reserves%TYPE;
	   nouveau_nb_tickets_reserves projet.artistes.nb_tickets_reserves%TYPE;
	   ancien_nb_tickets_vendus projet.evenements.nb_tickets_vendus%TYPE;
	   nouveau_nb_tickets_vendus projet.evenements.nb_tickets_vendus%TYPE;
BEGIN 
     -- mettre a jour aristes.nb_tickets_reserves
     FOR record IN SELECT DISTINCT AR.id_artiste, AR.nb_tickets_reserves FROM projet.artistes AR, projet.concerts CO
	 			   WHERE AR.id_artiste = CO.id_artiste
	 			   AND CO.id_evenement = NEW.id_evenement 
	 LOOP
	     nouveau_nb_tickets_reserves := record.nb_tickets_reserves + NEW.nb_tickets_reserves;
	 	 UPDATE projet.artistes SET nb_tickets_reserves = nouveau_nb_tickets_reserves WHERE id_artiste = record.id_artiste;
     END LOOP;
	 
	 -- mettre a jour concerts.nb_tickets_vendus
	 SELECT nb_tickets_vendus FROM projet.evenements WHERE id_evenement = NEW.id_evenement INTO ancien_nb_tickets_vendus;
	 nouveau_nb_tickets_vendus := ancien_nb_tickets_vendus + NEW.nb_tickets_reserves;
	 UPDATE projet.evenements SET nb_tickets_vendus = nouveau_nb_tickets_vendus WHERE id_evenement = NEW.id_evenement;
	 
	 
	 
     RETURN NEW; 
END; 
$$ LANGUAGE plpgsql; 

CREATE TRIGGER trigger_incrementer_nb_tickets_reserves_artiste
AFTER INSERT ON projet.reservations 
FOR EACH ROW  
EXECUTE PROCEDURE projet.incrementer_nb_tickets_reserves_artiste(); 



CREATE OR REPLACE FUNCTION projet.before_reservation() RETURNS TRIGGER   
AS $$ 
DECLARE 
       nb_tickets_deja_reserves projet.reservations.nb_tickets_reserves%TYPE;
	   date projet.evenements.date_evenement%TYPE;
	   capacite_salle projet.salles.capacite%TYPE;
	   nb_tickets_vendus_evenement projet.evenements.nb_tickets_vendus%TYPE;
	   
BEGIN 	 
	 -- -	Vérifier que l’ajout d’une réservation sur un évenement qui n’a pas de concert est impossible. 
	 IF (SELECT nb_concerts FROM projet.evenements WHERE id_evenement = NEW.id_evenement) = 0 THEN
	 	 RAISE EXCEPTION 'Attention, l’ajout d’une réservation sur un évenement qui n’a pas de concert est impossible.';
	 END IF;
	 	 
	 -- Nombre de tickets déjà réservés pour le même évènement
	 SELECT SUM(nb_tickets_reserves) FROM projet.reservations WHERE id_evenement = NEW.id_evenement 
	 AND id_client = NEW.id_client AND id_reservation != NEW.id_reservation INTO nb_tickets_deja_reserves;
	 	
	 -- Nombre de tickets réservés jusqu'a présent + ceux souhaités est compris entre [1,4]	
	 IF (nb_tickets_deja_reserves + NEW.nb_tickets_reserves) BETWEEN 1 AND 4 THEN
	 	RAISE EXCEPTION 'Attention,  pour éviter la revente illégale de tickets, il est impossible de réserver plus de
		4 tickets par personne par évènement. Rappel, 1 ticket minimum par réservation.';
	 END IF;
	 
     -- Date de l'evenement de la réservation souhaitée	
	 SELECT date_evenement FROM projet.evenements WHERE id_evenement = NEW.id_evenement INTO date;
	 
	 -- Vérifier si la personne a déjà réservé des tickets pour un autre évènement à la même date
	 IF EXISTS (SELECT * FROM projet.reservations RE, projet.evenements EV 
				WHERE RE.id_evenement = EV.id_evenement
			    AND RE.id_client = NEW.id_client 
				AND EV.date_evenement = date) THEN
	 	RAISE EXCEPTION 'Attention, vous avez déjà reservé des tickets pour un autre évènement se déroulant à la même date.';
	 END IF;
	 
	 
	 SELECT SA.capacite, EV.nb_tickets_vendus FROM projet.salles SA, projet.evenements EV
	 WHERE SA.id_salle = EV.id_salle AND EV.id_evenement = NEW.id_evenement INTO capacite_salle, nb_tickets_vendus_evenement;
	 
	 IF (nb_tickets_vendus_evenement + NEW.nb_tickets_reserves) > capacite_salle THEN
	 	RAISE EXCEPTION 'Attention, le nombre de tickets demandés est plus grand que le nombre de tickets encore disponibles pour cet événement.';
	 END IF;
	 
	 --Si l'événement est déjà passé
	 IF (NOW() > (SELECT date_evenement FROM projet.evenements WHERE id_evenement = NEW.id_evenement)) THEN
		RAISE EXCEPTION 'Attention, l''évènement est déjà passé.';
	 END IF;
	 
	 -- Pré-calculer le prix total d'une réservation
     SELECT NEW.nb_tickets_reserves * prix FROM projet.evenements WHERE id_evenement = NEW.id_evenement INTO NEW.prix_total;
	 
     RETURN NEW; 
END; 
$$ LANGUAGE plpgsql; 

CREATE TRIGGER trigger_before_reservation
BEFORE INSERT ON projet.reservations 
FOR EACH ROW  
EXECUTE PROCEDURE projet.before_reservation(); 









SELECT projet.ajouter_festival('BRUSSELS SUMMER FESTIVAL') AS id_festival_1;
SELECT projet.ajouter_salle('SALLE 001', 'Bruxelles', 3) AS id_salle_1;
SELECT projet.ajouter_salle('SALLE 002', 'Forest', 20000) AS id_salle_2;

SELECT projet.ajouter_evenement('ANGELE EN FOLIE', '2019-12-27', 60, NULL, 1) AS id_evenement_1;
SELECT projet.ajouter_evenement('NRJ MUSIC AWARDS', '2019-12-26', 60, NULL, 2) AS id_evenement_2;
SELECT projet.ajouter_evenement('LES ENFOIRES', '2019-12-22', 50, NULL, 2) AS id_evenement_3;


SELECT projet.ajouter_artiste('Angele', NULL) AS id_artiste_1;
SELECT projet.ajouter_artiste('Romeo', NULL) AS id_artiste_2;

SELECT projet.ajouter_concert('17:00:00', 1, 1) AS id_concert_1; -- (id_evenement, id_artiste)
SELECT projet.ajouter_concert('18:00:00', 1, 2) AS id_concert_2;
--SELECT projet.ajouter_concert('22:00:00', 2, 2) AS id_concert_3;

SELECT projet.ajouter_client('floriansollami@hotmail.fr', 'fsollam15', 'azerty', 'sel') AS id_client_1;
SELECT projet.ajouter_client('jacq@hotmail.fr', 'jacq15', 'azerty', 'sel') AS id_client_2;

SELECT projet.ajouter_reservation(1, 1, 3) AS id_reservation_1; -- (id_evenement, id_client, nb_tickets)
--SELECT projet.ajouter_reservation(2, 1, 2) AS id_reservation_2;
--SELECT projet.ajouter_reservation(1, 2, 4) AS id_reservation_3;
