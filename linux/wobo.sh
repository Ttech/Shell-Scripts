#!/bin/bash

lease_file="/var/lib/dhcp/dhcpd.leases"

function get_client_name(){
 ip=$1
 client=`cat $lease_file|grep -A 12 $ip|grep client|uniq|sed -e "s/^.*\"\(.*\)\".*$/\1/"`
 if [ ! "$client" = "" ]; then
  echo "$client"
 else
  echo "null"
 fi
}

function get_lease_date(){
 ip=$1
 date=`cat $lease_file|grep -A 8 $ip|grep start|awk '{ print $3" "$4 }'|tail -1|sed -e "s/;//g"`
 echo $date
}

function get_mac_address(){
 ip=$1
 mac=`cat $lease_file|grep -A 8 $ip|grep ethernet|uniq|sed -e "s/.*ethernet //g" -e "s/;//g"`
 echo $mac
}
function client_list(){
 check_ping=1

        echo "dialog --stdout --title \"Wake On Lan\" --menu \"Please select a computer to boot\" 15 55 5 \\"
  for ip in `cat $lease_file|grep ^lease|awk '{ print $2 }'|sort|uniq`
  do
          date=$(get_lease_date $ip)
             client=$(get_client_name $ip)
                mac=$(get_mac_address $ip)
                if [ ${check_ping} -eq 1 ]; then
                        ping -c 1 -W 1 -n $ip > /dev/null
                  if [ $? -eq 1 ]; then
                          if [ "$client" = "null" ]; then
         echo "\"$mac\" \"$ip (offline)\" \\"
        else
         echo "\"$mac\" \"$client (offline)\" \\"
        fi
                        else
                          if [ "$client" = "null" ]; then
         echo "\"$mac\" \"$ip (online)\" \\"
        else
         echo "\"$mac\" \"$client (online)\" \\"
        fi
                        fi
                else
                 if [ "$client" = "null" ]; then
      echo "\"$mac\" \"$ip\" \\"
     else
      echo "\"$mac\" \"$client\" \\"
     fi
    fi
  done
        echo "\"broadcast\" \"broadcast\""
}

function output(){
 message=$1
 sleep_time=2

 if which dialog 2>/dev/null; then
  dialog --infobox "$message" 3 $((${#message} + ${#level} + 7))
  sleep $sleep_time
 else
  echo -e "[$level]\t$message"
 fi
}

function broadcast_boot(){
 total=$(($(cat $lease_file|grep ^lease|awk '{ print $2 }'|sort|uniq|wc -l)))
 count=0
        (
        for ip in `cat $lease_file|grep ^lease|awk '{ print $2 }'|sort|uniq`
 do
  date=$(get_lease_date $ip)
                client=$(get_client_name $ip)
                mac=$(get_mac_address $ip)

  if [ "$client" = "null" ]; then
   system=$mac
  else
   system=$client
  fi

  percent=$(( 100*(++count)/total ))
  cat <<EOF
XXX
$percent
Attemping to boot client "$system"...
XXX
EOF
                        [ $count -eq 100 ] && break
   # delay it a specified amount of time i.e 1 sec
   wol "$mac" 
           sleep 1       
    done
        ) |
 dialog --title "Global Boot" --gauge "Please wait while all systems boot." 7 70 0
}


# actually run magic

menu=$(client_list)
result=$(echo $(eval $menu)|sed -e "s/ //g")
if [ -z "$result" ]; then
 output "I cowardly refuse to startup nothing!"
elif [ "$result" = "broadcast" ]; then
 broadcast_boot
else
 wol -w 2 "$result"
 output "Attemping to turn on system \"$result\"..."
fi

