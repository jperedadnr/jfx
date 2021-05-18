#!/bin/bash -xe

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
