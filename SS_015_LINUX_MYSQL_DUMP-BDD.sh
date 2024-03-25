#!/bin/bash
# =======================================================
# NAME: SS_015_E-LINUX_MYSQL_DUMP-BDD
# AUTHOR: GUILLEMARD, Erwan, PERSONNAL PROPRIETY
# DATE: 2020/09/22
#
# KEYWORDS: BDDITOP, MARIADB, MYSQL
# VERSION 1.5
# 2019/02/22 - 1.0 : Script creation
# 2019/03/06 - 1.1 : Add argument to realise n compressed backup and cleanup n backup repository
# 2020/09/22 - 1.2 : Add & develop sendMail function
# 2020/09/23 - 1.2.1 : Log Management on seven days retention
# 2024/03/09 - 1.5 : Review and release
#
# COMMENTS:
#
#Requires bash, mysqldump, mutt, msmtp, gunzip
# =======================================================
_modeHTML=true

_author="Erwan GUILLEMARD"
_version="1.5"
_dateRelease="2024-03-09"

_mailTo="xxxx.yyyy@zzz.com"

_pathLogRepository="/var/log/ERWAN"
_pathHTMLFile="/tmp/dumpHTMLTrace.html"
_pathTempFile="/tmp/dumpTrace.txt"
_pathLogFile="SS_015-LINUX_MYSQL_DUMP-BDD.log"
_pathBDDRepository="/mnt/backup"
_nbRetention=5
_dbName="bddName"
_dbUser="svc.backup"
_dbPassword="Password"

# =======================================================
#.SYNOPSIS
#   Function to Check Prerequis to launch the script
#.DESCRIPTION
#       Function checkPrerequis create LogRepository and dependencies repositories before to call dumpCreate function.
#       Work without arg.
#.PARAMETER
#       codeArg contain inside $1 specify special backup repository. On our case, must be MidDay or MidNight
#.EXAMPLE
#       checkPrerequis MidDay
#.INPUTS
#.OUTPUTS
#
#.NOTES
#       NAME:  LastRelease
#       AUTHOR: GUILLEMARD Erwan
#       LASTEDIT: 2024/03/09
#       VERSION:1.0.0 Function Create
#       1.0.0 Function create
#.LINK
#
# =======================================================
function checkPrerequis {
        echo "Start Prerequis Function" |& tee -a $_pathLogRepository/$_pathLogFile
        #Check if ERWAN repository exist under /var/log
        if [ -d $_pathLogRepository ];then
                #Repository exist
                echo "Repository exist- Do nothing" |& tee -a $_pathLogRepository/$_pathLogFile
        else
                #Create repository
                mkdir $_pathLogRepository
                chmod 700 $_pathLogRepository
        fi
        #Check if SS_015-Backup_iTop-BDD.log exist
        if [ -f $_pathLogRepository/$_pathLogFile ];then
                #exist
                echo "Log File - Do Nothing" |& tee -a $_pathLogRepository/$_pathLogFile
        else
                touch $_pathLogRepository/$pathLogFile
                chmod 700 $_pathLogRepository/$_pathLogFile
        fi
        echo "End Prerequis Function" |& tee -a $_pathLogRepository/$_pathLogFile
        #Check Argument MidDay/Midnight
        codeArg=$1
        if [ "$codeArg" == "MidDay" ] ;then
                #Check if midday repository exist under $_pathBDDRepository
                pathMidDayRepository=$_pathBDDRepository"/midday"
                if [ -d $pathMidDayRepository ];then
                        #Repository exist
                        echo "Midday Repository - Do nothing" |& tee -a $_pathLogRepository/$_pathLogFile
                else
                        #Create repository
                        mkdir $pathMidDayRepository
                        echo "Midday Repository create" |& tee -a $_pathLogRepository/$_pathLogFile
                        chmod 700 $pathMidDayRepository
                        echo "Midday Repository permission change" |& tee -a $_pathLogRepository/$_pathLogFile
                fi
                dumpCreate $pathMidDayRepository
        elif [ "$codeArg" == "MidNight" ] ;then
                #Check if midnight repository exist under /backup/
                pathMidNightRepository=$_pathBDDRepository"/midnight"
                if [ -d $pathMidNightRepository ];then
                        #Repository exist
                        echo "Midnight Repository - Do nothing" |& tee -a $_pathLogRepository/$_pathLogFile
                else
                        #Create repository
                        mkdir $pathMidNightRepository
                        echo "Midnight Repository create" |& tee -a $_pathLogRepository/$_pathLogFile
                        chmod 700 $pathMidNightRepository
                        echo "Midnight Repository permission change" |& tee -a $_pathLogRepository/$_pathLogFile
                fi
                dumpCreate $pathMidNightRepository
        else
                dumpCreate
        fi
        exit 0
}

# =======================================================
#.SYNOPSIS
#   Function to launch a SQL Dump
#.DESCRIPTION
#       Function dumpCreate realize Dump of SQL database and compress it if SQLDump is success before to call cleanupRepository function.
#       Work without arg and do backup to the level up repository.
#.PARAMETER
#       argDump contain inside $1 the path to specific backup
#.EXAMPLE
#       dumpCreate "/backup/midday"
#.INPUTS
#.OUTPUTS
#       Type [Integer] codeDump2Return = 0 if gzip & SQLdump is successful
#       Type [Integer] codeDump2Return = 10 if gzip fail
#       Type [Integer] codeDump2Return = 1 if SQLdumpl fail
#.NOTES
#       NAME:  LastRelease
#       AUTHOR: GUILLEMARD Erwan
#       LASTEDIT: 2024/03/09
#       VERSION:1.0.0 Function Create
#       1.0.0 Function create
#.LINK
#
# =======================================================
function dumpCreate {
        argDump=$1
        echo "Start DumpCreate function" |& tee -a $_pathLogRepository/$_pathLogFile
        #If arg Dump is NULL, Dump default
        if [ -z $argDump ];then
                /usr/bin/mysqldump -u $_dbUser -p$_dbPassword --master-data --default-character-set=utf8 --quick --single-transaction --verbose $_dbName > $_pathBDDRepository/`date +"%Y-%m-%d"`-$_dbName.sql 2>>$_pathLogRepository/$_pathLogFile
        #else launch Midnight/midday dump
        else
                /usr/bin/mysqldump -u $_dbUser -p$_dbPassword --master-data --default-character-set=utf8 --quick --single-transaction --verbose $_dbName > $argDump/`date +"%Y-%m-%d"`-$_dbName.sql 2>>$_pathLogRepository/$_pathLogFile
        fi
        #If dump is ok
        codeDump2Return=0
        if [ "$?" -eq 0 ];then
                #GZIP Compress
                #If arg Dump is NULL, GZIP the default dump
                if [ -z $argDump ];then
                        #echo "wait"
                        /bin/gzip -f -v $_pathBDDRepository/`date +"%Y-%m-%d"`-$_dbName.sql 2>>$_pathLogRepository/$_pathLogFile
                #else launch Midnight/midday gzip sql dump
                else
                        /bin/gzip -f -v $argDump/`date +"%Y-%m-%d"`-$_dbName.sql 2>>$_pathLogRepository/$_pathLogFile
                fi
                #GZIP is ok
                if [ "$?" -eq 0 ];then
                        codeDump2Return=0
                #GZIP fail
                else
                        codeDump2Return=10
                fi
        #Else dump fail
        else
                codeDump2Return=1
        fi
        echo "End DumpCreate function" |& tee -a $_pathLogRepository/$_pathLogFile
        cleanupRepository $argDump $_nbRetention
        prepare_mail $codeDump2Return
        #send_mail $codeDump2Return
        #cleanupRepository $_pathLogRepository/_$pathLogFile $_nbRetentionLog
}

# =======================================================
#.SYNOPSIS
#   Function to clean up the backup repositories and keep only some retention point
#.DESCRIPTION
#       Function cleanupRepository clean dataRepositories. Work without arg and clean the level up repository.
#.PARAMETER
#       argCleanup contain inside $1 the specific path to cleanup or nothing to cleanup the default repository.
#       argNbRetention contain inside $2 the specific number of retention files insides $1
#.EXAMPLE
#       cleanupRepository "/backup/midday" 2
#.INPUTS
#       Type [String] argCleanupPath = "/var/log/ERWAN"
#       Type [Integer] argNbRetention = 2
#.OUTPUTS
#.NOTES
#       NAME:  LastRelease
#       AUTHOR: GUILLEMARD Erwan
#       LASTEDIT: 2024/03/09
#       VERSION:1.1.0 Function generelized, path & nb retention point in arguments
#       1.0.0 Function create
#       1.1.0 Function generelized, path & nb retention point in arguments
#.LINK
#
# =======================================================
function cleanupRepository {
        argCleanupPath=$1
        argNbRetention=$2
        echo "Start CleanupRepository function" |& tee -a $_pathLogRepository/$_pathLogFile
        #If arg Dump is NULL, Dump default statement
        if [ -z $argCleanup ];then
                find $_pathBDDRepository -type f -mtime +$argNbRetention -delete
        else
                find $argCleanupPath -type f -mtime +$argNbRetention -delete
        fi
        echo "End CleanupRepository function" |& tee -a $_pathLogRepository/$_pathLogFile
}

# =======================================================
#.SYNOPSIS
#   Function to format the mail to send. TXT Format or HTML
#.DESCRIPTION
#       Function to compile information and structure the mail before to invoke the send_mail function.
#.PARAMETER
#       argDumpCode contain inside $1 the code return during the dump and zip thread.
#.EXAMPLE
#       prepare_mail 10
#.INPUTS
#       Type [Integer] argDumpCode = 0
#.OUTPUTS
#.NOTES
#       NAME:  LastRelease
#       AUTHOR: GUILLEMARD Erwan
#       LASTEDIT: 2024/03/09
#       VERSION:1.1.0 Function generelized
#       1.1.0 Function generelized
#.LINK
#
# =======================================================
function prepare_mail {
        argDumpCode=$1
        echo "----- Start Prepare Mail -----"
        if [ "$_modeHTML" = true ];then
                html_forge $argDumpCode
        else
                resultBody="SQL Dump Report : `date +"%Y-%m-%d %H:%M:%S"`"
                resultBody+=$(printf '%s\n')
                while read line;do
                        resultBody+=$(printf '%s\n' "$line" '\n')
                done < $_pathTempFile
                resultBody+="\n\nFor more information, please contact the Administrator team.\nBe care, the way is dangerous..."
                echo "------ End Prepare Mail ------"
                send_mail $resultBody
        fi
}

# =======================================================
#.SYNOPSIS
#   Function to format the HTML mail. 
#.DESCRIPTION
#       Function to build the html mail body line by line. In case of code return.
#.PARAMETER
#       codeDumpReturn contain inside $1 the code return during the dump and zip thread.
#.EXAMPLE
#       html_forge 10
#.INPUTS
#       Type [Integer] codeDumpReturn = 0
#.OUTPUTS
#.NOTES
#       NAME:  LastRelease
#       AUTHOR: GUILLEMARD Erwan
#       LASTEDIT: 2024/03/09
#       VERSION:1.1.0 Function generelized
#       1.1.0 Function generelized
#.LINK
#
# =======================================================
function html_forge {
        codeDumpReturn=$1
        titleH2="SQL Dump Report : `date +"%Y-%m-%d %H:%M"`"
        #Start Forge
        mail_global="<html>"
        mail_global+="<head>"
        mail_global+="<style>"
        mail_global+="table, th, td {border: 1px solid black; border-collapse: collapse;}"
        mail_global+="</style>"
        mail_global+="</head>"
        mail_global+="<body>"
        mail_global+="<table>"
        mail_global+="<thead>"
        mail_global+="<tr>"
        mail_global+='<th colspan="2">'
        mail_global+="<center>"
        mail_global+='<h1 style="background-color:#004c6c; color:#ffffff";>SS-015 - LINUX MYSQL DUMP-BDD</h1>'
        mail_global+="</center>"
        mail_global+="</th>"
        mail_global+="</thead>"
        mail_global+="<tbody>"
        mail_global+="<tr>"
        mail_global+="<td>"
        mail_global+="<h2 style="color:#004c6c";>$titleH2</h2>"
        mail_global+="</td>"
        mail_global+="<td>"
        mail_global+="<p align="right" style="color:#f1931e";>$_author<b><u> :Author</u></b><br/>$_version<b><u> :Version</u></b><br/>$_dateRelease<b><u> :Date</u></b></p>"
        mail_global+="</td>"
        mail_global+="</tr>"
        #Statement LockAccount
        mail_dump_contain="<tr>"
        mail_dump_contain+="<td style="background-color:#004c6c">"
        mail_dump_contain+="<center><h3 style="color:#f15a29";>Last DUMP action :</h3></center>"
        mail_dump_contain+="</td>"
        mail_dump_contain+="<td>"
       case $codeDumpReturn in
        0)
                #Success Dump & Zip
                mail_dump_contain+="<p style="color:#006a8d";>Success : Dump - Export & Zip<br/>"
                mail_dump_contain+="Dump & Gzip realized the `date +"%Y-%m-%d %h:%M"`.<br/>For more informations, please read the log file stored on : $_pathLogRepository/$_pathLogFile<br/></p>"
                ;;
        1)
                #Dump Failure
                mail_dump_contain+="<p style="color:#006a8d";>Failure : Dump - Export<br/>"
                mail_dump_contain+="Dump failure the `date +"%Y-%m-%d %h:%M"` please check log file in attachment.<br/>For more informations, please read the log file stored on : $_pathLogRepository/$_pathLogFile<br/></p>"
                ;;
        10)
                #Gunzip failure
                mail_dump_contain+="<p style="color:#006a8d";>Failure : Dump - Zip<br/>"
                mail_dump_contain+="Gunzip Failure the `date +"%Y-%m-%d %h:%M"` please check log file in attachment.<br/>For more informations, please read the log file stored on : $_pathLogRepository/$_pathLogFile<br/></p>"
                ;;
        *)
                mail_dump_contain+="<p style="color:#006a8d";>UNKNOWN : iTop - ??? <br/>"
                mail_dump_contain+="Error unknown `date +"%Y-%m-%d %h:%M"` please contact the Administrator Team.<br/>For more informations, please read the log file stored on : $_pathLogRepository/$_pathLogFile<br/></p>"
                ;;
        esac
        mail_dump_contain+="</td>"
        mail_global+=$mail_dump_contain
        mail_global+="</tbody>"
        mail_global+="</table>"
        mail_global+="<i>"
        mail_global+='<p style="color:red;">For all scripts assistance please contact Erwan GUILLEMARD</p>'
        mail_global+="</i>"
        mail_global+="</body>"
        mail_global+="</html>"
        echo $mail_global > $_pathHTMLFile
        send_mail
}
# =======================================================
#.SYNOPSIS
#   Function to notify Administrator Teams on SQLDump status
#.DESCRIPTION
#       Function sendMail send mail to monitor SQLDump. Work with argument on SQL Dump return.
#.PARAMETER
#       codeDumpReturn contain inside $1 the specific success or failures code.
#               0 = Dump & Zip Success
#               1 = Dump Failure
#               10 = Compression Failure
#               * = UNKNOWN Error
#.EXAMPLE
#       sendMail 0
#.INPUTS
#       Type [Integer] codeDump2Return = 0 if gzip & SQLdump is successful
#       Type [Integer] codeDump2Return = 10 if gzip fail
#       Type [Integer] codeDump2Return = 1 if SQLdumpl fail
#.OUTPUTS
#.NOTES
#       NAME:  LastRelease
#       AUTHOR: GUILLEMARD Erwan
#       LASTEDIT: 2024/03/09
#       VERSION:1.0.0 Function Create
#       1.0.0 Function create
#.LINK
#
# =======================================================
function send_mail {
        echo "----- Start Send Mail -----"
        body=$@
        subject="[R-ONE] : $HOSTNAME - DUMP BDD"
        #Send mail
        #To DEBUG
        #echo -e "Subject:$subject\n\n$body" | ssmtp ---vvv debug@erwanguillemard.com
        if [ "$_modeHTML" = true ];then
                #mutt -e "set content_type=text/html" -s "$subject" erwanguillemard@gmail.com < $_pathTempHTMLFile
                mutt -e "set content_type=text/html" -s "$subject" $_mailTo < $_pathHTMLFile
        else
                echo -e "To:$_mailTo\nSubject:$subject\n\n$body" | msmtp $_mailTo
        fi
        echo "----- End Send Mail -----"
}

echo "--Starting script at -- `date +"%Y-%m-%d__%H-%M"`--" |& tee -a $_pathLogRepository/$_pathLogFile
checkPrerequis $1
echo "--Ending script at -- `date +"%Y-%m-%d__%H-%M"`--" |& tee -a $_pathLogRepository/$_pathLogFile

