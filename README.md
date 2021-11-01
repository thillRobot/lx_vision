# lx_vision
  This is a ROS package for camera and computer vison for the Pioneer LX Robot at Tennessee Technological University 

## Updating to Ubuntu 20.04 and ROS Noetic 

### Overview

The LX robot at Tennessee Tech ran in Ubuntu Mate 16.04 for a long time. In the summer of 2021, the embedded Intel Atom computer was updated to Ubuntu Mate 20.04. An Intel NUC (thanks RTT) is now used as the control computer and development environment. 

The robot is intended to be used for guest demos and testing for the tour guide/greeter robot. Currently the SICK LiDAR is the primary sensor used for obstacle detection and navigation. In addition to LiDAR, the LX robot needs vison to increase safety and effectiveness during human interaction. 

### Goals
- [ ] enable Kinect V1 currently mounted and wired to LX robot
- [ ] enable rtabmap algorithms from Kinetic (archived launch files)
- [ ] add addtional two more kinects to increase fieid of view
- [ ] enable ZED stereo camera
- [ ] enable human detection, skeleton detecton, gesture detection

### Approach

There are serveral ways to approach this. To begin, I want to test the rtabmap algoritms that were used with the LX in Kinetic. The launch files from Kinetic are archived in this repository so this should work!

**Single Computer Approach:** Cameras directly on LX embedded computer (Intel Atom dual core 64bit)
	I  predict there will be resource limitations due to the age of the computer.

**Distributed Approach:** Cameras on separate camera module computer on-board robot.

- Camera Module Option 1: Intel i3/i5 - Lenovo M73 TinyDesktop 
- Camera Module Option 2: Nvidia Jetson Nano 2Gb/4Gb or TX2 NX (4Gb)
- Camera Module Option 3: Raspberry Pi 3b 
	
### Camera Selection

- Kinect V1 
- ZED Stereo
- Webcams
- I should buy a gigevision camera

### Enabling the Kinect V1

I followed this [guide](https://aibegins.net/2020/11/22/give-your-next-robot-3d-vision-kinect-v1-with-ros-noetic/) for compiling freenect and neccesary ROS package. I have copied the commands from the guide above here for my convience. 

Kinect V1 + Jetson Nano jetpack 4.6 upgraded to 20.04 = currently not working in 20.04 (dont give up!)

Kinect V1 + i5 thinkpad ubuntu 20.04  = currently working in 20.04 (it works super cool!)

#### Step 1 - Setup Ubuntu 20.04 Desktop

First I tried on my older T410 Thinkpad. It was not a fresh install, but I had not done much with this machine.  

#### Step 2 - Compile `libfreenect`


Update the packges
```
sudo apt update
sudo apt upgrade
```

Install Dependencies
```
sudo apt-get install git-core cmake freeglut3-dev pkg-config build-essential libxmu-dev libxi-dev libusb-1.0-0-dev
```
Download the libfreenect source code from gitgub. I cloned the files directly to home and compiled there, but I think you can do this elsewhere. Note, this is not in a catkin workspace. 
```
git clone git://github.com/OpenKinect/libfreenect.git
```
Make and install
```
cd libfreenect
mkdir build
cd build
cmake -L ..
make
sudo make install
sudo ldconfig /usr/local/lib64/
```
Add user to video and plugdev groups
```
sudo adduser $USER video
sudo adduser $USER plugdev
```

Add device rules for the camera. Use vim to open a new file `51-kinect.rules.
```
sudo vim /etc/udev/rules.d/51-kinect.rules
```

Copy the following into the new file and save.
```
# ATTR{product}=="Xbox NUI Motor"
SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02b0", MODE="0666"
# ATTR{product}=="Xbox NUI Audio"
SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02ad", MODE="0666"
# ATTR{product}=="Xbox NUI Camera"
SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02ae", MODE="0666"
# ATTR{product}=="Xbox NUI Motor"
SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02c2", MODE="0666"
# ATTR{product}=="Xbox NUI Motor"
SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02be", MODE="0666"
# ATTR{product}=="Xbox NUI Motor"
SUBSYSTEM=="usb", ATTR{idVendor}=="045e", ATTR{idProduct}=="02bf", MODE="0666"
```

Run` the `src/fwfetcher.py` script in `libfreenect` to configure a specific camera. Plug in and power the camera before running the command below.

```
cd libfreenect
python3 arc/fwfetcher.py`
```

A file `audios.bin` was generated by the python script. Move this to `/usr/local/share`

```
sudo cp audios.bin /usr/local/share/libfreenect
```

Now you can test the microphone and camera with follwing commands.

```
freenect-micview
```

```
freenect-glview
````
You should see the depth image shown in a new window.

#### Step 3 - Integrating with ROS 

If it is not installed already, install ROS Noetic using the official instruction [here](http://wiki.ros.org/noetic/Installation/Ubuntu).
Create and setup a catkin workspace and source the proper files or use a pre-existing catkin workspace.

```
mkdir -p ~/catkin_ws/src
```
Download and compile the packge `freenect_stack` in the workspace.

```
cd ~/catkin_ws/src
git clone https://github.com/ros-drivers/freenect_stack.git
cd ..
catkin_make
```

Source the setup file for the workspace
```
source devel/setup.bash
```
Add the source command to `~/.bashrc` to use the workspace each time a terminal is opened. 
```
echo "source ~/catkin_ws/devel/setup.bash" > ~/.bashrc
```

Now, test the kinect.
```
roslaunch freenect_launch freenect.launch depth_registration:=true
```

Start RVIZ to see the data.
```
rviz
```

Change the fixed from to `camera_link`.
Add a pointcloud2 object and change the topic to `/camera/depth_registered/points`

You should see the pointcloud displayed in the RVIZ window. Woo Hoo! 






### Enabling the ZED stereo camera 

ZED stereo (v1) on the Jetson Nano 4GB BO1 (2019) (model:P3450)

This approach is desired because the jetson is so low power and the M73 i5 is not. The robot has a huge battery, so this is not the biggest deal. The M73 has outdated embedded intel graphics, so the Jetsons Maxwell GPU should do much better with the camera stream.

If this works, it should port over to the TX2 NX if the nano has resource issues. It is below the reccomended specs from stereo labs, but we are going to try anyway. I have a feeling that it will work because I do not even want to display the video there or perform complex analyis...time to test

There are several approaches to this problem. It seems like most (or alot) of people are using docker. I need to try this, but for now let's do it the ME way. Not in docker lol.

Here is what I have done. 

#### Step 1 - Boot Jetson Nano in Jetpack 4.6 (Ubuntu 18.04)
Follow the getting started turtorial from Nvidia [here](https://developer.nvidia.com/embedded/learn/get-started-jetson-nano-devkit).
This involves downloading the Jetpack 4.6 (Ubuntu 18.04ish) operating system image from [here](https://developer.nvidia.com/jetson-nano-sd-card-image) and flashing it with the program of your choice. I have used pi-imager and balena-etcher, but I want to try `dd`. I tried once, but it did not work and now I now why. It is time to try again with `dd` 

#### Step 2 - Upgrade Jetson Nano to Ubuntu 20.04 (jetpack version remains 4.6)
We need to updgrade tp 20.04 because the robot is runnning ROS Noetic. I do not want to downgrade the robot. Do not downgrade the robot!
NVIDIA has not provided an image for 20.04 and will not provide support (see [here](https://forums.developer.nvidia.com/t/ubuntu-20-04-on-nano/125451)). Hopefully this will change. There are several images available like the one in that thread above, however these might not be stable and there is no telling what is in there.  (this is also true about the NVIDIA image of course but...)

I followed this [guide](https://qengineering.eu/install-ubuntu-20.04-on-jetson-nano.html) from QEngineering to use `do-release-upgrade` to upgrade 18.04 to 20.04. Apparantly the Jetpack version is still 4.6, so I do not know what that means. There are some signs on the internet that say this upgrade is a bad idea. For now this is just for testing, lets proceed with caution. Note that Chromium browser and some other packges may need to be removed and not re-installed. There is an alternative [guide](https://stackdata.com/upgrade-nvidia-jetson-nano-from-ubuntu-bionic-beaver-to-focal-fossa/) on stackdata that is similar. In this guide openCV is removed also, but I wanted to avoid this if possible.   

#### Step 3 - Install ROS 
The robot runs on ROS Noetic. Install ROS Noetic using the official instruction [here](http://wiki.ros.org/noetic/Installation/Ubuntu). For now `ros-noetic-desktop-full` will be used because space is not a limitation (I have 32Gb and 64Gb SDs cards). At first I ran into a key during the `apt update` line before the install. I started over at step 1.2 and then it worked fine. I may have skipped a step the first time. Don't be like me.

#### Step 4 - Install ZED SDK
[Download](https://www.stereolabs.com/developers/release/) and Install the software development kit from stereo labs following the getting started [guide](https://www.stereolabs.com/docs/getting-started/) . I think we have the ZED 1, but the SDK should work for all the cameras (check on this, dont beleive me). 
This installation will not work in the wrong OS so make sure to download the correct installer. For now we are using ZED SDK for Jetpack 4.6.

#### Step 5 - Integrate ZED with ROS
There is a section about ROS integration in the ZED docs [here](https://www.stereolabs.com/docs/ros/). Clone and compile the required [ZED packages](https://github.com/stereolabs) in a catkin workspace. I got a little confused about which packages are required, but I think I have it figured out. I should probably read the docs again. Here is what I have tried

I tried to compile the workspace with just `zed-ros-wrapper` and the following error was shown. It did not compile.

```
Could not find the required component `zed_interfaces`. The following ...
```
After reading the docs I tried again with `zed-ros-wrapper` and `zed-ros-interfaces` in src and it compiled without errors. It makes sense to include the `zed-ros-examples` package also. 

```
cd catkin_ws/src
git clone https://github.com/stereolabs/zed-ros-interfaces.git
git clone https://github.com/stereolabs/zed-ros-wrapper.git
git clone https://github.com/stereolabs/zed-ros-examples.git
cd ..
catkin_make
```

#### Test the ZED camera in ROS !

Plug in the camera and run the zed_wrapper launch file shown in the ZED docs. The launch file is specfic to the camera model.

```
roslaunch zed_wrapper zed.launch
```
Turn on RVIZ to see the data. The Jetson nano did not crash, but it did slow down during this process significantly. Add a pointcloud2 through the displays menu and select the topic `zed/zed_node/point_cloud/cloud_registered`, and the pointcloud with color should appear. Changing the view or zooming is very slow on this system (almost unusable). There is a message about reducing the framerate to reduce requirements. I am thinking about using a bigger Jetson!

<img src="images/zed_ros_%20wrapper_rviz.png" alt="drawing" width="800"/>

Cool, it works! Great job team.




## old stuff below here 

Goal: DO STUFF with RTABMAP and LX

    THis should work with a single launch file! MAKE THAT HAPPEN!:

    ON THE ROBOT COMPUTER (the kinect is plugged into the external usb port on LX)

        thill@robot:~$ roslaunch ttu_camera lx_3dmap.launch

	thill@robotlab-t1600:~$ roslaunch rtabmap_ros rtabmap.launch rgb_topic:=/camera/data_throttled_image depth_topic:=/camera/data_throttled_image_depth camera_info_topic:=/camera/data_throttled_camera_info compressed:=true rtabmap_args:="--delete_db_on_start"


	Now you should see the mapping in the rtabmapviz window! Woop Woop!
	Close the terminals and then do this.

	    thill@robotlab-t1600:~$ rtabmap-databaseViewer ~/.ros/rtabmap.db

	You can now save the file as a .ply and open it with 'meshlab'

  This works but my launch files should work!
