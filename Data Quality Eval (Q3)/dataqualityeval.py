#Evaluate data quality issue

import json
import pandas as pd

#converting ndjson file to regular json

x=open("receipts.txt")
ndjson_content =x.read()

result = []

for ndjson_line in ndjson_content.splitlines():
    if not ndjson_line.strip():
        continue  # ignore empty lines
    json_line = json.loads(ndjson_line)
    result.append(json_line)
    
result = json.dumps(result)

with open('rresult.json', 'w') as fp:
    # json.dump(result, fp, indent=4)
    print(result, file=fp)
    
#normalize nested json for receipts data
#open json file
with open('rresult.json') as f:
    data= json.load(f)

# Unnest receiptitems column
data['result'] = [x for x in data['result'] if x.get('rewardsReceiptItemList')]

df = pd.json_normalize(data['result'], record_path=['rewardsReceiptItemList'],meta=['_id'], errors='ignore')

#check dataframe quality
df.info()

#Findings
'''After running the python code to arrive at the image attached, it is clear that there are several columns with null values in the "Receipt Items" Table. This may cause problems especially during SQL querying. The first SQL query asked for the top 5 brands by receipts scanned for the most recent month; The image below shows that brandCode has 2600 non-null, meaning over 4000 entries are null. This would skew the query results possibly leading to nulls being the top brand for the month. 

I tried tieing finding a connection to the "brand" table with a brand ID but that was not present in the "Receipt Items" Table. Barcode and brand Code column were not helpful in creating the connection as well. 

I strongly suggest to add a brand id to each item that is purchased within the receipt items so it can be tied back to the actual brand information. 
'''
