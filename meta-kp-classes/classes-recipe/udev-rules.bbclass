RDEPENDS:${PN} += " bash"

do_install() {
    install -d ${D}/${sysconfdir}/udev/rules.d

    for rule in `ls ${WORKDIR}/*.rules`; do
        install -m 0644 $rule ${D}/${sysconfdir}/udev/rules.d
    done
}