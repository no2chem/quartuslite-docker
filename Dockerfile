FROM ubuntu:20.04 as build

ARG QUARTUS_URL=https://download.altera.com/akdlm/software/acdsinst/20.1std.1/720/ib_tar/Quartus-lite-20.1.1.720-linux.tar

# First, get wget so we can download Quartus
RUN apt-get update && apt-get install -y wget
    
# Make an install directory, download Quartus and extract Quartus into it.
RUN mkdir quartus_install \
    && wget ${QUARTUS_URL} -O quartus.tar \
    && tar -C quartus_install -xf quartus.tar \
    && rm quartus.tar

ARG QUARTUS_DIR="/quartus"

#Define items we don't need in the image. By default, we turn off modelsim, help and update to keep the image small
#Below are the valid options:
#quartus quartus_help devinfo arria_lite cyclone cyclone10lp cyclonev max max10 quartus_update modelsim_ase modelsim_ae
ARG QUARTUS_DISABLED="quartus_help,quartus_update,modelsim_ase,modelsim_ae"

# Run the Quartus installer and cleanup the install directory when done
RUN quartus_install/setup.sh --mode unattended --accept_eula 1 --installdir ${QUARTUS_DIR} --disable-components ${QUARTUS_DISABLED}\
    && rm -rf quartus_install && chmod -R a+rx ${QUARTUS_DIR}

# Flatten image
FROM ubuntu:20.04

# Need to redefine the quartus dir since this is a new stage.
ARG QUARTUS_DIR="/quartus"
COPY --from=build /${QUARTUS_DIR} /${QUARTUS_DIR}

# Install packages necessary for Quartus to work
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    libglib2.0-0 \
    libpng-dev \
    libfreetype6 \
    libsm6 \
    libxrender1 \
    libfontconfig1 \
    libxext6 \
# replaces libc allocator    
    libtcmalloc-minimal4 \
# for installing locales    
    locales \
# java needed for platform designer / qsys
    default-jre \
# needed for normal init environment
    dumb-init \
# needed to add the libpng12 repository
    software-properties-common \
# Need to manually get libpng12   
    && add-apt-repository ppa:linuxuprising/libpng12 \
    && apt update \
    && apt install libpng12-0 \
# Generate the en_US locale
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
# Remove wget from final image
    && apt-get remove -y wget \
# cleanup apt-list
    && rm -rf /var/lib/apt/lists/*

# Set environment so Quartus is in the path
ENV PATH="${QUARTUS_DIR}/quartus/bin:${PATH}"
ENV QUARTUS_DIR=${QUARTUS_DIR}

# Needed to fix allocator issues (see https://forums.intel.com/s/question/0D50P00003yyTbKSAU/quartus-prime-lite-edition-171-not-running-in-docker-linux)
ENV LD_PRELOAD="/usr/lib/x86_64-linux-gnu/libstdc++.so.6  /usr/lib/x86_64-linux-gnu/libtcmalloc_minimal.so.4"

# Force en_US.UTF8
ENV LC_ALL="en_US.UTF-8"

# Use dump-init as an entry point
ENTRYPOINT ["/usr/bin/dumb-init", "--"]