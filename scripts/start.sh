path=`pwd`
EXIST_HOME=${path%%/webapp*scripts}; 
export EXIST_HOME
echo "Starting eXist server with output redirected to 'server.log'"       
echo "running with EXIST_HOME set to $EXIST_HOME"
../../../../bin/startup.sh > server.log &
