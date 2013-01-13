#!/bin/bash
# Simple script
# to manage Trac users

# bash insanity

if [ -r ~/.trac-usermanage ]; then
 . ~/.trac-usermanage
elif [ -r /etc/trac-usermanage.conf ]; then
 . /etc/trac-usermanage.conf
else
 filename=$(basename $0)
 echo "Please run $filename -s to create configuration"
fi


function check_root(){
        if [ "$(whoami)" != "root" ]; then
                echo "This script must be run as root" 1>&2
                exit 1
        fi
}

function print_trac_users(){
 echo "Trac Users:"
 for user in `cat $trac_path/conf/trac.htdigest|sed -e "s/:.*//g"`
 do
  echo -e "\t $user"
 done
}

function manage_user(){
 htdigest "$trac_path/conf/trac.htdigest" "$realm" $1
 trac-admin $trac_path permission add $1 $2
}

function main(){
 if [[ $1 == "-h" || -z $1 ]]; then
  filename=$(basename $0)
  echo -e "$filename -lihs [user] [capability]"
  echo -e "\t\t -h Displays this command"
  echo -e "\t\t -i Interactive Run"
  echo -e "\t\t -s Create configuration file"
  echo -e "\t\t -l List current users!"
 elif [ $1 == "-i" ]; then
  echo "This method has not been implimented yet"
 elif [ $1 == "-s" ]; then
  echo "Interactive Configuration Creation"
  echo "Trac Project Path:"
  read trac_path
  echo "Trac Realm:"
  read trac_realm

  echo -e "trac_path=\"$trac_path\"\nrealm=\"$trac_realm\"" \
  > /etc/trac-usermanage.conf

 elif [ $1 == "-l" ]; then
  print_trac_users
 else
  if [ -n $2 ]; then
   manage_user $1 $2
  else
   echo "Incorrect Arguments"
  fi
 fi
}

# Now run the actual script, like usual
check_root
main $1 $2

