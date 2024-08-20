# XSA file (must be in ${WORKDIR}) containing bitstream
XSCTH_HDF = "${BITSTREAM_HDF_FILE}"

# Bitstream name used in image files, defaults to package name
#   Overlay: /lib/firmware/${BITSTREAM_NAME}/overlay.dtbo
#   Bitstream: /lib/firmware/${BITSTREAM_NAME}/bitstream.bit.bin
BITSTREAM_NAME ?=  "${PN}"

# Install directory for bitstream files.
FIRMWARE_DIR ?= "/usr/lib/firmware"

# Additional dtsi files to include in device tree overlay
DTSI_ADDONS ?= ""

DEPENDS = "dtc-native bootgen-native"

inherit xsctbase xsctyaml

FILESEXTRAPATHS:prepend := "${KP_XLNX_SCRIPTS_DIR}:"

require recipes-bsp/device-tree/device-tree.inc

SRC_URI += " file://generate_dt_overlay_for_bitstream.tcl"

S = "${WORKDIR}/git"
B = "${WORKDIR}/build"

XSCTH_BUILD_CONFIG ?= 'Release'

XSCTH_SCRIPT = "${WORKDIR}/generate_dt_overlay_for_bitstream.tcl"
XSCTH_PROC_IP = "psu_cortexa53_0"
YAML_ENABLE_DT_OVERLAY = "1"
YAML_FIRMWARE_NAME = "${BITSTREAM_NAME}/bitstream.bit"

XSCTH_MISC:append = " -xlnx_scripts ${XLNX_SCRIPTS_DIR}"

DTS_INCLUDE ?= "${WORKDIR}"
DT_PADDING_SIZE ?= "0x1000"

DEVICETREE_FLAGS ?= " \
        -R 8 -p ${DT_PADDING_SIZE} -b 0 -@ -H epapr \
        ${@' '.join(['-i %s' % i for i in d.getVar('DTS_INCLUDE', True).split()])} \
               "
DEVICETREE_PP_FLAGS ?= " \
        -nostdinc -Ulinux -x assembler-with-cpp \
        ${@' '.join(['-I%s' % i for i in d.getVar('DTS_INCLUDE', True).split()])} \
        "


do_compile_bitstream() {
    BITSTREAM_FILE=`find ${XSCTH_WS}/hw_platform/*.bit`

    echo "BITSTREAM_FILE = $BITSTREAM_FILE"

    cp ${BITSTREAM_FILE} ${B}/bitstream.bit

    echo "all:"                      > ${B}/bitstream.bif
    echo "{"                        >> ${B}/bitstream.bif
    echo "    ${B}/bitstream.bit"   >> ${B}/bitstream.bif
    echo "}"                        >> ${B}/bitstream.bif

    bootgen -image ${B}/bitstream.bif -arch ${SOC_FAMILY} -o ${B}/bitstream.bit.bin -w on ${@bb.utils.contains('SOC_FAMILY','zynqmp','','-process_bitstream bin',d)}
}

addtask do_compile_bitstream after do_configure before do_compile

do_compile_dts_overlay() {
    DTS_FILE_BASE=${XSCTH_WS}/hw_platform/pl.dtsi
    DTS_FILE=${B}/overlay.dtsi

    cp $DTS_FILE_BASE $DTS_FILE

    for f in ${DTSI_ADDONS}; do
        echo "/* Manual appended DTS file (from DTSI_ADDONS): $f */" >> ${DTS_FILE}
        cat ${f} >> ${DTS_FILE}
    done;


    ${BUILD_CPP} ${DEVICETREE_PP_FLAGS} -o ${B}/hw_platform-pl.dtsi.pp ${DTS_FILE}
    dtc ${DEVICETREE_FLAGS} -I dts -O dtb -o ${B}/hw_platform.dtbo ${B}/hw_platform-pl.dtsi.pp
}

addtask do_compile_dts_overlay after do_configure before do_compile

do_install() {
    install -m 0755 -d ${D}/usr/lib/firmware/${BITSTREAM_NAME}
    install -m 0644 ${B}/bitstream.bit.bin ${D}${FIRMWARE_DIR}/${BITSTREAM_NAME}/bitstream.bit.bin
    install -m 0644 ${B}/hw_platform.dtbo ${D}${FIRMWARE_DIR}/${BITSTREAM_NAME}/overlay.dtbo
}

FILES:${PN} = "\
    ${FIRMWARE_DIR}/${BITSTREAM_NAME}/ \
"
