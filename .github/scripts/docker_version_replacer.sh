#!/bin/sh

set -e

usage()
{
    echo "How to use it ?"
    echo "$(basename $0) <environment_label> <docker_registry> <namespace> <component> <new_docker_version> [base_docker_version]\n"
    echo "NOTE: Replace the < and > with parentesis with the value you want to use, example, \"dev\". "
}

print_used_params()
{
    echo "\e[33mParams used:\e[0m"
    echo "environment_label   = $1"
    echo "docker_registry     = $2"
    echo "namespace           = $3"
    echo "component           = $4"
    echo "new_docker_version  = $5"
    echo "base_docker_version = $6"
    echo "------------------------------------------"
}

print_comment_header() 
{
    echo "|file|Current Versions|New Version|" >> dockerversion_replacer_out.md
    echo "|---|---|---|" >> dockerversion_replacer_out.md   
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
    echo "$1" | awk '{print tolower($0)}' 
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

[ $1 ] || { echo "\e[31mERROR:\e[0m Invalid environment label (ex: dev, qa, prod)." >&2; usage; exit 1; }
[ $2 ] || { echo "\e[31mERROR:\e[0mInvalid docker registry (ex: acrapplications.azurecr.io)." >&2; usage; exit 1; }
[ $3 ] || { echo "\e[31mERROR:\e[0mNamespace used in the docker image version (ex: common)." >&2; usage; exit 1; }
[ $4 ] || { echo "\e[31mERROR:\e[0mThe name of component. (ex: liveagentmanagerwebapi)." >&2; usage; exit 1; }
[ $5 ] || { echo "\e[31mERROR:\e[0mThe new docker image version. (ex: master.a1c905b.7290957852)." >&2; usage; exit 1; }
#[ $6 ] || { echo "\e[31mERROR:\e[0mThe base or existence docker image version. (ex: master.a1c905b.7290957852)." >&2; usage; exit 1; }

print_comment_header
print_used_params $1 $2 $3 $4 $5 $6

# environment_label="$1" 
# cluster_aks="aks-sophie-$environment_label"
# docker_registry="$2" 
# namespace="$3" 
# component="$4" 
# new_docker_version="$5" 
# base_docker_version="$6" 

environment_label="dev"  #$1
cluster_aks="aks-sophie-$environment_label"
docker_registry="acrapplications.azurecr.io" #$2
namespace="common" #$3
component="eventflowwebapi" #$4
new_docker_version="master.DEV.$6" #$5
base_docker_version="master.DEV" # "master.DEV" #$6

echo "Deloyment environment: '$cluster_aks'."

found_any_env=false

for i in $(find . -type f \( -name "*.yaml" -o -name "*.yml" \));
do
    
    echo "\e[93m> Path '$i':\e[0m ";

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
                echo "  * First attempt! \e[35m> NOT FOUND\e[0m"; 
            fi;
        else
            echo "  * First attempt! \e[35m> NOT FOUND\e[0m"; 
        fi;
        
        pattern_found=$(grep -e "\"$docker_registry\/$namespace\/$component:.*\"" "$i" )
        
        if [ -n "$pattern_found" ]; then 

            found_any_env=true
            total_pattern_found=$(echo $pattern_found | awk -v RS="image: " 'NF {print $1}' |  wc -l)
            echo "  * Second attempt! \e[32m> Found ($total_pattern_found) version(s) to be replaced.\e[0m"; 
            current_versions=$(echo $pattern_found | awk -v RS="image: " 'BEGIN{ORS=""} NF {gsub(/"/, ""); print $1 " <br /> "}' )
            sed -i -E "s|(\"$docker_registry\/$namespace\/$component:)(..*)\"|\1$new_docker_version\"|g" "$i"
            echo "------------------------------------------"
            add_file_to_comment "$i" "$current_versions" "$new_docker_version"
        else
            echo "  * Second attempt! \e[35m> NOT FOUND\e[0m"; 

            pattern_found=$(grep -e "\/$component:.*\"" "$i" )

            if [ -n "$pattern_found" ]; then 

                found_any_env=true 

                total_pattern_found=$(echo $pattern_found | awk -v RS="image: " 'NF {print $1}' |  wc -l)
                echo "  * Third attempt! \e[32m> Found ($total_pattern_found) version(s) to be replaced.\e[0m"; 
                current_versions=$(echo $pattern_found | awk -v RS="image: " 'BEGIN{ORS=""} NF {gsub(/"/, ""); print $1 " <br /> "}' )
                sed -i -E "s|(\/$component:)(..*)|\1$new_docker_version\"|g" "$i"
                echo "------------------------------------------"
                add_file_to_comment "$i" "$current_versions" "$new_docker_version"
            else
                echo "  * Third attempt! \e[35m> NOT FOUND\e[0m"; 

                if ([ $(egrep -e "repository: $docker_registry\/$namespace\/$component" "$i" | wc -l) -gt 0 ] && [ $(grep -e "tag:\s\".*\"" "$i" | wc -l) -gt 0 ]); 
                then
                    found_any_env=true

                    pattern_found=$(grep -P 'tag:\s(\K[^"]+|\"\K[^"]+)' "$i" )
                    total_pattern_found=$(echo $pattern_found | awk -v RS="tag: " 'NF {print $1}' |  wc -l)
                    echo "  * Fourth attempt! \e[32m> Found ($total_pattern_found) version(s) to be replaced.\e[0m"; 
                    current_versions=$(echo $pattern_found | awk -v RS="tag: " 'BEGIN{ORS=""} NF {gsub(/"/, ""); print $1 " <br /> "}' )
                    pattern_found=$(grep -P 'tag:\s(\K[^"]+|\"\K[^"]+)' "$i" )
                    sed -i -E "s|(tag:\s)(..*)|\1\"$new_docker_version\"|g" "$i"
                    echo "------------------------------------------"
                    add_file_to_comment "$i" "$current_versions" "$new_docker_version"
                else
                    echo "  * \e[31mResult: We didn't find any reference of the image $new_docker_version !!!\e[0m"; 
                    echo "------------------------------------------"
                    add_file_to_comment "$i" "$current_versions" "$new_docker_version"
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

if [ "$found_any_env" = false ]; then
    echo "\e[31mResult: We didn't find any reference of the image $new_docker_version in the choosed environment $environment_label or the environment doesn't exists !!!\e[0m"; 
fi;