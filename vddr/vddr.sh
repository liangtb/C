#!/bin/sh
R_BOLD="\033[31m\033[1m"
G_BOLD="\033[32m\033[1m"
BOLD="\033[33m\033[1m"
NORM="\033[0m"
INFO="$BOLD Info: $NORM"
ERROR="$BOLD *** Error: $NORM"
INPUT="$BOLD => $NORM"

SWAP_FILE=`nvram get apps_swap_file`
SWAP_SIZE=`nvram get apps_swap_size`
i=1
cd /tmp

echo -e "$INFO This script will guide you through the swap installation."
echo -e "$INFO Script modifies \"swap\" folder only on the chosen drive,"

echo -e "$INFO Looking for available partitions..."
for mounted in `/bin/mount |awk '{if($0 ~/mnt/){ print $3}}'` ; do
  echo -e "$G_BOLD [$i] --> $mounted $NORM"
  eval mounts$i=$mounted
  i=`expr $i + 1`
done

if [ $i == "1" ] ; then
  echo -e "$ERROR $R_BOLD No partitions available. Exiting...$NORM"
  exit 1
fi

echo -en "$INPUT $BOLD Please enter partition number or 0 to exit $NORM\n$BOLD[0-`expr $i - 1`]$NORM: "
read partitionNumber
if [ "$partitionNumber" == "0" ] ; then
  echo -e $INFO Exiting...
  exit 0
fi
if [ "$partitionNumber" = "" ] || [ "`echo $partitionNumber|sed 's/[0-9]//g'`" != "" ] ; then  
  echo -e "$ERROR $R_BOLD Invalid arguments! Exiting...$NORM"
  exit 1
fi
if [ "$partitionNumber" -gt `expr $i - 1` ] ; then
  echo -e "$ERROR $R_BOLD Invalid partition number! Exiting...$NORM"
  exit 1
fi

eval entPartition=\$mounts$partitionNumber
echo -e "$INFO $G_BOLD $entPartition $NORM selected."
APPS_INSTALL_PATH=$entPartition/swap

case "$1" in
  start)

mem_size=`free |awk '$0 ~/Swap/{print $4}'`
pool_size=`df |awk '{if($0 ~"'$entPartition'") {print $4}}'`
if [ $pool_size -gt $SWAP_SIZE ]; then
        [ -e "$APPS_INSTALL_PATH/$SWAP_FILE" ] && swapoff $APPS_INSTALL_PATH/$SWAP_FILE
        [ -d "$APPS_INSTALL_PATH" ] && rm -rf $APPS_INSTALL_PATH
        echo -e "$INFO Creating $APPS_INSTALL_PATH folder..."
        mkdir -p $APPS_INSTALL_PATH
        echo -en "$INFO Swap size is [$BOLD$SWAP_SIZE$NORM],changed:\c $BOLD"
        read answer
        if [ "$answer" = "" ]
        then
        {
        echo -e "$INFO Swap size was not changed"
        }
        else
        {
             if [ "$answer" != "" ] && [ "`echo $answer|sed 's/[0-9]//g'`" = "" ] && [ $answer -lt $pool_size ]
             then
             {
                  SWAP_SIZE=$answer                                                                  
                  echo -en "$INFO Swap size was changed $BOLD[$SWAP_SIZE]$NORM \n"
             }
            else
            {
                  echo -e "$ERROR $R_BOLD Invalid arguments $NORM"
                  exit 1
            }
            fi
        }
        fi
       swap_count=`expr $SWAP_SIZE / 1000 - 1`
       echo -e "$INFO dd if=/dev/zero of=$APPS_INSTALL_PATH/$SWAP_FILE bs=1M count=$swap_count"
       dd if=/dev/zero of=$APPS_INSTALL_PATH/$SWAP_FILE bs=1M count=$swap_count
       echo -e "$INFO mkswap $APPS_INSTALL_PATH/$SWAP_FILE"
       mkswap $APPS_INSTALL_PATH/$SWAP_FILE
       echo -e "$INFO $G_BOLD swapon $APPS_INSTALL_PATH/$SWAP_FILE $NORM"
       swapon $APPS_INSTALL_PATH/$SWAP_FILE
       echo -e "**********************************************************"
        echo -e "  ${G_BOLD}Swap:$NORM  Total($G_BOLD$(free |grep -A1 "Swap" |awk   '{print $2}')$NORM)  Used($G_BOLD$(free |grep -A1 "Swap" |awk   '{print $3}')$NORM)  Free($G_BOLD$(free |grep -A1 "Swap" |awk   '{print $4}')$NORM)"
       echo -e "**********************************************************"
       fi
       echo -e "$INFO Create boot entry, y? :\c "
       read yor
       if [ "$yor" = "y" ] 
       then
       {
       [ -e "/jffs/scripts/services-start" ] && [ `cat /jffs/scripts/services-start |awk '{if($0 ~/swapon/) {print $0}}'|wc -l` -ge 1 ] &&\
       sed -i 'N;/\n.*swapon/!P;D' /jffs/scripts/services-start && sed -i '/swapon/d' /jffs/scripts/services-start 
       [ ! -e "/jffs/scripts/services-start" ] && echo "#!/bin/sh" > /jffs/scripts/services-start
       [ `grep "#!/bin/sh" /jffs/scripts/services-start |wc -l` -lt 1 ] && sed -i '1i#!\/bin\/sh' /jffs/scripts/services-start
       sed -i '1asleep 30' /jffs/scripts/services-start
       sed -i '2aswapon '$APPS_INSTALL_PATH'/'$SWAP_FILE'' /jffs/scripts/services-start
           chmod 755 /jffs/scripts/services-start
       echo -e "$INFO $G_BOLD Boot entry is created $NORM"
       }
       else
       {
       echo -e "$INFO $G_BOLD Boot entry was not created,Exiting $NORM"
       exit 1
       }
       fi
       ;;
  stop)
       [ -e "/jffs/scripts/services-start" ] && [ `cat /jffs/scripts/services-start |awk '{if($0 ~/swapon/) {print $0}}'|wc -l` -ge 1 ] &&\
       sed -i 'N;/\n.*swapon/!P;D' /jffs/scripts/services-start && sed -i '/swapon/d' /jffs/scripts/services-start
       [ -e "$APPS_INSTALL_PATH/$SWAP_FILE" ] && swapoff $APPS_INSTALL_PATH/$SWAP_FILE                        
       [ -d "$APPS_INSTALL_PATH" ] && rm -rf $APPS_INSTALL_PATH       
       echo -e "**********************************************************"
        echo -e "  ${G_BOLD}Swap:$NORM  Total($G_BOLD$(free |grep -A1 "Swap" |awk   '{print $2}')$NORM)  Used($G_BOLD$(free |grep -A1 "Swap" |awk   '{print $3}')$NORM)  Free($G_BOLD$(free |grep -A1 "Swap" |awk   '{print $4}')$NORM)"
       echo -e "**********************************************************"
       ;;
  *)
  exit 1
  ;;
esac
