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


