#!/bin/bash

# wait for the instruqt profile
# to be properly initialised.
echo ">>> Waiting for instrqut profile..."
while [ ! -f /home/user/.mozilla/firefox-esr/virtualbrowser.instruqt/times.json ] ;
do
  sleep 1;
done

###############################################################################
###############################################################################
# Chronosphere modification
###############################################################################
###############################################################################
DEFAULT_LOAD=0
DEFAULT_USER="No username found"

# To enable autoLogin extension
#   This allows tenant user/password to be passed as ENV variable
echo ">>> [c10e] Checking AUTOLOGIN"
if [[ ${AUTOLOGIN:-$DEFAULT_LOAD} -eq 1 ]]; then
  MY_EMAIL=${AUTOLOGIN_EMAIL:-$DEFAULT_USER}
  MY_PASSWORD=${AUTOLOGIN_PASSWORD:-$DEFAULT_USER}
  sed -i "s/{{AUTOLOGIN_EMAIL}}/${MY_EMAIL}/g" /c10e/c10e-autoLogin/autoLogin.js
  sed -i "s/{{AUTOLOGIN_PASSWORD}}/${MY_PASSWORD}/g" /c10e/c10e-autoLogin/autoLogin.js
  
  echo ">>> [c10e] AUTOLOGIN zipping"
  cd /c10e/c10e-autoLogin
  zip -r ../c10e-autoLogin@chronosphere.io.xpi ./*
  cd -

  echo ">>> [c10e] AUTOLOGIN adding to policies"
  jq --argjson ext "$(cat /c10e/c10e-autoLogin.json)" '.policies.ExtensionSettings += $ext' /usr/lib/firefox-esr/distribution/policies.json > ~/tmp-policies1.json && cat ~/tmp-policies1.json > /usr/lib/firefox-esr/distribution/policies.json
fi

# To enable removeNavMenuAdmin extension
echo ">>> [c10e] Checking REMOVEADMINMENU"
if [[ ${REMOVEADMINMENU:-$DEFAULT_LOAD} -eq 1 ]]; then

  echo ">>> [c10e] REMOVEADMINMENU zipping"
  cd /c10e/c10e-removeNavMenuAdmin
  zip -r ../c10e-removeNavMenuAdmin@chronosphere.io.xpi ./*
  cd -

  echo ">>> [c10e] REMOVEADMINMENU adding to policies"
  jq --argjson ext "$(cat /c10e/c10e-removeNavMenuAdmin.json)" '.policies.ExtensionSettings += $ext' /usr/lib/firefox-esr/distribution/policies.json > ~/tmp-policies2.json && cat ~/tmp-policies2.json > /usr/lib/firefox-esr/distribution/policies.json
fi

###############################################################################
###############################################################################

# kill the vncconfig windows that
# shows up for no reason.
pkill vncconfig

echo ">>> Setting up user prefs..."

# copy over firefox user preferences.
cp /firefox/user.js /home/user/.mozilla/firefox-esr/virtualbrowser.instruqt

# set the homepage url to the specified url value.
echo "user_pref('browser.startup.homepage', '${url:=}');" >> /home/user/.mozilla/firefox-esr/virtualbrowser.instruqt/user.js

# create folder to manage firefox css if not exists.
mkdir -p /home/user/.mozilla/firefox-esr/virtualbrowser.instruqt/chrome

# copy over firefox configuration styling.
cp /firefox/chrome/userChrome.css /home/user/.mozilla/firefox-esr/virtualbrowser.instruqt/chrome/

if [ -n "$username" ] && [ -n "$password" ]; then
  # copy over firefox configuration files
  # for login management.
  cp /firefox/logins.json /home/user/.mozilla/firefox-esr/virtualbrowser.instruqt
  cp /firefox/key4.db /home/user/.mozilla/firefox-esr/virtualbrowser.instruqt

  cat > /home/user/.mozilla/pwd.csv << EOF
url,username,password
"$url","$username","$password"
EOF

  # insert passwords into firefox browsers
  # password manager.
  ffpass import -f /home/user/.mozilla/pwd.csv -d /home/user/.mozilla/firefox-esr/virtualbrowser.instruqt

  # remove file after secrets imported.
  rm -f /home/user/.mozilla/pwd.csv
fi

count=0
# wait for the url to be accessible.
echo ">>> Checking $url is available..."
while ! wget --spider --quiet "$url"
do
  count=$((count + 1))
  if [ $count -ge 10 ]; then
    echo "10 seconds passed, $url is still not available."
    break
  fi
  echo "Waiting for $url to become available... ($count seconds passed)"
  sleep 1;
done

# open firefox using instruqt profile.
echo ">>> Open firefox using instruqt profile"
firefox-esr -P instruqt -url "$url"