#!/usr/bin/env bash

# Installs ROS Noetic + poppy_controllers package


# Function arguments
creature=$1
poppy_controllers_branch=${2:-"master"}

# Available robots for ROS
ros_robots="poppy-ergo-jr"


contains() {
	[[ "$1" =~ (^|[[:space:]])"$2"($|[[:space:]]) ]]
}

source "$HOME/pyenv/bin/activate"

GREEN="\e[92m"
YELLOW="\e[93m"
CLEAR="\e[0m"

install_ros()
{
	echo -e "${YELLOW}Installing ROS for ${1}${CLEAR}"

	sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu buster main" > /etc/apt/sources.list.d/ros-noetic.list'  # Set up ROS Noetic repo
	sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654  # Add official ROS key

	sudo apt update  # Pull all meta info of ROS Noetic packages
	sudo apt-get install -y python-rosdep python-rosinstall-generator python-wstool python-rosinstall build-essential cmake  # Dependencies for building packages

	sudo rosdep init  # Initialize rosdep
	rosdep update  # fetching package information from the repos that are just initialized

	mkdir -p $HOME/catkin_ws
	pushd $HOME/catkin_ws || exit
		rosinstall_generator ros_comm actionlib sensor_msgs control_msgs trajectory_msgs dynamic_reconfigure cv_bridge --rosdistro noetic --deps --wet-only --tar > noetic-custom_ros.rosinstall

		wstool init src noetic-custom_ros.rosinstall  # fetch all the remote repos specified from the noetic-custom_ros.rosinstall file locally to src
		rosdep install -y --from-paths src --ignore-src --rosdistro noetic -r --os=debian:buster  # install all system dependencies

		download_poppy_controllers "$poppy_controllers_branch"

    sudo $HOME/pyenv/bin/pip3 install empy catkin_pkg netifaces

    export PYTHONPATH="/usr/bin/python3.7:$HOME/pyenv/bin/python3"  # hard coded python3.7

		sudo ./src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release -j2 -DPYTHON_EXECUTABLE=$HOME/pyenv/bin/python3 --install-space /opt/ros/noetic

		source /opt/ros/noetic/setup.bash
		add_line_to_bashrc 'source /opt/ros/noetic/setup.bash'

	popd || exit

	source $HOME/catkin_ws/devel/setup.bash
	add_line_to_bashrc 'source $HOME/catkin_ws/devel/setup.bash'
	add_line_to_bashrc 'export ROS_HOSTNAME=$(hostname).local'
	add_line_to_bashrc 'export ROS_MASTER_URI=http://localhost:11311'

	add_ros_service

	echo -e "${GREEN}ROS has been installed${CLEAR}"
}


download_poppy_controllers()
{
	echo -e "${YELLOW}Installing poppy_controller${CLEAR}"
	pushd src || exit
		wget --progress=dot:mega "https://github.com/poppy-project/poppy_controllers/archive/${1}.zip" -O poppy_controllers.zip
        unzip -q poppy_controllers.zip
        rm -f poppy_controllers.zip
        mv "poppy_controllers-${1}" poppy_controllers
    popd || exit
}


add_ros_service()
{
	echo -e "${YELLOW}Creating a ROS service${CLEAR}"

	sudo tee /etc/systemd/system/ros-poppy_controllers.service > /dev/null <<EOF
[Unit]
Description=ROS Poppy Controllers
Wants=network-online.target
After=network.target network-online.target
[Service]
PIDFile=/run/ros-poppy_controllers.pid
Environment="PATH=/opt/ros/noetic/bin:$HOME/pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/games:/usr/games"
ExecStart=/usr/local/bin/poppy_controllers
User=poppy
Group=poppy
WorkingDirectory=/home/poppy/catkin_ws/
Type=simple
StandardOutput=append:/tmp/ros-poppy_controllers.log
StandardError=append:/tmp/ros-poppy_controllers.log
[Install]
WantedBy=multi-user.target
EOF

	sudo tee /usr/local/bin/poppy_controllers > /dev/null <<EOF
#!/usr/bin/env bash
source /opt/ros/noetic/setup.bash
source $HOME/catkin_ws/devel/setup.bash
export ROS_HOSTNAME=$(hostname).local
echo -e "=== Launching Poppy controllers - $(date '+%F %T') ==="
bash -c "roslaunch poppy_controllers control.launch"
EOF

}

add_line_to_bashrc()
{
  	if grep -q "$1" "$HOME/.bashrc"
		then
		  echo "${1} is already in .bashrc"
		else
		  echo "${1}" >> "$HOME/.bashrc"
		fi
}

if eval contains "$creature" $ros_robots ; then
	install_ros "$creature"
else
	echo -e "${YELLOW}ROS is not available for ${creature}.${CLEAR}"
fi