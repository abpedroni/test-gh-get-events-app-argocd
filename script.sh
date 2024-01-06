#!/bin/bash

##ITERATOR
# find . -type f \( -name "*.yaml" -o -name "*.yml" \) -print0


# for i in $(find . -type f \( -name "*.yaml" -o -name "*.yml" \)); \
# do sed -i -E "s|\"(..*)\"|\">>>\1<<<\"|g" "$i"; done

# for i in $(find . -type f \( -name "*.yaml" -o -name "*.yml" \)); \
# do sed -i -E "s|(tag:\s\")(..*)(\")|\1>>>\2<<<\3|g" "$i" ; done

usage()
{
    echo -e "$(basename $0) <environment_label> <docker_registry> <namespace> <component> <new_docker_version> [base_docker_version]\n"
}
usage

# [[ $1 ]] || { echo "Invalid environment label (ex: dev, qa, prod)." >&2; exit 1; }
# [[ $2 ]] || { echo "Invalid docker registry (ex: acrapplications.azurecr.io)." >&2; exit 1; }
# [[ $3 ]] || { echo "Invalid docker registry (ex: acrapplications.azurecr.io)." >&2; exit 1; }
# [[ $4 ]] || { echo "Invalid docker registry (ex: acrapplications.azurecr.io)." >&2; exit 1; }
# [[ $5 ]] || { echo "Invalid docker registry (ex: acrapplications.azurecr.io)." >&2; exit 1; }

environment_label="dev" #$1
cluster_aks="aks-sophie-$environment_label"
docker_registry="acrapplications.azurecr.io" #$2
namespace="common" #$3
component="eventflowwebapi" #$4
new_docker_version="NEW_DOCKER_VERSION" #$5
base_docker_version="master.DEV" #$6

echo "Deloyment environment: '$cluster_aks'."
echo -e "------------------------------------------"
for i in $(find . -type f \( -name "*.yaml" -o -name "*.yml" \));
do
    if [[ $i == *$cluster_aks/* ]]; 
    then 

        echo "> Path '$i':";

        if [[ -n "$base_docker_version" ]]; then

            if [ $(grep -e ":$base_docker_version\"" "$i" | wc -l) -gt 0 ]; 
            then 
                echo "First attempt! Pattern :$base_docker_version\"";
                
                grep -e ":$base_docker_version\"" "$i" | awk '{print "* Docker image found:", $2}' 
                echo -e "* New docker version: $new_docker_version"
                sed -i -E "s|(:)($base_docker_version)(\")|\1$new_docker_version\"|g" "$i"
                echo -e "------------------------------------------"
                sed -i $'s/$/\r/' "$i" #convert Unix to DOS/Windows format

                continue;
            else
                echo -e "First attempt! \e[31m> NOT FOUND\e[0m"; 
            fi;
        fi;

        if [ $(grep -e "\"$docker_registry\/$namespace\/$component:.*\"" "$i" | wc -l) -gt 0 ]; 
        then  
            echo "Second attempt! Pattern \"$docker_registry/$namespace/$component:.*\""; 
            grep -e "\"$docker_registry\/$namespace\/$component:.*\"" "$i" | awk '{print "* Docker image found:", $2}' 
            echo -e "* New docker version: $new_docker_version"
            sed -i -E "s|(\"$docker_registry\/$namespace\/$component:)(..*)\"|\1$new_docker_version\"|g" "$i"
            echo -e "------------------------------------------"
            sed -i $'s/$/\r/' "$i" #convert Unix to DOS/Windows format
        else
            echo -e "Second attempt! \e[31m> NOT FOUND\e[0m"; 

            if [ $(grep -e "\/$component:.*\"" "$i" | wc -l) -gt 0 ]; 
            then  
                echo "Third attempt! Pattern /$component:.*\""; 
                egrep -e "(\/$component:)(..*)(\")" "$i" | awk '{print "* Docker image found:", $2}'
                echo -e "* New docker version: $new_docker_version"
                sed -i -E "s|(\/$component:)(..*)(\")|\1$new_docker_version\3|g" "$i"
                echo -e "------------------------------------------"
                sed -i $'s/$/\r/' "$i" #convert Unix to DOS/Windows format
            else
                echo -e "Third attempt! \e[31m> NOT FOUND\e[0m"; 
                if ([ $(egrep -e "repository: $docker_registry\/$namespace\/$component" "$i" | wc -l) -gt 0 ] && [ $(grep -e "tag:\s\".*\"" "$i" | wc -l) -gt 0 ]); 
                then
                    echo "Forth attempt! Pattern tag:\s\".*\""; 
                    #tag starting with " and ending with "
                    grep -e "tag:\s\".*\"" "$i" | awk '{print "* Docker image found:", $2}' 
                    
                    sed -i -E "s|\"(..*)\"|\"$new_docker_version\"|g" "$i"
                    #tag starting with alphabet
                    grep -e "tag:\s\w.*" "$i" | awk '{print "* Docker image found:", $2}' 
                    sed -i -E "s|(tag:\s)(..*)|\1$new_docker_version|g" "$i"
                    

                    echo -e "* New docker version: $new_docker_version"
                    echo -e "------------------------------------------"
                    sed -i $'s/$/\r/' "$i" #convert Unix to DOS/Windows format
                else
                    echo -e "\e[31m> NOT FOUND any pattern !!!\e[0m"; 
                    echo -e "------------------------------------------"
                fi;
                
            fi;

        fi;

    else 
        #echo "Not proper format"; 
        continue;
    fi

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
 
 