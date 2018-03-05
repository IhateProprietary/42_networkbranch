FROM debian:latest
ADD .sh /root/
RUN chmod u+x /root/.sh
RUN /root/.sh
ADD .gitlab_start.sh /root/
RUN chmod u+x /root/.gitlab_start.sh
ENTRYPOINT ["bash", "/root/.gitlab_start.sh"]