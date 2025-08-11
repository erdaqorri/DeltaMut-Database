#!/bin/bash

for i in python3 git
do
	if ! $i --version > /dev/null
	then
		echo "Please install $i, and add it to the PATH."
		exit 1
	fi
done

if ! [[ -d DataverseMassUploader ]]
then
#	echo "Downloading DataverseMassUploader"
	git clone https://github.com/dsd-sztaki-hu/DataverseMassUploader.git
fi


## download datasets using private access URL
for URL
do
	if echo $URL | grep -q 'https://repo.researchdata.hu/privateurl.xhtml?token='
	then
		TOKEN=`echo $URL | sed 's/https:\/\/repo.researchdata.hu\/privateurl.xhtml?token=//'`
		DOWNLOAD_URL=`echo $URL | sed 's/privateurl.xhtml?token=/api\/datasets\/privateUrlDatasetVersion\//'`
	elif echo $URL | grep -q 'https://repo.researchdata.hu/api/datasets/privateUrlDatasetVersion/'
	then
		TOKEN=`echo $URL | sed 's/https:\/\/repo.researchdata.hu\/api\/datasets\/privateUrlDatasetVersion\///'`
		DOWNLOAD_URL=$URL
	elif echo $URL | egrep -q '^[0-9a-z-]{36}$'
	then
		TOKEN=$URL
		DOWNLOAD_URL="https://repo.researchdata.hu/api/datasets/privateUrlDatasetVersion/$TOKEN"
	else
		echo "ERROR: bad private URL/token: $URL"
		continue
	fi
	PROTEIN=`curl -s $DOWNLOAD_URL | jq '.data.metadataBlocks.citation.fields | .[] | select(.typeName == "title").value' | sed 's/.Alphafold structure of [a-z]* type //;s/ protein.$//;s/\//_/'`
	echo "Downloading dataset for $TOKEN, protein name $PROTEIN"
	mkdir -p $PROTEIN
	cd $PROTEIN
	python3 ../DataverseMassUploader/downloadDatasetFiles.py --dataverseBaseUrl "https://repo.researchdata.hu" --dataset $TOKEN
	cd ..
done
