#!/bin/sh

curl -O https://files.pythonhosted.org/packages/44/66/2c17bae31c906613795711fc78045c285048168919ace2220daa372c7d72/pyaes-1.6.1.tar.gz
tar -xvf pyaes-1.6.1.tar.gz
cd pyaes-1.6.1 && zip ../pyaes.zip ./pyaes/* && cd ..
rm -rf pyaes-1.6.1.tar.gz ./pyaes-1.6.1
echo "Listing contents of pyaes.zip..."
zip -sf pyaes.zip