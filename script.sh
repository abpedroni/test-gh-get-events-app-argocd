#!/bin/sh

set -e

usage()
{
    echo -e "$(basename $0) <environment_label> <docker_registry> <namespace> <component> <new_docker_version> [base_docker_version]\n"
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

# [ $1 ] || { echo "Invalid environment label (ex: dev, qa, prod)." >&2; exit 1; }
# [ $2 ] || { echo "Invalid docker registry (ex: acrapplications.azurecr.io)." >&2; exit 1; }
# [ $3 ] || { echo "Namespace used in the docker image version (ex: common)." >&2; exit 1; }
# [ $4 ] || { echo "The name of component. (ex: eventflowwebapi, liveagentmanagerwebapi)." >&2; exit 1; }
# [ $5 ] || { echo "The new docker image version. (ex: master.a1c905b.7290957852)." >&2; exit 1; }
# [ $6 ] || { echo "The base or existence docker image version. (ex: master.a1c905b.7290957852)." >&2; exit 1; }

# environment_label=$(to_lower "$1")  #$1
# cluster_aks="aks-sophie-$environment_label"
# docker_registry=$(to_lower "$2") #"acrapplications.azurecr.io"
# namespace=$(to_lower "$3") #common
# component=$(to_lower "$4") #eventflowwebapi
# new_docker_version=$(to_lower "$5") #NEW_DOCKER_VERSION
# base_docker_version="$6"

#DEBUG
environment_label="dev"  #$1
cluster_aks="aks-sophie-$environment_label"
docker_registry="acrapplications.azurecr.io" #$2
namespace="common" #$3
component="eventflowwebapi" #$4
new_docker_version="NEW_DOCKER_VERSION" #$5
base_docker_version="master.DEV" #$6

echo "Deloyment environment: '$cluster_aks'."

for i in $(find . -type f \( -name "*.yaml" -o -name "*.yml" \));
do
    
    if [ $(echo "$i" | grep -e "$cluster_aks/") ]; 
    then 

        echo "> Path '$i':";

        if [ -n "$base_docker_version" ]; then

            if [ $(grep -e ":$base_docker_version\"" "$i" | wc -l) -gt 0 ]; 
            then 
                echo "First attempt! Pattern :$base_docker_version\"";
                
                grep -e ":$base_docker_version\"" "$i" | awk '{print "* Docker image found:", $2}' 
                echo  "* New docker version: $new_docker_version"
                sed -i -E "s|(:)($base_docker_version)(\")|\1$new_docker_version\"|g" "$i"
                echo  "------------------------------------------"
                #sed -i $'s/$/\r/' "$i" #convert Unix to DOS/Windows format
                cat "$i"
                commit_files
                continue;
            else
                echo  "First attempt! \e[31m> NOT FOUND\e[0m"; 
            fi;
        else
            echo  "First attempt! \e[31m> NOT FOUND\e[0m"; 
        fi;

        if [ $(grep -e "\"$docker_registry\/$namespace\/$component:.*\"" "$i" | wc -l) -gt 0 ]; 
        then  
            echo "Second attempt! Pattern \"$docker_registry/$namespace/$component:.*\""; 
            grep -e "\"$docker_registry\/$namespace\/$component:.*\"" "$i" | awk '{print "* Docker image found:", $2}' 
            echo  "* New docker version: $new_docker_version"
            sed -i -E "s|(\"$docker_registry\/$namespace\/$component:)(..*)\"|\1$new_docker_version\"|g" "$i"
            echo  "------------------------------------------"
            sed -i $'s/$/\r/' "$i" #convert Unix to DOS/Windows format
        else
            echo  "Second attempt! \e[31m> NOT FOUND\e[0m"; 

            if [ $(grep -e "\/$component:.*\"" "$i" | wc -l) -gt 0 ]; 
            then  
                echo "Third attempt! Pattern /$component:.*\""; 
                egrep -e "(\/$component:)(..*)(\")" "$i" | awk '{print "* Docker image found:", $2}'
                echo  "* New docker version: $new_docker_version"
                sed -i -E "s|(\/$component:)(..*)(\")|\1$new_docker_version\3|g" "$i"
                echo  "------------------------------------------"
                sed -i $'s/$/\r/' "$i" #convert Unix to DOS/Windows format
            else
                echo  "Third attempt! \e[31m> NOT FOUND\e[0m"; 
                if ([ $(egrep -e "repository: $docker_registry\/$namespace\/$component" "$i" | wc -l) -gt 0 ] && [ $(grep -e "tag:\s\".*\"" "$i" | wc -l) -gt 0 ]); 
                then
                    echo "Forth attempt! Pattern tag:\s\".*\""; 
                    #tag starting with " and ending with "
                    grep -e "tag:\s\".*\"" "$i" | awk '{print "* Docker image found:", $2}' 
                    
                    sed -i -E "s|\"(..*)\"|\"$new_docker_version\"|g" "$i"
                    #tag starting with alphabet
                    grep -e "tag:\s\w.*" "$i" | awk '{print "* Docker image found:", $2}' 
                    sed -i -E "s|(tag:\s)(..*)|\1$new_docker_version|g" "$i"
                    

                    echo  "* New docker version: $new_docker_version"
                    echo  "------------------------------------------"
                    sed -i $'s/$/\r/' "$i" #convert Unix to DOS/Windows format
                else
                    echo  "\e[31m> NOT FOUND any pattern !!!\e[0m"; 
                    echo  "------------------------------------------"
                fi;
                
            fi;
        fi;

        commit_files

    else 
        echo "> Path '$i':";
        echo  "\e[31m> Differente environment\e[0m"; 
        echo  "------------------------------------------"

        continue;
    fi;

done;

#grep -r -e "tag:\s\".*\"" "$i" ; done
#grep -r -e "tag:\s\".*\"" * | grep -v "grep" | sed -E "s|\"(..*)\"|\">>>\1<<<\"|g"

# WORKING: find . -type f -exec grep -H 'id-' {} \;
#          grep -r "acrapplications.azurecr.io" *
#          find . -type f -name "*.*" -print0 | xargs --null grep --with-filename --line-number --no-messages --color --ignore-case "acrapplications.azurecr.io"

# docker image pattern
# grep -r -e "tag:\s\".*\"" *
# grep -r -e "tag:\s\".*\"" * | grep -v "grep" | sed -e 's/.*tag:\s\"//' | sed -e 's/\".*//' | sort | uniq
# regex pattern: $@"tag:\s\""(.*)\"""
#   WORKs for liveagent: grep -r -e "tag:\s\".*\"" * | grep -v "grep" | sed -E "s|\"(..*)\"|\">>>\1<<<\"|g"
# grep -r -e "eventflowwebapi.*\"" apps/*
# grep -r -e "eventflowwebapi.*\"" apps/* | grep -v "grep" | sed -e 's/.*tag:\s\"//' | sed -e 's/\".*//' | sort | uniq
# regex pattern: $@"{dockerImageInfo.ApiName}:(.*)\"""
#   WORKS: grep -r -e "\/eventflowwebapi:.*\"" * | grep -v "grep" | sed -E "s|(\/eventflowwebapi:)(..*)(\")|\1>>>\2<<<\3|g"

# regex pattern: @"\""{dockerImageInfo.DockerRegistry}\/{dockerImageInfo.Namespace}\/{dockerImageInfo.ApiName}:(.*)\"""
#   WORKS: grep -r -e "\"acrapplications.azurecr.io\/common\/eventflowwebapi:.*\"" * | sed -E "s|(\"acrapplications.azurecr.io\/common\/eventflowwebapi:)(..*)\"|\1>>>\2<<<\"|g"

# for i in $(find . -type f); \
# do echo ">>>$i<<<"; done

  # for i in $(find . -type f); echo "$i" done;
  #   do 
  #     if grep -i "id-" "$i" > /dev/null; then 
  #       echo "$i"; 
  #     fi; 
  #   done;
 
 