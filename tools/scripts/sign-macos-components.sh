#!/bin/bash -xe

#
# this script takes care of signing the required macOS components, which include:
#  - the dylib files inside the maven publication artifacts
#  - the dylib and jar files inside the SDK zip distribution
#  - the dylib files inside the jmods zip distribution
#
# environment variables used:
#  - KEYCHAIN: the full location to the keychain file that contains the credentials for signing
#  - KEYCHAIN_PASSWORD: the password to unlock the provided keychain
#  - MAJOR_VERSION: the major version of OpenJFX that is being signed
#  - JAVA_HOME: the directory that points to the home folder of a JDK installation
#

# setup keychain
security -v unlock-keychain -p $KEYCHAIN_PASSWORD $KEYCHAIN
security -v set-key-partition-list -S apple-tool:,apple: -k $KEYCHAIN_PASSWORD $KEYCHAIN
security -v list-keychains -d user -s $KEYCHAIN login.keychain
security -v find-identity

# sign dylib files inside maven publication jars
cd build/publications
for jar in `ls javafx.graphics-mac.jar javafx.media-mac.jar javafx.web-mac.jar`; do
  unzip $jar '*.dylib'
  for lib in `ls *.dylib`; do
    codesign -f --deep --options runtime -s "Developer ID Application: Gluon Software BVBA (S7ZR395D8U)" --prefix org.openjfx. -vvvv "$lib"
    $JAVA_HOME/bin/jar uvf $jar $lib
    rm -rf $lib
  done
done
cd ../../

# sign jars and dylib files inside sdk
cd build/artifacts/bundles
unzip javafx-sdk-${MAJOR_VERSION}.zip
cd javafx-sdk-${MAJOR_VERSION}
for jar in `find . -name "*.jar"`; do
  echo $jar
  codesign -f --deep --options runtime -s "Developer ID Application: Gluon Software BVBA (S7ZR395D8U)" --prefix org.openjfx. -vvvv "$jar"
done
for dylib in `find . -name "*.dylib"`; do
  echo $dylib
  codesign -f --deep --options runtime -s "Developer ID Application: Gluon Software BVBA (S7ZR395D8U)" --prefix org.openjfx. -vvvv "$dylib"
done
cd ..
zip -ur javafx-sdk-${MAJOR_VERSION}.zip javafx-sdk-${MAJOR_VERSION}
cd ../../../

# sign dylib files inside jmods
cd build/artifacts/bundles
unzip javafx-jmods-${MAJOR_VERSION}.zip
cd javafx-jmods-${MAJOR_VERSION}
for jmod in `ls javafx.graphics.jmod javafx.media.jmod javafx.web.jmod`; do
  mkdir ${jmod%%.jmod}
  cd ${jmod%%.jmod}
  ${JAVA_HOME}/bin/jmod extract ../$jmod
  rm ../$jmod
  codesign -f --deep --options runtime -s "Developer ID Application: Gluon Software BVBA (S7ZR395D8U)" --prefix org.openjfx. -vvvv lib/*.dylib
  ${JAVA_HOME}/bin/jmod create --class-path classes --legal-notices legal --libs lib ../$jmod
  cd ..
  rm -rf ${jmod%%.jmod}
done
cd ..
zip -ur javafx-jmods-${MAJOR_VERSION}.zip javafx-jmods-${MAJOR_VERSION}
cd ../../../
