
# Container in Container base example

# FROM registry.access.redhat.com/ubi8/ubi
FROM registry.access.redhat.com/ubi9/ubi

# Update & install items required to run as a TeamCity Agent
RUN dnf -y update && dnf -y install git rsync wget python3 java-17-openjdk

# Add things required for podman support here
RUN dnf -y install sudo procps-ng podman fuse-overlayfs openssh-clients --exclude container-selinux

# Post install cleanup
RUN dnf clean all && rm -rf /var/cache /var/log/dnf* /var/log/yum.*

# ====  Operating System application installation complete =====================

#               >> TeamCity Agent Configuration begins <<

# Add users, start with UID 2000 to be certain it is beyond all other default users
#RUN useradd --uid 2000 tc_agent
RUN useradd tc_agent; \
     echo tc_agent:20000:5000 > /etc/subuid;  \
     echo tc_agent:20000:5000 > /etc/subgid;


# User list for production services
#RUN useradd --uid 3001 agent01
#RUN useradd --uid 3002 agent02
#RUN useradd --uid 3003 agent03
#RUN useradd --uid 3004 agent04
#RUN useradd --uid 3005 agent05
#RUN useradd --uid 3006 agent06
#RUN useradd --uid 3007 agent07
#RUN useradd --uid 3008 agent08
#RUN useradd --uid 3009 agent09
#RUN useradd --uid 3010 agent10

# Users for prototyping
#RUN useradd --uid 4001 agentA
#RUN useradd --uid 4002 agentB
#RUN useradd --uid 4003 agentC

# Configure TeamCity configuration file
ENV CONFIG_FILE=/data/teamcity_agent/conf/buildAgent.properties 
RUN mkdir -p /data/teamcity_agent/conf && \
    chown -R tc_agent:tc_agent /data/teamcity_agent 

# Copy & configure TeamCity startup script (runs at Container start time)
COPY --chown=tc_agent:tc_agent TeamCity/run-agent.sh /run-agent.sh
RUN chmod +x /run-agent.sh && sync && sed -i -e 's/\r$//' /run-agent.sh

# Setup TeamCity Agent & directory structure 
COPY --chown=tc_agent:tc_agent TeamCity/buildAgentFull /opt/buildagent
RUN chmod +x /opt/buildagent/bin/*.sh && \
    mkdir -p /opt/buildagent/work && \
    mkdir -p /opt/buildagent/system/.teamcity-agent && \
    mkdir -p /opt/buildagent/temp && \
    mkdir -p /opt/buildagent/logs && \
    mkdir -p /opt/buildagent/tools && \
    chown -R tc_agent:tc_agent /opt/buildagent && \
    chown -R tc_agent:tc_agent /opt/buildagent/work/ && \
    echo >> /opt/buildagent/system/.teamcity-agent/teamcity-agent.xml && \
    sed -i -e 's/\r$//' /opt/buildagent/system/.teamcity-agent/teamcity-agent.xml && \
    echo >> /opt/buildagent/system/.teamcity-agent/unpacked-plugins.xml && \
    sed -i -e 's/\r$//' /opt/buildagent/system/.teamcity-agent/unpacked-plugins.xml

VOLUME /opt/buildagent/work
VOLUME /opt/buildagent/system
VOLUME /opt/buildagent/temp
VOLUME /opt/buildagent/logs
VOLUME /opt/buildagent/tools
VOLUME /opt/buildagent/plugins
VOLUME /data/teamcity_agent/conf

#
ENV JAVA_HOME=/usr
ENV LANG=C.UTF-8

# ====  Operating System application installation complete =====================

#          >> Podman Container in Container Configuration begins <<

RUN useradd podman; \
     echo podman:10000:5000 > /etc/subuid;  \
     echo podman:10000:5000 > /etc/subgid;

# Download latest stable configuration files
ARG _REPO_URL="https://raw.githubusercontent.com/containers/podman/main/contrib/podmanimage/stable"
ADD $_REPO_URL/containers.conf /etc/containers/containers.conf
ADD $_REPO_URL/podman-containers.conf /home/podman/.config/containers/containers.conf

# RUN mkdir -p /home/tc_agent/.config/containers/
# ADD $_REPO_URL/podman-containers.conf /home/tc_agent/.config/containers/containers.conf
# RUN chown -R tc_agent:tc_agent /home/tc_agent/.config/





# Entry command - starts TeamCity Agent
CMD ["/run-agent.sh"]

