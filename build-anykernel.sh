#!/bin/bash
## ------------------------------------------------------------------------------------------------- ##
## | Nebula Kernel Build Script, Original Script By @RenderBroken, 07/22/2015 <-- Original Build   | ##
## |                                                                                               | ##
## | ReWritten From Scratch By @Eliminater74, Build Script W/AnyKernel2 Support                    | ##
## |                                                                                               | ##
## | Devices Used On: LG G3, LG V10, HTC10, LG G6, OnePlus 6T                                      | ##
## |                                                                                               | ##
## |                                                                                               | ##
## | Current Device Setup: OnePlus 6/6T                                                            | ##
## |                                                                                               | ##
## |                                                                                               | ##
## |                                                                                               | ##
## | Updated: 11/28/2018: Rewrote a few vars for new paths and fixed signing keys.                 | ##
## ------------------------------------------------------------------------------------------------- ##

## <<<< DONT EDIT ANYTHING BELOW THIS >>>> ##

#clear

if [ -e build-anykernel.cfg ]
then
echo "Reading config...." >&2
source "$PWD/build-anykernel.cfg"
else
echo "Configure File is missing..."
exit
fi

### Check For Given Paths: Toolchains/Anykernel2 Directory:

#if [ -d "${TOOLCHAIN_DIR}/${TC_DESTRO}/${TC_NAME}/bin/" ]
#then
#echo "Toolchain Exist" >&2
#else
#echo "Toolchain Doesnt Exist. FIX Path in Configuration:"
#exit
#fi

if [ -d "$REPACK_DIR" ]
then
echo "Anykernel2 Repack Directory Exist." >&2
else
echo "No Anykernel2 Repack Directory Exist, Set paths in Configuration:"
exit
fi

# Optimize CPU Threads
# CPUS=$(grep "^processor" /proc/cpuinfo | wc -l)
# JOBS=$(bc <<< "$CPUS");
# THREAD="-j$(JOBS)"
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"

# Resources
KERNEL="Image"
DTBIMAGE="dtb"

# UKM Synapse Details #
UCI_REV="$UCI_REV" >&2

# Kernel Details
VER="$VER" >&2
REV="$REV" >&2
KNAME="$KNAME" >&2
DEVICES="$DEVICES" >&2
#BDATE=$(date +"%Y%m%d")
KVER="$KVER" >&2
TestBuild=0


export ERROR_LOG=ERRORS
export LOCALVERSION=$LOCALVERSION
export CROSS_COMPILE=$CROSS_COMPILE
export OUTPUT_DIR=$OUTPUT_DIR
export STRIP=$STRIP
export CHAIN=$CHAIN
export ARCH=$ARCH
export SUBARCH=$SUBARCH
export KBUILD_BUILD_USER=$KBUILD_BUILD_USER
export KBUILD_BUILD_HOST=$KBUILD_BUILD_HOST
export SET_LOCAL=$SET_LOCAL
export CCACHE=$CCACHE
export STRIP_MODULES=$STRIP_MODULES
export SIGN_MODULES=$SIGN_MODULES
export SIGNFILE_KEY_A=$SIGNFILE_KEY_A
export SIGNFILE_KEY_B=$SIGNFILE_KEY_B
export USE_SCRIPTS=$USE_SCRIPTS
export SPLIT_DTB=$SPLIT_DTB
export DTBTOOL=$DTBTOOL
#export ERROR_LOG=$ERROR_LOG
export VARIANTS=$VARIANTS
export CLANG_BUILDS=$CLANG_BUILDS
export CC=$CC
export CLANG_TRIPLE=$CLANG_TRIPLE

#################################################
## DO NOT CHANGE THIS:  PATHS And Configs      ##
#################################################
KERNEL_DIR="$KERNEL_DIR" >&2
REPACK_DIR="$REPACK_DIR" >&2
PATCH_DIR="$PATCH_DIR" >&2
MODULES_DIR="$MODULES_DIR" >&2
SIGNFILE_DIR="$SIGNFILE_DIR" >&2
MODULE_SIGNING_KEYS_DIR="$MODULE_SIGNING_KEYS_DIR" >&2
TOOLS_DIR="$TOOLS_DIR" >&2
RAMDISK_DIR="$RAMDISK_DIR" >&2
RAMDISK_DIR="$RAMDISK_DIR" >&2
COMPRESSED_IMAGE_DIR="$COMPRESSED_IMAGE_DIR" >&2
TOOLCHAIN_DIR="$TOOLCHAIN_DIR" >&2
TC_NAME="$TC_NAME" >&2
TC_PREFIX="$TC_PREFIX" >&2
TC_DESTRO="$TC_DESTRO" >&2
CLANG_NAME="$CLANG_NAME" >&2
SIGNAPK="$SIGNAPK" >&2
SIGNAPK_KEYS="$SIGNAPK_KEYS" >&2
DEFCONFIGS="$DEFCONFIGS" >&2
ZIP_MOVE="$ZIP_MOVE" >&2
COPY_ZIP="$COPY_ZIP" >&2
ZIMAGE_DIR="$ZIMAGE_DIR" >&2
DTBTOOL_DIR="$DTBTOOL_DIR" >&2
OUTPUT_DIR="$OUTPUT_DIR" >&2
#################################################

#######################################################
# COMMANDS USED FOR STRINGS                           #
#######################################################

# backup_file <file>
backup_file() { cp "$1" "$1"~; }

# replace_string <file> <if search string> <original string> <replacement string>
replace_string() {
  if [ -z "$(grep "$2" "$1")" ]; then
      sed -i "s;${3};${4};" "$1";
  fi;
}

# replace_section <file> <begin search string> <end search string> <replacement string>
replace_section() {
  line=`grep -n "$2" $1 | head -n1 | cut -d: -f1`;
  sed -i "/${2//\//\\/}/,/${3//\//\\/}/d" $1;
  sed -i "${line}s;^;${4}\\n;" $1;
}

# remove_section <file> <begin search string> <end search string>
remove_section() {
  sed -i "/${2//\//\\/}/,/${3//\//\\/}/d" $1;
}

# insert_line <file> <if search string> <before|after> <line match string> <inserted line>
insert_line() {
  if [ -z "$(grep "$2" $1)" ]; then
    case $3 in
      before) offset=0;;
      after) offset=1;;
    esac;
    line=$((`grep -n "$4" $1 | head -n1 | cut -d: -f1` + offset));
    sed -i "${line}s;^;${5}\\n;" $1;
  fi;
}

# replace_line <file> <line replace string> <replacement line>
replace_line() {
  if [ ! -z "$(grep "$2" $1)" ]; then
    line=`grep -n "$2" $1 | head -n1 | cut -d: -f1`;
    sed -i "${line}s;.*;${3};" $1;
  fi;
}

# remove_line <file> <line match string>
remove_line() {
  if [ ! -z "$(grep "$2" $1)" ]; then
    line=`grep -n "$2" $1 | head -n1 | cut -d: -f1`;
    sed -i "${line}d" $1;
  fi;
}

# prepend_file <file> <if search string> <patch file>
prepend_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    echo "$(cat $patch/$3 $1)" > $1;
  fi;
}

# insert_file <file> <if search string> <before|after> <line match string> <patch file>
insert_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    case $3 in
      before) offset=0;;
      after) offset=1;;
    esac;
    line=$((`grep -n "$4" $1 | head -n1 | cut -d: -f1` + offset));
    sed -i "${line}s;^;\\n;" $1;
    sed -i "$((line - 1))r $patch/$5" $1;
  fi;
}

# append_file <file> <if search string> <patch file>
append_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    echo -ne "\\n" >> $1;
    cat $patch/$3 >> $1;
    echo -ne "\\n" >> $1;
  fi;
}

# replace_file <file> <permissions> <patch file>
replace_file() {
  cp -pf $patch/$3 $1;
  chmod $2 $1;
}

## end methods
#######################################################

# Functions
function INITIALIZE_SCRIPT() {
	# Store menu options selected by the user
	INPUT=/tmp/menu.sh.$$
 
	# Storage file for displaying cal and date command output
	OUTPUT=/tmp/output.sh.$$

	# trap and delete temp files
	trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM

	_temp="/tmp/answer.$$"
	PN=`basename "$0"`
	dialog 2>$_temp
	DVER=`cat $_temp | head -1`

	# Bash Color
	RESTORE=$(echo -en '\033[0m')
	RED=$(echo -en '\033[00;31m')
	GREEN=$(echo -en '\033[00;32m')
	YELLOW=$(echo -en '\033[00;33m')
	BLUE=$(echo -en '\033[00;34m')
	MAGENTA=$(echo -en '\033[00;35m')
	PURPLE=$(echo -en '\033[00;35m')
	CYAN=$(echo -en '\033[00;36m')
	LIGHTGRAY=$(echo -en '\033[00;37m')
	LRED=$(echo -en '\033[01;31m')
	LGREEN=$(echo -en '\033[01;32m')
	LYELLOW=$(echo -en '\033[01;33m')
	LBLUE=$(echo -en '\033[01;34m')
	LMAGENTA=$(echo -en '\033[01;35m')
	LPURPLE=$(echo -en '\033[01;35m')
	LCYAN=$(echo -en '\033[01;36m')
	WHITE=$(echo -en '\033[01;37m')
	blink_red='\033[05;31m'
	clear
}

function CLEAN_UP() {
	# if temp files found, delete em
	[ -f $OUTPUT ] && rm $OUTPUT
	[ -f $INPUT ] && rm $INPUT
	[ -f $_temp ] && rm $_temp
	unset ERROR_LOG
}


function TIME_START() {
	DATE_START=$(date +"%s")
}
function TIME_END() {
	DATE_END=$(date +"%s")
	DIFF=$(($DATE_END - $DATE_START))
	TIME_LENGTH="$(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
	
}

## Clean everything that is left over ##
function clean_all {
		echo "Cleaning out $COMPRESSED_IMAGE_DIR"
		rm -rf $MODULES_DIR/*
		cd $COMPRESSED_IMAGE_DIR
		rm -rf Image.gz-dtb
		rm -rf $KERNEL
		rm -rf $DTBIMAGE
		echo "Removing any backups from $COMPRESSED_IMAGE_DIR"
		rm -rf *.bak
		echo "Removing any left over zip packages from $REPACK_DIR"
		cd $REPACK_DIR
		rm -rf *.bak
		rm -rf *.zip
		cd $KERNEL_DIR
		if [ -e "$OUTPUT_DIR" ]; then
		echo "Deleting ${OUTPUT_DIR} Directory."
		rm -rf $OUTPUT_DIR
		fi
		echo "Running Make Clean and Make MrProper"
		make O=${OUTPUT_DIR} clean && make O=${OUTPUT_DIR} mrproper
}

function set_timestamp() {
#BDATE=$(date +"%Y%m%d")
KVER="$KVER" >&2
}

## Change Variant in anykernel.sh file ##
function change_variant {
		TAG=$VARIANT
		echo "TAG: $TAG"
		cd $REPACK_DIR
		sed -i '19s/.*/device.name1='$TAG'/' anykernel.sh
		sed -i '20s/.*/device.name2=LG-'$TAG'/' anykernel.sh
		cd $KERNEL_DIR
}

function show_log {
rm -f build.log; echo Initialize log >> build.log
  date >> build.log
  tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
  trap 'rm -f $tempfile; stty sane; exit 1' 1 2 3 15
  dialog --title "TAIL BOXES" \
        --begin 10 10 --tailboxbg build.log 8 58 \
        --and-widget \
        --begin 3 10 --msgbox "Press OK " 5 30 \
        2>$tempfile &
  mypid=$!
  for i in 1 2 3;  do echo $i >> build.log; sleep 1; done
  echo Done. >> build.log
  wait $mypid
  rm -f $tempfile
}

## Build Log ##  
function build_log {
		rm -rf build.log
		if [ "$ERROR_LOG" == "ERRORS" ]; then
        exec 2> >(sed -r 's/'$(echo -e "\\033")'\[[0-9]{1,2}(;([0-9]{1,2})?)?[mK]//g' | tee -a build.log)
		fi
		if [ "$ERROR_LOG" == "FULL" ]; then
        exec &> >(tee -a build.log)
		fi
}


## Logging options ##
function menu_log {
DIALOG=${DIALOG=dialog}
tempfile=`tempfile 2>/dev/null` || tempfile=/tmp/test$$
trap "rm -f $tempfile" 0 1 2 5 15

$DIALOG --backtitle "Logging Options" \
	--title "Menu: Logging Options" --clear \
        --radiolist "Choose your Logging Option below" 20 61 5 \
        "Errors"  "Log only compile errors" on \
        "Full"    "Full logging" off \
        "Off" "Off: No Logging at all" off  2> $tempfile
# 0 = No Log
# 1 = FULL
# 2 = Errors Only

retval=$?

choice=`cat $tempfile`
case $retval in
  0)
	if [ "$choice" == "Errors" ]; then
	echo "Log set to Errors Only"
	export ERROR_LOG=ERRORS
	fi
	if [ "$choice" == "Full" ]; then
	echo "Log Full On"
	export ERROR_LOG=FULL
	fi
	if [ "$choice" == "Off" ]; then
	echo "Log If off"
	export ERROR_LOG=OFF
	fi
	build_log;;
  1)
    echo "Cancel pressed.";;
  255)
    echo "ESC pressed.";;
esac
}

function SET_LOCALVERSION() {
	if [ "$SET_LOCAL"  == 01 ]; then
	echo "Local Version From ${DEFCONFIG} Has been Changed to the Following:"
	echo ${DEFCONFIGS}/${DEFCONFIG} "CONFIG_LOCALVERSION" 'CONFIG_LOCALVERSION="'${KNAME}_${REV}_${KVER}'"'
	replace_line ${DEFCONFIGS}/${DEFCONFIG} "CONFIG_LOCALVERSION" 'CONFIG_LOCALVERSION="'${KNAME}_${REV}_${KVER}'"'
	else
	echo "Local Version From ${DEFCONFIG} Has not been changed."
    fi
}

## Pipe Output to Dialog Box ##
function pipe_output() {
	exec &> >(tee -a screen.log)
	dialog --title "$title" --tailbox screen.log 25 140
}


## Get Size Of Filename and Check it ##
function check_filesize() {
	minsize=3
	maxsize=18
	cd $ZIP_MOVE
	file=${KNAME}_${REV}_${VARIANT}_${KVER}.zip
	actualsize=$(du -k "$file" | cut -f 1)
	if [ $actualsize -ge $maxsize ]; then
    echo size is over $maxsize kilobytes
	else
    echo size is under $minimumsize kilobytes
	echo Size is: $actualsize
fi
}

## Unversal Message Box ##
## $TITLE = The Title
## $BACKTITLE = The Back Title
## $INFOBOX = Message you want displayed
function message() {
	dialog --title  "$TITLE"  --backtitle  "$BACKTITLE" \
	--infobox  "$INFOBOX" 7 65 ; read 
}


function menu_settings() {
while true
do

### display main menu ###
dialog --clear  --help-button --backtitle "Linux Shell Script Tutorial" \
--title "[ M A I N - M E N U ]" \
--menu "You can use the UP/DOWN arrow keys, the first \\n\
letter of the choice as a hot key, or the \\n\
number keys 1-5 to choose an option.\\n\
Choose the TASK" 23 60 15 \

	"Threads" "Change Default '$THREAD' Threads" \
	"MainMenu" "Exit to Main Menu" \
	"Exit" "Exit to the shell" 2>"${INPUT}"
 
	menuitem=$(<"${INPUT}")
 
 
# make decsion 
case $menuitem in
		Threads) build_kernels ;;
		MainMenu) main_menu ;; 
		Exit) echo "Bye"; exit;;
		Cancel) exit ;;
		255) echo "Cancel"; exit;;
esac
 
 done
}

## Batch Build ##
function build_all() {
		OIFS=$IFS
		IFS=';'
		arr2=$DEVICES
		for x in $arr2
		do
		VARIANT="$x"
		DEFCONFIG="${x}_defconfig"
		echo "Device: $VARIANT defconfig: $DEFCONFIG"
		clean_all
		build_log
		change_variant
		make_kernel
		make_dtb
		make_modules
		make_zip
done

IFS=$OIFS

echo -e "${green}"
echo "--------------------------------------------------------"
echo "Created Successfully.."
echo "Builds Completed in:"
echo "--------------------------------------------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo

# if temp files found, delete em
[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT
unset ERROR_LOG
exit
}

function make_kernel {
		echo
		TIME_START
		SET_LOCALVERSION
		echo
		mkdir -p $OUTPUT_DIR
		make O=$OUTPUT_DIR $DEFCONFIG
		if [ "$CLANG_BUILDS" == 1 ];then
		make O=$OUTPUT_DIR $THREAD ARCH=$ARCH \
		CC=$CC CLANG_TRIPLE=$CLANG_TRIPLE \
		CROSS_COMPILE=$CROSS_COMPILE INSTALL_MOD_STRIP=1
		else
		echo "NOTE: Not Using Clang:"
		make O=$OUTPUT_DIR $THREAD INSTALL_MOD_STRIP=1
		fi
}

function make_modules {
		if [ -f "$MODULES_DIR/*.ko" ]; then
			rm `echo $MODULES_DIR"/*.ko"`
		fi
		echo -e "\\e[34mCopying modules and Stripping them \\e[0m"
		find $KERNEL_DIR -name '*.ko' -type f -exec cp -v '{}' $MODULES_DIR/ \;
		cd $MODULES_DIR
		if [ "$STRIP_MODULES" == 1 ];then
		echo -e "${GREEN}"
		echo "----------------------------------------"
		echo -e "${RESTORE}"
		echo -e "${RED}Stripping Modules For Size"
		echo -e "${GREEN}"
		echo "----------------------------------------"
		echo -e "${RESTORE}"
		echo $STRIP --strip-unneeded --strip-debug --verbose *.ko
		$STRIP --strip-debug --verbose *.ko
		else
		echo "Not Stripping Modules, Set STRIP_MODULES=1 to Strip them."
		fi
		if [ "$SIGN_MODULES" == 1 ];then
		  echo -e "${GREEN}"
		  echo "----------------------------------------"
		  echo -e "${RESTORE}"
		  echo -e ""${RED}"Signing Modules:"
		  echo -e "${GREEN}"
		  echo "----------------------------------------"
		  echo -e "${RESTORE}"
		  echo "Signing Modules.........."
                  find $MODULES_DIR -name '*.ko' -exec \
		  $SIGNFILE_DIR/sign-file sha512 \
		  $MODULE_SIGNING_KEYS_DIR/${SIGNFILE_KEY_A} \
		  $MODULE_SIGNING_KEYS_DIR/${SIGNFILE_KEY_B} {} \;
		else
		  echo "WARNING: Not Signing Modules"
		fi
}

function make_dtb {
		if [ "$SPLIT_DTB" == 1 ];then
		DTB=`find . -name "*.dtb" | head -1`; echo $DTB
		echo $DTB
		DTBDIR=`dirname $DTB`
		echo $DTBDIR
		if [[ -z `strings $DTB | grep "qcom,board-id"` ]] ; then
		DTBVERCMD="--force-v3"
		echo $DTBVERCMD
		else
		DTBVERCMD="--force-v3"
		echo $DTBVERCMD
		fi
		echo `strings $DTB | grep "qcom,board-id"`
		$DTBTOOL_DIR/$DTBTOOL $DTBVERCMD -o $COMPRESSED_IMAGE_DIR/$DTBIMAGE -s 4096 -p scripts/dtc/ $DTBDIR/
fi
}

function make_boot {
		if [ "$SPLIT_DTB" == 1 ];then
		cp -vr $ZIMAGE_DIR/Image $COMPRESSED_IMAGE_DIR/Image
		else
		cp -vr $ZIMAGE_DIR/Image.gz-dtb $COMPRESSED_IMAGE_DIR/Image.gz-dtb
		fi
}

function make_zip {
		if [ "$USE_SCRIPTS" == 1 ];then
		cp -vr $RAMDISK_DIR $COMPRESSED_IMAGE_DIR
		fi
		cd $REPACK_DIR
		zip -r9 ${KNAME}_${REV}_${VARIANT}_${KVER}.zip * -x @zipexclude
		mv ${KNAME}_${REV}_${VARIANT}_${KVER}.zip $ZIP_MOVE
		rm -rf ${KNAME}_${REV}_${VARIANT}_${KVER}.zip
		cd $KERNEL_DIR
}


## Finished Build Displayed in a Dialog nfo box ##
function finished_build {
	TIME_END
	check_filesize
		if [ -e $ZIMAGE_DIR/$KERNEL ]; then
	dialog --title  "Build Finished"  --backtitle  "Build Finished" \
	--infobox "${KNAME}_${REV}_${VARIANT}_${KVER}.zip \\n\
	Created Successfully..\\n\
	FileSize: $actualsize kb \\n\
    Time: $TIME_LENGTH" 7 65 ; read 
	else
dialog --title  "Build Not Completed"  --backtitle  "Build Had Errors" \
	--infobox  "Build Aborted Do to errors, Image-gz doesnt exist,\n\
	Unsuccessful Build..\\n\
	Time: $TIME_LENGTH" 7 65 ; read
	cd $ZIP_MOVE
	rm -rf ${KNAME}_${REV}_${VARIANT}_${KVER}.zip
	cd $KERNEL_DIR
	fi
}

DATE_START=$(date +"%s")

function build_kernels {
echo -e "${green}"
echo "${KNAME} Creation Script:"
echo -e "${restore}"

## Build Menu ##
cmd=(dialog --keep-tite --menu "Select options:" 22 76 16)

options=( 1 "OnePlus 6T (6T T-Mo)"
	2 "OnePlus 6T (6T Global)"
	3 "OnePlus 6 (6 Global)"
	4 "OnePlus XX (XX T-Mo)"
        5 "Build All")

choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

for choice in $choices
do
    case $choice in
        1)	VARIANT="OnePlus6T"
		DEFCONFIG="elementalx_defconfig"
		break;;

        2)	VARIANT="OnePlus6"
		DEFCONFIG="elementalx_defconfig"
		break;;
		
        3)	VARIANT="us997"
		DEFCONFIG="lineageos_us997_defconfig"
		break;;
	
	4)	VARIANT="h918"
		DEFCONFIG="lineageos_h918_defconfig"
		break;;
		
	5)	VARIANT="msm"
		DEFCONFIG="msm_defconfig"
		break;;
		
	6) build_all
	  break;;
		
    esac

done

## Clean Left over Garbage Files Y/N ##
dialog --title "Clean Garbage Files" \
	--backtitle "Clean Junk From Build Dir" \
	--yesno "Do you want to clean garbage files ? \\n\
	Its a good idea do say yes here.." 7 60
 
	# Get exit status
	# 0 means user hit [yes] button.
	# 1 means user hit [no] button.
	# 255 means user hit [Esc] key.
	response=$?
	case $response in
	0) clean_all
	   buildkernel_msg;;
	1) echo "No Change";;
	255) echo "[ESC] key pressed.";;
esac

##  Build Kernel Y/N ##
dialog --title "Build Kernel" \
	--backtitle "Linux Shell Script Tutorial Example" \
	--yesno "You are about to Build Kernel For $VARIANT, \\n\
	Are you sure you want to build Kernel ?" 7 60
 
	# Get exit status
	# 0 means user hit [yes] button.
	# 1 means user hit [no] button.
	# 255 means user hit [Esc] key.
	response=$?
	case $response in
	0) 	build_log
 		if [ "$VARIANTS" == 1 ];then
		change_variant
		fi
		make_kernel
		make_dtb
		make_modules
		make_boot
		make_zip
		finished_build;;
	1) echo "File not deleted.";;
	255) echo "[ESC] key pressed.";;
esac
}

###############################################################################
### Script Settings ###                                                     ###
###############################################################################
function script_settings {

cmd=(dialog --keep-tite --menu "Select options:" 35 95 30)

options=(1 "KERNEL_DIR: ${KERNEL_DIR}"
         2 "DEFCONFIGS: ${DEFCONFIGS}"
		 3 "ZIP_MOVE: ${ZIP_MOVE}"
		 4 "COPY_ZIP: ${COPY_ZIP}"
		 5 "ZIMAGE_DIR: ${ZIMAGE_DIR}"
		 6 "RAMDISK_DIR: ${RAMDISK_DIR}"
		 7 "REPACK_DIR: ${REPACK_DIR}"
		 8 "PATCH_DIR: ${PATCH_DIR}"
		 9 "MODULES_DIR: ${MODULES_DIR}"
		 10 "TOOLS_DIR: ${TOOLS_DIR}"
		 11 "RAMDISK_DIR: ${RAMDISK_DIR}"
		 12 "DTBTOOL_DIR: ${DTBTOOL_DIR}"
		 13 "SIGNAPK: ${SIGNAPK}"
		 14 "SIGNAPK_KEY: ${SIGNAPK_KEY}"
		 17 "REV: ${REV}"	 
		 18 "KNAME: ${KNAME}"	 
		 19 "DEVICES: ${DEVICES}"	 
		 20 "KVER: ${KVER}"	 
		 21 "ARCH: ${ARCH}"	 
		 22 "SUBARCH: ${SUBARCH}"	 
		 23 "KBUILD_BUILD_USER: ${KBUILD_BUILD_USER}"	 
		 24 "KBUILD_BUILD_HOST: ${KBUILD_BUILD_HOST}"	 
		 25 "CCACHE: ${CCACHE}"	 
		 26 "ERROR_LOG: ${ERROR_LOG}"	 
		 27 "USE_SCRIPTS: ${USE_SCRIPTS}"	 
		 28 "DTBTOOL: ${DTBTOOL}"
		 29 "COMPRESSED_IMAGE_DIR: ${RAMDISK_DIR $COMPRESSED_IMAGE_DIR}"
		 30 "                     "
		 31 "                     "
		 32 "                     "
		 )

choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

for choice in $choices
do
    case $choice in
        1)
			echo "Not Implanted Yet"
			break;;
		2) echo "Not Implanted yet"
			break;;
		3) echo "Not Implanted yet"
			break;;
		
    esac

done

}

### Change TC Destro ###
function tc_changedestro() {
    dialog --backtitle "Change Toolchain Destro" \
           --radiolist "Choose Toolchain Destro To Use:" 15 50 8 \
		   01 "PureFusionTC" on\
		   02 "PUREFUSIONLLVM" off\
           03 "UBERTC" off\
           04 "LinaroTC" off\
           05 "CT-NG" off\
	       06 "SnapTC" off\
           07 "GoogleTC" off\
	       08 "QUVNTNM" off 2>$_temp
    result=`cat $_temp`
	TC_OLD="$TC_DESTRO"
	if [ "$result" == 01 ]; then
	echo "PureFusionTC"
		TC_DESTRO="PureFusionTC"
	fi
	if [ "$result" == 02 ]; then
	echo "PureFusionLLVM"
		TC_DESTRO="PUREFUSIONLLVM"
	fi
	if [ "$result" == 03 ]; then
	echo "UBER"
		TC_DESTRO="UBERTC"
	fi
	if [ "$result" == 04 ]; then
		echo "LinaroTC"
		TC_DESTRO="LinaroTC"
	fi
	if [ "$result" == 05 ]; then
		echo "Crosstool-ng"
		TC_DESTRO="CT-NG"
	fi
	if [ "$result" == 06 ]; then
		echo "SnapDragonTC"
		TC_DESTRO="SnapTC"
	fi
	if [ "$result" == 07 ]; then
		echo "GoogleTC"
		TC_DESTRO="GoogleTC"
	fi
	if [ "$result" == 08 ]; then
		echo "QUVNTNM"
		TC_DESTRO="QUVNTNM"
	fi
#    dialog --title " Item(s) selected " --msgbox "\nYou choose item: TC: ${TC_DESTRO} $result" 6 44
	replace_string build-anykernel.cfg "TC_DESTRO=$TC_OLD" "$TC_OLD" "$TC_DESTRO"
	break
}

## Change ToolChains ##
function defconfig_change() {
    fileroot=$DEFCONFIGS
    IFS_BAK=$IFS
    IFS=$'\n' # wegen Filenamen mit Blanks
    array=( $(ls $fileroot) )
    n=0
    for item in ${array[@]}
    do
        menuitems="$menuitems $n ${item// /_}" # subst. Blanks with "_"  
        let n+=1
    done
    IFS=$IFS_BAK
    dialog --backtitle "ToolChain Selection:" \
           --title "Select a Toolchain:" --menu \
           "Choose one of the available Toolchains:" 16 58 8 $menuitems 2> $_temp
    if [ $? -eq 0 ]; then
        item=`cat $_temp`
        selection=${array[$(cat $_temp)]}
		#TC_OLD="$TC_NAME"
		DEFCONFIG="$selection"
        dialog --msgbox "You choose:\nNo. $item --> $selection" 6 50
echo "test"
    fi
    
## Clean Left over Garbage Files Y/N ##
dialog --title "Clean Garbage Files" \
	--backtitle "Clean Junk From Build Dir" \
	--yesno "Do you want to clean garbage files ? \\n\
	Its a good idea do say yes here.." 7 60
 
	# Get exit status
	# 0 means user hit [yes] button.
	# 1 means user hit [no] button.
	# 255 means user hit [Esc] key.
	response=$?
	case $response in
	0) clean_all
	   buildkernel_msg;;
	1) echo "No Change";;
	255) echo "[ESC] key pressed.";;
esac

##  Build Kernel Y/N ##
dialog --title "Build Kernel" \
	--backtitle "Linux Shell Script Tutorial Example" \
	--yesno "You are about to Build Kernel For $VARIANT, \\n\
	Are you sure you want to build Kernel ?" 7 60
 
	# Get exit status
	# 0 means user hit [yes] button.
	# 1 means user hit [no] button.
	# 255 means user hit [Esc] key.
	response=$?
	case $response in
	0) 	build_log
		change_variant 
		make_kernel
		make_dtb
		make_modules
		make_boot
		make_zip
		finished_build;;
	1) echo "File not deleted.";;
	255) echo "[ESC] key pressed.";;
esac
}

## Change ToolChains ##
function tc_change() {
    fileroot=$TOOLCHAIN_DIR/${TC_DESTRO}
    IFS_BAK=$IFS
    IFS=$'\n' # wegen Filenamen mit Blanks
    array=( $(ls $fileroot) )
    n=0
    for item in ${array[@]}
    do
        menuitems="$menuitems $n ${item// /_}" # subst. Blanks with "_"  
        let n+=1
    done
    IFS=$IFS_BAK
    dialog --backtitle "ToolChain Selection:" \
           --title "Select a Toolchain:" --menu \
           "Choose one of the available Toolchains:" 16 58 8 $menuitems 2> $_temp
    if [ $? -eq 0 ]; then
        item=`cat $_temp`
        selection=${array[$(cat $_temp)]}
		TC_OLD="$TC_NAME"
		TC_NAME="$selection"
        dialog --msgbox "You choose:\\nNo. $item --> $selection" 6 50
		replace_string build-anykernel.cfg "TC_NAME=$TC_OLD" "$TC_OLD" "$TC_NAME"
    fi
}

## Change Clang ##
function clang_change() {
    fileroot=$TOOLCHAIN_DIR/clang
    IFS_BAK=$IFS
    IFS=$'\n' # wegen Filenamen mit Blanks
    array=( $(ls $fileroot) )
    n=0
    for item in ${array[@]}
    do
        menuitems="$menuitems $n ${item// /_}" # subst. Blanks with "_"  
        let n+=1
    done
    IFS=$IFS_BAK
    dialog --backtitle "ToolChain Selection:" \
           --title "Select a Clang Chain:" --menu \
           "Choose one of the available Clang:" 16 58 8 $menuitems 2> $_temp
    if [ $? -eq 0 ]; then
        item=`cat $_temp`
        selection=${array[$(cat $_temp)]}
		CLANG_OLD="$CLANG_NAME"
		CLANG_NAME="$selection"
        dialog --msgbox "You choose:\\nNo. $item --> $selection" 6 50
		replace_string build-anykernel.cfg "CLANG_NAME=$CLANG_OLD" "$CLANG_OLD" "$CLANG_NAME"
    fi
} 

###############################################################################
### TC Main Menu ###                                                        ###
###############################################################################
function tc_menu {

cmd=(dialog --keep-tite --menu "Select options:" 22 76 16)

options=(1 "Change Clang: Current: ${CLANG_NAME}"
        2 "Change ToolChain: Current: ${TC_NAME}"
         3 "Change Destro Current: ${TC_DESTRO}"
		 4 "Change Prefix")

choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

for choice in $choices
do
    case $choice in
		1)	clang_change
			break;;
		2)	tc_change
			break;;
		3)  tc_changedestro
			break;;
		4) echo "Not Implanted yet"
			break;;
		
    esac

done

}

###############################################################################
### DO NOT REMOVE OR MOVE THIS ###                                          ###
###############################################################################
 function main_menu() {
	set_timestamp
	while true
	do
###############################################################################
### MAIN MENU ###                                                           ###
###############################################################################
dialog --clear  --help-button --backtitle "Build Script W/AnyKernel2 Support:" \
		--title "[ M A I N - M E N U ]" \
		--cancel-label "Quit" \
		--menu "You can use the UP/DOWN arrow keys, the first \\n\
				letter of the choice as a hot key, or the \\n\
				number keys 1-9 to choose an option.\\n\
				Choose the TASK" 23 60 15 \
		"Build" "Build Kernels" \
		"Clean"	"Clean Builds" \
		"TC" "TC: $TC_NAME" \
		"Log" "Logging Options [Log: $ERROR_LOG]" \
		"Ccache" "Clear Ccache" \
		"Build_Zip" "Build Final Kernel Zip" \
		"Settings" "Settings" \
		"Test" "Testing Stage Area" \
		"Defconfig" "Change Defconfig" \
		"Exit" "Exit to the shell" 2>"${INPUT}"
 
	menuitem=$(<"${INPUT}")
 
 
# make decsion 
case $menuitem in
		Build) build_kernels ;;
		Clean) clean_all ;;
		TC) tc_menu ;;
		Log) menu_log ;;
		Ccache) echo "Clearing Ccache.."; rm -rf "${HOME}"/.ccache ;;
		Build_Zip) make_zip; exit;;
		Settings) menu_settings ;;
		Test) script_settings ; exit ;;
		Defconfig) defconfig_change ;;
		Exit) CLEAN_UP; exit ;;
		1) CLEAN_UP; exit ;;
		255) echo "Cancel"; exit;;
esac
if [ "$menuitem" == "" ]; then exit
	fi
 done
}

#-----------------------------------------------------------------------------#

main() {
	CLEAN_UP
	INITIALIZE_SCRIPT
    main_menu
}

INITIALIZE_SCRIPT "$@"
main "$@"
