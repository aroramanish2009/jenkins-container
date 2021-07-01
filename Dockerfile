FROM ubuntu:20.04

LABEL maintainer="The Last Packet Bender"

ARG DEBIAN_FRONTEND=noninteractive
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG JENKINS_AGENT_HOME=/home/${user}

# Make sure the package repository is up to date.
RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils && \
    apt-get -qy full-upgrade && \
    apt-get install -qy git && \
# Install a basic SSH server
    apt-get install -qy openssh-server && \
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
    mkdir -p /var/run/sshd && \
# Install JDK 8 (latest stable edition at 2019-04-01)
    apt-get install -qy openjdk-8-jdk && \
# Install Python3 and PIP3
    apt-get install -y python3 python3-pip && \
# Install net-tools 
    apt install -y net-tools && \
# Install Anisble and Paramiko using PIP
    pip3 install --upgrade ansible==2.10.6 paramiko && \
# Install ncclient version 0.6.9
    pip3 install ncclient==0.6.9 && \
# Install NAPALM
    pip3 install napalm napalm-ansible && \
# Cleanup old packages
    apt-get -qy autoremove

ENV JENKINS_AGENT_HOME ${JENKINS_AGENT_HOME}

RUN groupadd -g ${gid} ${group} \
    && useradd -d "${JENKINS_AGENT_HOME}" -u "${uid}" -g "${gid}" -m -s /bin/bash "${user}"

RUN sed -i /etc/ssh/sshd_config \
        -e 's/#PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/#RSAAuthentication.*/RSAAuthentication yes/'  \
        -e 's/#PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/#SyslogFacility.*/SyslogFacility AUTH/' \
        -e 's/#LogLevel.*/LogLevel INFO/'

VOLUME "${JENKINS_AGENT_HOME}" "/tmp" "/run" "/var/run"
WORKDIR "${JENKINS_AGENT_HOME}"

COPY setup-sshd /usr/local/bin/setup-sshd
COPY .ansible.cfg /home/jenkins/.ansible.cfg
COPY .vault_pass.txt /home/jenkins/.vault_pass.txt
COPY hosts /etc/hosts

# Copy authorized keys
COPY id_ed25519 /home/jenkins/.ssh/id_ed25519

EXPOSE 22

RUN chmod +x /usr/local/bin/setup-sshd
ENTRYPOINT ["/usr/local/bin/setup-sshd"]
