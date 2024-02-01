FROM ubuntu:focal

ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics

RUN apt update && apt dist-upgrade -y && apt update && apt install -y apt-utils build-essential \
    vim git wget curl apt-transport-https lsb-release

RUN DEBIAN_FRONTEND=noninteractive apt install -y libssl-dev libusb-1.0-0-dev libudev-dev \  
    pkg-config libgtk-3-dev cmake libglfw3-dev libgl1-mesa-dev libglu1-mesa-dev at libudev-dev udev \ 
    libelf-dev elfutils dwarves bison flex

ENV RS_WS=/home/realsense_ws
RUN mkdir $RS_WS 

RUN cd $RS_WS && git clone https://github.com/IntelRealSense/librealsense

RUN cd $RS_WS/librealsense && sed -i 's/sudo//g' scripts/setup_udev_rules.sh
RUN cd $RS_WS/librealsense && ./scripts/setup_udev_rules.sh

# use sed to remove the 'sudo' prefix from the commmands in the scripts
RUN cd $RS_WS/librealsense && sed -i 's/sudo//g' scripts/patch-utils-hwe.sh
RUN cd $RS_WS/librealsense && sed -i 's/sudo//g' scripts/patch-realsense-ubuntu-lts-hwe.sh
RUN cd $RS_WS/librealsense && ./scripts/patch-realsense-ubuntu-lts-hwe.sh

#RUN echo 'hid_sensor_custom' | tee -a /etc/modules

COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"] 
