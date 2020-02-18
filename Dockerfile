FROM dorowu/ubuntu-desktop-lxde-vnc
LABEL author="Joe Barbere"

RUN apt-get update && apt-get install -y dirmngr wget curl mlocate tmux htop

# Adding keys for ROS
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
RUN wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add -

# Installing ROS
RUN apt-get update && apt-get install -y ros-melodic-desktop-full \
		wget git nano python-rosinstall python3-colcon-common-extensions python3-pip
RUN rosdep init && rosdep update

# Installing Colcon bundle tools
RUN pip3 install -U setuptools && pip3 install colcon-ros-bundle

RUN mkdir -p /home/ubuntu/catkin_ws/src

# install minio
RUN wget https://dl.min.io/server/minio/release/linux-amd64/minio
RUN sudo chmod +x minio
RUN sudo mv minio /usr/local/bin
RUN sudo useradd -r minio-user -s /sbin/nologin
RUN sudo chown minio-user:minio-user /usr/local/bin/minio
RUN mkdir /data
RUN sudo chown minio-user:minio-user /data

# install ELK
RUN wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
RUN echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-6.x.list
RUN sudo apt-get update
RUN sudo apt-get install -y default-jdk
RUN sudo apt-get install -y elasticsearch logstash kibana

# CUDA/CNN
RUN sudo apt-get install -y nvidia-cuda-toolkit

RUN pip3 install matplotlib elasticsearch python-logstash jupyter seaborn jupyter-tensorboard

COPY . /home/ubuntu/catkin_ws/src

RUN /bin/bash -c "source /opt/ros/melodic/setup.bash \
    && cd /home/ubuntu/catkin_ws/ \
    && catkin_make \
    && echo 'source /home/ubuntu/catkin_ws/devel/setup.bash' >> ~/.bashrc \
    && source /home/ubuntu/catkin_ws/devel/setup.bash"

RUN cd /home/ubuntu/catkin_ws && sudo rosdep fix-permissions && rosdep update && rosdep install --from-paths src --ignore-src --rosdistro=melodic -y

RUN /bin/bash -c "source /opt/ros/melodic/setup.bash \
    && source /home/ubuntu/catkin_ws/devel/setup.bash \
    && cd /home/ubuntu/catkin_ws/src/simulation_ws \
    && ./setup.sh \
    && cd src \
    && colcon build \
    && cd rl-agent \
    && pip3 install . \
    && cd .. \
    && source install/local_setup.sh \
    && chmod +x /home/ubuntu/catkin_ws/src/run.sh \
    && chmod +x /home/ubuntu/catkin_ws/src/setup.sh \
    && chmod +x /home/ubuntu/catkin_ws/src/minio.sh \
    && chmod +x /home/ubuntu/catkin_ws/src/elk.sh \
    && chmod +x /home/ubuntu/catkin_ws/src/jupyter.sh"