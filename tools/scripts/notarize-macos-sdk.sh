#!/bin/bash -xe

#
# this script takes care of notarizing the macOS SDK zip distribution
#
# script arguments:
#  - the type of SDK that is being notarized: dynamic or dynamic-monocle
#
# environment variables used:
#  - KEYCHAIN: the full location to the keychain file that contains the credentials for signing
#  - KEYCHAIN_PASSWORD: the password to unlock the provided keychain
#  - NOTARIZATION_USERNAME: the username of the account being used for notarization
#  - NOTARIZATION_PASSWORD: the password associated with the account being used for notarization
#  - NOTARIZATION_ASC_PROVIDER: the provider of the account to use for notarization
#

SDK_TYPE=$1

# setup keychain
security -v unlock-keychain -p $KEYCHAIN_PASSWORD $KEYCHAIN
security -v set-key-partition-list -S apple-tool:,apple: -k $KEYCHAIN_PASSWORD $KEYCHAIN
security -v list-keychains -d user -s $KEYCHAIN login.keychain
security -v find-identity

SDK_NAME=`ls -1 artifacts/$SDK_TYPE/*-sdk.zip`
xcrun altool --notarize-app --primary-bundle-id "org.openjfx" --username "${NOTARIZATION_USERNAME}" --password "${NOTARIZATION_PASSWORD}" --asc-provider ${NOTARIZATION_ASC_PROVIDER} --file ${SDK_NAME} > xcrun-output.txt
XCRUN_EXITCODE=$?

if [[ ${XCRUN_EXITCODE} -eq 0 ]]; then
  XCRUN_UUID=`cat xcrun-output.txt | grep "^RequestUUID = " | cut -d= -f2 | sed "s/^ *//g"`
  XCRUN_STATUS="in progress"
  for i in {1..10}; do
    sleep 30
    xcrun altool --notarization-info ${XCRUN_UUID} --username "${NOTARIZATION_USERNAME}" --password "${NOTARIZATION_PASSWORD}" --asc-provider ${NOTARIZATION_ASC_PROVIDER} > xcrun-status.txt
    XCRUN_EXITCODE=$?
    if [[ ${XCRUN_EXITCODE} -eq 0 ]]; then
      XCRUN_STATUS=`cat xcrun-status.txt | grep "Status: " | cut -d: -f2 | sed "s/^ *//g"`
      if [[ ${XCRUN_STATUS} != "in progress" ]]; then
        if [[ ${XCRUN_STATUS} != "success" ]]; then
          cat xcrun-status.txt
          exit 1
        else
          break
        fi
      fi
    else
      cat xcrun-status.txt
      exit $XCRUN_EXITCODE
    fi
  done
else
  cat xcrun-output.txt
  exit $XCRUN_EXITCODE
fi
