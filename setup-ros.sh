#!/usr/bin/env bash

# Installs ROS Noetic + poppy_controllers package


# Function arguments
creature=$1
poppy_controllers_branch=${2:-"master"}
HOSTNAME_HOME="/home/${3:-"poppy"}"

# Available robots for ROS
ros_robots="poppy-ergo-jr"

# Returns boolean 'value $1 is in list $2'
contains() {
	[[ "$1" =~ (^|[[:space:]])"$2"($|[[:space:]]) ]]
}

# Color for echos
ORANGE="\e[33m"
CLEAR="\e[0m"

export PATH="$HOSTNAME_HOME/pyenv/bin:$PATH"

# activate the python virtual env for all the script
source "$HOSTNAME_HOME/pyenv/bin/activate"

print_env()
{
    env
}

install_ros()
{
	echo -e "${ORANGE} Installing ROS for ${1}${CLEAR}"

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

    pip install empy catkin_pkg netifaces rospkg

    print_env

		sudo PYTHONPATH="/usr/lib/python3.7/dist-packages:$HOSTNAME_HOME/pyenv/lib/python3.7/dist-packages" ./src/catkin/bin/catkin_make_isolated --install -DCMAKE_BUILD_TYPE=Release -j2 -DPYTHON_EXECUTABLE=/home/poppy/pyenv/bin/python3 --install-space /opt/ros/noetic

    source /opt/ros/noetic/setup.bash
    add_line_to_bashrc 'source /opt/ros/noetic/setup.bash'

    remove_ros_packages_from_catkin_after_install

    add_poppy_controllers "$poppy_controllers_branch"

	popd || exit

	add_line_to_bashrc 'export ROS_HOSTNAME=$(hostname).local'
	add_line_to_bashrc 'export ROS_MASTER_URI=http://localhost:11311'
}


add_poppy_controllers()
{
	echo -e "${ORANGE} Downloading poppy_controllers${CLEAR}"
	mkdir -p src/
	pushd src || exit
		wget --progress=dot:mega "https://github.com/poppy-project/poppy_controllers/archive/${1}.zip" -O poppy_controllers.zip
    unzip -q poppy_controllers.zip
    rm -f poppy_controllers.zip
    mv "poppy_controllers-${1}" poppy_controllers
  popd || exit

  catkin_make

  source $HOSTNAME_HOME/catkin_ws/devel/setup.bash
  add_line_to_bashrc 'source $HOME/catkin_ws/devel/setup.bash'
}

remove_ros_packages_from_catkin_after_install()
{
  echo -e "${ORANGE} Removing all built ros packages from catkin_ws${CLEAR}"

  sudo rm -rf ./*
}



add_ros_service()
{
	echo -e "${ORANGE} Creating a ROS service${CLEAR}"

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
export ROS_HOSTNAME=\$(hostname).local
echo -e "=== Launching Poppy controllers - $(date '+%F %T') ==="
bash -c "roslaunch poppy_controllers control.launch"
EOF

sudo chmod +x /usr/local/bin/poppy_controllers
}

add_line_to_bashrc()
{
  	if grep -q "$1" "$HOSTNAME_HOME/.bashrc"
		then
		  echo "${1} is already in .bashrc"
		else
		  echo "${1}" >> "$HOSTNAME_HOME/.bashrc"
		fi
}

if eval contains "$creature" $ros_robots ; then
	install_ros "$creature"

	add_ros_service

	echo -e "${ORANGE}ROS has been installed${CLEAR}"
else
	echo -e "${ORANGE}ROS is not available for ${creature}.${CLEAR}"
fi
