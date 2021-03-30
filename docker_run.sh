#!/usr/bin/env bash

ARGS=("$@")

# Make sure processes in the container can connect to the x server
# Necessary so gazebo can create a context for OpenGL rendering (even headless)
XAUTH=/tmp/.docker.xauth
if [ ! -f $XAUTH ]; then
    xauth_list=$(xauth nlist $DISPLAY)
    xauth_list=$(sed -e 's/^..../ffff/' <<<"$xauth_list")
    if [ ! -z "$xauth_list" ]; then
        echo "$xauth_list" | xauth -f $XAUTH nmerge -
    else
        touch $XAUTH
    fi
    chmod a+r $XAUTH
fi

DOCKER_OPTS=

# Get the current version of docker-ce
# Strip leading stuff before the version number so it can be compared
DOCKER_VER=$(dpkg-query -f='${Version}' --show docker-ce | sed 's/[0-9]://')
if dpkg --compare-versions 19.03 gt "$DOCKER_VER"; then
    echo "Docker version is less than 19.03, using nvidia-docker2 runtime"
    if ! dpkg --list | grep nvidia-docker2; then
        echo "Please either update docker-ce to a version greater than 19.03 or install nvidia-docker2"
        exit 1
    fi
    DOCKER_OPTS="$DOCKER_OPTS --runtime=nvidia"
else
    #DOCKER_OPTS="$DOCKER_OPTS --gpus all"
    echo "No GPU"
fi

# Prevent executing "docker run" when xauth failed.
if [ ! -f $XAUTH ]; then
    echo "[$XAUTH] was not properly created. Exiting..."
    exit 1
fi

if [ ! -z "$1" ]; then
    ROS_MASTER_URI=http://$1:11311
    echo "ROS_MASTER $1"
fi

if [ ! -z "$2" ]; then
    ROS_IP=$2
    echo "ROS_IP $2"
fi

BASH_OPTION=bash
# if [ ! -z "$3" ]; then
#     if [ $3 = "husky1" ]; then
#         BASH_OPTION="bash -c ~/subt-system/scripts/husky1_gui.sh"
#     fi
#     if [ $3 = "husky2" ]; then
#         BASH_OPTION="bash -c ~/subt-system/scripts/husky2_gui.sh"
#     fi
#     if [ $3 = "df_gui" ]; then
#         BASH_OPTION="bash -c ~/subt-system/scripts/df_gui.sh"
#     fi
#     echo "run $3"
# fi

docker run \
    -it \
    --rm \
    -e DISPLAY \
    -e QT_X11_NO_MITSHM=1 \
    -e XAUTHORITY=$XAUTH \
    -e ROS_MASTER_URI=$ROS_MASTER_URI \
    -e ROS_IP=$ROS_IP \
    -v "$XAUTH:$XAUTH" \
    -v "/home/$USER/subt-jackal:/home/argsubt/subt-jackal" \
    -v "/media/$USER:/media/argsubt" \
    -v "/tmp/.X11-unix:/tmp/.X11-unix" \
    -v "/etc/localtime:/etc/localtime:ro" \
    -v "/dev:/dev" \
    -v "/var/run/docker.sock:/var/run/docker.sock" \
    -v "/home/$USER/.bashrc:/home/argsubt/.bashrc" \
    -v "/home/$USER/xbee_ws:/home/argsubt/xbee_ws"\
    --name argsubt \
    --network host \
    --privileged \
    --security-opt seccomp=unconfined \
    $DOCKER_OPTS \
    argnctu/subt:jackal \
    $BASH_OPTION
