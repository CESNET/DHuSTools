
echo Step 1: get products list
# This gets images intersecting with a single point (49.8139,15.6617)
# It starts from sensing date 2018-09-01
# Server side supports paging, in fact 100 products is the most it will give
# hence start=0 (0th page) and rows=100 (100 products at once) 
curl -sS -n 'https://dhr1.cesnet.cz/search?q=footprint:%22Intersects(49.8139,15.6617)%22%20AND%20platformname:Sentinel-2%20AND%20producttype:S2MSI2Ap%20AND%20beginPosition:%5b2018-09-20T00:00:00.000Z%20TO%20NOW%5d&start=0&rows=100' > step1.$$.xml

echo Step 2: read product IDs
# Now we need to iterate throught the resulting xml. There are many optins.
# Let's go with the simplest
grep -Eo '<id>[a-z0-9\-]*</id>' step1.$$.xml | sed 's/<id>\(.*\)<\/id>/\1/' > step2.$$.csv

printf "Step 3: download products "
# Download all products (ZIP files) into a new directory
mkdir step3.$$
cd step3.$$
cat ../step2.$$.csv | while read id
do
	printf "."
	curl -sSJOn "https://dhr1.cesnet.cz/odata/v1/Products('${id}')/\$value"
done
cd ..
printf "\n"

printf "Step 4: extract images "
# Extract the best resolution optical image from each archive
mkdir step4.$$
for product in step3.$$/*.zip
do
	printf "."
	TCI=`unzip -Z1 "${product}" | grep TCI_10m`
	unzip -jqq "${product}" "${TCI}" -d step4.$$
done
printf "\n"

printf "Step 5: Crop and convert images "
# Extract the best resolution optical image from each archive
# The first pair of coords (521x714) is the SIZE of the outcropping
# The second pair is the top left corner of the outcropping
mkdir step5.$$
for image in step4.$$/*.jp2
do
	printf "."
	BN=`basename -s .jp2 $image`
	convert -crop 521x714+4431+7701 ${image} step5.$$/${BN}.png
done
printf "\n\nDone. Artifacts kept in step[1-5].$$\nYour `ls step5.$$ | wc -l` images are in step5.$$\n\n"

