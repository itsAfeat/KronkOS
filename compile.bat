@echo off

cls
echo Building KronkOS floppy image!
echo.
echo Assembling bootloader...
echo ======================================================
wsl nasm -f bin bootloader/boot.asm -o bootloader/boot.bin
echo Done!

echo.
echo Assembling KronkOS kernel...
echo ======================================================
wsl nasm -f bin kernel.asm -o KERNEL.BIN -l kernel_list.lst
echo Done!

::echo.
::echo Creating elf kernel file...
::echo ======================================================
::wsl nasm -f elf32 -o kernel.o kernel.asm
::wsl ld -m elf_i386 -o kernel.elf kernel.o
::del kernel.o
::echo Done!

echo.
echo Assembling programs...
echo ======================================================
cd programs
    for %%i in (*.BKF) do del %%i
    for %%i in (*.ASM) do wsl nasm -O0 -f BIN %%i
    for %%i in (*.) do ren %%i %%i.BKF
cd ..
echo Done!

echo.
echo Adding bootsector to disk image...
echo ======================================================
wsl mformat -f 1440 -B bootloader/boot.bin -C -i images/KronkOS.img
echo.
echo Done!

echo.
echo Copying kernel and applications to disk image...
echo ======================================================
wsl mcopy -D o -i images/KronkOS.img KERNEL.BIN ::/
wsl mcopy -D o -i images/KronkOS.img programs/*.BKF ::/
wsl mcopy -D o -i images/KronkOS.img programs/*.BAS ::/
echo.
echo Done!

echo.
echo Do you want to build and ISO?
echo ======================================================
choice /c YN
if errorlevel 1 set x=1
if errorlevel 2 set x=2

if "%x%" == "1" (
    cd images
    wsl genisoimage -input-charset utf-8 -o KronkISO.iso -V KRONKOS -b KronkOS.img ./
    cd..
    echo.
    echo Done!
)

echo.
echo ======================================================
echo Build done!
choice /c YN /m "Run KronkOS build in QEMU?"
if errorlevel 1 set y=1
if errorlevel 2 set y=2

if "%y%" == "1" (
    if "%1" == "-d" (
        qemu-system-x86_64.exe -s -S -fda images/KronkOS.img
    ) else (
        if "%x%" == "1" (
            qemu-system-x86_64.exe -cdrom images/KronkISO.iso
        ) else (
            qemu-system-x86_64.exe -fda images/KronkOS.img
        )
    )
)
