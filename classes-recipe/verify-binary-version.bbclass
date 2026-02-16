SUMMARY = "Verify binary version"
DESCRIPTION = "Verify that the binary version matches the expected version"

VERIFY_BINARY_VERSION ?= ""
VERIFY_BINARY_VERSION[doc] = "Expected version string to verify against"
VERIFY_BINARY_FILES ?= ""
VERIFY_BINARY_FILES[doc] = "List of binary files to verify the version of"

do_verify_binary_version() {
    expected_version="${VERIFY_BINARY_VERSION}"
    for file in ${VERIFY_BINARY_FILES}; do
        ${OBJCOPY} --dump-section .note.kplabs.version=${B}/actual_version ${file}
        actual_version=$(cat ${B}/actual_version)
        if [ "${actual_version}" != "${expected_version}" ]; then
            bberror "Version mismatch for ${file}: expected ${expected_version}, got ${actual_version}"
        fi
    done
}

addtask verify_binary_version after do_install before do_build