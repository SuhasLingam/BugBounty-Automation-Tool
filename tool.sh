#!/bin/bash	
url=$1
if [ ! -d "Info-Gather" ];then
	mkdir Info-Gather
fi
if [ ! -d "Info-Gather/recon" ];then
	mkdir Info-Gather/recon
fi
if [ ! -d 'Info-Gather/recon/eyewitness' ];then
    mkdir Info-Gather/recon/eyewitness
fi
if [ ! -d "Info-Gather/recon/scans" ];then
	mkdir Info-Gather/recon/scans
fi
if [ ! -d "Info-Gather/recon/httprobe" ];then
	mkdir Info-Gather/recon/httprobe
fi
if [ ! -d "Info-Gather/recon/potential_takeovers" ];then
	mkdir Info-Gather/recon/potential_takeovers
fi
if [ ! -d "Info-Gather/recon/wayback" ];then
	mkdir Info-Gather/recon/wayback
fi
if [ ! -d "Info-Gather/recon/wayback/params" ];then
	mkdir Info-Gather/recon/wayback/params
fi
if [ ! -d "Info-Gather/recon/wayback/extensions" ];then
	mkdir Info-Gather/recon/wayback/extensions
fi
if [ ! -f "Info-Gather/recon/httprobe/alive.txt" ];then
	touch Info-Gather/recon/httprobe/alive.txt
fi
if [ ! -f "Info-Gather/recon/final.txt" ];then
	touch Info-Gather/recon/final.txt
fi
 
echo "[+] Harvesting subdomains with assetfinder..."
assetfinder $url >> Info-Gather/recon/assets.txt
cat Info-Gather/recon/assets.txt | grep $1 >> Info-Gather/recon/final.txt
rm Info-Gather/recon/assets.txt
 
echo "[+] Double checking for subdomains with amass..."
amass enum -d Info-Gather >> Info-Gather/recon/f.txt
sort -u Info-Gather/recon/f.txt >> Info-Gather/recon/final.txt
rm Info-Gather/recon/f.txt
 
echo "[+] Probing for alive domains..."
cat Info-Gather/recon/final.txt | sort -u | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ':443' >> Info-Gather/recon/httprobe/a.txt
sort -u Info-Gather/recon/httprobe/a.txt > Info-Gather/recon/httprobe/alive.txt
rm Info-Gather/recon/httprobe/a.txt
 
echo "[+] Checking for possible subdomain takeover..."
 
if [ ! -f "Info-Gather/recon/potential_takeovers/potential_takeovers.txt" ];then
	touch Info-Gather/recon/potential_takeovers/potential_takeovers.txt
fi
 
subjack -w Info-Gather/recon/final.txt -t 100 -timeout 30 -ssl -c ~/go/src/github.com/haccer/subjack/fingerprints.json -v 3 -o Info-Gather/recon/potential_takeovers/potential_takeovers.txt
 
echo "[+] Scanning for open ports..."
nmap -iL Info-Gather/recon/httprobe/alive.txt -T4 -oA Info-Gather/recon/scans/scanned.txt
 
echo "[+] Scraping wayback data..."
cat Info-Gather/recon/final.txt | waybackurls >> Info-Gather/recon/wayback/wayback_output.txt
sort -u Info-Gather/recon/wayback/wayback_output.txt
 
echo "[+] Pulling and compiling all possible params found in wayback data..."
cat Info-Gather/recon/wayback/wayback_output.txt | grep '?*=' | cut -d '=' -f 1 | sort -u >> Info-Gather/recon/wayback/params/wayback_params.txt
for line in $(cat Info-Gather/recon/wayback/params/wayback_params.txt);do echo $line'=';done
 
echo "[+] Pulling and compiling js/php/aspx/jsp/json files from wayback output..."
for line in $(cat Info-Gather/recon/wayback/wayback_output.txt);do
	ext="${line##*.}"
	if [[ "$ext" == "js" ]]; then
		echo $line >> Info-Gather/recon/wayback/extensions/js1.txt
		sort -u Info-Gather/recon/wayback/extensions/js1.txt >> Info-Gather/recon/wayback/extensions/js.txt
	fi
	if [[ "$ext" == "html" ]];then
		echo $line >> Info-Gather/recon/wayback/extensions/jsp1.txt
		sort -u Info-Gather/recon/wayback/extensions/jsp1.txt >> Info-Gather/recon/wayback/extensions/jsp.txt
	fi
	if [[ "$ext" == "json" ]];then
		echo $line >> Info-Gather/recon/wayback/extensions/json1.txt
		sort -u Info-Gather/recon/wayback/extensions/json1.txt >> Info-Gather/recon/wayback/extensions/json.txt
	fi
	if [[ "$ext" == "php" ]];then
		echo $line >> Info-Gather/recon/wayback/extensions/php1.txt
		sort -u Info-Gather/recon/wayback/extensions/php1.txt >> Info-Gather/recon/wayback/extensions/php.txt
	fi
	if [[ "$ext" == "aspx" ]];then
		echo $line >> Info-Gather/recon/wayback/extensions/aspx1.txt
		sort -u Info-Gather/recon/wayback/extensions/aspx1.txt >> Info-Gather/recon/wayback/extensions/aspx.txt
	fi
done
 
rm Info-Gather/recon/wayback/extensions/js1.txt
rm Info-Gather/recon/wayback/extensions/jsp1.txt
rm Info-Gather/recon/wayback/extensions/json1.txt
rm Info-Gather/recon/wayback/extensions/php1.txt
rm Info-Gather/recon/wayback/extensions/aspx1.txt

echo "[+] Running eyewitness against all compiled domains..."
python3 EyeWitness/EyeWitness.py --web -f Info-Gather/recon/httprobe/alive.txt -d Info-Gather/recon/eyewitness --resolve
