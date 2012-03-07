name             "artifact"
maintainer       "Riot Games"
maintainer_email "jamie@vialstudios.com"
license          "All rights reserved"
description      "Provides your cookbooks with the Artifact Deploy LWRP"
version          "0.9.1"

%w{ centos redhat fedora }.each do |os|
  supports os
end
