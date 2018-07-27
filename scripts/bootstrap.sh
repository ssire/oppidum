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
../../../../bin/client.sh -u admin -P $1 -m /db/www/oppidum/mesh --parse ../mesh -s
../../../../bin/client.sh -u admin -P $1 -m /db/www/oppidum/config --parse ../init -s

../../../../bin/client.sh -u admin -P $1 -F bootstrap.xql