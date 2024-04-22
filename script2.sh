#!/bin/bash
    declare -a tabUsers
    if [ $1 == "-g" ]; then
        if [ $2 != "" ]; then
            secondarySchr=$2
            else echo "Erreur, argument manquant";
            exit
        fi
    fi
    j=0
    for userLine in $(cat /etc/passwd)
        do
            isSecondaryGroup=0
            user=$(echo $userLine | cut -d: -f1)
            if [ -d "/home/$user" -o "$user" == "root" ]; then
                declare -a User

                primaryGroup=$(id -gn $user)
                notes=$(echo $userLine | cut -d: -f5)
                name=$(echo $notes | cut -d, -f1)
                lastname=$(echo $notes | cut -d, -f2)
                
                User[0]=$user
                User[1]=$name
                User[2]=$lastname
                User[3]=$primaryGroup

                listGroup=""
                isSudoer="NON"
                l=0
                for userGroups in $(groups $user | cut -d: -f2)
                    do
                        if [ "$userGroups" == "sudo" ]; then 
                            isSudoer="OUI"
                        fi
                        if [ $l -gt 0 ]; then 
                            if [ "$secondarySchr" == $userGroups ]; then 
                                isSecondaryGroup=1
                            fi
                            listGroup="$listGroup $userGroups"
                        fi
                        ((l++))
                    done
                User[4]=$listGroup
                User[5]=$isSudoer

                if [ "$user" == "root" ]; then
                    User[6]=$(du -sh /root | cut -f1)
                else 
                    User[6]=$(du -sh /home/$user | cut -f1)
                fi
                if [ "$user" == "root" ]; then
                    User[5]="OUI"
                fi
            ((j++))

            case $1 in
                "-G")
                if [ -z $2];then echo "Erreur, arguments manquants"; exit; fi
                if [ "$primaryGroup" == $2 ];then
                echo "Utilisateur : ${User[0]}";
                echo "Prénom : ${User[1]}";
                echo "Nom de famille : ${User[2]}";
                echo "Groupe primaire : ${User[3]}";
                echo "Groupe secondaire : ${User[4]}";
                echo "Sudoer ${User[5]}";
                echo "Repertoire personnel : ${User[6]}";
                echo " "
                fi;;
                "-g")
                if [ -z $2];then echo "Erreur, arguments manquants"; exit; fi
                if [ $isSecondaryGroup -eq 1 ];then
                echo "Utilisateur : ${User[0]}";
                echo "Prénom : ${User[1]}";
                echo "Nom de famille : ${User[2]}";
                echo "Groupe primaire : ${User[3]}";
                echo "Groupe secondaire : ${User[4]}";
                echo "Sudoer ${User[5]}";
                echo "Repertoire personnel : ${User[6]}";
                echo " "
                fi;;
                "-s")
                if [ -z $2 ];then echo "Erreur, arguments manquants"; exit; fi
                if [ $2 -ne 1 -a $2 -ne 0 ];then echo "Erreur, mauvais arguments"; exit; fi
                if [ $2 -eq 0 ];then
                    if [ "${User[5]}" == "NON" ];then
                        echo "Utilisateur : ${User[0]}";
                echo "Prénom : ${User[1]}";
                echo "Nom de famille : ${User[2]}";
                echo "Groupe primaire : ${User[3]}";
                echo "Groupe secondaire : ${User[4]}";
                echo "Sudoer ${User[5]}";
                echo "Repertoire personnel : ${User[6]}";
                echo " "
                    fi
                fi
                if [ $2 -eq 1 ];then
                    if [ "${User[5]}" == "OUI" ];then
                        echo "Utilisateur : ${User[0]}";
                echo "Prénom : ${User[1]}";
                echo "Nom de famille : ${User[2]}";
                echo "Groupe primaire : ${User[3]}";
                echo "Groupe secondaire : ${User[4]}";
                echo "Sudoer ${User[5]}";
                echo "Repertoire personnel : ${User[6]}";
                echo " "
                    fi
                fi;;
                "-u")
                    if [ -z $2 ];then echo "Erreur, arguments manquants"; exit; fi
            
                    if [ "${User[0]}" == $2 ];then
                        echo "Utilisateur : ${User[0]}";
                        echo "Prénom : ${User[1]}";
                        echo "Nom de famille : ${User[2]}";
                        echo "Groupe primaire : ${User[3]}";
                        echo "Groupe secondaire : ${User[4]}";
                        echo "Sudoer ${User[5]}";
                        echo "Repertoire personnel : ${User[6]}";
                        echo " "
                    fi
                ;;
                "")
                echo "Utilisateur : ${User[0]}";
                echo "Prénom : ${User[1]}";
                echo "Nom de famille : ${User[2]}";
                echo "Groupe primaire : ${User[3]}";
                echo "Groupe secondaire : ${User[4]}";
                echo "Sudoer ${User[5]}";
                echo "Repertoire personnel : ${User[6]}";
                echo " "
                ;;
            esac
            fi
        done