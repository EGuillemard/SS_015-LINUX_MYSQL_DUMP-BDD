# SS_015-LINUX_MYSQL_DUMP-BDD
Generic Project to backup SQL databases on MySQL/MariaDB engin.

Please in links with more detail on https://erwanguillemard.com/projet-dump-sql (only french version at this moment).

Editez le script et modifier les constantes ci-dessous :
    _mailTo............: préciser l'adresse qui va recevoir les rapports de dump deux fois par jour.
    _pathBDDRepository.: préciser le répertoire racine créé précédemment  qui va contenir nos sauvegardes /mnt/backup.
    _nbRetention.......: Le nombre de point que vous avez définit dans notre formule. Vous pouvez l'augmenter ce dernier ou le 
                          diminuer à votre guise. Tant que l'espace de stockage arrive à suivre, pas de problème.
    _dbName............: Le nom de la database dont nous voulons réaliser le dump.
    _dbUser............: Le compte SQL dédié uniquement à la réalisation des dumps.
    _dbPassword........: Le mot de passe du compte SQL ci-haut.

-------------------------------------------------------------------------------------------------------------------------------

Edit the script and change globals vars as below :
    _mailTo............: specify the mail address who will received the report.
    _pathBDDRepository.: specify the root repository who will contains database dumps.
    _nbRetention.......: Retention point define earlier in the article. Can be increase up or down in your case. Be aware to 
                         storage capacity to be enough free space.
    _dbName............: Database name than we want to backup.
    _dbUser............: SQL backup user dedied to the mysql dump thread.
    _dbPassword........: SQL backup password.
