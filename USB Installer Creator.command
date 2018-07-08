#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

# Turn on case-insensitive matching
shopt -s nocasematch
# turn on extended globbing
shopt -s extglob

usbName=""
usbMount=""
usbIdent=""
usbDisk=""
usbPart=""

insMED=""
insDir=""

insESD=""
insESDMount=""
insESDIdent=""
insBaseSystem=""
insBaseSystemMount=""
insBaseSystemIdent=""

installerName="Install OS X/macOS.app"

scriptName="Create USB Installer"
scriptMessage="Select your USB drive:"

title="Create USB Installer"
subtitle="by CorpNewt"
sound="Pop.aiff"

function notification () {
    nTitle="$1"
    nSub="$2"
    nSound="$3"

    if [[ -z "$1" ]]; then
        # No title variable
        nTitle="$title"
    fi
    if [[ -z "$2" ]]; then
        # No subtitle variable
        nSub="$subtitle"
    fi
    if [[ -z "$3" ]]; then
        # No sound variable
        nSound="$sound"
    fi

# Display our notification
osascript <<EOF
display notification with title "$nTitle" subtitle "$nSub" sound name "$nSound"
EOF
}

function resetVars () {
    usbName=""
    usbMount=""
    usbIdent=""
    usbDisk=""
    usbPart=""

    insMED=""
    insDir=""

    insESD=""
    insESDMount=""
    insESDIdent=""
    insBaseSystem=""
    insBaseSystemMount=""
    insBaseSystemIdent=""
}

function setDisk () {
    usbName="$( getDiskName "$1" )"
    usbMount="$( getDiskMountPoint "$1" )"
    usbIdent="$( getDiskIdentifier "$1" )"
    usbDisk="$( getDiskNumber "$1" )"
    usbPart="$( getPartitionNumber "$1" )"
}

function displayWarning () {
    clear
    echo \#\#\# WARNING \#\#\#
    echo 
    echo This script is provided with NO WARRANTY whatsoever.
    echo I am not responsible for ANY problems or issues you
    echo may encounter, or any damages as a result of running
    echo this script.
    echo 
    echo To ACCEPT this warning and FULL RESPONSIBILITY for
    echo using this script, press [enter].
    echo 
    read -p "To REFUSE, close this script."
    mainMenu

}

function customQuit () {
    clear
    echo \#\#\# USB Installer Creator \#\#\#
    echo by CorpNewt
    echo 
    echo Thanks for testing it out, for bugs/comments/complaints
    echo send me a message on Reddit, or check out my GitHub:
    echo 
    echo www.reddit.com/u/corpnewt
    echo www.github.com/corpnewt
    echo 
    echo Have a nice day/night!
    echo 
    echo 
    shopt -u extglob
    shopt -u nocasematch
    exit $?
}

function mainMenu () {
    resetVars
    # Main Menu
    clear
    echo \#\#\# USB Installer Creator \#\#\#
    echo 
    echo 1. Create With createinstallmedia
    echo 2. Create With asr \(older way\)
    echo 
    echo ?. Help
    echo 
    echo Q. Quit
    echo 
    echo Please select a task:
    echo 
    read menuChoice

    if [[ "$menuChoice" == "1" ]]; then
        createUSB
    elif [[ "$menuChoice" == "2" ]]; then
        createUSBESD
    elif [[ "$menuChoice" == "q" ]]; then
        customQuit
    elif [[ "$menuChoice" == "?" ]]; then
        mainHelp
    fi
    mainMenu
}

function trimWhitespace () {
    # Trim leading and trailing whitespace
    local var=$1
    var=${var##+([[:space:]])}
    var=${var%%+([[:space:]])}
    echo -n "$var"
}

function mainHelp () {
    # Give some info on the main menu options.
    clear
    echo \#\#\# Main Menu Help \#\#\#
    echo 
    echo 1. Create With createinstallmedia - this uses the
    echo "createinstallmedia" binary located inside the
    echo OSX/macOS install application to build the USB.
    echo It is only available in OS 10.9+ installers - it\'s
    echo also worth noting that you can only run that binary
    echo on a machine running 10.9+ or it will fail.
    echo 
    echo 2. Create With asr \(older way\) - this uses asr
    echo \(Apple Software Restore\) to build the USB.  This
    echo method should be capable of building installers for
    echo 10.7+ - the asr command should be available on any
    echo version of OSX/macOS, meaning this is a viable
    echo solution for anyone running a pre-10.9 OS and
    echo trying to build a newer install USB.
    echo
    read -p "Press [enter] to return to the main menu..."

    mainMenu
}

function createUSBESD () {
    checkRoot "USBESD"
    clear
    echo \#\#\# Create USB Installer \#\#\#
    echo Using ASR \(Apple Software Restore\)
    echo
    echo Warning!
    echo 
    echo Please make sure you have connected an 8GB+ \(16GB recommended\)
    echo USB flash drive and a copy of the \"$installerName\" application to 
    echo continue!
    echo 
    echo This script tested ONLY with Mac OS X 10.9+
    echo 
    echo 
    read -p "Press [enter] to continue..."

    clear

    echo Please drag and drop the \"$installerName\" application or
    echo \"InstallESD.dmg\" here or type the path:
    echo 
    echo 
    read insDir

    if [ "$insDir" == "" ]; then
        createUSBESD
        return 0
    fi

    esdCheck="$( basename "$insDir" )"

    if [[ "$esdCheck" == *.dmg ]]; then
        # We have a dmg - let's proceed accordingly
        if [ ! -e "$insDir" ]; then
            clear
            echo Required files were missing in the installer.
            echo 
            echo "$insDir"
            echo Does not exist.
            echo 
            exit
        fi
        insESD="$insDir"
    else
        # Not a dmg - let's check for one
        if [ ! -e "$insDir/Contents/SharedSupport/InstallESD.dmg" ]; then
            clear
            echo Required files were missing in the installer.
            echo 
            echo "$insDir/Contents/SharedSupport/InstallESD.dmg"
            echo Does not exist.
            echo 
            exit
        fi

        insESD="$insDir/Contents/SharedSupport/InstallESD.dmg"
    fi

    clear

    pickDisk usb "$scriptName" "Please drag and drop (or type the name) the USB drive you would like to use as the installer:"

    eraseUSBESD "$usb"

}

function eraseUSBESD () {
    # Set up some info for later use
    setDisk "$1"

    checkErase erase

    # Unmount the USB drive
    clear
    echo \#\#\# Create USB Installer \#\#\#
    echo 

    if [[ "$erase" == "1" ]]; then
        
        # Post Notification
        notification "Erasing $usbName" "Formatting to JHFS+ GUID Partition Map"
        
        echo Unmounting "$usbName"...
        echo 

        checkMount "$usbIdent"

        # Reformat it to Journaled HFS+ with a GUID Partition Table
        #clear
        #echo \#\#\# Create USB Installer \#\#\#
        echo 
        echo Formatting disk disk"$usbDisk" to JHFS+ with GUID partition
        echo table...
        echo
        diskutil partitionDisk /dev/disk"$usbDisk" GPT JHFS+ "$usbName" 100%
    fi

    # Run the createinstallmedia program
    #clear
    #echo \#\#\# Create USB Installer \#\#\#
    
    echo 
    echo Creating Installer \(This will take awhile\)...
    echo 
    # echo "$insMED" --volume "$usbMount" --applicationpath "$insDir" --no interaction
    #echo hdiutil attach -noverify -nobrowse "$insESD"
    #echo 

    # Get the dmg mount point and identifier - ident is so much more helpful
    insESDIdent="$( mountDiskImage "$insESD" )"
    insESDMount="$( getDiskMountPoint "$insESDIdent" )"

    # "$insMED" --volume "$usbMount" --applicationpath "$insDir" --no interaction

    if [ ! -e "$insESDMount/BaseSystem.dmg" ]; then
        # Post Notification
        notification "Installer Creation Aborted!" "InstallESD.dmg is missing files..."
        echo InstallESD.dmg is missing files...
        checkMount "$insESDIdent"
        echo 
        exit
    fi

    echo 
    echo Attaching BaseSystem.dmg...
    echo

    # Get the dmg mount point and identifier - ident is so much more helpful
    insBaseSystemIdent="$( mountDiskImage "$insESDMount/BaseSystem.dmg" )"
    insBaseSystemMount="$( getDiskMountPoint "$insBaseSystemIdent" )"
    
    # Post Notification
    notification "Restoring OS X Base System" "This will take awhile..."

    echo 
    echo Restoring OS X Base System to "$usbName"...
    echo
    #cp -R -p "$insBaseSystemMount/" "$usbMount"
    asr -source "$insBaseSystemMount" -target "$usbMount" -erase -noprompt

    echo

    #Get disk info again since the volume name is most likely
    #different than before...

    local newName="$( getDiskName "$usbIdent" )"
    if [[ "$newName" != "$usbName" ]]; then
        echo \""$usbName"\" has been changed to \""$newName"\"...
        echo
        echo Renaming back to \""$usbName"\"...
        echo
        diskutil rename $usbIdent "$usbName"
        # usbName="$newName"
        echo 
    fi

    echo 
    echo Unmounting OS X Base System...
    echo
    checkMount "$insBaseSystemIdent"
    eject "$insBaseSystemIdent"
    echo

    # Post Notification
    notification "Copying Packages from OS X Base System" "This will take awhile..."

    echo 
    echo Copying Packages from OS X Base System...
    echo
    rm -Rf "$usbMount/System/Installation/Packages"
    cp -R -p "$insESDMount/Packages/" "$usbMount/System/Installation/Packages/"
    echo
    echo Copying BaseSystem.chunklist to "$usbName"...
    echo
    cp -R -p "$insESDMount/BaseSystem.chunklist" "$usbMount/BaseSystem.chunklist"

    # Post Notification
    notification "Copying BaseSystem.dmg" "This will take awhile..."

    echo 
    echo Copying BaseSystem.dmg to "$usbName"...
    echo
    cp -R -p "$insESDMount/BaseSystem.dmg" "$usbMount/BaseSystem.dmg"
    echo


    echo Unmounting OS X Install ESD...
    echo
    checkMount "$insESDIdent"
    eject "$insESDIdent"

    #Get disk info again since the volume name is most likely
    #different than before...
    
    # Post Notification
    notification "Done!" "Finished setting up $usbName"

    echo
    echo Done.
    echo

    sleep 3
    mainMenu
}

function mountDiskImage () {
    # This function mounts the passed disk image, and
    # returns the mount point
    local __imagePath=$1

    # Old way got mount point - this way gets the identifier
    # echo "/Volumes/$( hdiutil attach -noverify -nobrowse "$__imagePath" | grep -i "/Volumes/" | cut -d / -f 5 )"
    echo "$( hdiutil attach -noverify -nobrowse "$__imagePath" | grep -i "/dev/disk" | tail -f -n 1 | cut -d ' ' -f 1 | cut -d '/' -f 3)"
}

function createUSB () {
    checkRoot "USB"
    clear
    echo \#\#\# Create USB Installer \#\#\#
    echo Using createinstallmedia
    echo 
    echo Warning!
    echo 
    echo Please make sure you have connected an 8GB+ \(16GB recommended\)
    echo USB flash drive and a copy of the \"$installerName\" application to 
    echo continue!
    echo 
    echo This script works ONLY with Mac OS X 10.9+
    echo 
    echo 
    read -p "Press [enter] to continue..."

    clear

    echo Please drag and drop the \"$installerName\" application
    echo here or type the path:
    echo 
    echo 
    read insDir

    if [ "$insDir" == "" ]; then
        createUSB
        return 0
    fi

    if [ ! -e "$insDir/Contents/Resources/createinstallmedia" ]; then
        clear
        echo Required files were missing in the installer.
        echo 
        echo "$insDir/Contents/Resources/createinstallmedia"
        echo Does not exist.
        echo 
        exit
    fi

    insMED="$insDir/Contents/Resources/createinstallmedia"

    clear

    pickDisk usb "$scriptName" "Please drag and drop (or type the name) the USB drive you would like to use as the installer:"

    eraseUSB "$usb"

}

function eraseUSB () {
    # Set up some info for later use
    setDisk "$1"

    checkErase erase
    if [[ "$erase" == "1" ]]; then
    
        # Post Notification
        notification "Erasing $usbName" "Formatting to JHFS+ GUID Partition Map"
    
        # Erase the disk
        # Unmount the USB drive
        clear
        echo \#\#\# Create USB Installer \#\#\#
        echo Using createinstallmedia
        echo 

        echo Unmounting "$usbName"...
        echo 

        checkMount "$usbIdent"

        # Reformat it to Journaled HFS+ with a GUID Partition Table
        clear
        echo \#\#\# Create USB Installer \#\#\#
        echo Using createinstallmedia
        echo 
        echo Formatting disk disk"$usbDisk" to JHFS+ with GUID partition
        echo table...

        diskutil partitionDisk /dev/disk"$usbDisk" GPT JHFS+ "$usbName" 100%
    fi

    # Post Notification
    notification "Creating USB Installer" "This will take awhile..."

    # Run the createinstallmedia program
    clear
    echo \#\#\# Create USB Installer \#\#\#
    echo Using createinstallmedia
    echo 
    echo Creating Installer \(This will take awhile\)...
    echo 
    echo "$insMED" --volume "$usbMount" --applicationpath "$insDir" --no interaction
    echo 

    "$insMED" --volume "$usbMount" --applicationpath "$insDir" --no interaction


    echo 

    #Get disk info again since the volume name is most likely
    #different than before...

    local newName="$( getDiskName "$usbIdent" )"
    clear
    echo \#\#\# Create USB Installer \#\#\#
    echo Using createinstallmedia
    echo 
    if [[ "$newName" != "$usbName" ]]; then
        echo \""$usbName"\" has been renamed to \""$newName"\"...
        echo
        echo Renaming back to \""$usbName"\"...
        echo
        diskutil rename $usbIdent "$usbName"
        # usbName="$newName"
        echo 
    fi
    
    # Post Notification
    notification "Done!" "Finished setting up $usbName"
    
    echo Done.
    echo
    sleep 3
    mainMenu
}

function checkErase () {
    clear
    echo \#\#\# Check Erase \#\#\#
    echo
    echo Do you want to erase and repartition the USB disk
    echo first?  This will set up the USB disk with the
    echo following:
    echo
    echo Single Partition - OS X Extended \(Journaled\)
    echo GUID Partition Table
    echo
    echo Erase? \(y/n\):
    echo
    read toErase

    if [[ "$toErase" == "y" ]]; then
        eval $1=1
    elif [[ "$toErase" == "n" ]]; then
        eval $1=0
    else
        checkErase $1
    fi
}

function checkMount () {
    #echo Checking mount status...
    # We SHOULD only ever get here after confirming we have a valid disk
    if [ "$( getDiskMounted "$1" )" == "Yes" ]; then
        echo "$( getDiskName "$1" )" is still mounted.  Unmounting...
        unmount "$1"
    fi
}

function unmount () {
    #repeats to unmount a stuck disk
    #echo Unmounting Disk...
    hdiutil unmount -force "$( getDiskMountPoint "$1" )"
    checkMount "$1"
}

function eject () {
    # ejects a disk - only runs once
    hdiutil detach -force "disk$( getDiskNumber "$1" )"
}

function checkRoot () {
    if [[ "$(whoami)" != "root" ]]; then
        clear
        echo This script requires root privileges.
        echo Please enter your admin password to continue.
        echo 
        sudo "$0" "$1" "$installerName" "$installerVersion"
        exit $?
    fi

}

###################################################
###               Disk Functions                ###
###################################################

function pickDisk () { 
    #$1 = callback drive picked
    #$2 = title
    #$3 = prompt


    local __returnVar="$1"
    local __scriptName="$2"
    local __message="$3"

    clear
    echo \#\#\# "$__scriptName" \#\#\#
    echo
    echo "$__message"
    echo 

    local driveList="$( cd /Volumes/; ls -1 | grep "^[^.]" )"
    unset driveArray
    IFS=$'\n' read -rd '' -a driveArray <<<"$driveList"

    #driveCount="${#driveArray[@]}"
    local driveCount=0
    local driveIndex=0

    for aDrive in "${driveArray[@]}"
    do
        (( driveCount++ ))
        echo "$driveCount". "$aDrive"
    done

    driveIndex=$(( driveCount-1 ))

    #ls /volumes/
    echo 
    echo 
    read drive

    if [[ "$drive" == "" ]]; then
        #drive="/"
        #pickDrive
        pickDisk "$1" "$2" "$3"
    fi

    #Notice - must have the single brackets or this
    #won't accurately tell if $drive is a number.
    if [ "$drive" -eq "$drive" ] 2>/dev/null; then
        #We have a number - check if it's in the array
        if [  "$drive" -le "$driveCount" ] && [  "$drive" -gt "0" ]; then
            drive="${driveArray[ (( $drive-1 )) ]}"
        else
            echo Index "$drive" out of range, checking for drive name...
        fi
    fi

    if [[ "$( isDisk "$drive" )" != "0" ]]; then
        if [[ "$( volumeName "$drive" )" ]]; then
            # We have a valid disk
            drive="$( volumeName "$drive" )"
            #setDisk "$drive"
        else
            # No disk available there
            echo \""$drive"\" is not a valid disk name, identifier
            echo or mount point.
            echo 
            read -p "Press [enter] to return to drive selection..."
            pickDisk "$1" "$2" "$3"
        fi
    fi

    # We have a valid drive - return it's diskIdent

    eval $__returnVar="$( getDiskIdentifier "$drive" )"

}

function isDisk () {
    # This function checks our passed variable
    # to see if it is a disk
    # Accepts mount point, diskXsX and an empty variable
    # If empty, defaults to "/"
    local __disk=$1
    if [[ "$__disk" == "" ]]; then
        __disk="/"
    fi
    # Here we run diskutil info on our __disk and see what the
    # exit code is.  If it's "0", we're good.
    diskutil info "$__disk" &>/dev/null
    # Return the diskutil exit code
    echo $?
}

function volumeName () {
    # This is a last-resort function to check if maybe
    # Just the name of a volume was passed.
    local __disk=$1
    if [[ ! -d "$__disk" ]]; then
        if [ -d "/volumes/$__disk" ]; then
            #It was just volume name
            echo "/Volumes/$__disk"
        fi
    else
        echo "$__disk"
    fi
}

function getDiskMounted () {
    local __disk=$1
    # If variable is empty, set it to "/"
    if [[ "$__disk" == "" ]]; then
        __disk="/"
    fi
    # Output the "Volume Name" of __disk
    echo "$( diskutil info "$__disk" | grep 'Mounted' | cut -d : -f 2 | sed 's/^ *//g' | sed 's/ *$//g' )"
}

function getDiskName () {
    local __disk=$1
    # If variable is empty, set it to "/"
    if [[ "$__disk" == "" ]]; then
        __disk="/"
    fi
    # Output the "Volume Name" of __disk
    echo "$( diskutil info "$__disk" | grep 'Volume Name' | cut -d : -f 2 | sed 's/^ *//g' | sed 's/ *$//g' )"
}

function getDiskMountPoint () {
    local __disk=$1
    # If variable is empty, set it to "/"
    if [[ "$__disk" == "" ]]; then
        __disk="/"
    fi
    # Output the "Mount Point" of __disk
    echo "$( diskutil info "$__disk" | grep 'Mount Point' | cut -d : -f 2 | sed 's/^ *//g' | sed 's/ *$//g' )"
}

function getDiskIdentifier () {
    local __disk=$1
    # If variable is empty, set it to "/"
    if [[ "$__disk" == "" ]]; then
        __disk="/"
    fi
    # Output the "Mount Point" of __disk
    echo "$( diskutil info "$__disk" | grep 'Device Identifier' | cut -d : -f 2 | sed 's/^ *//g' | sed 's/ *$//g' )"
}

function getDiskNumbers () {
    local __disk=$1
    # If variable is empty, set it to "/"
    if [[ "$__disk" == "" ]]; then
        __disk="/"
    fi
    # Output the "Device Identifier" of __disk
    # If our disk is "disk0s1", it would output "0s1"
    echo "$( getDiskIdentifier "$__disk" | cut -d k -f 2 )"
}

function getDiskNumber () {
    local __disk=$1
    # If variable is empty, set it to "/"
    if [[ "$__disk" == "" ]]; then
        __disk="/"
    fi
    # Get __disk identifier numbers
    local __diskNumbers="$( getDiskNumbers "$__disk" )"
    # return the first number
    echo "$( echo "$__diskNumbers" | cut -d s -f 1 )"
}

function getPartitionNumber () {
    local __disk=$1
    # If variable is empty, set it to "/"
    if [[ "$__disk" == "" ]]; then
        __disk="/"
    fi
    # Get __disk identifier numbers
    local __diskNumbers="$( getDiskNumbers "$__disk" )"
    # return the second number
    echo "$( echo "$__diskNumbers" | cut -d s -f 2 )"	
}

function getPartitionType () {
    local __disk=$1
    # If variable is empty, set it to "/"
    if [[ "$__disk" == "" ]]; then
        __disk="/"
    fi
    # Output the "Volume Name" of __disk
    echo "$( diskutil info "$__disk" | grep 'Partition Type' | cut -d : -f 2 | sed 's/^ *//g' | sed 's/ *$//g' )"
}

function getEFIIdentifier () {
    local __disk=$1
    local __diskName="$( getDiskName "$__disk" )"
    local __diskNum="$( getDiskNumber "$__disk" )"
    # If variable is empty, set it to "/"
    if [[ "$__disk" == "" ]]; then
        __disk="/"
    fi
    # Output the "Device Identifier" for the EFI partition of __disk
    endOfDisk="0"
    i=1
    while [[ "$endOfDisk" == "0" ]]; do
        # Iterate through all partitions of the disk, and return those that
        # are EFI
        local __currentDisk=disk"$__diskNum"s"$i"
        # Check if it's a valid disk, and if not, exit the loop
        if [[ "$( isDisk "$__currentDisk" )" != "0" ]]; then
            endOfDisk="true"
            continue
        fi

        local __currentDiskType="$( getPartitionType "$__currentDisk" )"

        if [ "$__currentDiskType" == "EFI" ]; then
            echo "$( getDiskIdentifier "$__currentDisk" )"
        fi
        i="$( expr $i + 1 )"
    done	
}

function getUUID () {
    local __disk=$1
    # If variable is empty, set it to "/"
    if [[ "$__disk" == "" ]]; then
        __disk="/"
    fi
    # Output the "Disk / Partition UUID" of __disk
    echo "$( diskutil info "$__disk" | grep 'Disk / Partition UUID' | cut -d : -f 2 | sed 's/^ *//g' | sed 's/ *$//g' )"
}

function diskInfo () {
    # Echoes some info on the passed disk
    if [[ "$( isDisk "$1" )" == "0" ]]; then
        echo Is Disk: YES
        echo Disk Name: "$( getDiskName "$1" )"
        echo Mount Point: "$( getDiskMountPoint "$1" )"
        echo Disk Identifier: "$( getDiskIdentifier "$1" )"
        echo Disk Numbers: "$( getDiskNumbers "$1" )"
        echo Disk Number: "$( getDiskNumber "$1" )"
        echo Partition Number: "$( getPartitionNumber "$1" )"
    else
        echo Is Disk: NO
    fi

}


########################################
###           Script Start           ###
########################################

# Check if we restarted due to needing sudo permissions
# and go from there...

if [[ "$1" == "USB" ]]; then
    createUSB
elif [[ "$1" == "USBESD" ]]; then
    createUSBESD
else
    displayWarning
fi

exit
