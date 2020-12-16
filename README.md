# Docker image for Quartus

This repository contains a minimal image of Quartus Prime Lite.
You can remove more items by setting the ```QUARTUS_DISABLED``` argument (see Dockerfile).

Quartus is installed to ```/quartus``` in the image.

# Running the instance graphically

While it would be nice if Quartus allowed us to do everything on the command line,
this sometimes isn't possible.

You can pass an X server to quartus using the DISPLAY variable. 

On mac OS, using XQuartz will work. In XQuartz, allow remote connections under Preferences>Security "Allow connections from network clients". Then you'll need to tell X to allow connections from the
docker container. If you use host networking, then you just need to run:

`xhost +localhost`

Then start the container, passing through the directory of the project you want to work on as a volume mount:

`docker run --net=host -v {project_path}:/project --env DISPLAY=host.docker.internal:0 no2chem/quartuslite:latest /quartus/quartus/bin/quartus`