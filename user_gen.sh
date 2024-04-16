#!/bin/bash

echo "  _    _                _____            
 | |  | |              / ____|           
 | |  | |___  ___ _ __| |  __  ___ _ __  
 | |  | / __|/ _ \ '__| | |_ |/ _ \ '_ \ 
 | |__| \__ \  __/ |  | |__| |  __/ | | |
  \____/|___/\___|_|   \_____|\___|_| |_|
                                         
                                         "

if [ $# -eq 0 ]
then
    echo -e "USE"
    echo -e "      ./user_gen.sh <source_file_path>\n"
    echo -e "OPTIONS"
    echo    "      -f to see the format to follow"
    exit
fi

if [[ $1 == "-f" || $2 == "-f" ]]
then
    echo "Format : name:lastname:group1,group2:sudo:password"
    echo "- Sudo status must be 'oui' or 'non'"
    echo "- You can put several groups by separating them with commas"
    echo "- It is possible to put no group => first name:lastname::sudo:password"
    echo "(In this case, the user will have their default group)"
    exit
fi

generateFiles () {
    username=$1

    if [ -d "/home/$username" ]
    then
        filesCount=$(($RANDOM % (10-5+1)+5))
        for (( i=1; i<=filesCount; i++ ))
        do
            echo "          - Generating the file $i"
            fileSize=$(($RANDOM % (50-5+1)+5))
            sudo -u $username dd if=/dev/zero of=/home/$username/file-$i.img bs=1024 count=0 seek=$[1024*$fileSize]
        done
    else
        echo "      User directory not found, no files generated"
    fi
}

createUser() {
    name=$(echo "$line" | awk -F: '{print $1}')
    lastname=$(echo "$line" | awk -F: '{print $2}')
    groups=$(echo "$line" | awk -F: '{print $3}')
    sudo_status=$(echo "$line" | awk -F: '{print $4}')
    password=$(echo "$line" | awk -F: '{print $5}')

    check=0
    newUsername=${name:0:1}$lastname
    while [ $check -eq 0 ]
    do
        tmpCount=1
        if [ getent passwd $newUsername > /dev/null 2>&1 ]
        then
            checkName=$(cat /etc/passwd | grep $newUsername | awk -F: '{print $5}' | awk -F, {'print $1}')
            checkLastname=$(cat /etc/passwd | grep $newUsername | awk -F: '{print $5}' | awk -F, {'print $2}')
            if [[ $checkName == $name && $checkLastname == $lastname ]]
            then
                check=2
            else
                newUsername=${name:0:1}$lastname$tmpCount
                ((tmpCount=tmpCount+1))
            fi
        else
            check=1
        fi
    done

    if [ $check -eq 1 ]
    then
        echo "  User name = $newUsername"

        grp_length=${#groups}
        echo $grp_length
        if [ $grp_length -le 2 ]
        then
            echo "      No valid groups detected"
            echo "      Creating a Default Primary Group"
            sudo useradd -c "$name,$lastname,," -f 0 -m -s /bin/bash -U $newUsername
        else
            grpCount=0
            echo "      Creation of groups"

            # On split chaque groupe sur une ligne
            $groupsArray=$(echo $groups | tr "," "\n")
            for grp in $groupsArray
            do
                echo "          - $grp"
                if [ $(getent group $grp) ]; then
                    echo "              (Existing group)"
                else
                    sudo groupadd $grp
                fi

                # Si c'est le premier groupe, alors c'est le primaire, dans ce cas on crée l'utilisateur avec ce groupe
                if [ $grpCount -eq 0 ]; then
                    sudo useradd -c "$name,$lastname,," -f 0 -m -s /bin/bash -g $grp $newUsername
                else
                    usermod -aG $grp $newUsername
                fi
            done
        fi

        echo "$newUsername:$password" | sudo chpasswd
        # Permet de faire expirer le mot de passe de l'utilisateur
        sudo passwd --expire $newUsername
        if [[ "$sudo_status" == "oui" ]]; then
            sudo usermod -aG sudo $newUsername  # Ajout de l'utilisateur au sein des sudoers
        fi

        generateFiles $newUsername
    else
        echo "  User already exists"
    fi
}

checkUserFormat () {
    local status=1
    # Regex qui permet de vérifier le format de la ligne
    userRegexFormat='[a-zA-Z]+:[a-zA-Z]+:[a-zA-Z0-9_,:]+(oui|non):[a-zA-Z0-9]+'
    echo "  Treatment of $1"
    if [[ $1 =~ $userRegexFormat ]]
    then
        # Appel de la fonction de création
        echo "  Correct format, user creation"
        createUser "$line"
        echo "  End of suboperation completed"
    else
        echo "  Incorrect line format, see -f option for format"
        echo "  User creation canceled"
        status=0
    fi

    echo "--------------"
    return $status
}

filename=$1
count=0
success=0

if [[ -r $filename && -f $filename ]]
then
    while IFS= read -r line 
    do
        # On parcourt chaque ligne du fichier
        ((count=count+1))
        checkUserFormat "$line"
        tmp=$?
        ((success=success+tmp))
    done < "$filename"
else
    echo "File does not exist or can't be read"
    exit
fi

echo "  Operation completed"
echo "  $success / $count users created"
