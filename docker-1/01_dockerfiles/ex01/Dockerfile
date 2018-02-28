FROM debian:jessie

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install bzip2 -y
RUN apt-get install sudo -y
RUN apt-get install openssl -y
RUN apt-get install ca-certificates -y
WORKDIR /usr/local/teamspeak
ADD http://teamspeak.gameserver.gamed.de/ts3/releases/3.1.0/teamspeak3-server_linux_amd64-3.1.0.tar.bz2 .
RUN adduser --disabled-login --gecos "" teamspeak
RUN tar xjf teamspeak3-server_linux_amd64-3.1.0.tar.bz2
RUN chown -R teamspeak:teamspeak teamspeak3-server_linux_amd64
WORKDIR ./teamspeak3-server_linux_amd64
RUN echo 'license_accepted=1' > .ts3server_license_accepted
ENTRYPOINT ["sudo", "-u", "teamspeak", "./ts3server_minimal_runscript.sh"]