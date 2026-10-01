FROM debian:trixie

# Avoid prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install SSH server, sudo, and basic tools
RUN apt-get update

RUN apt-get install -y curl sudo \
    && rm -rf /var/lib/apt/lists/*

# 2. Create the 'vagrant' user with password 'vagrant'
RUN useradd -m -s /bin/bash vagrant && \
    echo 'vagrant:vagrant' | chpasswd

# 4. Set up passwordless sudo access for the vagrant user
RUN echo 'vagrant ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/vagrant && \
    chmod 0440 /etc/sudoers.d/vagrant

# 5. Install Vagrant's default insecure public key for SSH authentication
RUN mkdir -p /home/vagrant/.ssh && \
    curl -fsSL https://raw.githubusercontent.com/hashicorp/vagrant/refs/heads/main/keys/vagrant.pub -o /home/vagrant/.ssh/authorized_keys && \
    chown -R vagrant:vagrant /home/vagrant/.ssh && \
    chmod 0700 /home/vagrant/.ssh && \
    chmod 0600 /home/vagrant/.ssh/authorized_keys


COPY setup-buildbot.sh /usr/local/bin/setup-buildbot.sh

# 2. Make the script executable
RUN chmod +x /usr/local/bin/setup-buildbot.sh

# 3. Set the default command to execute the script
RUN /usr/local/bin/setup-buildbot.sh
