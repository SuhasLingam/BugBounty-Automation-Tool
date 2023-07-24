#!/bin/bash


url=$1

echo "[+] Finding SubDomains Using Assetfinder! ....."

if	[[ ! -d "Information-Gathering" ]]
then
	mkdir Information-Gathering
fi


if	[ ! -d "/recon" ]
then
	mkdir Information-Gathering/recon
fi

assetfinder -subs-only $url >> Information-Gathering/recon/asset-scan.txt

echo "[+] Done Finding SubDomains using Assetfinder"
sleep 1
echo "[+] Finding Unique Subdomains"
echo "[+] Saving"

cat Information-Gathering/recon/asset-scan.txt | sort -u >> Information-Gathering/recon/final.txt

rm -rf Information-Gathering/recon/asset-scan.txt

echo "[+] Finding SubDomains Using Amass! ....."

amass enum -d $url >> Information-Gathering/recon/f.txt
sort -u Information-Gathering/recon/f.txt >>  Information-Gathering/recon/final.txt

echo "[+] Done Finding SubDomains using Amass"
sleep 1
echo "[+] Finding Unique Subdomains"
echo "[+] Saving"


sleep 2


echo "[+] Finding Active Subdomains"
cat Information-Gathering/recon/final.txt | httpx-toolkit -mc 200 >> Information-Gathering/recon/url-200.txt


sed -E 's_^https?://__' Information-Gathering/recon/url-200.txt >> Information-Gathering/recon/final-urls.txt

rm -rf Information-Gathering/recon/url-200.txt 

echo "[+] Found Active Domains !"
echo "[+] Saving Active Subdomains to urls-200.txt"





