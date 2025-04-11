#!/bin/bash
set -e

# Validate and set environment variables with defaults.
validate_and_set_env() {
  # Check if PASSWORD is set.
  if [[ -z "$PASSWORD" ]]; then
    echo "Error: PASSWORD is not set. Please provide it as an environment variable."
    exit 1
  fi

  # Set default values for environment variables if not provided.
  export DISPLAY=${DISPLAY:-:1}
  export NOVNC_PORT=${NOVNC_PORT:-6901}
  export SSH_PORT=${SSH_PORT:-2222}

  # Log the values being used.
  echo "Using DISPLAY: $DISPLAY"
  echo "Using NOVNC_PORT: $NOVNC_PORT"
  echo "Using SSH_PORT: $SSH_PORT"
}

# Configure SSH password.
configure_ssh_password() {
  echo "root:$PASSWORD" | chpasswd
}

# Configure VNC password.
configure_vnc_password() {
  mkdir -p "$HOME/.vnc"
  local passwd_path="$HOME/.vnc/passwd"

  # Remove existing password file if it exists.
  if [[ -f $passwd_path ]]; then
    rm -f $passwd_path
  fi

  if [[ $VNC_VIEW_ONLY == "true" ]]; then
    echo "$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)" | vncpasswd -f >$passwd_path
  fi

  echo "$PASSWORD" | vncpasswd -f >>$passwd_path
  chmod 600 $passwd_path
}

# Configure xstartup file for VNC.
configure_xstartup() {
  mkdir -p "$HOME/.vnc"
  local xstartup_path="$HOME/.vnc/xstartup"

  if [[ ! -f $xstartup_path ]]; then
    cat >$xstartup_path <<'EOF'
#!/bin/sh
# Start up the standard system desktop
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
/usr/bin/startxfce4
EOF
    chmod +x $xstartup_path
  fi
}

# Generate Supervisor Configurations.
generate_supervisor_configs() {
  # Supervisor configuration
  cat >/etc/supervisor/supervisord.conf <<EOF
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
childlogdir=/var/log/supervisor
loglevel=$SUPERVISOR_LOG_LEVEL
user=root

[include]
files = /etc/supervisor/conf.d/*.conf
EOF

  # VNC server configuration.
  cat >/etc/supervisor/conf.d/vncserver.conf <<EOF
[program:vncserver]
command=/usr/bin/vncserver $DISPLAY -depth $VNC_COL_DEPTH -geometry $VNC_RESOLUTION -localhost no PasswordFile=$HOME/.vnc/passwd
priority=10
# autostart=true
# autorestart=true
stdout_logfile=/var/log/supervisor/vncserver.log
stderr_logfile=/var/log/supervisor/vncserver.err
EOF

  # noVNC configuration.
  cat >/etc/supervisor/conf.d/novnc.conf <<EOF
[program:novnc]
command=$NOVNC_HOME/utils/novnc_proxy --vnc localhost:$VNC_PORT --listen $NOVNC_PORT
priority=20
# autostart=true
# autorestart=true
stdout_logfile=/var/log/supervisor/novnc.log
stderr_logfile=/var/log/supervisor/novnc.err
EOF
}

# Main execution.
main() {
  echo -e "\n============================================================"
  echo "Validating Environment Variables"
  echo "============================================================"
  validate_and_set_env

  echo -e "\n============================================================"
  echo "Starting SSH Setup"
  echo "============================================================"
  echo "Restarting SSH service..."
  service ssh restart
  configure_ssh_password

  echo -e "\n============================================================"
  echo "Starting Supervisor"
  echo "============================================================"
  configure_vnc_password
  configure_xstartup
  generate_supervisor_configs
  exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
}

main "$@"
