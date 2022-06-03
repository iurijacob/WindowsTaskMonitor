# Task Monitor

Script to monitor Windows scheduled tasks. It checks for tasks that have failed in the last minutes and sends e-mail alerts in this case.

The settings and its specifications can be found in the beginning of file Taskmon.ps1

This script must be itself scheduled in Windows Task Schedule by calling Taskmon.bat at desired frequency.
