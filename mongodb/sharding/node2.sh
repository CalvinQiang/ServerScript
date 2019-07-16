mkdir soft
mv mongodb-linux-x86_64-4.0.10 /usr/local/mongodb
cat>>/etc/profile <<EOF
export PATH=$PATH:/usr/local/mongodb/bin
EOF
source /etc/profile

#创建mongodb数据节点的文件夹
   rm /data/mongodb -rf
   mkdir -p /data/mongodb/{shard12,shard22}
   mkdir -p /data/mongodb/{conf,logs}

   #[服务器2] - 生成shard12的配置文件
   cat>/data/mongodb/conf/shard12.conf <<EOF
   shardsvr=true
   replSet=shard1
   port=28017
   dbpath=/data/mongodb/shard12
   oplogSize=2048
   logpath=/data/mongodb/logs/shard12.log
   logappend=true
   fork=true
   bind_ip=0.0.0.0
   EOF
   # [服务器2] - 生成shard22的配置文件
   cat > /data/mongodb/conf/shard22.conf <<EOF
   shardsvr=true
   replSet=shard2
   port=28018
   dbpath=/data/mongodb/shard22
   oplogSize=2048
   logpath=/data/mongodb/logs/shard22.log
   logappend=true
   fork=true
   bind_ip=0.0.0.0
   EOF

   # [服务器2] - 仲裁节点文件夹生成
   mkdir -p /data/mongodb/{arbiter1,arbiter2}
   mkdir -p /data/mongodb/{conf,logs}

   #  [服务器2] - 生成arbiter1的配置文件
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

   # [服务器2] - 生成arbiter2的配置文件
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
   # [服务器2] - config server 相关文件夹生成
   mkdir -p /data/mongodb/config-server2

   # [服务器2] - 生成config server配置文件
   cat>/data/mongodb/conf/config-server2.conf <<EOF
   directoryperdb=true
   replSet=config
   configsvr=true
   dbpath=/data/mongodb/config-server2
   port=20000
   logpath=/data/mongodb/logs/config-server2.log
   logappend=true
   fork=true
   bind_ip=0.0.0.0
   EOF

   # [服务器2] - mongos 相关文件夹生成
   mkdir -p /data/mongodb/mongos

   # [服务器2] - 生成config server配置文件
   cat>/data/mongodb/conf/mongos2.conf <<EOF
   configdb=config/node1:20000,node2:20000,node3:20000
   port=28885
   logpath=/data/mongodb/logs/mongos2.log
   logappend=true
   fork=true
   bind_ip=0.0.0.0
   EOF