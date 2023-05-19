---------------------------------------------- EVENEMENTS -----------------------------------------------------------------
--# Les �venements permettent de :
--# 	- Programmer des requ�tes de suppression pour d�lester de vieilles discussions pour votre forum.
--# 	- Calcul annuel dint�r�t.
--# 	- Programmer des requ�tes de sauvegarde automatiques chaque nuit.
--# 	- Diff�rer lex�cution dun traitement gourmand en ressources aux heures creuses de la prochaine nuit.
--# 	- Analyser et optimiser lensemble des tables mises � jour dans la journ�e
	
	
	SHOW GLOBAL VARIABLES LIKE 'event_scheduler'; --#  permet de voir si les �v�nements sont activ�s ou d�sactiv�s.
	SET GLOBAL event_scheduler = 1 ; --#  on affecte 1 dans une variable et cela permet d'activer les �v�nements sous Mysql.
	SHOW GLOBAL VARIABLES LIKE 'event_scheduler';
--# 	Attention, lorsque lon ferme la console et quon la rouvre, les �v�nements sont toujours d�sactiv�s /!\
--# 	Pour les activers de mani�re permanente il faut se rendre � lendroit suivant : 
--# 	wamp > mysql > services > my.ini : dans la section [mysqld]	il faut ajouter la ligne: event_scheduler=1.
--# 	Si on ferme la console, les �v�n�ments continue de faire leur travail. Si on ferme le serveur WAMP les �v�n�ments ne continue pas de faire leur travail (cela dis, les serveurs sont fais pour rester allum�s).
	---------------------------------------
		SHOW EVENTS \G $
--# 	Cet �v�nement permet dins�r� une ligne toute les minutes dans la table.
		DROP EVENT IF EXISTS enregistrement_employes $
		CREATE EVENT e_enregistrement_employes
		ON SCHEDULE  EVERY 1 MINUTE
		DO INSERT INTO employes (prenom) VALUES ('Ifocop');
--# 	Le mot clef EVERY indique que l�v�nement est r�current. Il est suivi par lintervalle entre chaque r�p�tition.
	---------------------------------------
--# 	Cet �v�nement ins�rera 1 enregistrement (unique) dans 2 minute
		CREATE EVENT EXEMPLE_1_2
		ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 2 MINUTE
		DO INSERT INTO ARTICLE.DECLENCHEUR (INFORMATION_DECLENCHEUR) VALUES ('Exemple 1.2');
--# 	Le mot clef AT signifie que l�v�nement est � ex�cution unique. Il est suivi par la date et lheure de d�clenchement. Apr�s la date de d�clenchement, l�v�nement est automatiquement supprim�. 
	---------------------------------------
--# 	Lancer (une seule fois) une PROC�DURE STOCK�E � 03h50 du 1er janvier 2010
		CREATE EVENT EXEMPLE_1_3
		ON SCHEDULE AT '2010-01-01 03:50:00'
		DO CALL INSERTION('Exemple 1.3');
		SHOW EVENTS WHERE NAME='EXEMPLE_1_3'\G
--# 	Cet exemple na pas pris en compte le d�calage horaire avec GMT ! 
	---------------------------------------
--# 	Ins�rer une ligne dans la table DECLENCHEUR chaque jour � 04h00 du matin.
		CREATE EVENT EXEMPLE_1_4_a
		ON SCHEDULE EVERY 1 DAY STARTS '2016-06-12 04:00:00'
		DO INSERT INTO ARTICLE.DECLENCHEUR (INFORMATION_DECLENCHEUR) VALUES ('Exemple 1.4.a');
--# 	Le mot clef STARTS permet dindiquer quand l�v�nement est d�clench� pour la premi�re fois. Il est donc suivi par la date de la premi�re ex�cution. 
	---------------------------------------
--# 	Pendant une minute, ins�rer une ligne dans la table DECLENCHEUR toutes les 8 secondes.
		CREATE EVENT EXEMPLE_1_5
		ON SCHEDULE  EVERY 8 SECOND
		ENDS CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
		DO INSERT INTO ARTICLE.DECLENCHEUR (INFORMATION_DECLENCHEUR)
		VALUES ('Exemple 1.5');
--# 	Le mot clef ENDS permet dindiquer quand l�v�nement est d�clench� pour la derni�re fois. Il est donc suivi par la date de derni�re ex�cution. Il pourra �tre automatiquement supprim� apr�s la derni�re ex�cution. 
	---------------------------------------
--# 	Permet de renommer un �vent :
		ALTER EVENT EXEMPLE_1_5 RENAME TO NOUVEAU_EXEMPLE_1_5;
--# 	Modifiez la fr�quence dun �vent existant :
		ALTER EVENT EXEMPLE_1_1 ON SCHEDULE EVERY 10 MINUTE;
--# 	Suppression dun �vent : 
		DROP EVENT IF EXISTS EXEMPLE_1_1;
--# 	Desactiver un �vent :
		ALTER EVENT nom_evenement DISABLE;
--# 	Activer un �vent (sous reserve que le gestionaire d�venement soit activ�) :
		ALTER EVENT nom_evenement ENABLE;
--# 	Controler l�tat dun �vent :
		SELECT EVENT_NAME, STATUS FROM INFORMATION_SCHEMA.EVENTS; ou SHOW events;
		SELECT EVENT_NAME, STATUS FROM INFORMATION_SCHEMA.EVENTS WHERE EVENT_NAME = 'EXEMPLE_1_2' AND EVENT_SCHEMA = 'article'; --#  nous navons pas mis de USE car on a pr�ciser le nom de la BDD avant le nom de la table.
	 
	 
--# 	 Cr�ation dune BDD (tic_evenements) et dune table journal avec les champs suivants : id_journal, titre, texte.
--# 	 Insertion denregistrement.
	 
--# 	 Permet deffectuer une copie dans la table de sauvegarde.
		delimiter -
		CREATE EVENT journal_sauvegarde
			ON SCHEDULE EVERY 1 MINUTE
			DO INSERT INTO journal_copie SELECT * FROM journal; -
		--------------------------------------- 
--# 		Exemple � pr�senter:
--# 		>>> Exemple permettant de faire une sauvegarde de la table � chaque minute en cr�ant une table de copie � partir dune autre (chaque jour � partir dune date de d�part donn�e) :
		DELIMITER $$
		DROP procedure IF EXISTS p_sauvegarde_employes $$
		CREATE procedure p_sauvegarde_employes()
		BEGIN
			SET @sql=concat('CREATE table copie_employes_' ,curdate()+0, '    SELECT * FROM employes'); --#  Attention lespace avant le S de SELECT est capital. # curdate()+0 ou round(now()+0).
			PREPARE req FROM @sql ;
			EXECUTE req ;
			-- DEALLOCATE PREPARE req ; --# cette ligne n'est pas obligatoire.
		END $$
		DELIMITER ;
		
		DELIMITER $$
		DROP procedure IF EXISTS p_sauvegarde_employes $$
		CREATE procedure p_sauvegarde_employes()
		BEGIN
			CREATE table copie_employes(SELECT * FROM employes);
		END $$
--# 		### Tenter dex�cuter la proc�dure stock�e avant de cr�er levent. Si la table copie est cr�e, cela fonctionne, mais il faut maintenant la supprimer afin de laisser levent travailler. Possibilit� de mettre ROUND(now()+0) dans la procedure avec un every 1 minute dans levent pour tester cela plusieurs fois.
		
		DROP event IF EXISTS e_sauvegarde_employes;		
		CREATE EVENT e_sauvegarde_employes
			ON SCHEDULE EVERY 1 DAY STARTS '2012-11-01 15:10:00' --#  il faut adapter la date et lheure afin davoir le r�sultat en salle de cours dans linstant.
			DO CALL p_sauvegarde_employes();	
			
			SHOW TABLES $
			SELECT NOW() $
---------------------------------------------- FIN EVENEMENTS -----------------------------------------------------------------