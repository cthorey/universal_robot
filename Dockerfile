# Docker image for ros and kinetic
FROM osrf/ros:kinetic-desktop-full

# install moveit
RUN apt-get update &&\
    apt-get install -y iputils-ping &&\
    apt-get install -y ros-kinetic-moveit

# using bash instead of sh to be able to source
ENV TERM xterm
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Setup the catkkin worskapce
# ur_driver is obsolet above 1.8 for the firmware so we use ur_modern_driver.
# + we are using a fork of this one from a different guy cause of incompatibily
# with kinetic https://github.com/ThomasTimm/ur_modern_driver

RUN source "/opt/ros/kinetic/setup.bash" &&\
    mkdir catkin_ws &&\
    mkdir catkin_ws/src &&\
    cd /catkin_ws/src

# DONT PULL IT FRON UNIVERSAL ROBOT - THEY INTRODUCE SOME BREAKING CHANGE IN
# OR WE DID SOME CHANGE THAT ARE WORKING. I tried to find some good commit to
# go back to but did not find any
#TODO - Pull universal_robot from the official repo + ur_modern_driver from my fork.

COPY . /catkin_ws/src/universal_robot

# # python package

ADD get_pip.py /get_pip.py
RUN python get_pip.py
RUN pip install ipython

# https://github.com/ros-planning/moveit/issues/86#issuecomment-290319557
# trick to fix a bug in moveitcontroller
RUN pip uninstall -y pyassimp
RUN pip install pyassimp

# Needed to see the position_controllers/JointTrajectoryController
RUN apt-get update &&\
    apt-get install -y ros-kinetic-joint-trajectory-controller

# this variable is passed in the ur_modern_driver and represent the IP OF THE HOST. Necessaru
# for the robot to communicate properly, see https://github.com/ThomasTimm/ur_modern_driver/issues/111
ARG host_ip
ENV HOST_IP=${host_ip:-'0.0.0.0'}

#Setup the package
RUN source "/opt/ros/kinetic/setup.bash"  &&\
    cd /catkin_ws &&\
    catkin_make

COPY ./ros_entrypoint.sh /
ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
