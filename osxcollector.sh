# basename of results archive
IRCASE=`hostname`
DATETIME=`date "+%Y%m%d%H%m"`
# output destination, change according to needs
LOC=/Volumes/My\ Passport/$DATETIME\ -\ $IRCASE\ Incident
# tmp file to redirect results
TMP=$LOC/$IRCASE'_tmp.txt'
# redirect stderr
ERROR_LOG=$LOC/'errors.log'
ROOT_PATH='/'

[ -d "${LOC}" ] || mkdir "${LOC}"

function _get_download_info() {
	if [ -d $1 ]
	then 
		USER_PROFILE=(`basename "$(dirname "$1")"`)
		echo "Path: $1" >> $LOC/Downloads/$USER_PROFILE'_Downloads_mtime.txt'
		ls -latr "$1" >> $LOC/Downloads/$USER_PROFILE'_Downloads_mtime.txt'
		echo "Path: $1" >> $LOC/Downloads/$USER_PROFILE'_Downloads_atime.txt'
		ls -laur "$1" >> $LOC/Downloads/$USER_PROFILE'_Downloads_atime.txt'
		echo "Path: $1" >> $LOC/Downloads/$USER_PROFILE'_Downloads_ctime.txt'
		ls -lacr "$1" >> $LOC/Downloads/$USER_PROFILE'_Downloads_ctime.txt'
		find "$1" -type f -exec md5 {} >> "${LOC}/Downloads/${USER_PROFILE}_Downloads_md5.txt" \;
	fi
}

function _get_trash_info() {
	USER_PROFILE=(`basename "$(dirname "$1")"`)
	echo "Path: $1" >> $LOC/Trash/$USER_PROFILE'_Trash_mtime.txt'
	ls -latr "$1" >> $LOC/Trash/$USER_PROFILE'_Trash_mtime.txt'
	echo "Path: $1" >> $LOC/Trash/$USER_PROFILE'_Trash_atime.txt'
	ls -laur "$1" >> $LOC/Trash/$USER_PROFILE'_Trash_atime.txt'
	echo "Path: $1" >> $LOC/Trash/$USER_PROFILE'_Trash_ctime.txt'
	ls -lacr "$1" >> $LOC/Trash/$USER_PROFILE'_Trash_ctime.txt'
	find "$1" -type f -exec md5 {} >> "${LOC}/Trash/${USER_PROFILE}_Trash_md5.txt" \;
}

#Declare all array variables
#----------------------------

USER_DIR=()
for d in $ROOT_PATH/Users/*; do	
	USER_DIR+=("$d")
done

declare -a startup_items=(
    "System/Library/StartupItems"
    "Library/StartupItems"
)

declare -a launch_agents=(
    "System/Library/LaunchAgents"
    "Library/LaunchAgents"
)

declare -a launch_daemons=(
    "System/Library/LaunchDaemons"
    "Library/LaunchDaemons"
)

declare -a packages=(
    "System/Library/ScriptingAdditions"
    "Library/ScriptingAdditions"
)

declare -a download_to_hash=(
    "Library/Mail Downloads"
    "Library/Containers/com.apple.mail/Data/Library/Mail Downloads"
)

#XProtect adds hash-based malware checking to quarantine files.

#The plist for XProtect is at: /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.plist

#XProtect also add minimum versions for Internet Plugins. That plist is at:
#/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.meta.plist
if [ -f "$ROOT_PATH/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.plist" ]
then 
	cp $"ROOT_PATH/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.plist" "$LOC"
else
	echo "FILE NOT FOUND: ${ROOT_PATH}/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.plist" >> $ERROR_LOG
fi

if [ -f "$ROOT_PATH/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.meta.plist" ]
then 
	cp "$ROOT_PATH/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.meta.plist" "$LOC"
else
	echo "FILE NOT FOUND: ${ROOT_PATH}/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.meta.plist" >> $ERROR_LOG
fi

#Log the startup_item plist and hash its program argument

#Startup items are launched in the final phase of boot.  See more at:
#https://developer.apple.com/library/mac/documentation/macosx/conceptual/bpsystemstartup/chapters/StartupItems.html

#The 'Provides' element of the plist is an array of services provided by the startup item.
#_log_startup_items treats each element of 'Provides' as a the name of a file and attempts to hash it.
if [ -f "$ROOT_PATH/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.meta.plist" ]
then 
	cp "$ROOT_PATH/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.meta.plist" "$LOC"
else
	echo "FILE NOT FOUND: ${ROOT_PATH}/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/XProtect.meta.plist" >> $ERROR_LOG
fi

#Applications
#-------------
[ -d "$LOC/Software Installation/" ] || mkdir "$LOC/Software Installation/"
if [ -f "$ROOT_PATH/Library/Receipts/InstallHistory.plist" ]
then 
	cp "$ROOT_PATH/Library/Receipts/InstallHistory.plist" "$LOC/Software Installation"
else
	echo "FILE NOT FOUND: ${ROOT_PATH}/Library/Receipts/InstallHistory.plist" >> $ERROR_LOG
fi
if [ -f "$ROOT_PATH/Library/Preferences/com.apple.SoftwareUpdate.plist" ]
then 
	cp "$ROOT_PATH/Library/Preferences/com.apple.SoftwareUpdate.plist" "$LOC/Software Installation"
else
	echo "FILE NOT FOUND: ${ROOT_PATH}/Library/Preferences/com.apple.SoftwareUpdate.plist" >> $ERROR_LOG
fi

#Memory
#------
[ -d "$LOC/Memory/" ] || mkdir "$LOC/Memory/"
if [ -f "$ROOT_PATH/var/vm/sleepimage" ]
then 
	cp "$ROOT_PATH/var/vm/sleepimage" "$LOC/Software Installation"
else
	echo "FILE NOT FOUND: ${ROOT_PATH}/var/vm/sleepimage" >> $ERROR_LOG
fi
find "$ROOT_PATH/var/vm" -name "swapfile*" -type f -exec cp {} "${LOC}/Memory/" \;

#Kernel Extension
#------------------
[ -d "$LOC/Kernel Extension/" ] || mkdir "$LOC/Kernel Extension/"
if [ -d "$ROOT_PATH/System/Library/Extensions" ]
then
	for d in "${ROOT_PATH}/System/Library/Extensions"/*; do
		KEXTNAME=(`basename "$d"`)
		KEXTNAME=${KEXTNAME%%.*}
		if [ -f "$d/Info.plist" ]
		then
			cp "$d/Info.plist" "$LOC/Kernel Extension/$KEXTNAME_Info.plist"
		else
			cp "$d/Contents/Info.plist" "$LOC/Kernel Extension/$KEXTNAME_Info.plist"
		fi
		
	done
fi
if [ -d "$ROOT_PATH/Library/Extensions" ]
then
	for d in "${ROOT_PATH}/Library/Extensions"/*; do
		KEXTNAME=(`basename "$d"`)
		KEXTNAME=${KEXTNAME%%.*}
		cp "$d/Contents/Info.plist" "$LOC/Kernel Extension/$KEXTNAME_Info.plist"
	done
fi

#Logs
#-----
[ -d "$LOC/Logs/" ] || mkdir "$LOC/Logs/"
if [ -f "$ROOT_PATH/var/log/install.log" ]
then 
	cp "$ROOT_PATH/var/log/install.log" "$LOC/Logs/"
else
	echo "FILE NOT FOUND: ${ROOT_PATH}/Library/Receipts/InstallHistory.plist" >> $ERROR_LOG
fi
find "${dir_path}/var/log" -type f -exec cp {} "${LOC}/Logs/" \;


[ -d "$LOC/Logs/Misc_Logs" ] || mkdir "$LOC/Logs/Misc_Logs"
if [ -d "$ROOT_PATH/Library/Logs" ]
then 
	cp -R "$ROOT_PATH/Library/Logs/" "$LOC/Logs/Misc_Logs"
else
	echo "DIRECTORY NOT FOUND: ${ROOT_PATH}/Library/Logs" >> $ERROR_LOG
fi

#Autorun locations
#-----------------
[ -d "$LOC/Autorun/" ] || mkdir "$LOC/Autorun/"
for dir_path in ${startup_items[@]}
do
	COUNT=0
	if [ -f "$ROOT_PATH/$dir_path/StartupParameters.plist" ] 
	then
		((COUNT++))
		cp "$ROOT_PATH/$dir_path/StartupParameters.plist" "$LOC/Autorun/StartupParameters_$COUNT.plist"
	fi
done

[ -d "$LOC/Autorun/Launch Agents/" ] || mkdir "$LOC/Autorun/Launch Agents/"
for dir_path in ${launch_agents[@]}
do
	find "${ROOT_PATH}/${dir_path}/" -name "*.plist" -type f -exec cp {} "${LOC}/Autorun/Launch Agents/" \;
done

[ -d "$LOC/Autorun/Launch Daemons/" ] || mkdir "$LOC/Autorun/Launch Daemons/"
for dir_path in ${launch_daemons[@]}
do
	find "${ROOT_PATH}/${dir_path}/" -name "*.plist" -type f -exec cp {} "${LOC}/Autorun/Launch Daemons/" \;
done

[ -d "$LOC/Packages/" ] || mkdir "$LOC/Packages/"
for dir_path in ${packages[@]}
do
	find "${ROOT_PATH}/${dir_path}/" -name "*.plist" -type f -exec cp {} "${LOC}/Packages/" \;
done

#Hash all users's downloaded files
#----------------------------------

#find all users' downloads folder
for dir_path in ${USER_DIR[@]}
do
  if [ -d "$dir_path/Downloads" ]; then
    download_to_hash+=("$dir_path/Downloads")
  fi
done

#output mactime and md5 of files within downloads folder
[ -d "$LOC/Downloads/" ] || mkdir "$LOC/Downloads/"
for dir_path in ${download_to_hash[@]}
do
	_get_download_info $ROOT_PATH/$dir_path
done

#System Preferences
#-------------------
[ -d "$LOC/Preferences" ] || mkdir "$LOC/Preferences"
if [ -f "$ROOT_PATH/Library/Preferences/.GlobalPreferences.plist" ]
then 
	cp "$ROOT_PATH/Library/Preferences/.GlobalPreferences.plist" "$LOC/Preferences"
else
	echo "FILE NOT FOUND: ${ROOT_PATH}/Library/Preferences/.GlobalPreferences.plist" >> $ERROR_LOG
fi
if [ -f "$ROOT_PATH/Library/Preferences/com.apple.loginwindow.plist" ]
then 
	cp "$ROOT_PATH/Library/Preferences/com.apple.loginwindow.plist" "$LOC/Preferences"
else
	echo "FILE NOT FOUND: ${ROOT_PATH}/Library/Preferences/com.apple.loginwindow.plist" >> $ERROR_LOG
fi
if [ -f "$ROOT_PATH/Library/Preferences/com.apple.Bluetooth.plist" ]
then 
	cp "$ROOT_PATH/Library/Preferences/com.apple.Bluetooth.plist" "$LOC/Preferences"
else
	echo "FILE NOT FOUND: ${ROOT_PATH}/Library/Preferences/com.apple.Bluetooth.plist" >> $ERROR_LOG
fi
if [ -f "$ROOT_PATH/Library/Preferences/com.apple.TimeMachine.plist" ]
then 
	cp "$ROOT_PATH/Library/Preferences/com.apple.TimeMachine.plist" "$LOC/Preferences"
else
	echo "FILE NOT FOUND: ${ROOT_PATH}/Library/Preferences/com.apple.TimeMachine.plist" >> $ERROR_LOG
fi

#System settings and information
[ -d "$LOC/System Info" ] || mkdir "$LOC/System Info"
if [ -f "$ROOT_PATH/var/db/.AppleSetupDone" ]
then 
	echo "OS Installation Time: " > "$LOC/System Info/OSInstallationTime.txt"
	echo `stat -f "%m%t%Sm %N" "$ROOT_PATH/var/db/.AppleSetupDone"` >> "$LOC/System Info/OSInstallationTime.txt"
else
	echo "FILE NOT FOUND: ${ROOT_PATH}/var/db/.AppleSetupDone" >> $ERROR_LOG
fi
if [ -f "$ROOT_PATH/System/Library/CoreServices/SystemVersion.plist" ]
then 
	cp "$ROOT_PATH/System/Library/CoreServices/SystemVersion.plist" "$LOC/System Info"
else
	echo "FILE NOT FOUND: ${ROOT_PATH}/System/Library/CoreServices/SystemVersion.plist" >> $ERROR_LOG
fi

#Network
[ -d "$LOC/Network" ] || mkdir "$LOC/Network"
if [ -f "$ROOT_PATH/etc/hosts" ]
then 
	cp "$ROOT_PATH/etc/hosts" "$LOC/Network"
else
	echo "FILE NOT FOUND: ${ROOT_PATH}/etc/hosts" >> $ERROR_LOG
fi
if [ -f "$ROOT_PATH/Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist" ]
then 
	cp "$ROOT_PATH/Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist" "$LOC/Network"
else
	echo "FILE NOT FOUND: ${ROOT_PATH}/Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist" >> $ERROR_LOG
fi

#USER ARTIFACTS
for dir_path in ${USER_DIR[@]}
do
	USER_PROFILE=(`basename "$dir_path"`)
	#Collect firefox artefacts
	#--------------------------
	if [ -d "${dir_path}/Library/Application Support/Firefox/Profiles" ]
	then
		[ -d "$LOC/Firefox/$USER_PROFILE" ] || mkdir -p "$LOC/Firefox/$USER_PROFILE"
		for d in "${dir_path}/Library/Application Support/Firefox/Profiles"/*; do
			FIREFOX_PROFILE=(`basename "$d"`)
			[ -d "$LOC/Firefox/$USER_PROFILE/$FIREFOX_PROFILE" ] || mkdir "$LOC/Firefox/$USER_PROFILE/$FIREFOX_PROFILE"

			cp "${dir_path}/Library/Application Support/Firefox/Profiles/${FIREFOX_PROFILE}/cookies.sqlite" "${LOC}/Firefox/${USER_PROFILE}/${FIREFOX_PROFILE}"
			cp "${dir_path}/Library/Application Support/Firefox/Profiles/${FIREFOX_PROFILE}/downloads.sqlite" "${LOC}/Firefox/${USER_PROFILE}/${FIREFOX_PROFILE}"
			cp "${dir_path}/Library/Application Support/Firefox/Profiles/${FIREFOX_PROFILE}/formhistory.sqlite" "${LOC}/Firefox/${USER_PROFILE}/${FIREFOX_PROFILE}"
			cp "${dir_path}/Library/Application Support/Firefox/Profiles/${FIREFOX_PROFILE}/places.sqlite" "${LOC}/Firefox/${USER_PROFILE}/${FIREFOX_PROFILE}"
			cp "${dir_path}/Library/Application Support/Firefox/Profiles/${FIREFOX_PROFILE}/signons.sqlite" "${LOC}/Firefox/${USER_PROFILE}/${FIREFOX_PROFILE}"
			cp "${dir_path}/Library/Application Support/Firefox/Profiles/${FIREFOX_PROFILE}/key3.db" "${LOC}/Firefox/${USER_PROFILE}/${FIREFOX_PROFILE}"
			cp "${dir_path}/Library/Application Support/Firefox/Profiles/${FIREFOX_PROFILE}/permissions.sqlite" "${LOC}/Firefox/${USER_PROFILE}/${FIREFOX_PROFILE}"
			cp "${dir_path}/Library/Application Support/Firefox/Profiles/${FIREFOX_PROFILE}/addons.sqlite" "${LOC}/Firefox/${USER_PROFILE}/${FIREFOX_PROFILE}"
			cp "${dir_path}/Library/Application Support/Firefox/Profiles/${FIREFOX_PROFILE}/extensions.sqlite" "${LOC}/Firefox/${USER_PROFILE}/${FIREFOX_PROFILE}"
			cp "${dir_path}/Library/Application Support/Firefox/Profiles/${FIREFOX_PROFILE}/content-prefs.sqlite" "${LOC}/Firefox/${USER_PROFILE}/${FIREFOX_PROFILE}"
			cp "${dir_path}/Library/Application Support/Firefox/Profiles/${FIREFOX_PROFILE}/healthreport.sqlite" "${LOC}/Firefox/${USER_PROFILE}/${FIREFOX_PROFILE}"
			cp "${dir_path}/Library/Application Support/Firefox/Profiles/${FIREFOX_PROFILE}/webappsstore.sqlite" "${LOC}/Firefox/${USER_PROFILE}/${FIREFOX_PROFILE}"
		done
	else
		echo "DIRECTORY NOT FOUND: ${dir_path}/Library/Application Support/Firefox/Profiles" >> $ERROR_LOG
	fi

	#Collect Chrome artefacts
	#--------------------------
	# HAVE NOT TAKE INTO ACCOUNT PRESENCE OF OTHER CHROME PROFILE
	if [ -d "${dir_path}/Library/Application Support/Google/Chrome/Default" ]
	then
		[ -d "$LOC/Chrome/" ] || mkdir -p "$LOC/Chrome/$USER_PROFILE"
		cp "${dir_path}/Library/Application Support/Google/Chrome/Default/Bookmarks" "${LOC}/Chrome/${USER_PROFILE}/"
		cp "${dir_path}/Library/Application Support/Google/Chrome/Default/Cookies" "${LOC}/Chrome/${USER_PROFILE}/"
		cp "${dir_path}/Library/Application Support/Google/Chrome/Default/Login Data" "${LOC}/Chrome/${USER_PROFILE}/"
		cp "${dir_path}/Library/Application Support/Google/Chrome/Default/Top Sites" "${LOC}/Chrome/${USER_PROFILE}/"
		cp "${dir_path}/Library/Application Support/Google/Chrome/Default/Web Data" "${LOC}/Chrome/${USER_PROFILE}/"
		cp "${dir_path}/Library/Application Support/Google/Chrome/Default/History" "${LOC}/Chrome/${USER_PROFILE}/"
		cp "${dir_path}/Library/Application Support/Google/Chrome/Default/Arhived History" "${LOC}/Chrome/${USER_PROFILE}/"
		cp "${dir_path}/Library/Application Support/Google/Chrome/Default/databases/Databases.db" "${LOC}/Chrome/${USER_PROFILE}/"
		cp "${dir_path}/Library/Application Support/Google/Chrome/Default/Preferences" "${LOC}/Chrome/${USER_PROFILE}/"
		cp "${dir_path}/Library/Caches/com.google.Chrome/Cache.db" "${LOC}/Chrome/${USER_PROFILE}/"
		cp "${dir_path}/Library/Preferences/com.google.Chrome.plist" "${LOC}/Chrome/${USER_PROFILE}/"
		[ -d "$LOC/Chrome/$USER_PROFILE/Local Storage" ] || mkdir "$LOC/Chrome/$USER_PROFILE/Local Storage"
		find "${dir_path}/Library/Application Support/Google/Chrome/Default/Local Storage" -not -name "*.localstorage-journal" -type f -exec cp {} "${LOC}/Chrome/${USER_PROFILE}/Local Storage/" \;
	else
		echo "DIRECTORY NOT FOUND: ${dir_path}/Library/Application Support/Google/Chrome/Default" >> $ERROR_LOG
	fi

	#Collect Safari artefacts
	#--------------------------
	if [ -d "${dir_path}/Library/Safari" ]
	then
		[ -d "$LOC/Safari/" ] || mkdir -p "$LOC/Safari/$USER_PROFILE"
		cp "${dir_path}/Library/Safari/Downloads.plist" "${LOC}/Safari/${USER_PROFILE}/"
		cp "${dir_path}/Library/Safari/History.plist" "${LOC}/Safari/${USER_PROFILE}/"
		cp "${dir_path}/Library/Safari/History.db" "${LOC}/Safari/${USER_PROFILE}/"
		cp "${dir_path}/Library/Safari/HistoryIndex.sk" "${LOC}/Safari/${USER_PROFILE}/"
		cp "${dir_path}/Library/Safari/Extensions/Extensions.plist" "${LOC}/Safari/${USER_PROFILE}/"
		cp "${dir_path}/Library/Safari/Bookmarks.plist" "${LOC}/Safari/${USER_PROFILE}/"
		cp "${dir_path}/Library/Safari/LastSession.plist" "${LOC}/Safari/${USER_PROFILE}/"
		cp "${dir_path}/Library/Safari/TopSites.plist" "${LOC}/Safari/${USER_PROFILE}/"
		cp "${dir_path}/Library/Safari/History.db" "${LOC}/Safari/${USER_PROFILE}/"
		cp "${dir_path}/Library/Safari/WebpageIcons.db" "${LOC}/Safari/${USER_PROFILE}/"
		cp "${dir_path}/Library/Caches/com.apple.Safari/Cache.db" "${LOC}/Safari/${USER_PROFILE}/"
		cp "${dir_path}/Library/Cookies/Cookies.binarycookies" "${LOC}/Safari/${USER_PROFILE}/"
		cp "${dir_path}/Library/Preferences/com.apple.Safari.plist" "${LOC}/Safari/${USER_PROFILE}/"
		cp "${dir_path}/Library/Preferences/com.apple.Safari.Extensions.plist" "${LOC}/Safari/${USER_PROFILE}/"
		[ -d "$LOC/Safari/$USER_PROFILE/Bookmarks" ] || mkdir "$LOC/Safari/$USER_PROFILE/Bookmarks"
		find "${dir_path}/Library/Caches/Metadata/Safari/Bookmarks" -name "*.webbookmark" -type f -exec cp {} "${LOC}/Safari/${USER_PROFILE}/Bookmarks/" \;
		[ -d "$LOC/Safari/$USER_PROFILE/History" ] || mkdir "$LOC/Safari/$USER_PROFILE/History"
		find "${dir_path}/Library/Caches/Metadata/Safari/History" -name "*.webhistory" -type f -exec cp {} "${LOC}/Safari/${USER_PROFILE}/History/" \;
		[ -d "$LOC/Safari/$USER_PROFILE/Temporary Images" ] || mkdir "$LOC/Safari/$USER_PROFILE/Temporary Images"
		find "${dir_path}/Library/Caches/com.apple.Safari/fsCachedData" -type f -exec cp {} "${LOC}/Safari/${USER_PROFILE}/Temporary Images/" \;
		[ -d "$LOC/Safari/$USER_PROFILE/Webpage Previews" ] || mkdir "$LOC/Safari/$USER_PROFILE/Webpage Previews"
		find "${dir_path}/Library/Caches/com.apple.Safari/Webpage Previews" -type f -exec cp {} "${LOC}/Safari/${USER_PROFILE}/Webpage Previews/" \;
		[ -d "$LOC/Safari/$USER_PROFILE/Local Storage" ] || mkdir "$LOC/Safari/$USER_PROFILE/Local Storage"
		find "${dir_path}/Library/Safari/LocalStorage" -name "*.localstorage" -type f -exec cp {} "${LOC}/Safari/${USER_PROFILE}/Local Storage/" \;
		cp "${dir_path}/Library/Safari/LocalStorage/StorageTracker.db" "${LOC}/Safari/${USER_PROFILE}/Local Storage"
	else
		echo "DIRECTORY NOT FOUND: ${dir_path}/Library/Safari" >> $ERROR_LOG
	fi

	#Collect Mail artefacts
	#--------------------------
	if [ -d "${dir_path}/Library/Mail" ]
	then
		[ -d "$LOC/Mail/" ] || mkdir -p "$LOC/Mail/$USER_PROFILE"
		for d in "${dir_path}/Library/Mail"/*; do
			MAIL_VERSION=(`basename "$d"`)
			cp "${d}/MailData/OpenedAttachmentsV2.plist" "${LOC}/Mail/${USER_PROFILE}/${MAIL_VERSION}_OpenedAttachmentsV2.plist"
			cp "${d}/MailData/Accounts.plist" "${LOC}/Mail/${USER_PROFILE}/"
		done
		for d in "${dir_path}/Library/Containers/com.apple.mail/Data/Library/Mail Downloads"/*; do
			echo "Path: $d" >> $LOC/Mail/$USER_PROFILE/'Mail_Downloads_mtime.txt'
			ls -latr "$d" >> $LOC/Mail/$USER_PROFILE/'Mail_Downloads_mtime.txt'
			echo "Path: $d" >> $LOC/Mail/$USER_PROFILE/'Mail_Downloads_atime.txt'
			ls -laur "$d" >> $LOC/Mail/$USER_PROFILE/'Mail_Downloads_atime.txt'
			echo "Path: $d" >> $LOC/Mail/$USER_PROFILE/'Mail_Downloads_ctime.txt'
			ls -lacr "$d" >> $LOC/Mail/$USER_PROFILE/'Mail_Downloads_ctime.txt'
			find "${d}" -type f -exec md5 {} >> "${LOC}/Mail/${USER_PROFILE}/Mail_Downloads_md5.txt" \;
		done
		cp "${dir_path}/Library/Application Support/AddressBook/MailRecents-v4.abcdmr" "${LOC}/Mail/${USER_PROFILE}/"
	else
		echo "DIRECTORY NOT FOUND: ${dir_path}/Library/Mail" >> $ERROR_LOG
	fi

	#iDevice Backup
	#---------------
	if [ -d "${dir_path}/Library/Application Support/MobileSync" ]
	then
		[ -d "$LOC/iDevice Backup/" ] || mkdir -p "$LOC/iDevice Backup/$USER_PROFILE"
		for d in "${dir_path}/Library/Application Support/MobileSync/Backup"/*; do
			iDEVICE=(`basename "$d"`)
			cp "${d}/info.plist" "${LOC}/iDevice Backup/${USER_PROFILE}/${iDEVICE}_info.plist"
			cp "${d}/Manifest.plist" "${LOC}/iDevice Backup/${USER_PROFILE}/${iDEVICE}_Manifest.plist"
			cp "${d}/Manifest.mbdb" "${LOC}/iDevice Backup/${USER_PROFILE}/${iDEVICE}_Manifest.mbdb"
			cp "${d}/Status.plist" "${LOC}/iDevice Backup/${USER_PROFILE}/${iDEVICE}_Status.plist"
		done
	fi

	#Recent Items
	#--------------------------
	if [ -f "${dir_path}/Library/Preferences/com.apple.recentitems.plist" ]
	then
		[ -d "$LOC/Recent Items/" ] || mkdir -p "$LOC/Recent Items"
		cp "${dir_path}/Library/Preferences/com.apple.recentitems.plist" "${LOC}/Recent Items/${USER_PROFILE}_com.apple.recentitems.plist"
	else
		echo "FILE NOT FOUND: ${dir_path}/Library/Preferences/com.apple.recentitems.plist" >> $ERROR_LOG
	fi

	#User's Social Accounts
	#--------------------------
	if [ -f "${dir_path}/Library/Accounts/Accounts3.sqlite" ]
	then
		[ -d "$LOC/Social Accounts/" ] || mkdir -p "$LOC/Social Accounts"
		cp "${dir_path}/Library/Accounts/Accounts3.sqlite" "${LOC}/Social Accounts/${USER_PROFILE}_Accounts3.sqlite"
	else
		echo "FILE NOT FOUND: ${dir_path}/Library/Accounts/Accounts3.sqlite" >> $ERROR_LOG
	fi

	#Terminal Commands History
	#--------------------------
	if [ -f "${dir_path}/.bash_history" ]
	then
		[ -d "$LOC/Bash History/" ] || mkdir -p "$LOC/Bash History"
		cp "${dir_path}/.bash_history" "${LOC}/Bash History/${USER_PROFILE}_bash_history"
	else
		echo "FILE NOT FOUND: ${dir_path}/.bash_history" >> $ERROR_LOG
	fi

	#User specific logs
	#--------------------------
	if [ -d "${dir_path}/Library/Logs" ]
	then
		[ -d "$LOC/Logs/${USER_PROFILE}_Logs" ] || mkdir "$LOC/Logs/${USER_PROFILE}_Logs"
		cp -R "${dir_path}/Library/Logs/" "$LOC/Logs/${USER_PROFILE}_Logs/"
	else
		echo "DIRECTORY NOT FOUND: ${dir_path}/Library/Logs" >> $ERROR_LOG
	fi

	#User preferences
	#--------------------------
	[ -d "$LOC/Preferences/$USER_PROFILE" ] || mkdir -p "$LOC/Preferences/$USER_PROFILE"
	if [ -f "${dir_path}/Library/Preferences/MobileMeAccounts.plist" ]
	then 
		cp "${dir_path}/Library/Preferences/MobileMeAccounts.plist" "$LOC/Preferences/${USER_PROFILE}"
	else
		echo "FILE NOT FOUND: ${dir_path}/Library/Preferences/MobileMeAccounts.plist" >> $ERROR_LOG
	fi
	if [ -f "${dir_path}/Library/Preferences/com.apple.sidebarlists.plist" ]
	then 
		cp "${dir_path}/Library/Preferences/com.apple.sidebarlists.plist" "$LOC/Preferences/${USER_PROFILE}/"
	else
		echo "FILE NOT FOUND: ${dir_path}/Library/Preferences/com.apple.sidebarlists.plist" >> $ERROR_LOG
	fi
	if [ -f "${dir_path}/Library/Preferences/GlobalPreferences.plist" ]
	then 
		cp "${dir_path}/Library/Preferences/GlobalPreferences.plist" "$LOC/Preferences/${USER_PROFILE}/"
	else
		echo "FILE NOT FOUND: ${dir_path}/Library/Preferences/GlobalPreferences.plist" >> $ERROR_LOG
	fi
	if [ -f "${dir_path}/Library/Preferences/com.apple.Dock.plist" ]
	then 
		cp "${dir_path}/Library/Preferences/com.apple.Dock.plist" "$LOC/Preferences/${USER_PROFILE}"
	else
		echo "FILE NOT FOUND: ${dir_path}/Library/Preferences/com.apple.Dock.plist" >> $ERROR_LOG
	fi
	if [ -f "${dir_path}/Library/Preferences/com.apple.iPod.plist" ]
	then 
		cp "${dir_path}/Library/Preferences/com.apple.iPod.plist" "$LOC/Preferences/${USER_PROFILE}/"
	else
		echo "FILE NOT FOUND: ${dir_path}/Library/Preferences/com.apple.iPod.plist" >> $ERROR_LOG
	fi
	#Log the quarantines for a user
	#Quarantines is basically the info necessary to show the 'Are you sure you wanna run this?' when
	#a user is trying to open a file downloaded from the Internet.  For some more details, checkout the
	#Apple Support explanation of Quarantines: http://support.apple.com/kb/HT3662
	if [ -f "${dir_path}/Library/Preferences/com.apple.LaunchServices.QuarantineEvents" ]
	then 
		cp "${dir_path}/Library/Preferences/com.apple.LaunchServices.QuarantineEvents" "$LOC/Preferences/${USER_PROFILE}/"
	else
		echo "FILE NOT FOUND: ${dir_path}/Library/Preferences/com.apple.LaunchServices.QuarantineEvents" >> $ERROR_LOG
	fi
	if [ -f "${dir_path}/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2" ]
	then 
		cp "${dir_path}/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2" "$LOC/Preferences/${USER_PROFILE}/"
	else
		echo "FILE NOT FOUND: ${dir_path}/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2" >> $ERROR_LOG
	fi

	#Trash information (MACTIME and MD5)
	[ -d "$LOC/Trash/" ] || mkdir "$LOC/Trash/"
	if [ -d "${dir_path}/.Trash" ]
	then 
		_get_trash_info $dir_path/.Trash
	else
		echo "DIRECTORY NOT FOUND: ${dir_path}/.Trash" >> $ERROR_LOG
	fi

	#User autorun
	#-------------
	#Log the login items for a user

	#Login items are startup items that open automatically when a user logs in.
	#They are visible in 'System Preferences'->'Users & Groups'->'Login Items'

	#The name of the item is in 'SessionItems.CustomListItems.Name'
	#The application to launch is in 'SessionItems.CustomListItems.Alias' but this binary structure is hard to read.
	#FILE = /Library/Preferences/com.apple.loginitems.plist
	if [ -f "${dir_path}/Library/Preferences/com.apple.loginitems.plist" ]
	then 
		cp "${dir_path}/Library/Preferences/com.apple.loginitems.plist" "$LOC/Autorun/${USER_PROFILE}_com.apple.loginitems.plist"
	else
		echo "FILE NOT FOUND: ${dir_path}/Library/Preferences/com.apple.loginitems.plist" >> $ERROR_LOG
	fi
done
