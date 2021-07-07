
Use case is that there is a legacy code base. We want to find out which which manifests are NOT used.

This script uses the PE REST API to find out all the active nodes, 
and then saves all the manifests in use by the active nodes. Then some additional steps need to be taken to figure out which manifests are NOT used.