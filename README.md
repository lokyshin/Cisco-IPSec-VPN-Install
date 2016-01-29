# Cisco-IPSec-VPN-Install
This is a one-key file to install Cisco IPSec VPN on CentOS/Ubuntu/Debian/Fedora Server.
It will be stable when you connect your iPhone/Anroid/PC/Mac to your CentOS/Ubuntu Server with this tool in China.
And the only thing you should do is typing several words based on the tips.
So enjoy it if you have one VPS (CentOS/Ubuntu/Debian/Fedora) with XEN/KVM/OpenVZ.

Tips: This code supports the following servers: Linode/DigitalOcean/Bandwagonhost and more.

Pls remember, you must run this codes with your root user.

If you want to one-key install Cisco IPSec VPN on your server, you could copy the following codes and run:

wget --no-check-certificate https://raw.githubusercontent.com/lokyshin/Cisco-IPSec-VPN-Install/master/CIVInstall.sh && chmod +x CIVInstall.sh && bash CIVInstall.sh 2>&1 | tee civaws_install.log
