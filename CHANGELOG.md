## v.1.11.3

* [#104](https://github.com/RiotGames/artifact-cookbook/pull/104) Allow ssl_verify to exist in the data bag and be honored

## v.1.11.2

* [#111](https://github.com/RiotGames/artifact-cookbook/pull/111) Fix a bug in artifact_file and installing the aws-sdk gem.

## v.1.11.1

* [#109](https://github.com/RiotGames/artifact-cookbook/pull/109) Artifact file should write a checksum file, similar to remote_file for idempotency.
* [#108](https://github.com/RiotGames/artifact-cookbook/pull/108) Allow other cookbooks to lock down the windows cookbook dependency.

## v.1.11.0

* [#107](https://github.com/RiotGames/artifact-cookbook/pull/107) Added a new Proc attribute after_download, which executes only after downloading an artifact.
* [#92](https://github.com/RiotGames/artifact-cookbook/pull/92) Remove some brittle logic for parsing artifact_location and use NexusCli::Artifact.

## v.1.10.3

* Kyle released the plugin with his Mac when tar was using bsdtar.

## v.1.10.2

* [#105](https://github.com/RiotGames/artifact-cookbook/pull/105) Fixed an edge case due to skip_manifest_check and actually writing the manifest file.
* [#101](https://github.com/RiotGames/artifact-cookbook/pull/101) Files downloaded from S3 should now be written using binary mode.
* [#103](https://github.com/RiotGames/artifact-cookbook/pull/103) When Chef runs fail, your password should not be exposed by the Chef::Artifact::NexusConfiguration object.

## v1.10.1

* [#98] Pass the environment around fix nil access

## v1.10.0

* [#90] Adds support for all regions to S3
* [#89] New syntax for cusomizable Nexus configurations - see README
* [#91] Changes to logging to be less verbose - run in DEBUG to see all the old messaging
* [#93] Add customizable Nexus configuration support to artifact_package resource
* [#94] Fix skip_manifest_check and failed deploy race condition
* [#95] Remove activesupport dependency, bringing the method internal

## v1.9.0

* [#85] Allows basic auth to be used for nexus artifact retrieval.

## v1.8.1

* [#86] Repackage to get around tar issues. No changes.

## v1.8.0

* [#84] Add artifact_package resource.

## v1.7.1

* [#80] Fixes support for S3 and Ubuntu. Thanks to @ephess.

## v1.7.0

* [#71] Added support for using S3 as an artifact deployment source.

## v1.6.0

* [#70] Added a new LWRP, artifact\_file which wraps remote_file with some retry logic for corrupt downloads. Also uses the configured Nexus server to check Nexus downloads.
* Use artifact\_file for downloading HTTP or Nexus artifacts in artifact\_deploy.
* [#28] Add a new attribute for deleting the currently deployed artifact when a force deploy is issued. Useful for local iteration on a changing artifact with the same version.
* [#60] Add retries to execute resources for tar extraction.
* [#66], [#67] Cache the Encrypted Data Bag Item for Nexus. Looks for an environment-named data bag item, then "\_wildcard", and finally "nexus" for backwards compatibility.
* Support RSpec testing of the Library files.
* [#65] Support Test-Kitchen

## v1.5.0

* Add a new attribute for skipping the manifest creation and checking for an artifact. Useful for large artifacts.

## v1.4.0

* Add Windows support.
* Add a new attribute for removing a top level directory from the extracted zip file.

## v1.3.1

* Fix a bug where Nokogiri was still used.

## v1.3.0

* Use a newer nexus_cli gem which removes the requirement of installed libxml and libxslt packages.

## v1.2.0

Bug Fixes
* [#50] Now actually SHA1 hashing the files themselves as opposed to hashing the String of the path to the file.
* [#52] Manifest generation now ignores symlinked files and directories.

## v1.1.2

Bug Fixes
* case statement for extract_artifact! was not matching '.tar.gz' files correctly.

## v1.1.1

Bug Fixes
* [#47] Regex was matching some special characters like '-'.

## v1.1.0:

Major Improvements
* New, simpler API for Chef::Artifact.get_actual_version.
* Added an ssl_verify attribute to the resource to help facilitate communications with Nexus servers that have invalid SSL certs.

Bug Fixes
* [#45] Add a better check to ensure we don't redownload artifacts we already have.
* [#42] Deleting previous versions now uses Chef resources and is hopefully a bit more clear.
* [#35] Throw an error if the resource's name attribute has whitespace.
* Symlinks are now created in the symlink_it_up! method using recipe_eval. This helps ensure a clearer picture of the flow during the Chef run.
* Better logging throughout.

## v1.0.0:

Major Improvements
* Entirely new :deploy action flow. Please see the flowchart on the readme for a greater explanation.
* New :pre_seed action. This action will setup directories and download a the configured artifact.

Bug Fixes
* [#37] Remove the circular dependency on the nexus-cookbook.
* [#33] No longer default to not verifying SSL connections when using the nexus-cli gem.
* [#29] Better handling of various types of archives. Now supports tar, tgz, bz, and zips.
