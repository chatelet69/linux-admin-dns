#!/bin/bash
    j=0
    isSudoer="NON"
    for userLine in $(cat /etc/passwd)
        do
            user=$(echo $userLine | cut -d: -f1)
            if [ -d "/home/$user" -o "$user" == "root" ]; then 
                comments=$(echo $userLine | cut -d: -f5)
                name=$(echo $comments | cut -d, -f1)
                lastname=$(echo $comments | cut -d, -f2)
                echo "Utilisateur : $user"
                echo "Prénom : $name"
                echo "Nom : $lastname"
                k=1
                for userGroups in $(groups $user | cut -d: -f2)
                    do
                        if [ $k -eq 1 ]; then
                            if [ $userGroups == "sudo" ]; then 
                            isSudoer="OUI"
                            fi
                            echo "Groupe primaire : $(echo $userGroups)"
                            break
                        fi
                        k=$(($k+1))
                    done
                echo -n "Groupe Secondaire : "
                l=1
                for userGroups in $(groups $user | cut -d: -f2)
                    do
                        if [ $l -gt 1 ]; then
                            if [ $userGroups == "sudo" ]; then 
                            isSudoer="OUI"
                            fi
                            echo -n "$userGroups "
                        fi
                        l=$(($l+1))
                    done
                echo " "
                if [ "$user" == "root" ]; then
                echo "Repertoire personnel : $(du -sh /root | cut -d' ' -f1)"
                else echo "Repertoire personnel : $(du -sh /home/$user)"
                fi
                if [ "$user" == "root" ]; then
                echo "Sudoer : OUI"
                else echo "Sudoer : $isSudoer"
                fi
                
                echo " "

            fi
        done

