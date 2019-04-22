# Build apps with Gradle in Docker
# Baesd on the Gradle container from https://github.com/keeganwitt/docker-gradle
# MAINTAINER Florin Pățan <florinpatan@gmail.com>

FROM openjdk:12.0.1-jdk-oracle

ENV GRADLE_HOME /opt/gradle
ENV GRADLE_USER_HOME /home/deployer/.gradle
ENV GRADLE_VERSION 5.4
ENV DEBUG_APP false

ARG GRADLE_DOWNLOAD_SHA256=c8c17574245ecee9ed7fe4f6b593b696d1692d1adbfef425bef9b333e3a0e8de
RUN yum install -q -y wget unzip \
    && set -o errexit -o nounset \
    && echo "Downloading Gradle" \
    && wget --no-verbose --output-document=gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    \
    && echo "Checking download hash" \
    && echo "${GRADLE_DOWNLOAD_SHA256} *gradle.zip" | sha256sum --check - \
    \
    && echo "Installing Gradle" \
    && unzip --qq gradle.zip \
    && yum remove -q -y wget unzip \
    && rm gradle.zip \
    && mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
    && ln --symbolic "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle \
    \
    && echo "Adding deployer user and group" \
    && groupadd --system --gid 1000 deployer \
    && useradd --system --gid deployer --uid 1000 --shell /bin/bash --create-home deployer \
    && mkdir -p /home/deployer/.gradle \
    && mkdir -p /home/deployer/workspace \
    && chown --recursive deployer:deployer /home/deployer \
    \
    && echo "Symlinking root Gradle cache to deployer Gradle cache" \
    && ln -s /home/deployer/.gradle /root/.gradle

USER deployer

WORKDIR /home/deployer/workspace

EXPOSE 8080

COPY src ./src
COPY build.gradle .

CMD ["gradle", "-q", "-Dorg.gradle.debug=${DEBUG_APP}", "bootRun"]
