################################################################################
# Author      : Seunghwan Shin 
# Create date : 2022-11-06 
# Description : automating mongod installation
#	    
# History     : 2022-11-06 Seunghwan Shin       # first create
#               
#				  

################################################################################

die () {
        echo "ERROR: $1. Aborting!"
        exit 1
}


#Absolute path to this script => 절대경로
SCRIPT=$(readlink -f $0)
#Absolute path this script is in => 절대경로에서 디렉토리 이름까지만
SCRIPTPATH=$(dirname $SCRIPT)
#mongod, mongos 가 존재하는 경로
INSTANCEPATH=$SCRIPTPATH'/bin'
#mongo conf 디렉토리 확인
CONFDIR='/etc/mongodb/'
#mongod 인스턴스를 옮길 경로 지정
MOVEPATH='/usr/bin'



_DEFAULT_MONGOD_PORT=27017
_DEFAULT_DATA_DIR="/var/lib/mongod"
_DEFAULT_ENGINE_CACHE_SIZE=16
_DEFAULT_COMPRESSOR_TYPE="snappy"
_DEFAULT_SYSTEM_LOG="/var/log/mongodb/"
_DEFAULT_SECURITY_KEY_DIR="/etc/mongodb/keyfile"
_DEFAULT_REPLICA_SET_NAME="rs1"
_MANUAL_EXECUTION=false


echo "Welcome to the mongod installer"
echo "This script will help you easily set up a running mongod instance"
echo

#check for root user
if [ "$(id -u)" -ne 0 ] ; 
then
        echo "You must run this script as root. Sorry!"
        exit 1
fi


# mongod port 지정
if ! echo $MONGOD_PORT | egrep -q '^[0-9]+$' ; 
then
        _MANUAL_EXECUTION=true
        #Read the mongod port
        read  -p "Please select the mongod port for this instance: [$_DEFAULT_MONGOD_PORT] " MONGOD_PORT
        if ! echo $MONGOD_PORT | egrep -q '^[0-9]+$' ; then
                echo "Selecting default: $_DEFAULT_MONGOD_PORT"
                MONGOD_PORT=$_DEFAULT_MONGOD_PORT
        fi
fi

# data dir 지정
if [ -z "$DATA_DIR" ] ; then
        _MANUAL_EXECUTION=true

        read -p "Please select the mongod data dir [$_DEFAULT_DATA_DIR$MONGOD_PORT] " DATA_DIR
        if [ -z "$DATA_DIR" ] ; then
                DATA_DIR=$_DEFAULT_DATA_DIR$MONGOD_PORT
                echo "Selected default - $DATA_DIR"
        fi
fi

# mongod cache size 설정
if ! echo $ENGINE_CACHE_SIZE | egrep -q '^[0-9]+$' ; 
then
        _MANUAL_EXECUTION=true
        
        read  -p "Please select the mongod wireTigered option - cache size for this instance: [$_DEFAULT_ENGINE_CACHE_SIZE] " ENGINE_CACHE_SIZE
        if ! echo $ENGINE_CACHE_SIZE | egrep -q '^[0-9]+$' ; then
                echo "Selecting default: $_DEFAULT_ENGINE_CACHE_SIZE GB"
                ENGINE_CACHE_SIZE=$_DEFAULT_ENGINE_CACHE_SIZE
        fi
fi

# 압축 알고리즘 설정
if [ -z "$COMPRESSOR_TYPE" ] ; then
        _MANUAL_EXECUTION=true

        read -p "Please select the mongod wireTigered option - compressor type: [$_DEFAULT_COMPRESSOR_TYPE] " COMPRESSOR_TYPE
        if [ -z "$COMPRESSOR_TYPE" ] ; then
                COMPRESSOR_TYPE=$_DEFAULT_COMPRESSOR_TYPE
                echo "Selected default - $COMPRESSOR_TYPE"
        fi
fi


# 시스템 로그 경로 설정
if [ -z "$SYSTEM_LOG" ] ; then
        _MANUAL_EXECUTION=true

        read -p "Please select the mongod log dir [$_DEFAULT_SYSTEM_LOG] " SYSTEM_LOG
        if [ -z "$SYSTEM_LOG" ] ; then
                SYSTEM_LOG=$_DEFAULT_SYSTEM_LOG
                echo "Selected default - $SYSTEM_LOG"
        fi
fi


# keyfile 경로 설정
if [ -z "$SECURITY_KEY_DIR" ] ; then
        _MANUAL_EXECUTION=true

        read -p "Please select the mongod log dir [$_DEFAULT_SECURITY_KEY_DIR] " SECURITY_KEY_DIR
        if [ -z "$SECURITY_KEY_DIR" ] ; then
                SECURITY_KEY_DIR=$_DEFAULT_SECURITY_KEY_DIR
                echo "Selected default - $SECURITY_KEY_DIR"
        fi
fi

# Replica Set 이름설정
if [ -z "$REPLICA_SET_NAME" ] ; then
        _MANUAL_EXECUTION=true

        read -p "Please select the Replica Set Name [$_DEFAULT_REPLICA_SET_NAME] " REPLICA_SET_NAME
        if [ -z "$REPLICA_SET_NAME" ] ; then
                REPLICA_SET_NAME=$_DEFAULT_REPLICA_SET_NAME
                echo "Selected default - $REPLICA_SET_NAME"
        fi
fi


# echo $MONGOD_PORT
# echo $DATA_DIR
# echo $ENGINE_CACHE_SIZE
# echo $COMPRESSOR_TYPE
# echo $SYSTEM_LOG
# echo $SECURITY_KEY_DIR
# echo $REPLICA_SET_NAME

# mongod 정보 확인
echo "Selected config:"
echo "Port              : $MONGOD_PORT"
echo "Data dir          : $DATA_DIR"
echo "Cache Size        : $ENGINE_CACHE_SIZE"
echo "Compressor Type   : $COMPRESSOR_TYPE"
echo "System log file   : $SYSTEM_LOG"
echo "Security Key dir  : $SECURITY_KEY_DIR"
echo "Replica Set Name  : $REPLICA_SET_NAME"
echo "Service Name      : mongod@$MONGOD_PORT.service"


if $_MANUAL_EXECUTION == true ; then
        read -p "Is this ok? Then press ENTER to go on or Ctrl-C to abort." _UNUSED_
fi


# mongod 가 /usr/bin 에 존재하는지 확인 -> 존재하지 않을경우에 복사
if [ ! -e $MOVEPATH'/mongod' ]
then
        cp $INSTANCEPATH'/mongod' $MOVEPATH
        chown mongodb:mongodb $MOVEPATH'/mongod'
fi

# conf 디렉토리가 없을 경우에 만들어줌
# 또한 mongodb 소유자도 지정해줌
if [ ! -d $CONFDIR ]
then
        mkdir $CONFDIR
        chown mongodb:mongodb $CONFDIR
fi

# mongodb dir 만들어주기
if [ ! -d $DATA_DIR ]
then
        mkdir $DATA_DIR
        chown mongodb:mongodb $DATA_DIR
fi

# mongodb log dir 만들어주기
if [ ! -d $SYSTEM_LOG ]
then
        mkdir $SYSTEM_LOG
        chown mongodb:mongodb $SYSTEM_LOG
fi

# mongodb log file 생성
if [ ! -e $SYSTEM_LOG'/mongod'$MONGOD_PORT'.log' ]
then
        touch $SYSTEM_LOG'/mongod'$MONGOD_PORT'.log'
        chown mongodb:mongodb $SYSTEM_LOG'/mongod'$MONGOD_PORT'.log'
fi

# =============== mongodConfig 파일 setting ====================
MONGO_CONFIG=''
MONGO_LOG_FILE=$SYSTEM_LOG'mongod'$MONGOD_PORT'.log'

# mongoconf 파일 생성
if [ ! -e $CONFDIR'mongod'$MONGOD_PORT'.conf' ]
then
        MONGO_CONFIG=$CONFDIR'mongod'$MONGOD_PORT'.conf'
        touch $MONGO_CONFIG
        chown mongodb:mongodb $MONGO_CONFIG

        echo '# Where and how to store data.' >> $MONGO_CONFIG
        echo 'storage:' >> $MONGO_CONFIG
        echo '  dbPath: '$DATA_DIR >> $MONGO_CONFIG
        echo '  journal:' >> $MONGO_CONFIG
        echo '    enabled: true ' >> $MONGO_CONFIG
        echo -e '\n' >> $MONGO_CONFIG

        echo '# WiredTiger Option' >> $MONGO_CONFIG
        echo 'storage:' >> $MONGO_CONFIG
        echo '  wiredTiger:' >> $MONGO_CONFIG
        echo '    engineConfig:' >> $MONGO_CONFIG
        echo '      cacheSizeGB: '$ENGINE_CACHE_SIZE >> $MONGO_CONFIG
        echo '    collectionConfig: ' >> $MONGO_CONFIG
        echo '      blockCompressor: '$COMPRESSOR_TYPE >> $MONGO_CONFIG
        echo -e '\n' >> $MONGO_CONFIG

        echo '# where to write logging data.' >> $MONGO_CONFIG
        echo 'systemLog:' >> $MONGO_CONFIG
        echo '  destination: file' >> $MONGO_CONFIG
        echo '  logAppend: true' >> $MONGO_CONFIG
        echo '  path: '$MONGO_LOG_FILE >> $MONGO_CONFIG
        echo -e '\n' >> $MONGO_CONFIG

        echo '# network interfaces.' >> $MONGO_CONFIG
        echo 'net:' >> $MONGO_CONFIG
        echo '  port: '$MONGOD_PORT >> $MONGO_CONFIG
        echo '  bindIp: 0.0.0.0' >> $MONGO_CONFIG
        echo -e '\n' >> $MONGO_CONFIG

        echo '# how the process runs.' >> $MONGO_CONFIG
        echo 'processManagement:' >> $MONGO_CONFIG
        echo '  timeZoneInfo: /usr/share/zoneinfo' >> $MONGO_CONFIG
        echo -e '\n' >> $MONGO_CONFIG

        echo '#security:' >> $MONGO_CONFIG
        echo '#  keyFile: '$SECURITY_KEY_DIR >> $MONGO_CONFIG
        echo -e '\n' >> $MONGO_CONFIG

        echo 'replication:' >> $MONGO_CONFIG
        echo '  replSetName: "'$REPLICA_SET_NAME'"' >> $MONGO_CONFIG
        echo -e '\n' >> $MONGO_CONFIG

        echo 'sharding:' >> $MONGO_CONFIG
        echo '  clusterRole: shardsvr' >> $MONGO_CONFIG
fi





# =============== mongod service 등록 ====================


# 1.Service File 생성
SERVICE_FILE="/lib/systemd/system/mongod@.service"

# 서비스파일이 존재하는지 체크 -> 존재하지 않으면 만들어준다.
if [ ! -e $SERVICE_FILE ]
then
        touch $SERVICE_FILE
        chown mongodb:mongodb $SERVICE_FILE
        chmod 744 $SERVICE_FILE

        echo '[Unit]' >> $SERVICE_FILE
        echo 'Description=MongoDB Shard Serivice - instance %i' >> $SERVICE_FILE
        echo 'Documentation=https://docs.mongodb.org/manual' >> $SERVICE_FILE
        echo 'AssertPathExists=/etc/mongodb/mongod%i.conf' >> $SERVICE_FILE
        echo -e '\n' >> $SERVICE_FILE

        echo 'After=network-online.target' >> $SERVICE_FILE
        echo 'Wants=network-online.target' >> $SERVICE_FILE
        echo -e '\n' >> $SERVICE_FILE

        echo '[Service]' >> $SERVICE_FILE
        echo 'User=mongodb' >> $SERVICE_FILE
        echo 'Group=mongodb' >> $SERVICE_FILE
        echo 'ExecStart=/usr/bin/mongod -config /etc/mongodb/mongod%i.conf' >> $SERVICE_FILE
        echo -e '\n' >> $SERVICE_FILE

        echo 'ExecReload=/bin/kill -HUP $MAINPID' >> $SERVICE_FILE
        echo 'Restart=on-failure' >> $SERVICE_FILE
        echo -e '\n' >> $SERVICE_FILE

        echo '[Install]' >> $SERVICE_FILE
        echo 'WantedBy=multi-user.target' >> $SERVICE_FILE

       

fi


# 2.symbolic link 등록
if [ -e $SERVICE_FILE ]
then
    _DEFAULT_LINK="/etc/systemd/system/multi-user.target.wants/mongod@$MONGOD_PORT.service"

    if [ -e $_DEFAULT_LINK ]    
    then
        rm $_DEFAULT_LINK
    fi

    ln -s /lib/systemd/system/mongod@.service mongod@$MONGOD_PORT.service
    mv mongod@$MONGOD_PORT.service /etc/systemd/system/multi-user.target.wants/
fi



systemctl daemon-reload
systemctl enable mongod@$MONGOD_PORT.service
systemctl start mongod@$MONGOD_PORT.service























