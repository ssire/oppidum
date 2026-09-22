# Synopsis  : ./bootstrap-docker.sh {docker container name} {password}
# Loads oppidum resources to database and configure persmissions on those resources
# ---
# Preconditions
# - eXist-DB running 
# - eXist-DB password 
# ---

if ([ $# -lt 2 ]); then
    echo "Syntax: $0 container password"
    echo "where container is the name of the Docker container and passord is the eXist-DB admin password or '' if not set"
    exit 1
fi

echo "loading oppidum mesh collection"
docker exec $1 java org.exist.start.Main client -u admin -P $2 -m "/db/www/oppidum/mesh" -s
docker exec $1 java org.exist.start.Main client -u admin -P $2 --collection "/db/www/oppidum/mesh" --parse "/exist/etc/webapp/projects/oppidum/mesh" -s

echo "loading oppidum config collection"
docker exec $1 java org.exist.start.Main client -u admin -P $2 -m "/db/www/oppidum/config" -s
docker exec $1 java org.exist.start.Main client -u admin -P $2 --collection "/db/www/oppidum/config" --parse "/exist/etc/webapp/projects/oppidum/init" -s

echo "configuring oppidum permissions on collections"
docker exec $1 java org.exist.start.Main client -u admin -P $2 -F "/exist/etc/webapp/projects/oppidum/scripts/bootstrap.xql"

# uncomment next 2 lines if you want to debug oppidum from eXide
# docker exec $1 java org.exist.start.Main client -u admin -m "/db/www/oppidum/lib" -s
# docker exec $1 java org.exist.start.Main client -u admin --collection "/db/www/oppidum/lib" --parse "/exist/etc/webapp/projects/oppidum/lib" -s