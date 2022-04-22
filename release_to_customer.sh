#!/bin/bash

while getopts "f:p:q:t:" opt; do
  case $opt in
    f)
      flashtype=$OPTARG
      ;;
    p)
      project=$OPTARG
      ;;
	q)
      fastboot=$OPTARG
      ;;
	t)
      toolchain=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

DATE=$(date +%m%d)
#RELEASEDIR=ReleaseToCus_${DATE}
RELEASEDIR=$(pwd)
#release source code
#find ./boot/ | grep -v boot/.git | cpio -pdm ${RELEASEDIR}/
#find ./project/ | grep -v project/.git | cpio -pdm ${RELEASEDIR}/
#find ./kernel/ | grep -v kernel/.git | cpio -pdm ${RELEASEDIR}/
#find ./sdk/ | grep sdk/verify | grep -v sdk/verify/application/smarttalk | cpio -pdm ${RELEASEDIR}/

#save code version
#repo manifest -o snapshot.xml -r
#cp snapshot.xml ${RELEASEDIR}/sdk_version.xml


echo chose ${flashtype} ${toolchain}

# build uboot
cd ${RELEASEDIR}/boot
if [ "${toolchain}" = "uclibc" ]; then
	declare -x ARCH="arm"
	declare -x CROSS_COMPILE="arm-buildroot-linux-uclibcgnueabihf-"
else
	declare -x ARCH="arm"
	declare -x CROSS_COMPILE="arm-linux-gnueabihf-"
fi

if [ "${flashtype}" = "nor" ]; then
	make infinity2m_defconfig
else
	make infinity2m_spinand_defconfig
fi
make clean;make

if [ "${flashtype}" = "nor" ]; then
	if [ -d ../project/board/i2m/boot/nor/uboot ]; then
		cp u-boot.xz.img.bin ../project/board/i2m/boot/nor/uboot
	fi
else
	if [ -d ../project/board/i2m/boot/spinand/uboot ]; then
		cp u-boot_spinand.xz.img.bin ../project/board/i2m/boot/spinand/uboot
	fi
fi

#build kernel
cd ${RELEASEDIR}/kernel
if [ "${toolchain}" = "uclibc" ]; then
	declare -x ARCH="arm"
	declare -x CROSS_COMPILE="arm-buildroot-linux-uclibcgnueabihf-"
else
	declare -x ARCH="arm"
	declare -x CROSS_COMPILE="arm-linux-gnueabihf-"
fi
if [ "${flashtype}" = "nor" ]; then
	if [ "${fastboot}" = "fastboot" ]; then
		make infinity2m_ssc011a_s01a_fastboot_defconfig
	else
		make infinity2m_ssc011a_s01a_minigui_defconfig
	fi
	
else
	if [ "${fastboot}" = "fastboot" ]; then
		echo fast kernel
		make infinity2m_spinand_ssc011a_s01a_minigui_fastboot_defconfig
	else
		make infinity2m_spinand_ssc011a_s01a_defconfig
	fi
	
fi
make clean;make -j8

#build project
cd ${RELEASEDIR}/project
if [ "${toolchain}" = "uclibc" ]; then
	if [ "${flashtype}" = "nor" ]; then
		if [ "${project}" = "ssd201" ]; then
			./setup_config.sh ./configs/nvr/i2m/8.2.1/nor.uclibc-squashfs.011a.64
		fi
		if [ "${project}" = "ssd202" ]; then
			./setup_config.sh ./configs/nvr/i2m/8.2.1/nor.uclibc-squashfs.011a.128
		fi
	else
		if [ "${project}" = "ssd201" ]; then
			./setup_config.sh ./configs/nvr/i2m/8.2.1/spinand.uclibc-squashfs.011a.64
		fi
		if [ "${project}" = "ssd202" ]; then
			./setup_config.sh ./configs/nvr/i2m/8.2.1/spinand.uclibc-squashfs.011a.128
		fi
	fi
else
	if [ "${flashtype}" = "nor" ]; then
		if [ "${fastboot}" = "fastboot" ]; then
			if [ "${project}" = "ssd201" ]; then
				./setup_config.sh ./configs/nvr/i2m/8.2.1/nor.glibc-ramfs.011a.64
			fi
			if [ "${project}" = "ssd202" ]; then
				./setup_config.sh ./configs/nvr/i2m/8.2.1/nor.glibc-ramfs.011a.128
			fi
		else
			if [ "${project}" = "ssd201" ]; then
				./setup_config.sh ./configs/nvr/i2m/8.2.1/nor.glibc-squashfs.011a.64
			fi
			if [ "${project}" = "ssd202" ]; then
				./setup_config.sh ./configs/nvr/i2m/8.2.1/nor.glibc-squashfs.011a.128
			fi
		fi
	else
		if [ "${fastboot}" = "fastboot" ]; then
			if [ "${project}" = "ssd201" ]; then
				./setup_config.sh ./configs/nvr/i2m/8.2.1/spinand.ram-glibc-squashfs.011a.64
			fi
			if [ "${project}" = "ssd202" ]; then
				./setup_config.sh ./configs/nvr/i2m/8.2.1/spinand.ram-glibc-squashfs.011a.128
			fi
		else
			if [ "${project}" = "ssd201" ]; then
				./setup_config.sh ./configs/nvr/i2m/8.2.1/spinand.glibc.011a.64
			fi
			if [ "${project}" = "ssd202" ]; then
				./setup_config.sh ./configs/nvr/i2m/8.2.1/spinand.glibc.011a.128
			fi
		fi

	fi
fi

cd ${RELEASEDIR}/project/kbuild/4.9.84
if [ "${toolchain}" = "uclibc" ]; then
	if [ "${flashtype}" = "nor" ]; then
		./release.sh -k ${RELEASEDIR}/kernel -b 011A -p nvr -f nor -c i2m -l uclibc -v 4.9.4
	else
		./release.sh -k ${RELEASEDIR}/kernel -b 011A -p nvr -f spinand -c i2m -l uclibc -v 4.9.4
	fi
else
	if [ "${flashtype}" = "nor" ]; then
		if [ "${fastboot}" = "fastboot" ]; then
			./release.sh -k ${RELEASEDIR}/kernel -b 011A-fastboot -p nvr -f nor -c i2m -l glibc -v 8.2.1
		else
			./release.sh -k ${RELEASEDIR}/kernel -b 011A -p nvr -f nor -c i2m -l glibc -v 8.2.1
		fi
	else
		if [ "${fastboot}" = "fastboot" ]; then
			echo fast release
			./release.sh -k ${RELEASEDIR}/kernel -b 011A-fastboot -p nvr -f spinand -c i2m -l glibc -v 8.2.1
		else
			./release.sh -k ${RELEASEDIR}/kernel -b 011A -p nvr -f spinand -c i2m -l glibc -v 8.2.1
		fi
		
	fi
fi

cd ${RELEASEDIR}/project
make clean_keep_release;make image-nocheck

#install Image
cd ${RELEASEDIR}
rm -rf ${RELEASEDIR}/images
cp ${RELEASEDIR}/project/image/output/images . -rf

#tar -cvzf boot_${DATE}.tar.gz boot
#tar -cvzf kernel_${DATE}.tar.gz kernel
#tar -cvzf project_${DATE}.tar.gz project
#tar -cvzf sdk_${DATE}.tar.gz sdk


