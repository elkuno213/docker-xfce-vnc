# Docker Headless VNC Container

This repository provides a Docker container for running a headless VNC environment. It is designed for remote access to a graphical desktop environment via a web browser or VNC client.

## Concept

The container runs a lightweight desktop environment with a VNC server and a noVNC web client. This allows users to interact with the desktop remotely without requiring a physical display.

## Components

- **VNC Server**: Provides remote desktop access.
- **noVNC**: Web-based VNC client for browser access (optional).
- **Desktop Environment**: Lightweight XFCE4 for a minimal GUI experience.

## How to build

To build the Docker image, use the following command:

```bash
docker image build -t <tag-name> --file Dockerfile.ubuntu-xfce-vnc .
```

## How to Run

### Required Arguments

Run the container with the following command:

```bash
docker container run         \
  -it                        \
  --rm                       \
  -e VNC_PASSWORD=<password> \
  -e DISPLAY=:1              \
  -e VNC_PORT=5901           \
  -e NOVNC_PORT=6901         \
  -p 5901:5901               \
  -p 6901:6901               \
  <image>
```

### Optional Arguments

You can customize the container using these optional environment variables:

- **`VNC_COL_DEPTH`**: Sets the color depth for the VNC server. Default: `24`.
- **`VNC_RESOLUTION`**: Defines the screen resolution for the VNC server. Default: `1920x1080`.
- **`VNC_VIEW_ONLY`**: Enables view-only mode. Default: `false`. Set to `true` to allow viewing without control.
- **`SUPERVISOR_LOG_LEVEL`**: Specifies the log level for Supervisor. Default: `warn`. Options: `debug`, `info`, `warn`, `error`.

### Accessing the Desktop

- **VNC Client**:

```bash
vncviewer localhost::5901
# or
vncviewer <ip-address>::5901
```

- **Web Browser**:

```bash
<your-browser> http://localhost:6901/\?password\=<password>
# or
<your-browser> http://<ip-address>:6901/\?password\=<password>
```
