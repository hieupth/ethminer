FROM nvidia/cuda:11.2.0-devel-ubuntu18.04 AS build

WORKDIR /

# Package and dependency setup
RUN apt-get update && \
    apt-get install -yq --no-install-recommends \
        software-properties-common \
        git \
        cmake \
        build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add source files
COPY . /ethminer
WORKDIR /ethminer

# Manually copy Boost sources
# RUN mkdir -p /root/.hunter/_Base/Download/Boost/1.66.0/075d0b4 && \
#     mv boost_1_66_0.7z /root/.hunter/_Base/Download/Boost/1.66.0/075d0b4/

# Build. Use all cores.
RUN mkdir build; \
    cd build; \
    cmake .. -DETHASHCUDA=ON -DAPICORE=ON -DETHASHCL=OFF -DBINKERN=OFF; \
    cmake --build . -- -j; \
    make install;

FROM nvidia/cuda:11.2.0-base-ubuntu18.04

# Copy only executable from build
COPY --from=build /usr/local/bin/ethminer /usr/local/bin/

# Prevent GPU overheading by stopping in 90C and starting again in 60C
ENV GPU_TEMP_STOP=90
ENV GPU_TEMP_START=60

# These need to be given in command line.
ENV ETH_WALLET=0x00
ENV WORKER_NAME="none"
ENV ETHMINER_API_PORT=3000

EXPOSE ${ETHMINER_API_PORT}

# Start miner. Note that wallet address and worker name need to be set
# in the container launch.
CMD ["bash", "-c", "/usr/local/bin/ethminer -U --api-port ${ETHMINER_API_PORT} \
--HWMON 2 --tstart ${GPU_TEMP_START} --tstop ${GPU_TEMP_STOP} --exit \
-P stratums://$ETH_WALLET.$WORKER_NAME@eu1.ethermine.org:5555 \
-P stratums://$ETH_WALLET.$WORKER_NAME@asia1.ethermine.org:5555 \
-P stratums://$ETH_WALLET.$WORKER_NAME@us1.ethermine.org:5555 \
-P stratums://$ETH_WALLET.$WORKER_NAME@us2.ethermine.org:5555"]
