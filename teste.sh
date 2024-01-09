set -e

# Define the new Docker version
#teste=$(cat ./apps/eventflowwebapi/aks-sophie-dev/values.yaml | grep -P 'acrapplications.azurecr.io/common/eventflowwebapi:\K[^"]+')
new_docker_version="NEW_VERSION.$RANDOM" #$5

environment_label="dev"  #$1
cluster_aks="aks-sophie-$environment_label"
docker_registry="acrapplications.azurecr.io" #$2
namespace="common" #$3
component="eventflowwebapi" #$4

i="./apps/liveagent/aks-sophie-dev/values.yaml"
base_docker_version="release-SOE-10" #$6

        #pattern_found=$(grep -P 'tag:\s(\K[^"]+|\"\K[^"]+)' "$i" )
        #echo "\K\"$docker_registry\/$namespace\/$component"
        pattern_found=$(grep -P "\K\"$docker_registry/$namespace/$component" "$i" )
        echo $pattern_found #| awk -v RS="image: " '{print $1}' | wc -l
        exit
        echo "\e[93m> Path '$i':\e[0m ";

        if [ -n "$pattern_found" ]; then 
            #echo "  * First attempt! \e[32m> FOUND the pattern $base_docker_version\"\e[0m";
            #echo $pattern_found | awk -v RS="image: " 'NF {print $1}' #| wc -l

            total_pattern_found=$(echo $pattern_found | awk -v RS="tag: " 'NF {print $1}' |  wc -l)

            echo "  * Found ($total_pattern_found) version(s) to be replaced.";

            echo $pattern_found | awk -v RS="tag: " 'NF {print $1}' | awk '{gsub(/"/, "");print "  *", $1}'

            #echo $pattern_found | awk '{print "  * Docker image found:", $2}' 
            echo "  * New docker version: $new_docker_version"
            #cat "$i" | sed -E "s|\"(..*)\"|\"$new_docker_version\"|g"

            #new_text=$(echo "$text" | sed -r 's|(acrapplications.azurecr.io/common/eventflowwebapi:)[^"]+|\1'"$new_version"'|')
            #cat "$i" | sed -E "s|(tag:\s)(..*)|\1\"$new_docker_version\"|g"
            #| sed -E "s|(tag:\s)(..*)|\1\"$new_docker_version\"|g"

        fi
