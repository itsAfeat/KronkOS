; ==================================================================
; The Kronk Operating System bootloader
; Copyright (C) 2019 - 2020 Alexander Wiencken
;
; Based on the bootloader made by the MikeOS Developers
; This must grow no larger than 512 bytes (one sector), with the final
; two bytes being the boot signature (0xAA55). Note that in FAT12,
; a cluster is the same as a sector: 512 bytes
; ==================================================================

    ORG 0x0000
	BITS 16

	jmp short bootloader_start	; Jump past disk description section
	nop				            ; Pad out before disk description

; ------------------------------------------------------------------
; Disk descriptor table, to make it a valid floppy
; Note: some of these values are hard-coded in the source!
; Values are those used by IBM for 1.44 MB, 3.5" diskette

OEMLabel            db "KBOOT   "       ; Disk label [Must be 8 chars]
BytesPerSector      dw 512              ; Bytes per sector
SectorsPerCluster   db 1                ; Secters per cluster
ReservedForBoot     dw 1                ; Resrved sectors for boot record
NumberOfFats        db 2                ; Number of copies of FAT
RootDirEntries      dw 224              ; Number of entries in root dir
                                        ; (224 * 32 = 7168 = 14 sectors to read)
LogicalSectors      dw 2880             ; Number of logical sectors
MediumByte          db 0x0F0            ; Medium descriptor byte
SectorsPerFat       dw 9                ; Sectors per FAT
SectorsPerTrack     dw 18               ; Sectors per track (36/cylinder)
Sides               dw 2                ; Number of sides/heads
HiddenSectors       dd 0                ; Number of hidden sectors
LargeSectors        dd 0                ; Number of LBA sectors
DriveNo             dw 0                ; Drive number = 0
Signature           db 41               ; Drive signature = 41 for floppy
VolumeID            dd 0x00000000       ; Volume ID
VolumeLabel         db "KRONKOS    "    ; Volume Label [Must be 11 chars]
FileSystem          db "FAT12   "       ; File system type [Must not be changed!]

; ------------------------------------------------------------------
; Main bootloader code
bootloader_start:
    mov   ax, 0x07C0                    ; Set up 4K of stack space above our buffer
    add   ax, 544                       ; 8K buffer = 512 paragraphs + 32 paragraphs (loader)
    cli                                 ; Disable interrupts while changing stack
    mov   ss, ax
    mov   sp, 4096
    sti                                 ; Restore interrupts

    mov   ax, 0x07C0                    ; Set data segment to where we're loaded
    mov   ds, ax
    
    ; NOTE: A few early BIOSes are reported to improperly set DL

    cmp   dl, 0
    je    no_change
    mov   [bootdev], dl                 ; Save boot device number
    mov   ah, 8                         ; Get drive parameters
    int   0x13

    jc    disk_error
    and   cx, 0x3F                      ; Maximum sector number
    mov   [SectorsPerTrack], cx         ; Sector numbers start at 1
    movzx dx, dh                        ; Maximum head number
    add   dx, 1                         ; Head numbers start at 0 - add 1 for total
    mov   [Sides], dx

no_change:
    mov   eax, 0                        ; Needed for some older BIOSes

; We need to load the root directory from the disk. In more details...
; Start of root      = ReservedForBoot + NumberOfFats * SectorsPerFat = logical 19
; Number of root     = RootDirEntries * 32 bytes/entry / 512 bytes/sector = 14
; Start of user data = (start of root) + (number of root) = logical 33

floopy_ok:                              ; Ready to read first block of data
    mov   ax, 19                        ; Root dir starts at logical sector 19
    call  l2hts

    mov   si, buffer                    ; Set ES:BX to point to our buffer
    mov   bx, ds
    mov   es, bx
    mov   bx, si

    mov   ah, 2                         ; Params for int 0x13
    mov   al, 14                        ; And read 14 of them

    pusha                               ; Prepare to enter loop

read_root_dir:
    popa                                ; In case registers are altered by int 0x13
    pusha

    stc                                 ; A few BIOSes do not set properly on error
    int   0x13                          ; Read sectors using BIOS

    jnc   search_dir                    ; If read succeded, skip ahead
    call  reset_floppy                  ; If not, reset floppy controller and try again
    jnc   read_root_dir                 ; Check if the floppy reset is ok *pats back*

    jmp   reboot                        ; If not... fuck

search_dir:
    popa

    mov   ax, ds                        ; Root dir is now in [buffer] (cool how I did that eh?)
    mov   es, ax                        ; Set DI to this info
    mov   di, buffer

    mov   cx, word [RootDirEntries]     ; Searh all 224 entries
    mov   ax, 0                         ; Searching at offset 0

next_root_entry:
    xchg  cx, dx                        ; We use CX in the inner loop...

    mov   si, kern_filename             ; Start searching for kernel filename
    mov   cx, 11
    rep   cmpsb
    je    found_file_to_load            ; Pointer DI will be at offset 11

    add   ax, 32                        ; Bump searched entries by 1 (32 bytes per entry)

    mov   di, buffer                    ; Point to next entry
    add   di, ax

    xchg  dx, cx                        ; Get the original CX back
    loop next_root_entry

    mov   si, file_not_found            ; If kernel is not found, aurotten der juden im Europa
    call  print_string
    jmp   reboot

found_file_to_load:                     ; Get the clusters and load FAT into RAM
    mov   ax, word [es:di+0x0F]         ; Offset 11 + 15 = 26, the 1st cluster
    mov   word [cluster], ax

    mov   ax, 1                         ; Sector 1 = first sector of first FAT
    call  l2hts

    mov   di, buffer                    ; ES:BX points to our buffer
    mov   bx, di

    mov   ah, 2                         ; int 0x13 params: read FAT sectors
    mov   al, 9                         ; All 9 sectors of 1st FAT

    pusha                               ; Prepare to enter a wacky time warping, mind bending
                                        ; nipple twisting, ass whooping, finger licking loop

read_fat:
    popa
    pusha

    stc
    int   0x13

    jnc   read_fat_ok
    call  reset_floppy
    jnc   read_fat

; ******************************************************************
disk_error:
    mov  si, disk_err_msg
    call print_string
    jmp  reboot

read_fat_ok:
    popa

    mov  ax, 0x2000
    mov  es, ax
    mov  bx, 0

    mov  ah, 2
    mov  al, 1

    push ax

; Load FAT from disk
; FAT cluster 0 = media descriptor = 0x0F0
; FAT cluster 1 = filler clutser   = 0x0FF
; Cluster start = ((cluster number) - 2) * SectorsPerCluster + (start of user)
;               = (cluster number) + 31

load_file_sector:
    mov  ax, word [cluster]             ; Convert dummy sectors to big brain logical
    add  ax, 31

    call l2hts                          ; Make some erotic yet appropriate params for int 0x13

    mov  ax, 0x2000                     ; Set buffer past what we've already read
    mov  es, ax
    mov  bx, word [pointer]

    pop  ax                             ; Save in case we (or some small brain int) lose it
    push ax

    stc
    int  0x13

    jnc  calc_next_cluster              ; If no stinky errors

    call reset_floppy                   ; UH OH Stinky error! Better retry
    jmp  load_file_sector

calc_next_cluster:
    mov  ax, [cluster]
    mov  dx, 0
    mov  bx, 3
    mul  bx
    mov  bx, 2
    div  bx
    mov  si, buffer
    add  si, ax
    mov  ax, word [ds:si]

    or   dx, dx
    jz   even

odd:
    shr  ax, 4
    jmp  short next_cluster_cont

even:
    and  ax, 0x0FFF

next_cluster_cont:
    mov  word [cluster], ax

    cmp  ax, 0x0FF8
    jae  end

    add  word [pointer], 512
    jmp  load_file_sector

end:
    pop  ax
    mov  dl, byte [bootdev]

    jmp  0x2000:0x0000
; ******************************************************************

; ------------------------------------------------------------------
; BOOTLOADER SUBROUTINES
reboot:
    mov  ax, 0
    int  0x16
    mov  ax, 0
    int  0x19

print_string:
    pusha
    mov ah, 0x0E

    .repeat:
        lodsb
        cmp al, 0
        je  .done
        int 0x10
        jmp short .repeat

    .done:
        popa
        ret

reset_floppy:
    push ax
    push dx
    mov  ax, 0
    mov  dl, byte [bootdev]
    stc
    int  0x13
    pop  dx
    pop  ax
    ret

l2hts:
    push bx
    push ax

    mov  bx, ax

    mov  dx, 0
    div  word [SectorsPerTrack]
    add  dl, 0x01
    mov  cl, dl
    mov  ax, bx

    mov  dx, 0
    div  word [SectorsPerTrack]
    mov  dx, 0
    div  word [Sides]
    mov  dh, dl
    mov  ch, al

    pop  ax
    pop  bx

    mov  dl, byte [bootdev]

    ret

; ------------------------------------------------------------------
; STRINGS AND VARIABLES

    kern_filename  db "KERNEL  BIN"     ; KronkOS kernel filename
    disk_err_msg   db "Floppy error! Press any key...", 0
    file_not_found db "KERNEL.BIN not found!", 0

    bootdev        db 0                 ; Boot device number
    cluster        dw 0                 ; Cluster of the file we want to load
    pointer        dw 0                 ; Pointer into Buffer, for loading kernel

; ------------------------------------------------------------------
; END OF BOOT SECTOR AND BUFFER START

    times 510-($-$$) db 0               ; Pad remainder of boot sector with zeros
    dw 0xAA55                           ; Boot signature


buffer:                                 ; Disk buffer begins
                                        ; (8k after this, the stack starts)
; ==================================================================