#!/bin/sh

set -e

usage()
{
    echo "$(basename $0) <environment_label> <docker_registry> <namespace> <component> <new_docker_version> [base_docker_version]\n"
}

to_lower() {
    echo "$1" | awk '{print tolower($0)}' 
}

commit_files() {

    if [ $(git status --porcelain | wc -l) -gt 0 ];
    then 
        echo  "------------------------------------------"
        echo "Commit files updated."
        git config user.name "github-actions"
        git config user.email "github-actions@users.noreply.github.com"
        git add .
        git commit -m "chore(deps): update $new_docker_version"
        git push
    fi
}

usage

[ $1 ] || { echo "Invalid environment label (ex: dev, qa, prod)." >&2; exit 1; }
[ $2 ] || { echo "Invalid docker registry (ex: acrapplications.azurecr.io)." >&2; exit 1; }
[ $3 ] || { echo "Namespace used in the docker image version (ex: common)." >&2; exit 1; }
[ $4 ] || { echo "The name of component. (ex: eventflowwebapi, liveagentmanagerwebapi)." >&2; exit 1; }
[ $5 ] || { echo "The new docker image version. (ex: master.a1c905b.7290957852)." >&2; exit 1; }
[ $6 ] || { echo "The base or existence docker image version. (ex: master.a1c905b.7290957852)." >&2; exit 1; }

environment_label="$1" #$1
cluster_aks="aks-sophie-$environment_label"
docker_registry="$2" #"acrapplications.azurecr.io"
namespace="$3" #common
component="$4" #eventflowwebapi
new_docker_version="$5" #NEW_DOCKER_VERSION
base_docker_version="$6"

echo "Deloyment environment: '$cluster_aks'."

for i in $(find . -type f \( -name "*.yaml" -o -name "*.yml" \));
do
    
    echo "\e[93m> Path '$i':\e[0m ";

    if [ $(echo "$i" | grep -e "$cluster_aks/") ]; 
    then 

        if [ -n "$base_docker_version" ]; then

            if [ $(grep -e ":$base_docker_version\"" "$i" | wc -l) -gt 0 ]; 
            then 
                echo "  * First attempt! \e[32m> FOUND the pattern $base_docker_version\"\e[0m";
                
                grep -e ":$base_docker_version\"" "$i" | awk '{print "  * Docker image found:", $2}' 
                echo "  * New docker version: $new_docker_version"
                sed -i -E "s|(:)($base_docker_version)(\")|\1$new_docker_version\"|g" "$i"
                echo "------------------------------------------"
                sed -i $'s/$/\r/' "$i" #convert Unix to DOS/Windows format
                commit_files
                continue;
            else
                echo "  * First attempt! \e[35m> NOT FOUND\e[0m"; 
            fi;
        else
            echo "  * First attempt! \e[35m> NOT FOUND\e[0m"; 
        fi;

        if [ $(grep -e "\"$docker_registry\/$namespace\/$component:.*\"" "$i" | wc -l) -gt 0 ]; 
        then  
            echo "  * Second attempt! \e[32m> FOUND the pattern \"$docker_registry/$namespace/$component:.*\"\e[0m"; 
            grep -e "\"$docker_registry\/$namespace\/$component:.*\"" "$i" | awk '{print "  * Docker image found:", $2}' 
            echo "  * New docker version: $new_docker_version"
            sed -i -E "s|(\"$docker_registry\/$namespace\/$component:)(..*)\"|\1$new_docker_version\"|g" "$i"
            echo "------------------------------------------"
            sed -i $'s/$/\r/' "$i" #convert Unix to DOS/Windows format
        else
            echo "  * Second attempt! \e[35m> NOT FOUND\e[0m"; 

            if [ $(grep -e "\/$component:.*\"" "$i" | wc -l) -gt 0 ]; 
            then  
                echo "  * Third attempt! \e[32m> FOUND the pattern /$component:.*\"\e[0m"; 
                egrep -e "(\/$component:)(..*)(\")" "$i" | awk '{print "  * Docker image found:", $2}'
                echo "  * New docker version: $new_docker_version"
                sed -i -E "s|(\/$component:)(..*)(\")|\1$new_docker_version\3|g" "$i"
                echo "------------------------------------------"
                sed -i $'s/$/\r/' "$i" #convert Unix to DOS/Windows format
            else
                echo "  * Third attempt! \e[35m> NOT FOUND\e[0m"; 
                if ([ $(egrep -e "repository: $docker_registry\/$namespace\/$component" "$i" | wc -l) -gt 0 ] && [ $(grep -e "tag:\s\".*\"" "$i" | wc -l) -gt 0 ]); 
                then
                    echo "Forth attempt! \e[32m> FOUND the pattern tag:\s\".*\"\e[0m"; 
                    #tag starting with " and ending with "
                    grep -e "tag:\s\".*\"" "$i" | awk '{print "  * Docker image found:", $2}' 
                    
                    sed -i -E "s|\"(..*)\"|\"$new_docker_version\"|g" "$i"
                    #tag starting with alphabet
                    grep -e "tag:\s\w.*" "$i" | awk '{print "  * Docker image found:", $2}' 
                    sed -i -E "s|(tag:\s)(..*)|\1$new_docker_version|g" "$i"
                    

                    echo "  * New docker version: $new_docker_version"
                    echo "------------------------------------------"
                    sed -i $'s/$/\r/' "$i" #convert Unix to DOS/Windows format
                else
                    echo "  * \e[31mResult: We didn't find any reference of the image $new_docker_version !!!\e[0m"; 
                    echo "------------------------------------------"
                fi;
                
            fi;
        fi;

        commit_files

    else 
        echo "  * Different environment! \e[35m>Excluded!\e[0m"; 
        echo "------------------------------------------"

        continue;
    fi;

done;