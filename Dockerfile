FROM ubuntu:18.04

MAINTAINER Anton Malinskiy "anton@malinskiy.com"

# TODO: Add your keychain for signing the app
# Make JRE aware of container limits
COPY ./container-limits /
# Set up insecure default adb key
COPY adb/* /root/.android/

ENV LINK_ANDROID_SDK=https://dl.google.com/android/repository/commandlinetools-linux-6514223_latest.zip \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    GRADLE_VERSION=6.3 \
    GRADLE_HOME="/opt/gradle-6.3/bin" \
    ANDROID_HOME=/opt/android-sdk-linux \
    PATH="$PATH:/usr/local/rvm/bin:/opt/android-sdk-linux/tools:/opt/android-sdk-linux/platform-tools:/opt/android-sdk-linux/tools/bin:/opt/android-sdk-linux/emulator:/opt/gradle-4.1/bin"

RUN dpkg --add-architecture i386 && \
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt bionic main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt bionic-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb mirror://mirrors.ubuntu.com/mirrors.txt bionic-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq software-properties-common libstdc++6:i386 zlib1g:i386 libncurses5:i386 \
        openjdk-11-jdk vim git git-extras zip gpg-agent \
        locales ca-certificates apt-transport-https curl unzip redir iproute2 expect \
        libc6 libdbus-1-3 libfontconfig1 libgcc1 \
        libpulse0 libtinfo5 libx11-6 libxcb1 libxdamage1 \
        libnss3 libxcomposite1 libxcursor1 libxi6 \
        libxext6 libxfixes3 zlib1g libgl1 socat \
        --no-install-recommends && \
        locale-gen en_US.UTF-8

# Install Android SDK
RUN curl -L $LINK_ANDROID_SDK > /tmp/android-sdk-linux.zip && \
    unzip -q /tmp/android-sdk-linux.zip -d ${ANDROID_HOME}/ && \
    rm /tmp/android-sdk-linux.zip && \
    # Customized steps per specific platform
    yes | sdkmanager --no_https --licenses --sdk_root=${ANDROID_HOME} && \
    yes | sdkmanager --sdk_root=${ANDROID_HOME} tools platform-tools "platforms;android-28" "build-tools;28.0.3" --verbose | uniq && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq purge && \
    # Clean up
    apt-get -yq autoremove && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install stf-client
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
	curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - && \
    curl -sSL https://get.rvm.io | grep -v __rvm_print_headline | bash -s stable --ruby && \
    echo "source /usr/local/rvm/scripts/rvm" >> ~/.bashrc && \
    # Install gems
	/bin/bash -l -c "gem install bundler stf-client:0.3.0 --no-document"

# Install Gradle
RUN cd /opt && \
    curl -fl -sSL https://downloads.gradle.org/distributions/gradle-$GRADLE_VERSION-all.zip -o gradle-all.zip && \
    unzip -q "gradle-all.zip" && \
    rm "gradle-all.zip" && \
    mkdir -p ~/.gradle && \
    echo "org.gradle.daemon=false\norg.gradle.parallel=true\norg.gradle.configureondemand=true" > ~/.gradle/gradle.properties

# Install Marathon
RUN cd /opt && \
	curl -fl -sSL https://github.com/Malinskiy/marathon/releases/download/0.6.0/marathon-0.6.0.zip -o marathon.zip && \
	unzip -q "marathon.zip" && \
    rm "marathon.zip"

# Add STF init script
COPY ./setup-stf.sh /etc/profile.d/stf.sh
RUN echo "source /etc/profile.d/stf.sh" >> ~/.bashrc
