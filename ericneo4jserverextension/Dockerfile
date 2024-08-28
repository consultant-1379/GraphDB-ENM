FROM armdocker.rnd.ericsson.se/proj-ldc/common_base_os_release/sles:1.2.0-15

ARG PACKAGE_REPO_URL=https://arm.rnd.ki.sw.ericsson.se/artifactory/proj-ldc-repo-rpm-local/common_base_os/sles/1.2.0-15/
ARG ENM_DPS_EXT_RPM_URL=https://arm101-eiffel004.lmera.ericsson.se:8443/nexus/content/repositories/releases/com/ericsson/oss/itpf/datalayer/dps/3pp/ERICneo4jserverextension_CXP9032727/1.39.6/ERICneo4jserverextension_CXP9032727-1.39.6.rpm

ENV ADDITIONAL_PKGS="curl cpio"

COPY lifecycle-scripts /opt/ericsson/lifecycle-scripts

RUN zypper ar -C -G -f ${PACKAGE_REPO_URL}?ssl_verify=no COMMON_BASE_OS_SLES_REPO \
    && zypper ref -f -r COMMON_BASE_OS_SLES_REPO \
    && zypper in -l -y ${ADDITIONAL_PKGS} \
    && curl --insecure ${ENM_DPS_EXT_RPM_URL} -o /tmp/dps.rpm \
    && cd /tmp \
    && rpm2cpio dps.rpm | cpio --directory=/ -idmv \
    && rm dps.rpm \
    && zypper rm -u -y ${ADDITIONAL_PKGS}
