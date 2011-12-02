password=test
path=`pwd`
EXIST_HOME=${path%%/webapp*scripts}; 
export EXIST_HOME
echo "Shutting down eXist server with EXIST_HOME=$EXIST_HOME and password $password"       
../../../../bin/shutdown.sh -u admin -p $password
