# Use that script to stop eXist when it has been started from a specific conf-version.xml file in a custom location
port=${2:-8080}
echo "Assume port configured to $port"
if curl --output /dev/null --silent --head --fail "http://localhost:$port/exist"; then
  password=${1:-test}
  path=`pwd`
  EXIST_HOME=${path%%/webapp*scripts};
  export EXIST_HOME
  echo "Shutting down eXist server with EXIST_HOME=$EXIST_HOME and password $password"
  ../../../../bin/shutdown.sh -u admin -p $password
else
  echo "Server is not running, nothing to stop, or maybe you have a wrong port number in client.properties"
fi
if test -f running.ver; then 
  dir=`cat running.ver`
  path=`dirname $dir`
  file="${path}/conf-saved.xml"
  echo "Restoring conf.xml from $file"
  echo "cp $file ../../../../conf.xml"
else
  echo "No configuration file to restore"
fi
