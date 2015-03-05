#!/bin/bash
clear
echo "";
echo "现在将为您的VPS安装Casio IPSec VPN"
echo "[提示] 仅测试了Ubuntu及CentOS系统"
echo "            Written by Lokyshin"
echo ""

function ConfirmSys()
{
echo "[提示] 请确认您的系统: (1~2)"
select selectedSys in 'Ubuntu' 'CentOS'; do break; done

if [ "$selectedSys" == 'Ubuntu' ]; then
echo "您选择的系统为：${selectedSys}"
elif [ "$selectedSys" == 'CentOS' ]; then
echo "您选择的系统为：${selectedSys}"
else
echo "您输入了错误选项"
exit
fi
}

function ConfirmCore()
{
echo "[提示] 请确认您的内核: (1~2)"
select selectedCore in 'Xen/KVM' 'OpenVZ'; do break; done

if [ "$selectedCore" == 'Xen/KVM' ]; then
echo "您确认的内核为：${selectedSys}"
elif [ "$selectedCore" == 'OpenVZ' ]; then
echo "您确认的内核为：${selectedSys}"
else
echo "您输入了错误选项"
exit
fi
}

function ConfirmAgain()
{
echo "[提示] 请再次确认上面的选择是否正确: (1~2)"
select selectedAgain in '正确' '错误'; do break; done

if [ "$selectedAgain" == '错误' ]; then
echo "您输入了错误选项，即将退出。"
exit
fi
}

#开始编译安装Strongswan
echo "#开始编译安装Strongswan"
ConfirmSys;
ConfirmCore;
ConfirmAgain;

if [ "$selectedSys" == 'Ubuntu' ]; then
apt-get update
apt-get install libpam0g-dev libssl-dev make gcc
else
yum update
yum install pam-devel openssl-devel make gcc
fi

wget http://download.strongswan.org/strongswan.tar.gz
tar xzf strongswan.tar.gz
cd strongswan-*

./configure  --enable-eap-identity --enable-eap-md5 --enable-eap-mschapv2 --enable-eap-tls --enable-eap-ttls --enable-eap-peap  --enable-eap-tnc --enable-eap-dynamic --enable-eap-radius --enable-xauth-eap  --enable-xauth-pam  --enable-dhcp  --enable-openssl  --enable-addrblock --enable-unity  --enable-certexpire --enable-radattr --enable-tools --enable-openssl --disable-gmp

if [ "$selectedCore" == 'OpenVZ' ]; then
./configure --enable-kernel-libipsec
fi

make; make install
clear
ipsec version
echo ""
echo "如您看到了Ipsec的版本信息，代表Ipsec工作正常。"

#开始配置证书
echo "#开始配置证书"
echo "开始签名CA证书"
echo -n "请输入您需要配置的C值（任意）:"
read C
echo -n "请输入您需要配置的O值（任意）:"
read O
echo -n "请输入您需要配置的CN值（任意）:"
read CN
echo -n "请输入现在服务器ip地址或域名（请务必准确）:"
read CNsan
echo -n "请输入您使用CA签名客户端证书的CN值（任意）:"
read CACN
echo -n "请输入您生成pkcs12证书名（任意）:"
read pkcsname
echo "[提示] 接下来设置两次证书密码，请注意字符不显示。"
ipsec pki --gen --outform pem >ca.pem && ipsec pki --self --in ca.pem --dn "C=$C, O=$O, CN=$CN" --ca --outform pem >ca.cert.pem && ipsec pki --gen --outform pem > server.pem && ipsec pki --pub --in server.pem | ipsec pki --issue --cacert ca.cert.pem --cakey ca.pem --dn "C=$C, O=$O, CN=$CNsan" —san=\"$CNsan\" --flag serverAuth --flag ikeIntermediate --outform pem > server.cert.pem && ipsec pki --gen --outform pem > client.pem && ipsec pki --pub --in client.pem | ipsec pki --issue --cacert ca.cert.pem --cakey ca.pem --dn "C=$C, O=$O, CN=$CACN" --outform pem >client.cert.pem && openssl pkcs12 -export -inkey client.pem -in client.cert.pem -name "$pkcsname" -certfile ca.cert.pem -caname "$CN" -out client.cert.p12

cp -r ca.cert.pem /usr/local/etc/ipsec.d/cacerts/ && cp -r server.cert.pem /usr/local/etc/ipsec.d/certs/ && cp -r server.pem /usr/local/etc/ipsec.d/private/ && cp -r client.cert.pem /usr/local/etc/ipsec.d/certs/ && cp -r client.pem  /usr/local/etc/ipsec.d/private/
echo "完成。"

#开始配置Strongswan
echo "配置Strongswan..."
echo "config setup" > /usr/local/etc/ipsec.conf
echo "    uniqueids=never" >> /usr/local/etc/ipsec.conf
echo "    " >> /usr/local/etc/ipsec.conf
echo "conn iOS_cert" >> /usr/local/etc/ipsec.conf
echo "    keyexchange=ikev1" >> /usr/local/etc/ipsec.conf
echo "    # strongswan version >= 5.0.2, compatible with iOS 6.0,6.0.1" >> /usr/local/etc/ipsec.conf
echo "    fragmentation=yes" >> /usr/local/etc/ipsec.conf
echo "    left=%defaultroute" >> /usr/local/etc/ipsec.conf
echo "    leftauth=pubkey" >> /usr/local/etc/ipsec.conf
echo "    leftsubnet=0.0.0.0/0" >> /usr/local/etc/ipsec.conf
echo "    leftcert=server.cert.pem" >> /usr/local/etc/ipsec.conf
echo "    right=%any" >> /usr/local/etc/ipsec.conf
echo "    rightauth=pubkey" >> /usr/local/etc/ipsec.conf
echo "    rightauth2=xauth" >> /usr/local/etc/ipsec.conf
echo "    rightsourceip=10.31.2.0/24" >> /usr/local/etc/ipsec.conf
echo "    rightcert=client.cert.pem" >> /usr/local/etc/ipsec.conf
echo "    auto=add" >> /usr/local/etc/ipsec.conf
echo "    " >> /usr/local/etc/ipsec.conf
echo "conn android_xauth_psk" >> /usr/local/etc/ipsec.conf
echo "    keyexchange=ikev1" >> /usr/local/etc/ipsec.conf
echo "    left=%defaultroute" >> /usr/local/etc/ipsec.conf
echo "    leftauth=psk" >> /usr/local/etc/ipsec.conf
echo "    leftsubnet=0.0.0.0/0" >> /usr/local/etc/ipsec.conf
echo "    right=%any" >> /usr/local/etc/ipsec.conf
echo "    rightauth=psk" >> /usr/local/etc/ipsec.conf
echo "    rightauth2=xauth" >> /usr/local/etc/ipsec.conf
echo "    rightsourceip=10.31.2.0/24" >> /usr/local/etc/ipsec.conf
echo "    auto=add" >> /usr/local/etc/ipsec.conf
echo "    " >> /usr/local/etc/ipsec.conf
echo "conn networkmanager-strongswan" >> /usr/local/etc/ipsec.conf
echo "    keyexchange=ikev2" >> /usr/local/etc/ipsec.conf
echo "    left=%defaultroute" >> /usr/local/etc/ipsec.conf
echo "    leftauth=pubkey" >> /usr/local/etc/ipsec.conf
echo "    leftsubnet=0.0.0.0/0" >> /usr/local/etc/ipsec.conf
echo "    leftcert=server.cert.pem" >> /usr/local/etc/ipsec.conf
echo "    right=%any" >> /usr/local/etc/ipsec.conf
echo "    rightauth=pubkey" >> /usr/local/etc/ipsec.conf
echo "    rightsourceip=10.31.2.0/24" >> /usr/local/etc/ipsec.conf
echo "    rightcert=client.cert.pem" >> /usr/local/etc/ipsec.conf
echo "    auto=add" >> /usr/local/etc/ipsec.conf
echo "    " >> /usr/local/etc/ipsec.conf
echo "conn windows7" >> /usr/local/etc/ipsec.conf
echo "    keyexchange=ikev2" >> /usr/local/etc/ipsec.conf
echo "    ike=aes256-sha1-modp1024!" >> /usr/local/etc/ipsec.conf
echo "    rekey=no" >> /usr/local/etc/ipsec.conf
echo "    left=%defaultroute" >> /usr/local/etc/ipsec.conf
echo "    leftauth=pubkey" >> /usr/local/etc/ipsec.conf
echo "    leftsubnet=0.0.0.0/0" >> /usr/local/etc/ipsec.conf
echo "    leftcert=server.cert.pem" >> /usr/local/etc/ipsec.conf
echo "    right=%any" >> /usr/local/etc/ipsec.conf
echo "    rightauth=eap-mschapv2" >> /usr/local/etc/ipsec.conf
echo "    rightsourceip=10.31.2.0/24" >> /usr/local/etc/ipsec.conf
echo "    rightsendcert=never" >> /usr/local/etc/ipsec.conf
echo "    eap_identity=%any" >> /usr/local/etc/ipsec.conf
echo "    auto=add" >> /usr/local/etc/ipsec.conf
echo "完成。"

echo "配置Strongswan的配置文件..."
echo "charon {" > /usr/local/etc/strongswan.conf
echo "    load_modular = yes" >> /usr/local/etc/strongswan.conf
echo "    duplicheck.enable = no" >> /usr/local/etc/strongswan.conf
echo "    compress = yes" >> /usr/local/etc/strongswan.conf
echo "    plugins {" >> /usr/local/etc/strongswan.conf
echo "        include strongswan.d/charon/*.conf" >> /usr/local/etc/strongswan.conf
echo "    }" >> /usr/local/etc/strongswan.conf
echo "    dns1 = 8.8.8.8" >> /usr/local/etc/strongswan.conf
echo "    dns2 = 8.8.4.4" >> /usr/local/etc/strongswan.conf
echo "    nbns1 = 8.8.8.8" >> /usr/local/etc/strongswan.conf
echo "    nbns2 = 8.8.4.4" >> /usr/local/etc/strongswan.conf
echo "}" >> /usr/local/etc/strongswan.conf
echo "include strongswan.d/*.conf" >> /usr/local/etc/strongswan.conf
echo "完成。"

#开始配置PSK和XAUTH，以及用户名和密码
echo "#开始配置PSK和XAUTH，以及用户名和密码"
echo -n "输入您想配置的PSK:"
read mypsk
echo -n "输入您想配置的XAUTH:"
read myxauth
echo ": RSA server.pem" > /usr/local/etc/ipsec.secrets
echo ": PSK \"$mypsk\"" >> /usr/local/etc/ipsec.secrets
echo ": XAUTH \"$myxauth\"" >> /usr/local/etc/ipsec.secrets

for ((i=1;i<1000;i++))
do
echo -n "输入您想配置的用户名:"
read name[$i]
echo -n "输入该用户的授权秘钥:"
read psw[$i]
echo "${name[$i]} %any : EAP \"${psw[$i]}\"" >> /usr/local/etc/ipsec.secrets
echo -n "需要追加用户请直接回车，如不需要请输入n并回车。"
read addconfirm
if [ "$addconfirm" == 'n' ]; then
n=$i
i=2000
fi
done
echo "完成。"

#开始配置防火墙
echo "#开始配置防火墙"
sed -i '/Controls IP packet forwarding/d' /etc/sysctl.conf
sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
echo "# Controls IP packet forwarding" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s 10.31.0.0/24  -j ACCEPT
iptables -A FORWARD -s 10.31.1.0/24  -j ACCEPT
iptables -A FORWARD -s 10.31.2.0/24  -j ACCEPT
iptables -A INPUT -i venet0 -p esp -j ACCEPT
iptables -A INPUT -i venet0 -p udp --dport 500 -j ACCEPT
iptables -A INPUT -i venet0 -p tcp --dport 500 -j ACCEPT
iptables -A INPUT -i venet0 -p udp --dport 4500 -j ACCEPT
iptables -A INPUT -i venet0 -p udp --dport 1701 -j ACCEPT
iptables -A INPUT -i venet0 -p tcp --dport 1723 -j ACCEPT
iptables -A FORWARD -j REJECT

if [ "$selectedCore" == 'OpenVZ' ]; then
iptables -t nat -A POSTROUTING -s 10.31.0.0/24 -o venet0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.31.1.0/24 -o venet0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.31.2.0/24 -o venet0 -j MASQUERADE
else
iptables -t nat -A POSTROUTING -s 10.31.0.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.31.1.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.31.2.0/24 -o eth0 -j MASQUERADE
fi

if [ "$selectedSys" == 'Ubuntu' ]; then
iptables-save > /etc/iptables.rules
cat > /etc/network/if-up.d/iptables<<EOF
#!/bin/sh
iptables-restore < /etc/iptables.rules
EOF
chmod +x /etc/network/if-up.d/iptables
else
service iptables save
fi
echo "完成。"

#在登陆目录生成开机手动启动文件
echo "#在登陆目录生成开机手动启动文件"
cd ~
echo "#!/bin/bash" > startvpn.sh
echo "echo \"Starting Cisco Ipsec VPN ...\"" >> startvpn.sh
echo "ipsec restart" >> startvpn.sh
echo "iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" >> startvpn.sh
echo "iptables -A FORWARD -s 10.31.0.0/24  -j ACCEPT" >> startvpn.sh
echo "iptables -A FORWARD -s 10.31.1.0/24  -j ACCEPT" >> startvpn.sh
echo "iptables -A FORWARD -s 10.31.2.0/24  -j ACCEPT" >> startvpn.sh
echo "iptables -A INPUT -i venet0 -p esp -j ACCEPT" >> startvpn.sh
echo "iptables -A INPUT -i venet0 -p udp --dport 500 -j ACCEPT" >> startvpn.sh
echo "iptables -A INPUT -i venet0 -p tcp --dport 500 -j ACCEPT" >> startvpn.sh
echo "iptables -A INPUT -i venet0 -p udp --dport 4500 -j ACCEPT" >> startvpn.sh
echo "iptables -A INPUT -i venet0 -p udp --dport 1701 -j ACCEPT" >> startvpn.sh
echo "iptables -A INPUT -i venet0 -p tcp --dport 1723 -j ACCEPT" >> startvpn.sh
echo "iptables -A FORWARD -j REJECT" >> startvpn.sh

if [ "$selectedCore" == 'OpenVZ' ]; then
echo "iptables -t nat -A POSTROUTING -s 10.31.0.0/24 -o venet0 -j MASQUERADE" >> startvpn.sh
echo "iptables -t nat -A POSTROUTING -s 10.31.1.0/24 -o venet0 -j MASQUERADE" >> startvpn.sh
echo "iptables -t nat -A POSTROUTING -s 10.31.2.0/24 -o venet0 -j MASQUERADE" >> startvpn.sh
else
echo "iptables -t nat -A POSTROUTING -s 10.31.0.0/24 -o eth0 -j MASQUERADE" >> startvpn.sh
echo "iptables -t nat -A POSTROUTING -s 10.31.1.0/24 -o eth0 -j MASQUERADE" >> startvpn.sh
echo "iptables -t nat -A POSTROUTING -s 10.31.2.0/24 -o eth0 -j MASQUERADE" >> startvpn.sh
fi

echo "echo \"Cisco Ipsec VPN has been launched on your server now.\"" >> startvpn.sh

chmod -R 775 startvpn.sh
bash startvpn.sh
clear

echo "您的配置如下："
echo "您的PSK $mypsk"
echo "您的XAUTH $myxauth"
echo "================================="
echo " ｜ 用户名 ｜ 授权秘钥 ｜ "
for ((i=1;i<n+1;i++))
do
echo " ｜ ${name[$i]} ｜ ${psw[$i]} ｜ "
done
echo "================================="

echo "每次重启服务器后，不要忘了手动运行bash startvpn.sh"
echo "您的用户配置文件位置在/usr/local/etc/ipsec.secrets"
echo "祝您使用愉快，谢谢！"
echo "";
echo "Casio IPSec VPN"
echo "Ver 1.1"
echo "Written by Lokyshin"
echo ""
