### 将chaincode部署到其他机器上的方法

- 方法一：修改peer chaincode的代码

- 方法二：使用一个chaincode最为中间代理，将并将链码的tls证书文件转发到另一台机器上。


chaincode运行需要的参数
```bash
CORE_CHAINCODE_LOGGING_LEVEL=info
CORE_CHAINCODE_LOGGING_SHIM=warning
CORE_CHAINCODE_LOGGING_FORMAT="%{color}%{time:2006-01-02 15:04:05.000 MST} [%{module}] %{shortfunc} -> %{level:.4s} %{id:03x}%{color:reset} %{message}"
CORE_CHAINCODE_ID_NAME=mycc:1.0
CORE_PEER_TLS_ENABLED=true
CORE_TLS_CLIENT_KEY_PATH=/etc/hyperledger/fabric/client.key
CORE_TLS_CLIENT_CERT_PATH=/etc/hyperledger/fabric/client.crt
CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/peer.crt
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
CORE_CHAINCODE_BUILDLEVEL=1.2.1

#运行，建立grpc连接
chaincode -peer.address=peer0.org1.example.com:7052
```

这里可以解决的一个问题是，链码安装在peer上，会使的peer节点容器过多

查询过程：client-->peer-->chaincode中间-->chaincode终端(部署在其他机器上)-->