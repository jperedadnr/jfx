#!/bin/bash -xe

# set variables
VERSION=$1

# unlock gluon custom keychain
security -v unlock-keychain -p jenkins /Users/m1/gluon-custom.keychain
security -v list-keychains -d system -s /Users/m1/gluon-custom.keychain
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

# sign dylib files inside jmods
cd build/artifacts/bundles
unzip javafx-jmods-${VERSION}.zip
cd javafx-jmods-${VERSION}
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
zip -ur javafx-jmods-${VERSION}.zip javafx-jmods-${VERSION}
cd ../../../
