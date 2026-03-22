{
  roles = [ "graphical/plasma" ];

  # sddm fails to start gamescope-session (Authentication error: SDDM::Auth::ERROR_INTERNAL "Child process set up failed: execve: No such file or directory")
  overlay.enableUutils = false;
}
