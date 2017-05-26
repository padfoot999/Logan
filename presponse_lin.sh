#!/bin/bash

# Check that there is at least 10GB (10485760K) available on /tmp
DF=$(df /)
while IFS=' ' read -ra RES; do
    LEN=${#RES[@]}
    AVAIL=`expr $LEN - 3`
    if [ ${RES[$AVAIL]} -lt 10485760 ]
    then
        echo Less than 10GB available. Exiting.
        exit
    fi
done <<< $DF


###### CURL VARIABLES ######
### If you want to use Curl, then set the variables below.
### Be sure to use a version of curl that supports SSL. Be sure to
### create the Box folder in a location that is accessible via the 
### Box API; the 'Client Uploads' folder qualifies. The version of 
### curl I used requires the -k flag in order to skip cert verification.
###
### UseCurl: 1=enable
### UserEmail: Set to email address of valid Box account email address
### FolderID: Set to the ID of the destination Box folder
UseCurl=0
UserEmail=
FolderID=


# To exclude paths from the directory listing, provide a file called 
# 'excludes.txt' that contains the paths to exclude. Each path should 
# be on a new line. The excludes file should be placed in the same 
# directory as the collection script.
EXCLUDES="-path /var/cache -o -path /var/spool"
if [ -f excludes.txt ]; then
    while read line
    do
        EXCLUDES="$EXCLUDES -o -path $line"
    done <excludes.txt
fi

#
# set environment variables, target directory, and config settings
#

# basename of results archive
IRCASE=`hostname`
# output destination, change according to needs
LOC=/tmp/$IRCASE
# tmp file to redirect results
TMP=$LOC/$IRCASE'_tmp.txt'
# redirect stderr
ERROR_LOG=$LOC/'errors.log'

# This sleep stuff is for the ls command. If a sleep value is 
# provided then the script will sleep between each 'get' of the 
# file listing (actually done by 'find').
if [ $# == 1 ]
then
    SLEEP=$1
else
    SLEEP=0
fi

{
    mkdir $LOC
    touch $ERROR_LOG 
    mkdir $LOC/userprofiles
} 2> /dev/null


#
# collect data for Phase 1 analysis
#

function collect {

    # current datetime
    date '+%Y-%m-%d %H:%M:%S %Z %:z' > $LOC/'date.txt'

    # running processes
    {
        PS_FORMAT=user,pid,ppid,vsz,rss,tname,stat,stime,time,args

        if ps axwwSo $PS_FORMAT &> /dev/null
        then
            # bsd
            ps axwwSo $PS_FORMAT
        elif ps -eF &> /dev/null
        then
            # gnu
            ps -eF
        else
            # bsd without ppid
            ps axuSww 
        fi
    } > $LOC/'ps.txt'

    # process tree
    pstree -aclpu > $LOC/'processtree.txt'

    # active network connections
    {
        if netstat -pvWanoee &> /dev/null
        then
            # gnu
            netstat -pvWanoee
        else
            # redhat/centos
            netstat -pvTanoee
        fi
    } > $LOC/'netstat.txt'

    # list of open files
    if [ -x /sbin/lsof ]
    then 
        # rhel5
        LSOF=/sbin/lsof
    else
        LSOF=`which lsof`
    fi
    # list of open files, link counts
    $LSOF +L > $LOC/'lsof-linkcounts.txt'
    # list of open files, with network connection
    $LSOF -i -P > $LOC/'lsof-netfiles.txt'
    # list parent id of open files
    $LSOF -R > $LOC/'lsof-parentid.txt'

    # list all services and runlevel
    if chkconfig -l &> /dev/null
    then
        chkconfig -l > $LOC/'chkconfig.txt'
    else
        chkconfig --list > $LOC/'chkconfig.txt'
    fi

    # cron
    # users with crontab access
    cp /etc/cron.allow $LOC/'cronallow.txt'
    # users with crontab access
    cp /etc/cron.deny $LOC/'crondeny.txt'
    # crontab listing
    cp /etc/crontab $LOC/'crontab.txt'
    # cronfile listing
    ls -al /etc/cron.* > $LOC/'cronfiles.txt'

    # mounted devices
    mount > $LOC/'mounteddevices.txt'

    # path
    echo $PATH > $LOC/'path.txt'

    # environment variables
    printenv > $LOC/'printenv.txt'

    # socket statistics
    ss -aempino > $LOC/'socketstatistics.txt'

    # directory listings
    # The listings are actually done through the 'find' command, not the
    # ls command. The '-xdev' flag prevents from from walking directories 
    # on other file systems.
    {
        find / -xdev \( $EXCLUDES \) -prune -o -type f -printf '%C+\t%CZ\t' -ls;
    } > $LOC/'ls.txt';

    # network interfaces
    if [ -x /sbin/ifconfig ]
    then 
        # rhel5
        IFCONFIG=/sbin/ifconfig
    else
        IFCONFIG=`which ifconfig`
    fi
    $IFCONFIG -a > $LOC/'ifconfig.txt'

    # logs
    # httpd logs
    mkdir $LOC/httpdlogs
    if [ -d "/var" ]; then
        find /var -name *access.log -exec cp {} $LOC/httpdlogs/ \;
        find /var -name *error.log -exec cp {} $LOC/httpdlogs/ \;
    fi

    # boot logs
    cp /var/log/boot.log $LOC/'bootlog.txt'
    # kernel logs
    cp /var/log/kern.log $LOC/'kernlog.txt'
    # auth log
    cp /var/log/auth.log $LOC/'authlog.txt'
    # security log
    cp /var/log/secure $LOC/'securelog.txt'

    # current logged in users
    if who -a &> /dev/null
    then
        who -a > $LOC/'who.txt'
    else
        cat /var/run/utmp > $LOC/'wh.ohobin'
    fi
    # last logged in users
    if last -Fwx -f /var/log/wtmp* &> /dev/null
    then 
        last -Fwx -f /var/log/wtmp* > $LOC/'last.txt'
    else
        cp /var/log/wtmp* > $LOC/
    fi

    # installed packages with version information - ubuntu
    if dpkg-query -W &> /dev/null
    then
        dpkg-query -W -f='${PackageSpec}\t${Version}\n' > $LOC/'packages.txt'
    fi
    # installed packages with version information - redhat/centos
    if /bin/rpm -qa --queryformat "%{NAME}\t%{VERSION}\n" &> /dev/null
    then
        /bin/rpm -qa --queryformat '%{NAME}\t%{VERSION}\n' >> $LOC/'packages.txt'
    fi

    # kernel ring buffer messages
    {
        if dmesg -T &> /dev/null
        then 
            dmesg -T
        else
            dmesg  
        fi
    } > $LOC/'dmesg.txt'

    # version information
    {
        echo -n "kernel_name="; uname -s; 
        echo -n "nodename="; uname -n;
        echo -n "kernel_release="; uname -r;
        echo -n "kernel_version="; uname -v;
        echo -n "machine="; uname -m;
        echo -n "processor="; uname -p;
        echo -n "hardware_platform="; uname -i; 
        echo -n "os="; uname -o;

    } > $LOC/'version.txt'

    # kernel modules
    lsmod | sed 1d > $TMP
    while read module size usedby
    do
        {
            echo -e $module'\t'$size'\t'$usedby;
            modprobe --show-depends $module;
            modinfo $module;
            echo "";
        } >> $LOC/'modules.txt'
    done < $TMP
    rm $TMP

    # list of PCI devices
    if [ -x /sbin/lspci ]
    then 
        # rhel5
        LSPCI=/sbin/lspci
    else
        LSPCI=`which ifconfig`
    fi
    $LSPCI > $LOC/'lspci.txt'

    # locale information
    locale > $LOC/'locale.txt'

    # user accounts
    cp /etc/passwd $LOC

    # user groups
    cp /etc/group $LOC

    # user accounts
    {
        while read line
        do
            user=`echo "$line" | cut -d':' -f1`
            pw=`echo "$line" | cut -d':' -f2`
            # ignore the salt and hash, but capture the hashing method
            hsh_method=`echo "$pw" | cut -d'$' -f2`
            rest=`echo "$line" | cut -d':' -f3,4,5,6,7,8,9`
            echo "$user:$hsh_method:$rest"
        done < /etc/shadow
    } > $LOC/'shadow.txt'

    # userprofile
    while read line
    do
        user=`echo "$line" | cut -f1 -d:`
        home=`echo "$line" | cut -f6 -d:`
        mkdir $LOC/userprofiles/$user
        # user contabs
        crontab -u $user -l > $LOC/userprofiles/$user/'crontab.txt'
        # ssh known hosts
        cp $home/.ssh/known_hosts $LOC/userprofiles/$user/'ssh_known_hosts.txt'
        # ssh config
        cp $home/.ssh/config $LOC/userprofiles/$user/'ssh_config.txt'
        # user shell history
        for f in $home/.*_history; do
            count=0
            while read line
            do
                echo $f $count $line >> $LOC/userprofiles/$user/'shellhistory.txt'
                count=$(( $count + 1 ))
            done < $f
        done
    done < /etc/passwd
}

# run collect and catch errors
ERRORS=$(collect 2>&1)
# log errors
echo "$ERRORS" > $ERROR_LOG

#
# compression and cleanup
#

cd $LOC
tar -zcvf "/tmp/$IRCASE.tar.gz" * > /dev/null
cd /tmp
rm -r $LOC
if [ "$UseCurl" = "1" ] ; then
    curl -F new_file_1=@"/tmp/$IRCASE.tar.gz" -F uploader_email="$UserEmail" https://upload.box.com/api/1.0/upload/vp3xvh6hm0lqdtsngna3a6nvkq4qw69d/$FolderID -k &> /dev/null
    rm "/tmp/$IRCASE.tar.gz"
fi
