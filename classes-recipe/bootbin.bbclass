SUMMARY = "Generates boot.bin using bootgen tool"
DESCRIPTION = "Manages task dependencies and creation of boot.bin. Use the \
BIF_PARTITION_xyz global variables and flags to determine what makes it into \
the image."

LICENSE = "BSD"

include machine-xilinx-${SOC_FAMILY}.inc

inherit deploy

BIN_KIND ?= "common"

PROVIDES = "bootbin-${BIN_KIND}"

DEPENDS += "bootgen-native"

PACKAGE_ARCH = "${MACHINE_ARCH}"

BIF_FILE_PATH ?= "${B}/bootgen.bif"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

BOOTGEN_ARCH_DEFAULT = "${SOC_FAMILY}"
BOOTGEN_ARCH ?= "${BOOTGEN_ARCH_DEFAULT}"
BOOTGEN_EXTRA_ARGS ?= ""

do_patch[noexec] = "1"

def create_bif(config, attrflags, attrimage, common_attr, biffd, d):
    import re, os
    for cfg in config:
        if cfg not in attrflags and common_attr:
            error_msg = "%s: invalid ATTRIBUTE" % (cfg)
            bb.error("BIF attribute Error: %s " % (error_msg))
        else:
            if common_attr:
                cfgval = d.expand(attrflags[cfg]).split(',')
                cfgstr = "\t [%s] %s\n" % (cfg,', '.join(cfgval))
            else:
                if cfg not in attrimage:
                    error_msg = "%s: invalid or missing elf or image" % (cfg)
                    bb.error("BIF atrribute Error: %s " % (error_msg))
                imagestr = d.expand(attrimage[cfg])
                if not os.path.exists(imagestr):
                    bb.fatal("Expected file %s, specified from the bif file does not exists!" %(imagestr))
                if os.stat(imagestr).st_size == 0:
                    bb.warn("Empty file %s, excluding from bif file" %(imagestr))
                    continue
                if cfg in attrflags:
                    cfgval = d.expand(attrflags[cfg]).split(',')
                    cfgstr = "\t [%s] %s\n" % (', '.join(cfgval), imagestr)
                else:
                    cfgstr = "\t %s\n" % (imagestr)
            biffd.write(cfgstr)

    return

python do_configure() {
    fp = d.getVar("BIF_FILE_PATH")
    if fp == (d.getVar('B') + '/bootgen.bif'):
        biffd = open(fp, 'w')
        biffd.write("the_ROM_image:\n")
        biffd.write("{\n")

        bifattr = (d.getVar("BIF_COMMON_ATTR") or "").split()
        if bifattr:
            attrflags = d.getVarFlags("BIF_COMMON_ATTR") or {}
            create_bif(bifattr, attrflags,'', 1, biffd, d)

        bifpartition = (d.getVar("BIF_PARTITION_ATTR") or "").split()
        if bifpartition:
            attrflags = d.getVarFlags("BIF_PARTITION_ATTR") or {}
            attrimage = d.getVarFlags("BIF_PARTITION_IMAGE") or {}
            create_bif(bifpartition, attrflags, attrimage, 0, biffd, d)

        biffd.write("}")
        biffd.close()
}

do_configure[vardeps] += "BIF_PARTITION_ATTR BIF_PARTITION_IMAGE BIF_COMMON_ATTR"

do_compile() {
    cd ${WORKDIR}
    rm -f ${B}/BOOT.bin
    bootgen -image ${BIF_FILE_PATH} -arch ${BOOTGEN_ARCH} ${BOOTGEN_EXTRA_ARGS} -w -o ${B}/BOOT.bin
    if [ ! -e ${B}/BOOT.bin ]; then
        bbfatal "bootgen failed. See log"
    fi
}

inherit image-artifact-names

QEMUQSPI_BASE_NAME ?= "QEMU_qspi-${MACHINE}-${IMAGE_VERSION_SUFFIX}"

BOOTBIN_BASE_NAME ?= "BOOT-${BIN_KIND}-${MACHINE}-${IMAGE_VERSION_SUFFIX}"

BOOTGEN_BASE_NAME ?= "BOOTGEN-${BIN_KIND}-${MACHINE}-${IMAGE_VERSION_SUFFIX}"

OUTPUT_FOLDER = "${DEPLOYDIR}/bootbins/"

do_deploy() {
    install -d ${OUTPUT_FOLDER}
    
    install -m 0644 ${B}/BOOT.bin ${OUTPUT_FOLDER}/${BOOTBIN_BASE_NAME}.bin
    ln -sf ${BOOTBIN_BASE_NAME}.bin ${OUTPUT_FOLDER}/BOOT-${BIN_KIND}-${MACHINE}.bin
    ln -sf ${BOOTBIN_BASE_NAME}.bin ${OUTPUT_FOLDER}/boot-${BIN_KIND}.bin

    install -m 0644 ${B}/bootgen.bif ${OUTPUT_FOLDER}/${BOOTGEN_BASE_NAME}.bif
    ln -sf ${BOOTGEN_BASE_NAME}.bif ${OUTPUT_FOLDER}/BOOTGEN-${BIN_KIND}-${MACHINE}.bif
    ln -sf ${BOOTGEN_BASE_NAME}.bif ${OUTPUT_FOLDER}/bootgen-${BIN_KIND}.bif
}

FILES:${PN} += "/boot/BOOT.bin \
                /boot/bootgen.bif \
"
SYSROOT_DIRS += "/boot"

addtask do_deploy before do_build after do_compile
