#!/bin/bash

NU=$(cat /proc/cpuinfo | grep "processor" | wc -l)
#echo $NU

if [ $? -eq 0 ]; then
    #echo "{\"changed\": False, \"ansible_facts\": {\"SBUILD_JOBS\": \"$NU\"}}"
    cat << EOF 
{
    "changed": false,
    "ansible_facts": {
        "SBUILD_JOBS": $NU
    }
}
EOF

else
    echo "{\"failed\":true, \"msg\": \"query cpuinfo error\"}"
fi
