VERSION=$1
: ${VERSION:="1.2.3"}
tar cvfz artifact_test-$VERSION.tgz artifact_test_app
nexus-cli push_artifact artifact_cookbook:test:$VERSION:tgz artifact_test-$VERSION.tgz
