
FROM registry.access.redhat.com/ubi9/ubi

# Update & install items required to run as a TeamCity Agent
RUN dnf -y update && dnf -y install git rsync wget python3 java-17-openjdk

# Add things required for podman support here
RUN dnf -y install sudo procps-ng podman fuse-overlayfs openssh-clients --exclude container-selinux

# Post install cleanup
RUN dnf clean all && rm -rf /var/cache /var/log/dnf* /var/log/yum.*

# ====  Operating System application installation complete =====================

#               >> TeamCity Agent Configuration begins <<

# From 'How to Use Podman Inside A Container' Test Image
RUN useradd developer;    \
    echo -e "developer:1:999\ndeveloper:1001:64535" > /etc/subuid;   \
    echo -e "developer:1:999\ndeveloper:1001:64535" > /etc/subgid;

RUN groupadd containers && usermod --append --groups containers developer

# Configure TeamCity configuration file
ENV CONFIG_FILE=/data/teamcity_agent/conf/buildAgent.properties 
RUN mkdir -p /data/teamcity_agent/conf && \
    chown -R developer:developer /data/teamcity_agent 

# Copy & configure TeamCity startup script (runs at Container start time)
COPY --chown=developer:developer TeamCity/run-agent.sh /run-agent.sh
RUN chmod +x /run-agent.sh && sync && sed -i -e 's/\r$//' /run-agent.sh

# Setup TeamCity Agent & directory structure 

# Copy prebuilt configuration files into the container. (web URLs above went stale) - THINK THESE COPYs ARE DUPLICATED BELOW SO REMOVE THESE??
COPY ./containers.conf /etc/containers/containers.conf
COPY ./podman-containers.conf /home/developer/.config/containers/containers.conf

COPY --chown=developer:developer TeamCity/buildAgentFull /opt/buildagent
RUN chmod +x /opt/buildagent/bin/*.sh && \
    mkdir -p /opt/buildagent/work && \
    mkdir -p /opt/buildagent/system/.teamcity-agent && \
    mkdir -p /opt/buildagent/temp && \
    mkdir -p /opt/buildagent/logs && \
    mkdir -p /opt/buildagent/tools && \
    chown -R developer:developer /opt/buildagent && \
    chown -R developer:containers /opt/buildagent/work/ && \
    echo >> /opt/buildagent/system/.teamcity-agent/teamcity-agent.xml && \
    sed -i -e 's/\r$//' /opt/buildagent/system/.teamcity-agent/teamcity-agent.xml && \
    echo >> /opt/buildagent/system/.teamcity-agent/unpacked-plugins.xml && \
    sed -i -e 's/\r$//' /opt/buildagent/system/.teamcity-agent/unpacked-plugins.xml

# These VOLUMES were commented because, as is, they required rootful VOLUMES.
# Behavior doesn't seem to be impacted, but worth investigating support of 
# both types of volumes...
# VOLUME /opt/buildagent/work
# VOLUME /opt/buildagent/system
# VOLUME /opt/buildagent/temp
# VOLUME /opt/buildagent/logs
# VOLUME /opt/buildagent/tools
# VOLUME /opt/buildagent/plugins
# VOLUME /data/teamcity_agent/conf

# Duplicated from above, the above didn't seem to 'take'
RUN chown -R developer:developer /data/teamcity_agent 

ENV JAVA_HOME=/usr
ENV LANG=C.UTF-8

# ====  Operating System application installation complete =====================

#          >> Podman Container in Container Configuration begins <<

#RUN useradd podman; \
#     echo podman:10000:5000 > /etc/subuid;  \
#     echo podman:10000:5000 > /etc/subgid;

# RootFULL container storage
VOLUME /var/lib/containers

# RootLESS container storage
# VOLUME /home/developer/.local/share/containers
RUN mkdir --parents /home/developer/.local/share/containers
RUN chown developer:developer -R /home/developer/.local/share/containers

# Download latest stable configuration files
# ARG _REPO_URL="https://raw.githubusercontent.com/containers/podman/main/contrib/podmanimage/stable"
# ADD $_REPO_URL/containers.conf /etc/containers/containers.conf
# ADD $_REPO_URL/podman-containers.conf /home/developer/.config/containers/containers.conf

# Copy prebuilt configuration files into the container. (web URLs above went stale)
COPY ./containers.conf /etc/containers/containers.conf
COPY ./podman-containers.conf /home/developer/.config/containers/containers.conf

RUN chown developer:developer -R /home/developer/.config

#RUN chown developer:developer -R /home/developer
#RUN sed -i -e 's|^#mount_program|mount_program|g' /etc/containers/storage.conf
#RUN sed -i -e 's|^#mount_program|mount_program|g' -e '/additionalimage.*/a "/var/lib/shared",' /etc/containers/storage.conf

# Change permissions for containers.conf
RUN chmod 644 /etc/containers/containers.conf

# Update settings in storage.conf
RUN sed -i -e 's|^#mount_program|mount_program|g' \
    -e '/additionalimage.*/a "/var/lib/shared",' \
    -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' \
    /etc/containers/storage.conf

RUN mkdir --parents \
    /var/lib/shared/overlay-images \
    /var/lib/shared/overlay-layers \
    /var/lib/shared/vfs-images     \
    /var/lib/shared/vfs-layers     \

#RUN \
#    touch /var/lib/shared/overlay-images/images.lock; \
#    touch /var/lib/shared/overlay-layers/layers.lock; \ 
#    touch /var/lib/shared/vfs-images/images.lock;     \
#    touch /var/lib/shared/vfs-layers/layers.lock

# Entry command - starts TeamCity Agent
USER developer
CMD ["/run-agent.sh"]

