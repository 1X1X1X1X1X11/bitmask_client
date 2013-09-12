REPOS_ROOT=$1
VERSION=$2
TEMPLATE_BUNDLE=$3
JOINT_CHANGELOG=$4
DEST=$5

# clean template

rm $TEMPLATE_BUNDLE/CHANGELOG.txt
rm $TEMPLATE_BUNDLE/relnotes.txt
rm -rf $TEMPLATE_BUNDLE/Bitmask.app/Contentes/MacOS/apps/leap
rm $TEMPLATE_BUNDLE/Bitmask.app/Contentes/MacOS/lib/leap/{common,keymanager,soledad,mail}

# checkout VERSION in all repos

for i in {leap_client,leap_pycommon,soledad,keymanager,leap_mail}
  do
    cd $REPOS_ROOT/$i
    git checkout $VERSION
  done

# make ui in client

cd $REPOS_ROOT/leap_client
make

# cp client

cp -r $REPOS_ROOT/leap_client/src/leap $TEMPLATE_BUNDLE/Bitmask.app/Contents/MacOS/apps/leap

# setup sdist client

cd $REPOS_ROOT/leap_client
python setup.py sdist

# extract $VERSION and copy _version.py to TEMPLATE_BUNDLE/Bitmask.app/Contents/MacOS/apps/leap/bitmask/_version.py

cd dist
rm -rf leap.bitmask-$VERSION
tar xzf leap.bitmask-$VERSION.tar.gz
cp leap.bitmask-$VERSION/src/leap/bitmask/_version.py $TEMPLATE_BUNDLE/Bitmask.app/Contents/MacOS/apps/leap/bitmask/_version.py
cp leap.bitmask-$VERSION/src/leap/bitmask/util/reqs.txt $TEMPLATE_BUNDLE/Bitmask.app/Contents/MacOS/apps/leap/bitmask/util/reqs.txt

# cp common, soledad(client and common), mail and keymanager in TEMPLATE_BUNDLE/Bitmask.app/Contents/MacOS/lib/leap/

LEAP_LIB=$TEMPLATE_BUNDLE/Bitmask.app/Contents/MacOS/lib/leap/

cp -r $REPOS_ROOT/leap_pycommon/src/leap/common $LEAP_LIB
cp -r $REPOS_ROOT/soledad/common/src/leap/soledad $LEAP_LIB
cp -r $REPOS_ROOT/soledad/client/src/leap/soledad/client $LEAP_LIB/soledad
cp -r $REPOS_ROOT/leap_mail/src/leap/mail $LEAP_LIB
cp -r $REPOS_ROOT/keymanager/src/leap/keymanager $LEAP_LIB

# cp leap_client launcher to TEMPLATE_BUNDLE/Bitmask.app/Contents/MacOS/Bitmask

BITMASK_BIN=$TEMPLATE_BUNDLE/Bitmask.app/Contents/MacOS/Bitmask

cd $REPOS_ROOT/leap_client_launcher/build/
make
cp src/launcher $BITMASK_BIN

# cp launcher.py to TEMPLATE_BUNDLE/Bitmask.app/Contents/MacOS/apps/

cd $REPOS_ROOT/leap_client_launcher/src/
cp launcher.py $TEMPLATE_BUNDLE/Bitmask.app/Contents/MacOS/apps/

# install_name_tool it

install_name_tool -change libboost_python.dylib lib/libboost_python.dylib $BITMASK_BIN
install_name_tool -change libboost_filesystem.dylib lib/libboost_filesystem.dylib $BITMASK_BIN
install_name_tool -change libboost_system.dylib lib/libboost_system.dylib $BITMASK_BIN

# cp relnotes to TEMPLATE_BUNDLE

cp $REPOS_ROOT/leap_client/relnotes.txt $TEMPLATE_BUNDLE

# cp joint_chglog to TEMPLATE_BUNDLE

cp $JOINT_CHANGELOG $TEMPLATE_BUNDLE/CHANGELOG.txt

# cp LICENSE to TEMPLATE_BUNDLE

cp $REPOS_ROOT/leap_client/LICENSE $TEMPLATE_BUNDLE/LICENSE.txt

# clean pyc$

cd $TEMPLATE_BUNDLE
for i in $(find . | grep pyc$);
  do
    rm $i
  done

# create dmg

TMP=/tmp/Bitmask
VOLUME_NAME=Bitmask
DMG_FILE=Bitmask-OSX-$VERSION.dmg

rm -rf $TMP
mkdir -p $TMP
cp -R $TEMPLATE_BUNDLE/* $TMP
cp $REPOS_ROOT/leap_assets/mac/bitmask.icns $TMP/.VolumeIcon.icns
SetFile -c icnC $TMP/.VolumeIcon.icns
hdiutil create -srcfolder $TMP -volname $VOLUME_NAME -format UDRW -ov $DEST/raw-$DMG_FILE

rm -rf $TMP
mkdir -p $TMP
hdiutil attach $DEST/raw-$DMG_FILE -mountpoint $TMP

SetFile -a C $TMP
hdiutil detach $TMP

rm -rf $TMP
rm -f $DEST/$DMG_FILE
hdiutil convert $DEST/raw-$DMG_FILE -format UDZO -o $DEST/$DMG_FILE
rm -f $DEST/raw-$DMG_FILE

# go back to develop in all repos
for i in {leap_client,leap_pycommon,soledad,keymanager,leap_mail}
  do
    cd $REPOS_ROOT/$i
    git checkout develop
  done
