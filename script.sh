#!/bin/sh

#set -e

usage()
{
    echo -e "How to use it ?"
    echo -e "$(basename $0) <environment_label> <docker_registry> <namespace> <component> <new_docker_version> [base_docker_version]\n"
    echo -e "NOTE: Replace the < and > with parentesis with the value you want to use, example, \"dev\". "
}

print_used_params()
{
    echo -e "\e[33mParams used:\e[0m"
    echo "environment_label   = $1"
    echo "docker_registry     = $2"
    echo "namespace           = $3"
    echo "component           = $4"
    echo "new_docker_version  = $5"
    echo "base_docker_version = $6"
    echo -e "------------------------------------------"
}

print_comment_header() 
{
    echo -e "|file|Current Versions|New Version|" >> dockerversion_replacer_out.md
    echo -e "|---|---|---|" >> dockerversion_replacer_out.md   
}

add_file_to_comment() 
{
    file="$1"
    current_versions="$2"
    new_version="$3"

    if [ -z "$file" ]; then
        file="N/A"
    fi

    if ( [ -z "$current_versions" ] || [ "$current_versions" = "N/A" ] ); then
        current_versions="N/A"
        new_version="-"
    fi
    
    echo "|$file|$current_versions|$new_version|" >> dockerversion_replacer_out.md
}

to_lower() {
    echo -e "$1" | awk '{print tolower($0)}' 
}

commit_files() {

    if [ $(git status --porcelain | wc -l) -gt 0 ];
    then 
        # echo "------------------------------------------"
        #echo "Commit files updated."
        echo "LINE OF git push were disabled."
        # pwd
        # git branch --show-current
        # git status

        # git config user.name "github-actions"
        # git config user.email "github-actions@users.noreply.github.com"
        # git add .
        # git commit -m "chore(deps): update $new_docker_version"
        # git push
    fi
}

rm dockerversion_replacer_out.md
print_comment_header

#usage

# [ $1 ] || { echo -e "\e[31mERROR:\e[0m Invalid environment label (ex: dev, qa, prod)." >&2; usage; exit 1; }
# [ $2 ] || { echo -e "\e[31mERROR:\e[0mInvalid docker registry (ex: acrapplications.azurecr.io)." >&2; usage; exit 1; }
# [ $3 ] || { echo -e "\e[31mERROR:\e[0mNamespace used in the docker image version (ex: common)." >&2; usage; exit 1; }
# [ $4 ] || { echo -e "\e[31mERROR:\e[0mThe name of component. (ex: eventflowwebapi, liveagentmanagerwebapi)." >&2; usage; exit 1; }
# [ $5 ] || { echo -e "\e[31mERROR:\e[0mThe new docker image version. (ex: master.a1c905b.7290957852)." >&2; usage; exit 1; }
# [ $6 ] || { echo -e "\e[31mERROR:\e[0mThe base or existence docker image version. (ex: master.a1c905b.7290957852)." >&2; usage; exit 1; }

#DEBUG
environment_label="dev"  #$1
cluster_aks="aks-sophie-$environment_label"
docker_registry="acrapplications.azurecr.io" #$2
namespace="common" #$3
component="eventflowwebapi" #$4
new_docker_version="master.DEV.$RANDOM" #$5
base_docker_version="" # "master.DEV" #$6

echo "Deloyment environment: '$cluster_aks'."

found_any_env=false

for i in $(find . -type f \( -name "*.yaml" -o -name "*.yml" \));
do
    
    pattern_found=""
    
    echo -e "\e[93m> Path '$i':\e[0m ";

    if [ $(echo "$i" | grep -e "$cluster_aks/") ]; 
    then 

        if [ -n "$base_docker_version" ]; then

            pattern_found=$(grep -P "\K:$base_docker_version" "$i" )
            
            if [ -n "$pattern_found" ]; then 
                found_any_env=true

                total_pattern_found=$(echo $pattern_found | awk -v RS="image: " 'NF {print $1}' |  wc -l)

                echo "  * First attempt! \e[32m> Found ($total_pattern_found) version(s) to be replaced.\e[0m"; 

                current_versions=$(echo $pattern_found | awk -v RS="image: " 'BEGIN{ORS=""} NF {gsub(/"/, ""); print $1 " <br /> "}' )
                
                add_file_to_comment "$i" "$current_versions" "$new_docker_version"
                
                #echo "  * New docker version: $new_docker_version"
                sed -i -E "s|(:)($base_docker_version)(..*)|\1$new_docker_version\"|g" "$i"
                echo "------------------------------------------"
                
                continue;
            else
                echo -e "  * First attempt! \e[35m> NOT FOUND\e[0m"; 
            fi;
        else
            echo -e "  * First attempt! \e[35m> NOT FOUND\e[0m"; 
        fi;
        
        pattern_found=$(grep -e "\"$docker_registry\/$namespace\/$component:.*\"" "$i" )
        
        if [ -n "$pattern_found" ]; then 

            found_any_env=true
            total_pattern_found=$(echo $pattern_found | awk -v RS="image: " 'NF {print $1}' |  wc -l)
            echo -e "  * Second attempt! \e[32m> Found ($total_pattern_found) version(s) to be replaced.\e[0m"; 
            current_versions=$(echo $pattern_found | awk -v RS="image: " 'BEGIN{ORS=""} NF {gsub(/"/, ""); print $1 " <br /> "}' )
            sed -i -E "s|(\"$docker_registry\/$namespace\/$component:)(..*)\"|\1$new_docker_version\"|g" "$i"
            echo "------------------------------------------"
            add_file_to_comment "$i" "$current_versions" "$new_docker_version"
        else
            echo -e "  * Second attempt! \e[35m> NOT FOUND\e[0m"; 

            pattern_found=$(grep -e "\/$component:.*\"" "$i" )

            if [ -n "$pattern_found" ]; then 

                found_any_env=true 

                total_pattern_found=$(echo $pattern_found | awk -v RS="image: " 'NF {print $1}' |  wc -l)
                echo -e "  * Third attempt! \e[32m> Found ($total_pattern_found) version(s) to be replaced.\e[0m"; 
                current_versions=$(echo $pattern_found | awk -v RS="image: " 'BEGIN{ORS=""} NF {gsub(/"/, ""); print $1 " <br /> "}' )
                sed -i -E "s|(\/$component:)(..*)|\1$new_docker_version\"|g" "$i"
                echo "------------------------------------------"
                add_file_to_comment "$i" "$current_versions" "$new_docker_version"
            else
                echo -e "  * Third attempt! \e[35m> NOT FOUND\e[0m"; 

                if ([ $(egrep -e "repository: $docker_registry\/$namespace\/$component" "$i" | wc -l) -gt 0 ] && [ $(grep -e "tag:\s\".*\"" "$i" | wc -l) -gt 0 ]); 
                then
                    found_any_env=true

                    pattern_found=$(grep -P 'tag:\s(\K[^"]+|\"\K[^"]+)' "$i" )
                    total_pattern_found=$(echo $pattern_found | awk -v RS="tag: " 'NF {print $1}' |  wc -l)
                    echo -e "  * Fourth attempt! \e[32m> Found ($total_pattern_found) version(s) to be replaced.\e[0m"; 
                    current_versions=$(echo $pattern_found | awk -v RS="tag: " 'BEGIN{ORS=""} NF {gsub(/"/, ""); print $1 " <br /> "}' )
                    pattern_found=$(grep -P 'tag:\s(\K[^"]+|\"\K[^"]+)' "$i" )
                    sed -i -E "s|(tag:\s)(..*)|\1\"$new_docker_version\"|g" "$i"
                    echo "------------------------------------------"
                    add_file_to_comment "$i" "$current_versions" "$new_docker_version"
                else
                    echo -e "  * \e[31mResult: We didn't find any reference of the image $new_docker_version !!!\e[0m"; 
                    echo "------------------------------------------"
                    add_file_to_comment "$i" "$current_versions" "$new_docker_version"
                fi;
                
            fi;
        fi;
        
        commit_files

    else 
        echo -e "  * Different environment! \e[35m>Excluded!\e[0m"; 
        echo "------------------------------------------"

        continue;
    fi;

done;

if [ "$found_any_env" = false ]; then
    echo -e "\e[31mResult: We didn't find any reference of the image $new_docker_version in the choosed environment $environment_label or the environment doesn't exists !!!\e[0m"; 
fi;

cat dockerversion_replacer_out.md



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
# do echo -e ">>>$i<<<"; done

  # for i in $(find . -type f); echo -e "$i" done;
  #   do 
  #     if grep -i "id-" "$i" > /dev/null; then 
  #       echo -e "$i"; 
  #     fi; 
  #   done;
 
 