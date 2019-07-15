mkdir soft
mv mongodb-linux-x86_64-4.0.10 /usr/local/mongodb
cat>>/etc/profile <<EOF
export PATH=$PATH:/usr/local/mongodb/bin
EOF
source /etc/profile

#创建mongodb数据节点的文件夹
rm /data/mongodb -rf
mkdir -p /data/mongodb/{shard11,shard21}
mkdir -p /data/mongodb/{conf,logs}

#[服务器1] - 生成shard11的配置文件
cat>/data/mongodb/conf/shard11.conf <<EOF
shardsvr=true
replSet=shard1
port=28017
dbpath=/data/mongodb/shard11
oplogSize=2048
logpath=/data/mongodb/logs/shard11.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF
# [服务器1] - 生成shard21的配置文件
cat > /data/mongodb/conf/shard21.conf <<EOF
shardsvr=true
replSet=shard2
port=28018
dbpath=/data/mongodb/shard21
oplogSize=2048
logpath=/data/mongodb/logs/shard21.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF

# [服务器1] - 仲裁节点文件夹生成
mkdir -p /data/mongodb/{arbiter1,arbiter2}
mkdir -p /data/mongodb/{conf,logs}

#  [服务器1] - 生成arbiter1的配置文件
cat>/data/mongodb/conf/arbiter1.conf <<EOF
shardsvr=true
replSet=shard1
port=28031
dbpath=/data/mongodb/arbiter1
oplogSize=100
logpath=/data/mongodb/logs/arbiter1.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF

# [服务器1] - 生成arbiter2的配置文件
cat>/data/mongodb/conf/arbiter2.conf <<EOF
shardsvr=true
replSet=shard2
port=28032
dbpath=/data/mongodb/arbiter2
oplogSize=100
logpath=/data/mongodb/logs/arbiter2.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF
# [服务器1] - config server 相关文件夹生成
mkdir -p /data/mongodb/config-server1

# [服务器1] - 生成config server配置文件
cat>/data/mongodb/conf/config-server1.conf <<EOF
directoryperdb=true
replSet=config
configsvr=true
dbpath=/data/mongodb/config-server1
port=20000
logpath=/data/mongodb/logs/config-server1.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF

# [服务器1] - mongos 相关文件夹生成
mkdir -p /data/mongodb/mongos

# [服务器1] - 生成config server配置文件
cat>/data/mongodb/conf/mongos1.conf <<EOF
configdb=config/node1:20000,node2:20000,node3:20000
port=28885
logpath=/data/mongodb/logs/mongos1.log
logappend=true
fork=true
bind_ip=0.0.0.0
EOF