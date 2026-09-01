if ([ $# -lt 1 ]); then
    echo "Syntax: $0 container"
    echo "where container is the name of the Docker container"
    exit 1
fi
docker exec $1 java org.exist.start.Main client -u admin -m "/db/www/oppidum/mesh" -s
docker exec $1 java org.exist.start.Main client -u admin --collection "/db/www/oppidum/mesh" --parse "/exist/etc/webapp/projects/oppidum/mesh" -s
docker exec $1 java org.exist.start.Main client -u admin -m "/db/www/oppidum/config" -s
docker exec $1 java org.exist.start.Main client -u admin --collection "/db/www/oppidum/config" --parse "/exist/etc/webapp/projects/oppidum/init" -s
docker exec $1 java org.exist.start.Main client -u admin -m "/db/www/oppidum/mesh" -s
docker exec $1 java org.exist.start.Main client -u admin -F "/exist/etc/webapp/projects/oppidum/scripts/bootstrap.xql"
# uncomment next 2 lines if you want to debug oppidum from eXide
# docker exec $1 java org.exist.start.Main client -u admin -m "/db/www/oppidum/lib" -s
# docker exec $1 java org.exist.start.Main client -u admin --collection "/db/www/oppidum/lib" --parse "/exist/etc/webapp/projects/oppidum/lib" -s