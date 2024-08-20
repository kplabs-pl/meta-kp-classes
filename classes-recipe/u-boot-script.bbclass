# Usage:
# Create a recipe and add `inherit u-boot-script`
# Add `.cmd` source files to it

# Following architecture deduction comes from poky/meta/classes-recipe/kernel-arch.bbclass

valid_archs = "alpha cris ia64 \
               i386 x86 \
               m68knommu m68k ppc powerpc powerpc64 ppc64  \
               sparc sparc64 \
               arm aarch64 \
               m32r mips \
               sh sh64 um h8300   \
               parisc s390  v850 \
               avr32 blackfin \
               loongarch64 \
               microblaze \
               nios2 arc riscv xtensa"

def map_kernel_arch(a, d):
    import re

    valid_archs = d.getVar('valid_archs').split()

    if   re.match('(i.86|athlon|x86.64)$', a):  return 'x86'
    elif re.match('arceb$', a):                 return 'arc'
    elif re.match('armeb$', a):                 return 'arm'
    elif re.match('aarch64$', a):               return 'arm64'
    elif re.match('aarch64_be$', a):            return 'arm64'
    elif re.match('aarch64_ilp32$', a):         return 'arm64'
    elif re.match('aarch64_be_ilp32$', a):      return 'arm64'
    elif re.match('loongarch(32|64|)$', a):     return 'loongarch'
    elif re.match('mips(isa|)(32|64|)(r6|)(el|)$', a):      return 'mips'
    elif re.match('mcf', a):                    return 'm68k'
    elif re.match('riscv(32|64|)(eb|)$', a):    return 'riscv'
    elif re.match('p(pc|owerpc)(|64)', a):      return 'powerpc'
    elif re.match('sh(3|4)$', a):               return 'sh'
    elif re.match('bfin', a):                   return 'blackfin'
    elif re.match('microblazee[bl]', a):        return 'microblaze'
    elif a in valid_archs:                      return a
    else:
        if not d.getVar("TARGET_OS").startswith("linux"):
            return a
        bb.error("cannot map '%s' to a linux kernel architecture" % a)

def map_uboot_arch(a, d):
    import re

    if   re.match('p(pc|owerpc)(|64)', a): return 'ppc'
    elif re.match('i.86$', a): return 'x86'
    return a

UBOOT_ARCH = "${@map_uboot_arch(map_kernel_arch(d.getVar('TARGET_ARCH'), d), d)}"

# Generate u-boot scripts
inherit deploy

SCRIPTS_PATH ?= "${S}"
DEPENDS = "u-boot-mkimage-native"
B = "${WORKDIR}/build"

do_compile() {
    cd "${SCRIPTS_PATH}"
    for script in `ls *.cmd`; do
        mkimage -A ${UBOOT_ARCH} -O u-boot -T script -d $script ${B}/$(basename --suffix .cmd $script).scr
    done
}

do_deploy() {
    cd "${B}"
    mkdir -p "${DEPLOYDIR}/u-boot-scripts/${PN}"
    for script in `ls *.scr`; do
        install -m 0644 "${B}/$script" ${DEPLOYDIR}/u-boot-scripts/${PN}
    done
}

addtask do_deploy after do_compile
