# Oppidum dev tools installation in database
# ---
# Synopsis  : ./bootstrap.sh test
# Parameter : database admin password
# ---
# Preconditions
# - eXist instance running
# - edit ../../../../client.properties to point to the running instance (port number, etc.)
# - to be run from the script folder itself (because of relative paths)
# ---
# Creates the initial /db/www/oppidum/config and /db/www/oppidum/mesh collections
# Then you can point your browser to http://localhost:8080/exist/projects/oppidum
../../../../../bin/client.sh -u admin -P $1 -c /db/www/oppidum/mesh -p ../mesh/* -s
../../../../../bin/client.sh -u admin -P $1 -c /db/www/oppidum/config -p ../init/* -s
../../../../../bin/client.sh -u admin -P $1 -F bootstrap.xql
