# Synopsis  : ./bootstrap.sh test
# Parameter : database admin password
# ---
# Preconditions
# - eXist instance running
# - edit ../../../../client.properties to point to the running instance (port number, etc.)
# ---
# Creates the initial /db/www/oppidum/config and /db/www/oppidum/mesh collections
#
../../../../bin/client.sh -u admin -P $1 -m /db/www/oppidum/mesh -p ../mesh
../../../../bin/client.sh -u admin -P $1 -m /db/www/oppidum/config -p ../init
