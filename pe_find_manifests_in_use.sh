#!/bin/bash 
# -vx

# this script makes REST API calls to Puppet Enterprise to 
# get the list of manifests used on 'recently active' nodes.
run_setup() { 
   PE_SERVER="$(puppet config print server)"
   echo "Enter PE Username:"
   read PE_USER
   echo "Enter PE Password:"
   read PE_PASSWORD

   TOKEN=$(curl -s -k -X POST -H 'Content-Type: application/json' -d "{\"login\": \"$PE_USER\", \"password\": \"$PE_PASSWORD\"}" https://$PE_SERVER:4433/rbac-api/v1/auth/token |jq -r '.token')
}

get_active_nodes() {
   mapfile -t ACTIVE_NODES < <(curl -k -s -X GET https://$PE_SERVER:8081/pdb/query/v4/nodes --data-urlencode "query=[\">\", \"facts_timestamp\", \"$(date -d '-1 day' -Isec)\"]"  -H "X-Authentication:$TOKEN"  |jq -r '.[].certname')

    (( ${#ACTIVE_NODES[@]} > 0 )) || {
      fail "Error: Failed to get the active nodes from the PDB." \
      "Please ensure this script is run on a Puppet Primary server."
   }
}

get_manifests_in_active_nodes() {
   MANIFESTS_FILE="${PE_SERVER}_all_manifests.txt"
   OUTPUT_FILE="${PE_SERVER}_manifests.txt"
   
   rm -f $MANIFESTS_FILE $OUTPUT_FILE

   for node in ${ACTIVE_NODES[@]}
   do
      mapfile -t MANIFESTS < <(curl -k -s -X GET https://$PE_SERVER:8081/pdb/query/v4/nodes/$node/resources  -H "X-Authentication:$TOKEN"|jq -r '.[]|.file'|grep -v 'null')

      (( ${#MANIFESTS[@]} > 0 )) || {
        fail "Error: Failed to get the name of manifests from the PDB." \
             "Also ensure this script is run on a Puppet Primary server."
      }

      for manifest in ${MANIFESTS[@]} 
      do 
          echo $manifest >> $MANIFESTS_FILE
      done 
   done
  
   # remove duplicate entries
   sort -u $MANIFESTS_FILE > $OUTPUT_FILE 
   echo "Info: $OUTPUT_FILE contains all the manifest files used in all the nodes"
}

# main
run_setup
# get the list of active nodes, by checking in the last time they sent 'facts'
get_active_nodes
# for each active-node, get the list of manifests used
get_manifests_in_active_nodes
