#!/bin/bash
MONGO_BIN="/usr/local/mongodb/bin/mongo"
MONGOD_BIN="/usr/local/mongodb/bin/mongod"
MONGOS_BIN="/usr/local/mongodb/bin/mongos"
MONGO_DATA_DIR="/data/mongodb"
MONGO_SHARD1_PORT=28017
MONGO_SHARD2_PORT=28018
MONGOS_PORT=28885
MONGO_CONFIG_SERVER_PORT=20000
echo "-----------------------------------------"
echo "+---------部署三节点mongodb集群-----------+"
echo "-----------------------------------------"

read -t 30 -p "是否要清除之前已存在的mongodb数据:[y/n,默认值:y]" isdelete
echo "正在清除残存的mongo进程..."
kill  $(ps -ef | grep mongo | grep -v grep|awk '{print $2}' )

case "isdelete" in
    "y")
        rm "${MONGO_DATA_DIR}" -rf
        ;;
    "n")
        ;;
    *)
         rm "${MONGO_DATA_DIR}" -rf
        ;;
esac
read -t 30 -p "是否打开mongo所需要的端口[y/n,默认值:y]" openfirewall
case "isdelete" in
    "y")
        echo "防火墙正在开放mongodb使用的端口..."
        firewall-cmd --add-port 28017/tcp --permanent
        firewall-cmd --add-port 28018/tcp --permanent
        firewall-cmd --add-port 28031/tcp --permanent
        firewall-cmd --add-port 28032/tcp --permanent
        firewall-cmd --add-port 20000/tcp --permanent
        firewall-cmd --add-port 28885/tcp --permanent
        service firewalld reload
        ;;
    *)
        ;;
esac
echo "-------------------------------------------------"
echo "服务器已开放端口:"
ss -ntl
read -t 30 -p "请输入当前待部署节点为:[节点1/2/3]" digit

case "$digit" in
        "1")
        echo "创建公用文件夹..."
        mkdir -p ${MONGO_DATA_DIR}/{shard11,shard21}
        mkdir -p ${MONGO_DATA_DIR}/{conf,logs}
                echo "生成shard11配置文件"
cat>${MONGO_DATA_DIR}/conf/shard11.conf <<EOF
shardsvr=true
replSet=shard1
port=${MONGO_SHARD1_PORT}
dbpath=${MONGO_DATA_DIR}/shard11
oplogSize=2048
logpath=${MONGO_DATA_DIR}/logs/shard11.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF
echo "生成shard21的配置文件"
# [服务器1] - 生成shard21的配置文件
cat > ${MONGO_DATA_DIR}/conf/shard21.conf <<EOF
shardsvr=true
replSet=shard2
port=${MONGO_SHARD2_PORT}
dbpath=${MONGO_DATA_DIR}/shard21
oplogSize=2048
logpath=${MONGO_DATA_DIR}/logs/shard21.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF
       echo "生成config service配置文件"
mkdir -p ${MONGO_DATA_DIR}/config-server1
# [服务器1] - 生成config server配置文件
cat>${MONGO_DATA_DIR}/conf/config-server1.conf <<EOF
directoryperdb=true
replSet=config
configsvr=true
dbpath=${MONGO_DATA_DIR}/config-server1
port=${MONGO_CONFIG_SERVER_PORT}
logpath=${MONGO_DATA_DIR}/logs/config-server1.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF
    echo "生成mongos配置文件"
# [服务器1] - mongos 相关文件夹生成
mkdir -p ${MONGO_DATA_DIR}/mongos

# [服务器1] - 生成mongos配置文件
cat>${MONGO_DATA_DIR}/conf/mongos1.conf <<EOF
configdb=config/node1:${MONGO_CONFIG_SERVER_PORT},node2:${MONGO_CONFIG_SERVER_PORT},node3:${MONGO_CONFIG_SERVER_PORT}
port=${MONGOS_PORT}
logpath=${MONGO_DATA_DIR}/logs/mongos1.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF
echo "开启rs - shard1集群服务..."
${MONGOD_BIN} --config /data/mongodb/conf/shard11.conf &
${MONGOD_BIN} --config /data/mongodb/conf/shard21.conf &
${MONGOD_BIN} --config /data/mongodb/conf/config-server1.conf &
${MONGOS_BIN} --config /data/mongodb/conf/mongos1.conf &
${MONGO_BIN} node1:${MONGO_SHARD1_PORT}/admin<<EOF
config = {_id: "shard1", members:[
                     {_id: 0, host:"node1:${MONGO_SHARD1_PORT}"},
                     {_id: 1, host:"node2:${MONGO_SHARD1_PORT}"},
                     {_id: 2, host:"node3:${MONGO_SHARD1_PORT}",arbiterOnly:true},
              ],
              writeConcernMajorityJournalDefault:false,
              protocolVersion:1
};
rs.initiate(config);
EOF
echo "开启rs - shard2集群服务..."
${MONGO_BIN} node1:${MONGO_SHARD2_PORT}/admin<<EOF
config = {_id: "shard1", members:[
                     {_id: 0, host:"node1:${MONGO_SHARD2_PORT}"},
                     {_id: 1, host:"node2:${MONGO_SHARD2_PORT}"},
                     {_id: 2, host:"node3:${MONGO_SHARD2_PORT}",arbiterOnly:true},
              ],
              writeConcernMajorityJournalDefault:false,
              protocolVersion:1
};
rs.initiate(config);
EOF
echo "配置config service 的rs"
${MONGO_BIN} node1:${MONGO_CONFIG_SERVER_PORT}/admin<<EOF
 config = {_id: "config",members:[
      {_id:0,host:"node1:20000"},
      {_id:1,host:"node2:20000"},
      {_id:2,host:"node3:20000"}
    ],protocolVersion:1,
    configsvr:true
    };
rs.initiate(config);
EOF
echo "配置mongos..."
${MONGO_BIN} node1:${MONGOS_PORT}/admin<<EOF
sh.addShard("shard1/node1:28017,node2:28017");
sh.addShard("shard2/node1:28018,node2:28018");
EOF
                ;;
        "2")
        echo "创建公用文件夹..."
        mkdir -p ${MONGO_DATA_DIR}/{shard12,shard22}
        mkdir -p ${MONGO_DATA_DIR}/{conf,logs}
                 echo "生成shard12配置文件"
#[服务器2] - 生成shard12的配置文件
cat>${MONGO_DATA_DIR}/conf/shard12.conf <<EOF
shardsvr=true
replSet=shard1
port=${MONGO_SHARD1_PORT}
dbpath=${MONGO_DATA_DIR}/shard12
oplogSize=2048
logpath=${MONGO_DATA_DIR}/logs/shard12.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF
echo "生成shard22配置文件"
# [服务器2] - 生成shard22的配置文件
cat > ${MONGO_DATA_DIR}/conf/shard22.conf <<EOF
shardsvr=true
replSet=shard2
port=${MONGO_SHARD2_PORT}
dbpath=${MONGO_DATA_DIR}/shard22
oplogSize=2048
logpath=${MONGO_DATA_DIR}/logs/shard22.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF
echo "生成config server配置文件"
# [服务器2] - config server 相关文件夹生成
mkdir -p ${MONGO_DATA_DIR}/config-server2

# [服务器2] - 生成config server配置文件
cat>${MONGO_DATA_DIR}/conf/config-server2.conf <<EOF
directoryperdb=true
replSet=config
configsvr=true
dbpath=${MONGO_DATA_DIR}/config-server2
port=${MONGO_CONFIG_SERVER_PORT}
logpath=${MONGO_DATA_DIR}/logs/config-server2.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF
echo "生成mongos配置文件"
# [服务器2] - mongos 相关文件夹生成
mkdir -p ${MONGO_DATA_DIR}/mongos

# [服务器2] - 生成config server配置文件
cat>${MONGO_DATA_DIR}/conf/mongos2.conf <<EOF
configdb=config/node1:${MONGO_CONFIG_SERVER_PORT},node2:${MONGO_CONFIG_SERVER_PORT},node3:${MONGO_CONFIG_SERVER_PORT}
port=${MONGOS_PORT}
logpath=${MONGO_DATA_DIR}/logs/mongos2.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF
echo "开启服务中"
${MONGOD_BIN} --config /data/mongodb/conf/shard12.conf &
${MONGOD_BIN} --config /data/mongodb/conf/shard22.conf &
${MONGOD_BIN} --config /data/mongodb/conf/config-server2.conf &
${MONGOS_BIN} --config /data/mongodb/conf/mongos2.conf &
                ;;

        "3")
        echo "创建公用文件夹..."
        mkdir -p ${MONGO_DATA_DIR}/{shard13,shard23}
        mkdir -p ${MONGO_DATA_DIR}/{conf,logs}
                echo "生成shard13配置文件"
#[服务器3] - 生成shard13的配置文件
cat>${MONGO_DATA_DIR}/conf/shard13.conf <<EOF
shardsvr=true
replSet=shard1
port=${MONGO_SHARD1_PORT}
dbpath=${MONGO_DATA_DIR}/shard13
oplogSize=2048
logpath=${MONGO_DATA_DIR}/logs/shard13.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF
echo "生成shard23配置文件"
# [服务器3] - 生成shard23的配置文件
cat > ${MONGO_DATA_DIR}/conf/shard23.conf <<EOF
shardsvr=true
replSet=shard2
port=${MONGO_SHARD2_PORT}
dbpath=${MONGO_DATA_DIR}/shard23
oplogSize=2048
logpath=${MONGO_DATA_DIR}/logs/shard23.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF
echo "生成config server配置文件"
# [服务器3] - config server 相关文件夹生成
mkdir -p ${MONGO_DATA_DIR}/config-server3

# [服务器3] - 生成config server配置文件
cat>${MONGO_DATA_DIR}/conf/config-server3.conf <<EOF
directoryperdb=true
replSet=config
configsvr=true
dbpath=${MONGO_DATA_DIR}/config-server3
port=${MONGO_CONFIG_SERVER_PORT}
logpath=${MONGO_DATA_DIR}/logs/config-server3.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF
 echo "生成mongos配置文件"
# [服务器3] - mongos 相关文件夹生成
mkdir -p ${MONGO_DATA_DIR}/mongos

# [服务器3] - 生成config server配置文件
cat>${MONGO_DATA_DIR}/conf/mongos3.conf <<EOF
configdb=config/node1:${MONGO_CONFIG_SERVER_PORT},node2:${MONGO_CONFIG_SERVER_PORT},node3:${MONGO_CONFIG_SERVER_PORT}
port=${MONGOS_PORT}
logpath=${MONGO_DATA_DIR}/logs/mongos3.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF
echo "开启服务中"
${MONGOD_BIN} --config /data/mongodb/conf/shard13.conf &
${MONGOD_BIN} --config /data/mongodb/conf/shard23.conf &
${MONGOD_BIN} --config /data/mongodb/conf/config-server3.conf &
${MONGOS_BIN} --config /data/mongodb/conf/mongos3.conf &
                ;;
        *)
                #其它输入
                echo "未安装任何节点"
                ;;
esac