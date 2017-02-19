#!/bin/bash
#Block bad web bots (wiki/forum/SEO spammers)
/usr/bin/wget -q -N -P /etc/firewall/source https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_abusers_1d.netset
/usr/bin/wget -q -N -P /etc/firewall/source https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/stopforumspam_7d.ipset
/usr/bin/wget -q -N -P /etc/firewall/source https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/sblam.ipset
/bin/grep -v '#' /etc/firewall/source/firehol_abusers_1d.netset > /etc/firewall/source/firehol_abusers_1d.txt
/bin/grep -v '#' /etc/firewall/source/stopforumspam_7d.ipset > /etc/firewall/source/stopforumspam_7d.txt
/bin/grep -v '#' /etc/firewall/source/sblam.ipset > /etc/firewall/source/sblam.txt
/bin/cat /etc/firewall/source/firehol_abusers_1d.txt /etc/firewall/source/stopforumspam_7d.txt /etc/firewall/source/sblam.txt > /etc/firewall/source/webbots.ips
/bin/sort /etc/firewall/source/webbots.ips | /usr/bin/uniq > /etc/firewall/webbots.txt
#Delete iptables rule for this ipset, if one exists
iptables -D INPUT $(iptables -L -v -n --line-numbers | grep webbots | awk '{print $1}')
#Delete and recreate the ipset
ipset -q -F webbots
ipset -q -X webbots
ipset -N webbots hash:net maxelem 131072
for i in $(cat /etc/firewall/webbots.txt ); do ipset -A webbots $i; done
#Add iptables rule to drop matching packets
iptables -I INPUT -p tcp -m set --match-set webbots src --match multiport --dports 22,25,80,110,443,995,143,993,587,465 -j DROP
