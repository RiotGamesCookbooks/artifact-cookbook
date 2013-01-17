## v1.0.0:

Major Improvements
* Entirely new :deploy action flow. Please see the flowchart on the readme for a greater explanation.
* New :pre_seed action. This action will setup directories and download a the configured artifact.

Bug Fixes
* [#37] Remove the circular dependency on the nexus-cookbook.
* [#33] No longer default to not verifying SSL connections when using the nexus-cli gem.
* [#29] Better handling of various types of archives. Now supports tar, tgz, bz, and zips.