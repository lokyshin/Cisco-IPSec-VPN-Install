#!/bin/bash
clear
echo "";
echo "现在将为您的VPS安装Casio IPSec VPN"
echo "[提示] 请注意：仅支持Ubuntu及CentOS"
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


#开始配置证书
ipsec pki --gen --outform pem >ca.pem && ipsec pki --self --in ca.pem --dn "C=CH, O=lokyshin, CN=lokyshinCA" --ca --outform pem >ca.cert.pem && ipsec pki --gen --outform pem > server.pem && ipsec pki --pub --in server.pem | ipsec pki --issue --cacert ca.cert.pem --cakey ca.pem --dn "C=CH, O=lokyshin, CN=lokyshin.com" —san="lokyshin.com" --flag serverAuth --flag ikeIntermediate --outform pem > server.cert.pem && ipsec pki --gen --outform pem > client.pem && ipsec pki --pub --in client.pem | ipsec pki --issue --cacert ca.cert.pem --cakey ca.pem --dn "C=CH, O=lokyshin, CN=lokyshin.com client" --outform pem >client.cert.pem && openssl pkcs12 -export -inkey client.pem -in client.cert.pem -name "lkspk12forclient" -certfile ca.cert.pem -caname "lokyshinCA" -out client.cert.p12

cp -r ca.cert.pem /usr/local/etc/ipsec.d/cacerts/ && cp -r server.cert.pem /usr/local/etc/ipsec.d/certs/ && cp -r server.pem /usr/local/etc/ipsec.d/private/ && cp -r client.cert.pem /usr/local/etc/ipsec.d/certs/ && cp -r client.pem  /usr/local/etc/ipsec.d/private/

#开始配置Strongswan
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

#开始配置PSK和XAUTH，以及用户名和密码
echo -n "输入您想配置的PSK:"
read mypsk
echo -n "输入您想配置的xauth:"
read readmyxauth
echo ": RSA server.pem" > /usr/local/etc/ipsec.secrets
echo ": PSK \"$mypsk\"" >> /usr/local/etc/ipsec.secrets
echo ": XAUTH \$myxauth\"" >> /usr/local/etc/ipsec.secrets

for ((i=1;i<100;i++))
do
echo -n "输入您想配置的用户名:"
read name
echo -n "输入您想配置的用户的密码:"
read psw
echo "$name %any : EAP \"$psw\"" >> /usr/local/etc/ipsec.secrets
echo "如果需要添加用户，请在最后一行输入同上格式的"
echo -n "是否还是需要继续添加用户？ (y/n)"
read addconfirm
if [ "$addconfirm" == 'n' ]; then
i=200
fi
done

#开始配置防火墙
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


#登陆目录生成开机手动启动文件
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
clear
echo "每次重启服务器后，不要忘了手动运行./startvpn.sh"
echo "您的用户配置文件位置在/usr/local/etc/ipsec.secrets"
echo "祝您使用愉快，谢谢！"
echo "";
echo "现在将为您的VPS安装Casio IPSec VPN"
echo "[提示] 请注意：仅支持Ubuntu及CentOS"
echo "            Written by Lokyshin"
echo ""
