#!/bin/bash
HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=4
BACKTITLE="KronkOS Compile"
TITLE="Run build?"

function progessBar () {
    local counter = 0
    while :
    do
        echo $counter | dialog --backtitle "$BACKTITLE" --title "$2" --gauge "$1" 7 70 0
        (( counter+=( RANDOM%75 +1) ))
        [ $counter -ge 100 ] && break
        sleep 0.75
    done
}

clear
progessBar "Assembling bootloader..." "Bootloader"
nasm -f bin bootloader/boot.asm -o bootloader/boot.bin

progessBar "Assembling KronkOS kernel..." "Kernel"
nasm -f bin kernel.asm -o KERNEL.BIN -l kernel_list.lst

progessBar "Adding bootsector to disk image..." "Disk image"
mformat -f 1440 -B bootloader/boot.bin -C -i images/KronkOS.img

progessBar "Copying kernel and applications to disk image..." "Disk image"
mcopy -D o -i images/KronkOS.img KERNEL.BIN ::/
mcopy -D o -i images/KronkOS.img programs/*.BKF ::/
mcopy -D o -i images/KronkOS.img programs/*.BAS ::/

dialog --clear --title "Build done!" --backtitle "$BACKTITLE" --yesno "Run build?" 7 60
response=$?
echo
echo "Run build?"
select response in Yes No
do
    case $response in
        "Yes") qemu-system-i386 -fda images/KronkOS.img
                break ;;
        "No") break ;;
        *) break ;;
    esac
done

clear