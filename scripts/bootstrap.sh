# Synopsis  : ./bootstrap.sh test
# Parameter : database admin password
# ---
# Preconditions
# - eXist instance running
# - edit ../../../../client.properties to point to the running instance (port number, etc.)
# - to be run from the script folder itself (because of relative paths)
# ---
# Creates the initial /db/www/oppidum/config and /db/www/oppidum/mesh collections
# Sets execute permission (eXist 2.x compatibility)
# Then you can point your browser to http://localhost:8080/exist/{your projects folder name}/oppidum
../../../../bin/client.sh -u admin -P $1 -m /db/www/oppidum/mesh -p ../mesh -s
../../../../bin/client.sh -u admin -P $1 -m /db/www/oppidum/config -p ../init -s

#echo "xmldb:chmod-collection('/db/www/oppidum/config', util:base-to-integer(0775, 8))" | ../../../../bin/client.sh -u admin -P $1 -x '/db/www/oppidum/config'
../../../../bin/client.sh -u admin -P $1 -x "xmldb:chmod-collection('/db/www/oppidum/config', util:base-to-integer(0775, 8))"
#echo "xmldb:chmod-collection('/db/www/oppidum/mesh', util:base-to-integer(0775, 8))" | ../../../../bin/client.sh -u admin -P $1 -x '/db/www/oppidum/mesh'
../../../../bin/client.sh -u admin -P $1 -x "xmldb:chmod-collection('/db/www/oppidum/mesh', util:base-to-integer(0775, 8))"