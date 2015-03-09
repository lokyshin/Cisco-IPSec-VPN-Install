# Cisco-IPSec-VPN-Install
This is a one-key file to install Cisco IPSec VPN on CentOS or Ubuntu Server.
It will be stable when you connect your iPhone/Anroid/PC/Mac to your CentOS/Ubuntu Server with this tool in China.
And the only thing you should do is typing several words based on the tips.
So enjoy it if you have one VPS with XEN/KVM/OpenVZ.

======================================================";
            Casio IPSec VPN 一键安装脚本
[提示] 经测试支持如下系统：CentOS/Ubuntu/Debian/Fedora
         并支持x86/64位版本，以及全部常用版本
                                   Written by Lokyshin
                                               Ver 2.0
"======================================================";

Tips: This code supports the following servers: Linode/DigitalOcean/Bandwagonhost and more.

Pls remember, you must run this codes with your root user.

If you want to one-key install Cisco IPSec VPN on your server, you could copy the following codes and run:

wget --no-check-certificate http://lokyshin.com/codes/CIVInstall.sh && chmod +x CIVInstall.sh && bash CIVInstall.sh 2>&1 | tee civaws_install.log
