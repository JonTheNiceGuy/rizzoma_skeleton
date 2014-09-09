Rizzoma Skeleton
================

This set of scripts builds on the [Rizzoma Collaboration Platform](https://github.com/rizzoma/rizzoma) to help those of us that want to hack on it, do so. The actual application is pulled from the Rizzoma main tree, and this just gives you enough setup to get running.

##Getting started

###Requirements

* [Vagrant](http://vagrantup.com) - note, download the latest version from the [download page](http://www.vagrantup.com/downloads.html) on their site, don't just use your Distro's package, as they are likely to be very out-dated.
* [Virtualbox](https://www.virtualbox.org/)
* git

####Run

    git clone https://github.com/JonTheNiceGuy/rizzoma_skeleton.git
    git submodule update --init
    cd Vagrant
    vagrant up

###What does this do

When you perform the git clone, you check out a small number of files which allow you to boot a virtual machine with all the software pre-configured for Rizzoma to run. You boot your virtual machine using the Vagrant command shown above.

Vagrant is a way of provisioning virtual machines using configuration files rather than shipping ISO files around (although, ultimately, this will download a virtual machine image to use). After the virtual machine is booted, there are a set of scripts (called Puppet manifests) that install all the required software and configure the virtual machine for you.

At the end of this process, you'll have a running Ubuntu 14.04 32bit machine with Rizzoma (running at http://rizzoma.lan - unless you change the Vagrantfile "config.vm.hostname" entry - assuming your DHCP works and updates your DNS!) and a simple SMTP catcher (called "Mailcatcher" running at http://rizzoma.lan:1080) that will catch all emails sent from rizzoma, so you can login to your Rizzoma service, without needing to configure your e-mail services.

###What to do next?

####Just play with Rizzoma

If you want to just play around with Rizzoma, you're all done - head over to the URLs mentioned before, or failing that, whatever IP address your DHCP server has allocated your Rizzoma VM, and have a play.

####Take a look at the Virtual Machine

Go into the Vagrant directory of this repo, and (once you've done vagrant up, as above), type `vagrant ssh` - this will bring you into the virtual machine as a user.

####Make code changes

Either edit in the Application folder outside of the virtual machine (ideal for CSS changes) or to edit the node.js code, enter the virtual machine (see the section above) and then go into /all_code/Application (which is one of the places where the Rizzoma application lives) to make pull requests (just be sure you add a git remote to that tree) and restart Rizzoma by running `sudo restart rizzoma` (it won't ask for a password). The puppet provisioning scripts will update the Rizzoma application to the git master HEAD, so if you want to go to any other point in the tree, you'll need to `git checkout` to the appropriate place in the tree - or even your own branch.

####Shut it down

Once you're finished with the Vagrant machine, either inside the VM, type `sudo shutdown -h now` or outside it, ensure you're in the Vagrant directory, and type `vagrant halt`. If you're really done, or just want to start over, type `vagrant destroy` to entirely remove the virtual machine - bringing the virtual machine back up won't make too many network requests, or download too much traffic, as it keeps the Virtual machine's "base image", you'll just need to download any packages that have been updated since the base release.
