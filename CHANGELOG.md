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