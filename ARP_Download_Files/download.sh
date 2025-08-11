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

if [[ "$#" -eq 0 ]] || [[ "$1" == -h ]] || ([[ "$#" -eq 1 ]] && [[ "$1" == "-r" ]])
then
	echo "This is a script to download DeltaMut datasets' contents from the ARP data repository."
	echo "Usage: $0 [OPTION] [uniprot id / pattern]"
	echo "Options:"
	echo "  <uniprot id>    If no options given, the uniprot ID is searched for verbatim."
	echo "  -a              Download all datasets."
	echo "  -g              Download using glob pattern."
	echo "  -r              Download using regexp pattern (EXPERIMENTAL)."
	echo "  -h              This help."
	echo "Environment variables: API_TOKEN"
	exit 0
fi

case "$1" in
	"-a")
		Q='*' ;;
	"-g")
		GLOB="$2"
		echo "$GLOB"
		Q=`echo "$GLOB" | sed 's/\[[^]]\+\]/*/g ; s/\*\+/*/g'`
		echo "$Q" ;;
	"-r")
		REGEXP="$2"
		Q=`echo "$REGEXP" | sed 's/[.]\+/*/g; s/\[[^]\+]\]/*/g ; s/\*\+/*/g'`
		echo $Q
		exit ;;
	*)
		PROT=$1
		if echo $1 | grep -q '/'
		then
			Q="title:\"Alphafold+structure+of+mutation+type+$1+protein\""
		else
			Q="title:\"Alphafold+structure+of+wild+type+$1+protein\""
		fi
esac

SEARCHURL="https://repo.researchdata.hu/api/search?subtree=SBVEP&type=dataset&q=$Q&per_page=10&start="
if [[ "$API_TOKEN" ]]
then
	CURLTOKEN="-H X-Dataverse-key:$API_TOKEN"
	DMUTOKEN="--apiKey $API_TOKEN"
else
	CURLTOKEN=""
	DMUTOKEN=""
fi
echo curl "$CURLTOKEN" -s "$SEARCHURL"0
#curl "$CURLTOKEN" -s "$SEARCHURL"0

#curl -s $CURLTOKEN "$SEARCHURL"0
# | jq .data.total_count
COUNT=`curl -s $CURLTOKEN "$SEARCHURL"0 | jq .data.total_count`
echo "Starting to examine $COUNT datasets"
for ((start=0;start<COUNT;start+=10))
do
	curl -s $CURLTOKEN "$SEARCHURL"0 | jq '.data.items | .[] |(.name + " " + .global_id) '| sed 's/"Alphafold structure of [a-z]* type //;s/ protein//;s/"$//' \
	 | while read PROTEIN HANDLE
	do
		if [[ $GLOB ]] && [[ "$PROTEIN" != +($GLOB) ]]
		then
			continue
		fi
		DIR=`echo $PROTEIN| tr '/' '_'`
		mkdir $DIR
		cd $DIR
		python3 ../DataverseMassUploader/downloadDatasetFiles.py --dataverseBaseUrl "https://repo.researchdata.hu" $DMUTOKEN --dataset $HANDLE
		cd ..
	done
done
