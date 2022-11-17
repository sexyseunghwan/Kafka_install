################################################################################
# Author      : Seunghwan Shin 
# Create date : 2022-11-10 
# Description : automating kafka installation
#	    
# History     : 2022-11-10 Seunghwan Shin       # first create
#               
#				  

################################################################################

die () {
        echo "ERROR: $1. Aborting!"
        exit 1
}


SCRIPT=$(readlink -f $0)
SCRIPTPATH=$(dirname $SCRIPT) ## /opt/kafka
KAFKA_START_DIR=$SCRIPTPATH/kafka_start.sh
ZOOKEEPER_START_DIR=$SCRIPTPATH/zookeeper_start.sh
SERVER_PROPERTIES=$SCRIPTPATH/config/server.properties
ZOOKEEPER_PROPERTIES=$SCRIPTPATH/config/zookeeper.properties

_MANUAL_EXECUTION=false

_DEFAULT_KAFKA_BROKER_ID=1
_DEFAULT_KAFKA_IP=$(hostname -I | awk -F' ' '{print $1}')
_DEFAULT_KAFKA_PORT=9092
_DEFAULT_KAFKA_LOG_DIR="/var/log/kafka-logs"
_DEFAULT_PARTITION=1
_DEFAULT_MIN_REPLICATION_FACTOR=3
_DEFAULT_MIN_TRANSACTION_REPLICATION_FACTOR=3
_DEFAULT_LOG_RETENTIOM_HOURS=168
_DEFAULT_ZOOKEEPER_IP=$(hostname -I | awk -F' ' '{print $1}')
_DEFAULT_ZOOKEEPER_PORT=2181
_DEFAULT_ZOOKEEPER_DATA_DIR="/var/lib/zookeeper"
_DEFAULT_INITLIMIT=5
_DEFAULT_SYNCLIMIT=2

## cluster-related variables
KAFKA_CLUSTERING=false
_DEFAUL_CLUSTER_INDEX=3

## cluster ip array to configure
declare -a CLUSTER_ARR


echo "Welcome to the mongod installer"
echo "This script will help you easily set up a running kafka instance"
echo


#check for root user
if [ "$(id -u)" -ne 0 ] ; 
then
        echo "You must run this script as root. Sorry!"
        exit 1
fi



# Check whether to use Kafka's cluster structure
if [ $KAFKA_CLUSTERING == false ] ; then
        _MANUAL_EXECUTION=true

        read -p "Would you like to use kafka clustering ? (y/n) " KAFKA_CLUSTERING_YN
        
        if [ -z "$KAFKA_CLUSTERING_YN" ]
        then
               echo "Selected default - n" 
               KAFKA_CLUSTERING=false
        elif [ $KAFKA_CLUSTERING_YN == 'y' ] || [ $KAFKA_CLUSTERING_YN == 'Y' ]
        then
                KAFKA_CLUSTERING=true
        elif [ $KAFKA_CLUSTERING_YN == 'n' ] || [ $KAFKA_CLUSTERING_YN =='N' ]
        then
                KAFKA_CLUSTERING=false
        else
                echo "Selected default - n"
                KAFKA_CLUSTERING=false
        fi
fi


# When configuring a cluster structure
if [ $KAFKA_CLUSTERING == true ]
then
        _MANUAL_EXECUTION=true

        _CLUSTER_NUM_IDX=1
        _CLUSTER_IP_ADDR=''

        read -p "Please specify the number of server in the cluster [$_DEFAUL_CLUSTER_INDEX] " CLUSTER_INDEX        
        if ! echo $CLUSTER_INDEX | egrep -q '^[0-9]+$' ; then
                echo "Selecting default: $_DEFAUL_CLUSTER_INDEX"
                CLUSTER_INDEX=$_DEFAUL_CLUSTER_INDEX
        fi
        
        while [ $_CLUSTER_NUM_IDX -le $CLUSTER_INDEX ]
        do
                read -p "Please specify the server IP inside the cluster - server.$_CLUSTER_NUM_IDX : " _CLUSTER_IP_ADDR
                
                if [ -z "$_CLUSTER_IP_ADDR" ] ; then
                                continue
                else
                        read -p "Please check that the information of the corresponding IP address is correct : $_CLUSTER_IP_ADDR (y/n) : " _CHECK_IP_YN
                        
                        if [ -z "$_CHECK_IP_YN" ]
                        then
                                continue
                        elif [ $_CHECK_IP_YN == 'y' ] || [ $_CHECK_IP_YN == 'Y' ]
                        then
                                CLUSTER_ARR[_CLUSTER_NUM_IDX]=$_CLUSTER_IP_ADDR
                                _CLUSTER_NUM_IDX=`expr $_CLUSTER_NUM_IDX + 1`
                        else
                                continue
                        fi
                fi

        done

fi



# Specify kafka broker id
if ! echo $KAFKA_BROKER_ID | egrep -q '^[0-9]+$' ; 
then
        _MANUAL_EXECUTION=true
        
        read  -p "Please select the ID of the kafka broker : [$_DEFAULT_KAFKA_BROKER_ID] " KAFKA_BROKER_ID
        if ! echo $KAFKA_BROKER_ID | egrep -q '^[0-9]+$' ; then
                echo "Selecting default: $_DEFAULT_KAFKA_BROKER_ID"
                KAFKA_BROKER_ID=$_DEFAULT_KAFKA_BROKER_ID
        fi
fi


# Specify listeners and advertised listeners ips
if [ -z "$KAFKA_IP" ] ; then
        _MANUAL_EXECUTION=true

        read -p "Please select the kafka listners ip : [$_DEFAULT_KAFKA_IP] " KAFKA_IP
        if [ -z "$KAFKA_IP" ] ; then
                KAFKA_IP=$_DEFAULT_KAFKA_IP
                echo "Selected default - $KAFKA_IP"
        fi
fi

# kafka port configuration
if [ -z "$KAFKA_PORT" ] ; then
        _MANUAL_EXECUTION=true

        read -p "Please select kafka port : [$_DEFAULT_KAFKA_PORT] " KAFKA_PORT
        if [ -z "$KAFKA_PORT" ] ; then
                KAFKA_PORT=$_DEFAULT_KAFKA_PORT
                echo "Selected default - $KAFKA_PORT"
        fi
fi

# kafka log dir 설정
if [ -z "$KAFKA_LOG_DIR" ] ; then
        _MANUAL_EXECUTION=true

        read -p "Please specify the log directory of kafka : [$_DEFAULT_KAFKA_LOG_DIR] " KAFKA_LOG_DIR
        if [ -z "$KAFKA_LOG_DIR" ] ; then
                KAFKA_LOG_DIR=$_DEFAULT_KAFKA_LOG_DIR
                echo "Selected default - $KAFKA_LOG_DIR"
        fi
fi

# kafka partition
if ! echo $PARTITION | egrep -q '^[0-9]+$' ; then
        _MANUAL_EXECUTION=true
        #Read the redis port
        read  -p "Please select the number of kafka partitions : [$_DEFAULT_PARTITION] " PARTITION
        if ! echo $PARTITION | egrep -q '^[0-9]+$' ; then
                echo "Selecting default: $_DEFAULT_PARTITION"
                PARTITION=$_DEFAULT_PARTITION
        fi
fi


# kafka replication factor
if ! echo $MIN_REPLICATION_FACTOR | egrep -q '^[0-9]+$' ; then
        _MANUAL_EXECUTION=true
        #Read the redis port
        read  -p "Please select the minimum number of replication factors for the kafka offset topic : [$_DEFAULT_MIN_REPLICATION_FACTOR] " MIN_REPLICATION_FACTOR
        if ! echo $MIN_REPLICATION_FACTOR | egrep -q '^[0-9]+$' ; then
                echo "Selecting default: $_DEFAULT_MIN_REPLICATION_FACTOR"
                MIN_REPLICATION_FACTOR=$_DEFAULT_MIN_REPLICATION_FACTOR
        fi
fi


# kafka transaction replication factor
if ! echo $MIN_TRANSACTION_REPLICATION_FACTOR | egrep -q '^[0-9]+$' ; then
        _MANUAL_EXECUTION=true
        #Read the redis port
        read  -p "Please select the minimum number of replication factors for the kafka transaction topic : [$_DEFAULT_MIN_TRANSACTION_REPLICATION_FACTOR] " MIN_TRANSACTION_REPLICATION_FACTOR
        if ! echo $MIN_TRANSACTION_REPLICATION_FACTOR | egrep -q '^[0-9]+$' ; then
                echo "Selecting default: $_DEFAULT_MIN_TRANSACTION_REPLICATION_FACTOR"
                MIN_TRANSACTION_REPLICATION_FACTOR=$_DEFAULT_MIN_TRANSACTION_REPLICATION_FACTOR
        fi
fi


# Set log retention period
if ! echo $LOG_RETENTIOM_HOURS | egrep -q '^[0-9]+$' ; then
        _MANUAL_EXECUTION=true
        #Read the redis port
        read  -p "Please select the log retention period for kafka (hour): [$_DEFAULT_LOG_RETENTIOM_HOURS] " LOG_RETENTIOM_HOURS
        if ! echo $LOG_RETENTIOM_HOURS | egrep -q '^[0-9]+$' ; then
                echo "Selecting default: $_DEFAULT_LOG_RETENTIOM_HOURS"
                LOG_RETENTIOM_HOURS=$_DEFAULT_LOG_RETENTIOM_HOURS
        fi
fi


# Set zookeeper information to connect
if [ -z "$ZOOKEEPER_IP" ] && [ $KAFKA_CLUSTERING == false ]
then
        _MANUAL_EXECUTION=true

        read -p "Please set the Zookeeper IP address to connect to : [$_DEFAULT_ZOOKEEPER_IP] " ZOOKEEPER_IP
        if [ -z "$ZOOKEEPER_IP" ] ; then
                ZOOKEEPER_IP=$_DEFAULT_ZOOKEEPER_IP
                echo "Selected default - $ZOOKEEPER_IP"
        fi
fi


# set zookeeper port
if [ ! $(echo $ZOOKEEPER_PORT | egrep -q '^[0-9]+$') ] && [ $KAFKA_CLUSTERING == false ] 
then
        _MANUAL_EXECUTION=true
        #Read the redis port
        read  -p "Please set the Zookeeper port number to connect to : [$_DEFAULT_ZOOKEEPER_PORT] " ZOOKEEPER_PORT
        if ! echo $ZOOKEEPER_PORT | egrep -q '^[0-9]+$' ; then
                echo "Selecting default: $_DEFAULT_ZOOKEEPER_PORT"
                ZOOKEEPER_PORT=$_DEFAULT_ZOOKEEPER_PORT
        fi
fi


# Allow topic to be removed
if [ -z "$DELETE_TOPIC_ENABLE" ] ; then
        _MANUAL_EXECUTION=true

        read -p "Are you sure you want to allow deletion of the kafka topic? (y/n) " DELETE_TOPIC_ENABLE
        if [ -z "$DELETE_TOPIC_ENABLE" ]
        then
               echo "Selected default - y" 
               DELETE_TOPIC_ENABLE=true
        elif [ $DELETE_TOPIC_ENABLE = 'y' ] || [ $DELETE_TOPIC_ENABLE = 'Y' ]
        then
                DELETE_TOPIC_ENABLE=true
        elif [ $DELETE_TOPIC_ENABLE = 'n' ] || [ $DELETE_TOPIC_ENABLE = 'N' ]
        then
                DELETE_TOPIC_ENABLE=false
        else
                echo "Selected default - y"
                DELETE_TOPIC_ENABLE=true
        fi
fi


# Decide whether to allow auto-creation of topics
if [ -z "$AUTO_TOPIC_CREATE" ] ; then
        _MANUAL_EXECUTION=true

        read -p "Are you sure you want to allow auto-generation option for kafka topics? (y/n) " AUTO_TOPIC_CREATE
        if [ -z "$AUTO_TOPIC_CREATE" ]
        then
               echo "Selected default - y" 
               AUTO_TOPIC_CREATE=true
        elif [ $AUTO_TOPIC_CREATE = 'y' ] || [ $AUTO_TOPIC_CREATE = 'Y' ]
        then
                AUTO_TOPIC_CREATE=true
        elif [ $AUTO_TOPIC_CREATE = 'n' ] || [ $AUTO_TOPIC_CREATE = 'N' ]
        then
                AUTO_TOPIC_CREATE=false
        else
                echo "Selected default - y"
                AUTO_TOPIC_CREATE=true
        fi
fi


# set zookeeper data directory
if [ -z "$ZOOKEEPER_DATA_DIR" ] ; then
        _MANUAL_EXECUTION=true

        read -p "Please specify the data directory of zookeeper : [$_DEFAULT_ZOOKEEPER_DATA_DIR] " ZOOKEEPER_DATA_DIR
        if [ -z "$ZOOKEEPER_DATA_DIR" ] ; then
                ZOOKEEPER_DATA_DIR=$_DEFAULT_ZOOKEEPER_DATA_DIR
                echo "Selected default - $ZOOKEEPER_DATA_DIR"
        fi
fi


# Limit number of ticks when connecting to the Follwer Leader
if ! echo $INITLIMIT | egrep -q '^[0-9]+$' ; then
        _MANUAL_EXECUTION=true
        #Read the redis port
        read  -p "Please select the initLimit value of zookeeper : [$_DEFAULT_INITLIMIT] " INITLIMIT
        if ! echo $INITLIMIT | egrep -q '^[0-9]+$' ; then
                echo "Selecting default: $_DEFAULT_INITLIMIT"
                INITLIMIT=$_DEFAULT_INITLIMIT
        fi
fi


# The number of ticks to synchronize after the follower is connected to the leader
if ! echo $SYNCLIMIT | egrep -q '^[0-9]+$' ; then
        _MANUAL_EXECUTION=true
        #Read the redis port
        read  -p "Please select the syncLimit value of zookeeper : [$_DEFAULT_SYNCLIMIT] " SYNCLIMIT
        if ! echo $SYNCLIMIT | egrep -q '^[0-9]+$' ; then
                echo "Selecting default: $_DEFAULT_SYNCLIMIT"
                SYNCLIMIT=$_DEFAULT_SYNCLIMIT
        fi
fi


echo -e "\n"
echo "=============================  Selected config  =================================="
echo -e "\n"

echo "Clustering Set enable                             : $KAFKA_CLUSTERING"
echo "Kafka Broker Id                                   : $KAFKA_BROKER_ID"
echo "Kafka IP:PORT                                     : $KAFKA_IP:$KAFKA_PORT"
echo "Kafka Log Dir                                     : $KAFKA_LOG_DIR"
echo "Kafka PARTITION                                   : $PARTITION"
echo "minimim of offset topic replication factor        : $MIN_REPLICATION_FACTOR"
echo "minimim of transaction topic replication factor   : $MIN_TRANSACTION_REPLICATION_FACTOR"
echo "Kafka Log Retension Hours                         : $LOG_RETENTIOM_HOURS"
echo "Kafka Allow topic to be removed                   : $DELETE_TOPIC_ENABLE"
echo "Kafka auto-generation option enable               : $AUTO_TOPIC_CREATE"

if [ $KAFKA_CLUSTERING == true ]
then
        echo "Zookeeper ip:port                                   "

        for ((i=1;i<=$CLUSTER_INDEX;i++))
        do
                echo '                                                  : '${CLUSTER_ARR[$i]}:2181
        done
else
        echo "Zookeeper ip:port                                 : $ZOOKEEPER_IP:$ZOOKEEPER_PORT"
fi

echo "Zookeeper Data Dir                                : $ZOOKEEPER_DATA_DIR"
echo "Zookeeper INITLIMIT value                         : $INITLIMIT"
echo "Zookeeper SYNCLIMIT value                         : $SYNCLIMIT"

echo -e "\n"




if [ $KAFKA_CLUSTERING == true ]
then
        echo  "selected Cluster config:"
        
        for ((i=1;i<=$CLUSTER_INDEX;i++))
        do
                echo "Cluster server.$i                                  : ${CLUSTER_ARR[$i]}:2888:3888"
        done        
fi

echo "=================================================================================="


if $_MANUAL_EXECUTION == true ; then
        read -p "Is this ok? Then press ENTER to go on or Ctrl-C to abort." _UNUSED_
fi

echo "Installing zookeeper & kafka instance..."



if [ -f "$KAFKA_START_DIR" ] || [ -f "$ZOOKEEPER_START_DIR" ]
then
        echo "The file kafka_start.sh or zookeeper_start.sh already exists."
        exit 100
fi


### server properties
touch $KAFKA_START_DIR
touch $ZOOKEEPER_START_DIR

echo '#!/bin/bash' >> $KAFKA_START_DIR
echo 'KAFKA_HOME='$SCRIPTPATH >> $KAFKA_START_DIR
echo '$KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties' >> $KAFKA_START_DIR

echo '#!/bin/bash' >> $ZOOKEEPER_START_DIR
echo 'KAFKA_HOME='$SCRIPTPATH >> $ZOOKEEPER_START_DIR
echo 'nohup $KAFKA_HOME/bin/zookeeper-server-start.sh -daemon $KAFKA_HOME/config/zookeeper.properties' >> $ZOOKEEPER_START_DIR

chmod 755 kafka_start.sh
chmod 755 zookeeper_start.sh

mkdir -p $ZOOKEEPER_DATA_DIR
mkdir -p $KAFKA_LOG_DIR




## set zookeeper broker id
ZOOKEEPER_MY_ID=$ZOOKEEPER_DATA_DIR/myid
touch $ZOOKEEPER_MY_ID
echo $KAFKA_BROKER_ID >> $ZOOKEEPER_MY_ID




### server properties

sed -i 's/broker.id=0/broker.id='$KAFKA_BROKER_ID'/g' $SERVER_PROPERTIES
sed -i 's/#listeners=PLAINTEXT\:\/\/:9092/listeners=PLAINTEXT\:\/\/'$KAFKA_IP:$KAFKA_PORT'/g' $SERVER_PROPERTIES
sed -i 's/#advertised.listeners=PLAINTEXT\:\/\/your.host.name:9092/advertised.listeners=PLAINTEXT\:\/\/'$KAFKA_IP:$KAFKA_PORT'/g' $SERVER_PROPERTIES
sed -i 's:/tmp/kafka-logs:'$KAFKA_LOG_DIR':g' $SERVER_PROPERTIES
sed -i 's/num.partitions=1/num.partitions='$PARTITION'/g' $SERVER_PROPERTIES
sed -i 's/offsets.topic.replication.factor=1/offsets.topic.replication.factor='$MIN_REPLICATION_FACTOR'/g' $SERVER_PROPERTIES
sed -i 's/transaction.state.log.replication.factor=1/transaction.state.log.replication.factor='$MIN_TRANSACTION_REPLICATION_FACTOR'/g' $SERVER_PROPERTIES
sed -i 's/log.retention.hours=168/log.retention.hours='$LOG_RETENTIOM_HOURS'/g' $SERVER_PROPERTIES

if [ $KAFKA_CLUSTERING == true ]
then
        for ((i=1;i<=$CLUSTER_INDEX;i++))
        do
               ZOOKEEPER_IP_PORT+=${CLUSTER_ARR[$i]}
               ZOOKEEPER_IP_PORT+=':2181,' 
        done

        ZOOKEPPER_IP_PORT_LEN=${#ZOOKEEPER_IP_PORT}
        ZOOKEEPER_IP_PORT=${ZOOKEEPER_IP_PORT:0:$ZOOKEPPER_IP_PORT_LEN-1}

        sed -i 's/zookeeper.connect=localhost:2181/zookeeper.connect='$ZOOKEEPER_IP_PORT'/g' $SERVER_PROPERTIES
else
        sed -i 's/zookeeper.connect=localhost:2181/zookeeper.connect='$ZOOKEEPER_IP:$ZOOKEEPER_PORT'/g' $SERVER_PROPERTIES
fi

echo 'delete.topic.enable='$DELETE_TOPIC_ENABLE >> $SERVER_PROPERTIES
echo 'auto.create.topics.enable='$AUTO_TOPIC_CREATE >> $SERVER_PROPERTIES



### zookeeper properties

sed -i 's:/tmp/zookeeper:'$ZOOKEEPER_DATA_DIR':g' $ZOOKEEPER_PROPERTIES

if [ $KAFKA_CLUSTERING == true ]
then
        for ((i=1;i<=$CLUSTER_INDEX;i++))
        do
                echo 'server.'$i'='${CLUSTER_ARR[$i]}:2888:3888 >> $ZOOKEEPER_PROPERTIES
        done

else
        echo 'server.1='$ZOOKEEPER_IP:2888:3888 >> $ZOOKEEPER_PROPERTIES
fi


echo 'initLimit='$INITLIMIT >> $ZOOKEEPER_PROPERTIES
echo 'syncLimit='$SYNCLIMIT >> $ZOOKEEPER_PROPERTIES




### service 
ZOOKEEPER_SERVICE_FILE="/lib/systemd/system/zookeeper.service"
KAFKA_SERVICE_FILE="/lib/systemd/system/kafka.service"
JAVA_HOME_DIR=$JAVA_HOME

if [ -f "$ZOOKEEPER_SERVICE_FILE" ] || [ -f "$KAFKA_SERVICE_FILE" ]
then
        echo "file exists check the system file"
        exit 100
else
        touch $ZOOKEEPER_SERVICE_FILE
        touch $KAFKA_SERVICE_FILE
        
        ## zookeeper
        echo "[Unit]" >> $ZOOKEEPER_SERVICE_FILE
        echo "Description=Apache Zookeeper server (Kafka)" >> $ZOOKEEPER_SERVICE_FILE
        echo "Requires=network.target remote-fs.target" >> $ZOOKEEPER_SERVICE_FILE
        echo "After=network.target remote-fs.target" >> $ZOOKEEPER_SERVICE_FILE
        echo -e "\n" >> $ZOOKEEPER_SERVICE_FILE

        echo "[Service]" >> $ZOOKEEPER_SERVICE_FILE
        echo "Type=simple" >> $ZOOKEEPER_SERVICE_FILE
        echo "Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> $ZOOKEEPER_SERVICE_FILE
        echo "SyslogIdentifier=zookeeper" >> $ZOOKEEPER_SERVICE_FILE
        echo "WorkingDirectory="$SCRIPTPATH >> $ZOOKEEPER_SERVICE_FILE
        echo "RestartSec=0s" >> $ZOOKEEPER_SERVICE_FILE
        echo "ExecStart="$SCRIPTPATH'/bin/zookeeper-server-start.sh '$SCRIPTPATH'/config/zookeeper.properties' >> $ZOOKEEPER_SERVICE_FILE
        echo "ExecStop="$SCRIPTPATH"/bin/zookeeper-server-stop.sh" >> $ZOOKEEPER_SERVICE_FILE
        echo -e "\n" >> $ZOOKEEPER_SERVICE_FILE

        echo "[Install]" >> $ZOOKEEPER_SERVICE_FILE
        echo "WantedBy=multi-user.target" >> $ZOOKEEPER_SERVICE_FILE
        echo -e "\n" >> $ZOOKEEPER_SERVICE_FILE

        ## kafka
        echo "[Unit]" >> $KAFKA_SERVICE_FILE
        echo "Description=Apache Kafka server (broker)" >> $KAFKA_SERVICE_FILE
        echo "Requires=zookeeper.service" >> $KAFKA_SERVICE_FILE
        echo "After=zookeeper.service" >> $KAFKA_SERVICE_FILE
        echo -e "\n" >> $KAFKA_SERVICE_FILE

        echo "[Service]" >> $KAFKA_SERVICE_FILE
        echo "Type=simple" >> $KAFKA_SERVICE_FILE
        echo "Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> $KAFKA_SERVICE_FILE
        echo "SyslogIdentifier=kafka" >> $KAFKA_SERVICE_FILE
        echo "WorkingDirectory="$SCRIPTPATH >> $KAFKA_SERVICE_FILE
        echo "RestartSec=0s" >> $KAFKA_SERVICE_FILE
        echo "ExecStart="$SCRIPTPATH'/bin/kafka-server-start.sh '$SCRIPTPATH'/config/server.properties' >> $KAFKA_SERVICE_FILE
        echo "ExecStop="$SCRIPTPATH"/bin/kafka-server-stop.sh" >> $KAFKA_SERVICE_FILE
        echo -e "\n" >> $KAFKA_SERVICE_FILE

        echo "[Install]" >> $KAFKA_SERVICE_FILE
        echo "WantedBy=multi-user.target" >> $KAFKA_SERVICE_FILE


        ln -s $ZOOKEEPER_SERVICE_FILE zookeeper.service
        ln -s $KAFKA_SERVICE_FILE kafka.service

        mv zookeeper.service /etc/systemd/system
        mv kafka.service /etc/systemd/system


        systemctl daemon-reload
        service zookeeper start

        sleep 3s

        ZOOKEEPER_STATE=$(service zookeeper status)
        
        
        if [[ "$ZOOKEEPER_STATE" == *"Active: active (running)"* ]] 
        then
                if [ $KAFKA_CLUSTERING == true ]
                then
                        echo "In other servers, run the zookeeper service first and then run the kafka service."  
                else
                        service kafka start
                        
                        sleep 3s

                        KAFKA_STATS=$(service kafka status)
                        
                        if [[ "$KAFKA_STATS" == *"Active: active (running)"* ]]
                        then
                                echo "Both zookeeper and kafka services were successfully executed."
                        else
                                echo "The kafka service failed to start with an error."
                        fi
                fi
        else
                echo "The zookeeper service failed to start with an error."
        fi

fi


