import re
import json

ALGO = "SHA512_256"
ALGO_LOWER = ALGO.lower()

def parse_to_json_array(data):
    # Split the data into blocks based on blank lines
    blocks = data.strip().split('\n\n')
    result = []

    for block in blocks:
        obj = {}
        # Find all occurrences of Key = Value
        matches = re.findall(r'(\w+)\s*=\s*(\w+)', block)
        for key, value in matches:
            # Convert Len to an integer, keep others as strings
            if key == "Len":
                obj[key] = int(value)
            else:
                obj[key] = value
        
        if obj:
            result.append(obj)
    return result

def parse_monte_data(text):
    # 1. Extract the Seed (assuming it appears only once)
    seed_match = re.search(r'Seed\s*=\s*(\w+)', text)
    seed_value = seed_match.group(1) if seed_match else None

    # 2. Extract all COUNT and MD pairs
    # This regex looks for COUNT and MD blocks following each other
    data_entries = []
    blocks = re.findall(r'COUNT\s*=\s*(\d+)\s*MD\s*=\s*(\w+)', text)
    
    for count, md in blocks:
        data_entries.append({
            "COUNT": int(count),
            "MD": md
        })

    # 3. Construct final structure
    result = {
        "seed": seed_value,
        "data": data_entries
    }
    
    return json.dumps(result, indent=4)

with open(f'test_vectors/{ALGO_LOWER}/{ALGO}ShortMsg.rsp', 'r') as file:
    raw_data = file.read()
    short_data = parse_to_json_array(raw_data)
with open(f'test_vectors/{ALGO_LOWER}/{ALGO}LongMsg.rsp', 'r') as file:
    raw_data = file.read()
    long_data = parse_to_json_array(raw_data)

data = short_data + long_data
json_output = json.dumps(data, indent=4)

with open(f'test_vectors/{ALGO_LOWER}/{ALGO_LOWER}.json', 'w') as json_file:
    json_file.write(json_output)

with open(f'test_vectors/{ALGO_LOWER}/{ALGO}Monte.rsp', 'r') as file:
    monte_raw_data = file.read()
    monte_json_output = parse_monte_data(monte_raw_data)
with open(f'test_vectors/{ALGO_LOWER}/{ALGO_LOWER}_monte.json', 'w') as json_file:
    json_file.write(monte_json_output)