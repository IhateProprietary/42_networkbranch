FROM debian:latest
ADD .sh /root/
RUN chmod u+x /root/.sh
RUN /root/.sh
ADD .gitlab_start.sh /root/
RUN apt-get install openssh-server -y
RUN chmod u+x /root/.gitlab_start.sh
EXPOSE 80
EXPOSE 22
ENTRYPOINT ["bash", "/root/.gitlab_start.sh"]