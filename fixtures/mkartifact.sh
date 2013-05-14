VERSION=$1
: ${VERSION:="1.2.3"}
tar cvfz artifact_test-$VERSION.tgz artifact_test_app

# nexus-cli push_artifact artifact_cookbook:test:$VERSION:tgz artifact_test-$VERSION.tgz

mv artifact_test_app/lib/bar.rb artifact_test_app/lib/foo.rb 
tar cvfz artifact_test_force-$VERSION.tgz artifact_test_app
mv artifact_test_app/lib/foo.rb artifact_test_app/lib/bar.rb 
