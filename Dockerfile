FROM rockylinux:8.9
# FROM centos:7
RUN yum update -y; yum clean all;\
    yum -y install mkisofs python3; yum clean all;

WORKDIR /opt
COPY ./scripts /opt/scripts

ENV PATH $PATH:/opt/scripts
# CMD [ "bash" ]
