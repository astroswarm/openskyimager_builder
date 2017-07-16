ARG ARCH

FROM astroswarm/base-$ARCH:latest

# Install X dependencies
RUN apt-get -y update && apt-get -y install \
  x11vnc \
  xvfb

# Install build dependencies
RUN apt-get -y update && apt-get -y install \
  build-essential \
  cmake \
  git \
  libcfitsio3-dev \
  libglib2.0-0 \
  libglib2.0-dev \
  libgtk2.0-0 \
  libgtk2.0-dev \
  libgtk-3-0 \
  libgtk-3-dev \
  libudev-dev \
  libusb-1.0-0 \
  sudo \
  wget

# Configure application
ARG OPENSKYIMAGER_ARCH

# Build
WORKDIR /tmp
RUN wget http://download.cloudmakers.eu/atikccd-1.11-$OPENSKYIMAGER_ARCH.deb
RUN dpkg -i atikccd-1.11-$OPENSKYIMAGER_ARCH.deb; apt-get -fy install
RUN git clone https://github.com/freerobby/OpenSkyImager.git /OpenSkyImager
RUN mkdir /OpenSkyImager/build
WORKDIR /OpenSkyImager/build
RUN cmake -D FORCE_QHY_ONLY=false ..
RUN make -j 1 # OSI's dependency chain cannot guarantee successful parallel builds, so only use one core.

# Configure display
ENV BIT_DEPTH 16
ENV GUI_HEIGHT 550
ENV GUI_WIDTH 870

# Create startup script to run full graphical environment followed by phd2
RUN echo "#!/usr/bin/env sh" > /start.sh
# Docker doesn't clean the file system on restart, so clean any old lock that may exist
RUN echo "/bin/rm -f /tmp/.X0-lock" >> /start.sh
RUN echo "/usr/bin/Xvfb :0 -screen 0 ${GUI_WIDTH}x${GUI_HEIGHT}x${BIT_DEPTH} &" >> /start.sh
RUN echo "/usr/bin/x11vnc -display :0 -forever &" >> /start.sh
RUN echo "DISPLAY=:0 /OpenSkyImager/build/gtk/gtkImager" >> /start.sh
RUN echo "" >> /start.sh
RUN chmod +x /start.sh

EXPOSE 5900

CMD "/start.sh"
