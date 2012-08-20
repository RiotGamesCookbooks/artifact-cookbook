name             "artifact"
maintainer       "Riot Games"
maintainer_email "jamie@vialstudios.com"
license          "Apache 2.0"
description      "Provides your cookbooks with the Artifact Deploy LWRP"
version          "0.10.3"

%w{ centos redhat fedora }.each do |os|
  supports os
end
