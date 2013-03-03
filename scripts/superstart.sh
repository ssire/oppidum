# Use that script to start eXist with a specific conf{-version}.xml file in a custom location
# Then do not forget to stop eXist using superstop.sh to restore conf.xml to its original version
# This allows to centralize several projects with Oppidum onto one eXist distribution 
# (which is convenient to maintain code on Git repositories) and to switch between databases 
# which can be useful if the projects data define incompatible users
if [ $# -lt 1 ]
  then echo "usage: superstart.sh path [port]"
       exit 2
fi
port=${2:-8080}
echo "Assume port configured to $port"
if curl --output /dev/null --silent --head --fail "http://localhost:$port/exist"; then
  echo "You must stop eXist first"
else
  name=`basename $1`
  ver=${name#conf-}
  dir=`dirname $1`
  echo "saving existing conf.xml (use superstop.sh to restore it)"
  cp ../../../../conf.xml $dir/conf-saved.xml
  echo "replacing existing conf.xml by $1"
  cp $dir/conf-${ver} ../../../../conf.xml
  echo $1 > running.ver
  path=`pwd`
  EXIST_HOME=${path%%/webapp*scripts}; 
  export EXIST_HOME
  echo "Starting eXist server with output redirected to 'server.log'"       
  echo "running with EXIST_HOME set to $EXIST_HOME"
  ../../../../bin/startup.sh > server.log &
fi
