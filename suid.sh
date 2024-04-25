#!/bin/bash

echo -e "Début du programme\n"

SEARCH_PATH=$1
CURRENT_LIST="current_suid_sgid_list.txt"
PREVIOUS_LIST="previous_suid_sgid_list.txt"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <search_path>"
    exit 1
fi

if [ ! -r "$SEARCH_PATH" ] || [ ! -x "$SEARCH_PATH" ]; then
    echo "Erreur : Vous n'avez pas les autorisations nécessaires pour accéder au répertoire spécifié."
    exit 1
fi

if [ ! -d "$SEARCH_PATH" ]; then
    echo "Le chemin spécifié n'est pas valide ou n'existe pas."
    exit 1
fi

# Pour checker l'inode de deux fichiers et voir si c'est les mêmes
checkIdFiles() {
    local filename=$1
    local oldFile=$2

    fileInode=$(stat -c '%i' $filename)
    oldFileInode=$(stat -c '%i' $oldFile)

    if [ $fileInode -eq $oldFileInode ]; then
        return 0
    else
        return 1
    fi
}

# Cette fonction cherchera la présence du fichier envoyé dans la liste previous
checkFilePresence() {
    local filename=$1
    local list=$2
    local status=1

    isFilePresent=$(cat $list | grep $filename)
    isFilePresent=${#isFilePresent}
    if [ $isFilePresent -eq 0 ]; then
        status=0
    fi

    return $status
}

function format_changes() {
    local old_list="$1"
    local new_list="$2"

    if [ ! -f "$old_list" ]; then
        echo "Le fichier $old_list n'existe pas."
        return 1
    fi

    if [ ! -f "$new_list" ]; then
        echo "Le fichier $new_list n'existe pas."
        return 1
    fi

    local changes=$(diff -u "$old_list" "$new_list")
    local droitAvant=""
    local droitApres=""
    local oldFileName=""

    while IFS= read -r line; do
        echo $line
        lineLen=${#line}
        if [ $lineLen -le 1 ]; then
            break
        fi

        fileName=$(echo "$line" | awk '{print $9}')
        oldFileName=$fileName
        checkFile=$(echo $line | grep "sgid_list")
        checkChangesTextDiff=$(echo $line | grep "@@")
        rightsString=$(echo $line | awk '{print $1}')
        # afin de ne pas afficher les changements des fichiers listes

        checkId=0
        if [[ ${#checkFile} -eq 0 && ${#checkChangesTextDiff} -eq 0 ]]
        then
            checkFilePresence $fileName $old_list
            checkFileWasAlreadyHere=$?

            # Si le fichier n'était pas présent avant
            if [ $checkFileWasAlreadyHere -eq 0 ]
            then
                echo "----------------------------"
                echo "  Le fichier $fileName a été ajouté"
                echo "----------------------------"
                break;
            fi

            #if [[ $fileName != $oldFileName ]]
            #then
            #    checkIdFiles $fileName $oldFileName
            #    checkId=$?
            #fi
        fi

        if [[ ${#checkFile} -eq 0 && ${#checkChangesTextDiff} -eq 0 && checkId -eq 0 ]]
        then
            if [ ${#rightsString} -ne 11 ]; then
                break;
            fi
            echo "----------------------------"

            modifDay=$(echo "$line" | awk '{print $6}')
            modifMonth=$(echo "$line" | awk '{print $7}')
            modifTime=$(echo "$line" | awk '{print $8}')
            modifDate="$modifDay $modifMonth a $modifTime"
            editType=${rightsString:0:1}

            if [ $editType == "-" ]
            then
                echo "  Fichier avant modification :"
                droitAvant=${rightsString:1:10}
            fi

            if [ $editType == "+" ]
            then
                echo "  Fichier après modification :"
                droitApres=${rightsString:1:10}
            fi

            formatedLine=${line:1:lineLen}
            echo "  Nom du fichier -> $fileName"
            echo "  Détails -> $formatedLine"
            echo "  Date de dernière modification -> $modifDate"

            checkFilePresence $fileName $new_list
            checkIfFileIsHere=$?
            if [ $checkIfFileIsHere -eq 0 ]; then
                echo "  Le fichier $fileName a été supprimé"
            fi

            if [[ "$droitAvant" != "$droitApres" && $editType == "+" ]]
            then
                echo "  Les droits ont été modifiés"
                echo "  Droits avant => $droitAvant"
                if [[ "$oldFileName" == "$fileName" && ${#droitApres} -ne 0 ]]
                then
                    echo "  Droits après => $droitApres"
                fi
            fi
            
            echo "----------------------------"
        fi
    done <<< "$changes"
}

rm -f "$CURRENT_LIST"

find $SEARCH_PATH -type f \( -perm -4000 -o -perm -2000 \) -exec ls -l {} \; > "$CURRENT_LIST"
if [ -f "$PREVIOUS_LIST" ]; then
changes=$(diff -u "$PREVIOUS_LIST" "$CURRENT_LIST")
    if [ ! -z "$changes" ]; then
        echo "Liste des changements (si il y en a eu) des fichiers SUID/SGID:"
        format_changes "$PREVIOUS_LIST" "$CURRENT_LIST"
    else
        echo "Aucun changement éffectué."
    fi
else
    echo "C'est la première exécution ou le fichier précédent n'existe pas."
fi

rm -f "$PREVIOUS_LIST"
mv "$CURRENT_LIST" "$PREVIOUS_LIST"

echo -e "\n--------------\nFin du programme\n--------------"