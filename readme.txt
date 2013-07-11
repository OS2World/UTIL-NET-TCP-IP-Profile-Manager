TCP/IP PROFILE MANAGER

  TCP/IP Profile Manager lets you define multiple TCP/IP configurations (as
  selectable "profiles") and switch between them without rebooting.

  This is mainly useful if you have a laptop which you have to move between
  different locations which require diffent IP configurations (for instance,
  some static, others using DHCP).

  This program is designed to manage WIRED network configurations.  To switch
  between wired (Ethernet, Token-ring) and wireless (WiFi) connections, you 
  should use XWLAN (available at http://wlan.netlabs.org) instead.  (In 
  theory, this program should be able to change your IP configuration between
  wired and wireless without trouble; however, it has no facility for setting 
  up the actual wireless connection, so you will still need XWLAN or an
  equivalent program for that purpose.)

  Similarly, to manage dial-up connections, you will still need to use an 
  appropriate dial-up manager.  You can still use this program to manage any
  direct (wired) network connections you may have.


HOW IT WORKS

  This program works by storing copies of the three main TCP/IP configuration 
  files (listed below) under each selectable profile.  When you activate a 
  profile, the active configuration files used by the system are replaced
  on the fly with the copies from the selected profile, and then all TCP/IP
  interfaces are flushed and reset.  You can create and edit each profile 
  independently (without having to activate it first).  

  The currently-active configuration is treated as a separate pseudo-profile;
  you can therefore independently modify the active TCP/IP configuration at
  any time without affecting the operation of this program.

  The three configuration files affected are:
     ?:\MPTN\BIN\SETUP.CMD   TCP/IP interface configuration script
     %ETC%\RESOLV2           DNS configuration and domain resolution
     %ETC%\DHCPCD.CFG        DHCP configuration options

  Note that each profile contains the configuration for ALL direct TCP/IP
  connections (lan0 through lan7).


INSTALLATION

  Copy IPPROF.EXE to a directory of your choosing.  It is best to place it 
  in its own dedicated directory, as all saved profiles will be stored in a
  subdirectory (called PROFILES) of whatever directory IPPROF.EXE is located 
  in.

  Create a program object for IPPROF.EXE somewhere on your desktop.  Call 
  it "TCP/IP Profiles" or something similar.

  Make sure VROBJEX.DLL (included) exists somewhere on your LIBPATH, or
  in the same directory as IPPROF.EXE.

  The first time you run TCP/IP Profile Manager, it will prompt you to 
  create a new profile based on your current TCP/IP settings.


USAGE

  TCP/IP Profile Manager is quite simple to use.  The main window shows a
  list of defined profiles, plus an entry representing the current
  configuration (which may or may not be the same as an existing profile).

  The "New" button lets you create a new profile by bringing up the "Create
  New Profile" dialog:

   - Profile name: This is a short identifier for the profile.  All files 
                   for this profile will be kept in a subdirectory of this
                   name (under the PROFILES directory).  For this reason,
                   the profile name must be a legal filename.

   - Description:  A string which describes the profile.  This will be
                   displayed (along with the profile name) in the main
                   window's list of profiles, and also in the titlebar of
                   the profile view window.

   - Copy from:    If selected, this option allows you to copy the new 
                   profile's configuration from one of your previously-
                   existing profiles.  If not selected, the new profile's
                   configuration will be copied from the currently-active
                   TCP/IP configuration instead.  In either case, you will
                   presumably want to make modifications to the profile
                   configuration once it has been created.

  The "View" button brings up a dialog which shows the contents of the
  profile's configuration files.  You also have the option of editing each
  file manually in an editor using the "Edit" button.

  The "Modify" button allows you to modify the selected profile using the
  TCP/IP configuration GUI.

  The "Delete" button deletes the selected profile (you will be prompted for
  confirmation first).

  The "Activate" button activates the selected profile.

  The "Options" button brings up a dialog where you can modify selected
  program options:

   - Configuration Editor
        This option allows you to select the external program to be used as 
        the TCP/IP configuration GUI (called when you select "Modify" on the 
        main window).  
          o  Run the IBM Java configuration GUI (TCPCFG2):
               This corresponds to the default OS/2 TCP/IP configuration GUI 
               (which is assumed to be run with the command "TCPCFG2").  This 
               option requires you to have at least TCP/IP version 4.1 on your
               system.
          o  Run a another configuration program:
               This lets you specify a different configuration program.  There
               are a couple of third-party programs available which you may
               prefer to use.  Also, if you have a Warp 4 or Warp 3 system 
               without TCP/IP 4.1 (or higher) installed, you can use this 
               option to run the legacy configuration GUI by entering 
             "TCPCFG.EXE" as the configuration program name.

   - Quick Editor
        This lets you specify the text editor to use when manually editing
        a profile's individual configuration files using the "Edit" button
        on the View Profile dialog.  The default is the system editor (E.EXE).


HISTORY

  1.0 (2010-10-27)
   - Initial release


LICENSE

  Copyright (C) 2010 Alex Taylor.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.

  3. The name of the author may not be used to endorse or promote products
     derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY EXPRESS OR
  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
  STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
  ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.


--
Alex Taylor - alex at altsan dot org  (<-- almost-usable address)
http://users.socis.ca/~ataylo00/
