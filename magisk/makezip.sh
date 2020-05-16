#! /bin/sh

zipname="uperf-magisk.zip"

echo "Compile Uperf binary..."
cd ..
make clean 1> /dev/null
make ndkbuild 1> /dev/null

echo "Compile Uperf configs..."
cd config
python3 make_configs.py
cd ..

echo "Copy files from project..."
cp -r build/uperf magisk/uperf/
cp -r build/configs/ magisk/config

echo "Make flashable magisk package..."
cd magisk
rm "$zipname"
zip "$zipname" -q -9 -r . -x makezip.sh

echo "Cleanup..."
rm -r uperf
rm -r config

echo "Make zip done."
