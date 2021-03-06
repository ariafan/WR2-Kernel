#!/bin/bash
set -e

#Toolchain
export CROSS_COMPILE=`pwd`/toolchain/arm-cortex_a7-linux-gnueabihf-linaro_4.9/bin/arm-cortex_a7-linux-gnueabihf-

#AKB Version
version=1.1

#Calculate what version you are building. If this is your first build, it will show nothing in last version.
if [ "$(ls -A `pwd`/.numero)" ]; then
last_kversion=`cat .numero`
current_kversion=$(echo "scale=1; $last_kversion+0.1" | bc)
else
last_kversion=none
current_kversion=1.0
fi

while :
do

	clear
	
	# If error exists, display it
	if [ "$ERR_MSG" != "" ]; then
		echo "$ERR_MSG"
		echo ""
	fi
  echo
  echo "Last version: $last_kversion"
  echo "Current version: $current_kversion"
  echo
  echo "========================================================"
  echo "             Automatic Kernel Builder - AKB             "
  echo "            made by Suribi - Copyright© 2014            "
  echo "             Thanks to Dr-Shadow and dsixda             "
  echo "                 Moded by moonrotation                  "
  echo "========================================================"
  echo
  echo "Version: $version"
  echo
  echo "Select the product you want to build for:"
  echo
  echo "  1 - Wiko RAINBOW"
  echo "  2 - Micromax A120 C2C"
  echo
  echo "  x - Exit"
  echo
  echo -n "Enter Option: "
  read opt

	case $opt in
		1) TARGET_PRODUCT=wiko; break;;
		2) TARGET_PRODUCT=mmx; break;;
		x) clear; echo; echo "Goodbye."; echo; exit 1;;
		*) ERR_MSG="Invalid option!"; clear;;
	esac
done

echo
echo "You are actualy building for $TARGET_PRODUCT"
echo

DATE_START=$(date +"%s")
zImage_path=out/target/product/$TARGET_PRODUCT/obj/KERNEL_OBJ/arch/arm/boot/zImage
BUILDVERSION=WR2-V$current_kversion-`date +%Y%m%d-%H%M`-$TARGET_PRODUCT

#Build phase
./mk -o=TARGET_BUILD_VARIANT=user -t  $TARGET_PRODUCT n lk && ./mk -o=TARGET_BUILD_VARIANT=user -t  $TARGET_PRODUCT n k

if [ "$(ls -A `pwd`/$zImage_path)" ]; then
echo "Build Successful"
else
while [ ! -d "`pwd`/$zImage_path" ]; do
	clear
	echo "========================================================"
	echo "       Oh no, there where some code errors :(           "
	echo "   Now you must find and solve them, then press b       "
	echo "========================================================"
	echo
	echo " b - Build again"
	echo " x - exit"
	echo
	echo -n "Enter option: "
	read option
	
	case $option in
		b) ./makeMtk -o=TARGET_BUILD_VARIANT=user -t  $TARGET_PRODUCT n k; break;;
		x) clear; echo; echo "Goodbye."; echo; exit 1;;
		*) ERR_MSG="Invalid option!"; clear;;
	esac
done
fi

# make boot.img
 echo "		==> [WORKING] build boot.img in process..."
 echo ""
 echo ""
 echo ""
 echo ""
 mediatek/build/tools/images/acp -uv out/target/product/${TARGET_PRODUCT}/kernel_${TARGET_PRODUCT}.bin out/target/product/${TARGET_PRODUCT}/kernel
 mediatek/build/tools/images/mkbootfs mediatek/host/${TARGET_PRODUCT} | mediatek/build/tools/images/minigzip > out/target/product/${TARGET_PRODUCT}/ramdisk.img
 mediatek/build/tools/mkimage out/target/product/${TARGET_PRODUCT}/ramdisk.img ROOTFS > out/target/product/${TARGET_PRODUCT}/ramdisk_android.img
 mv out/target/product/${TARGET_PRODUCT}/ramdisk.img mediatek/kernel/trace32/${TARGET_PRODUCT}_ramdisk.img
 mv out/target/product/${TARGET_PRODUCT}/ramdisk_android.img out/target/product/${TARGET_PRODUCT}/ramdisk.img
 mediatek/build/tools/images/mkbootimg  --kernel out/target/product/${TARGET_PRODUCT}/kernel --ramdisk out/target/product/${TARGET_PRODUCT}/ramdisk.img --board 1336460062 --output out/target/product/${TARGET_PRODUCT}/boot.img
 echo "		==> [SUCCESS]   boot.img done!"


# Copy all to build_results folder
 echo ""
 echo ""
 echo ""
 echo ""
 echo "		==> [WORKING] moving files!"
 
 if [ "$(ls -A ./build_results)" ]; then
 rm -R ./build_results
 fi
 mkdir -p build_results
 mkdir -p build_results/modules
 cp out/target/product/${TARGET_PRODUCT}/boot.img build_results
 cp out/target/product/${TARGET_PRODUCT}/logo.bin build_results
 cp out/target/product/${TARGET_PRODUCT}/lk.bin build_results
 cp out/target/product/${TARGET_PRODUCT}/kernel build_results
 mv build_results/kernel build_results/zImage
 cp out/target/product/${TARGET_PRODUCT}/obj/KERNEL_OBJ/fs/exfat/exfat.ko build_results/modules
 echo ""
 echo ""
 echo ""
 echo "		==> [SUCCESS] find files into build_results folder!"


# Make flashable zip
 cp out/target/product/${TARGET_PRODUCT}/boot.img mediatek/host/zip
 cp out/target/product/${TARGET_PRODUCT}/obj/KERNEL_OBJ/fs/exfat/exfat.ko mediatek/host/zip/modules
 cd mediatek/host/zip
 zip -r -0 WR2-Kernel-${TARGET_PRODUCT}.zip ./*
 mv WR2-Kernel-${TARGET_PRODUCT}.zip ../../../build_results
 rm ../../../mediatek/host/zip/boot.img
 rm ../../../mediatek/host/zip/modules/exfat.ko
 echo "		==> [OK]   Find all filen into build_results folder!"

DATE_END=$(date +"%s")
echo
echo
DIFF=$(($DATE_END - $DATE_START))

echo
echo
echo "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
