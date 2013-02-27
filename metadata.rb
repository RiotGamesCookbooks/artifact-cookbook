name             "artifact"
maintainer       "Riot Games"
maintainer_email "kallan@riotgames.com"
license          "Apache 2.0"
description      "Provides your cookbooks with the Artifact Deploy LWRP"
version          "1.3.1"

%w{ centos redhat fedora windows }.each do |os|
  supports os
end

depends "windows", "~> 1.8.0"