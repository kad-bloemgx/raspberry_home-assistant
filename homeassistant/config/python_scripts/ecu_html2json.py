import requests
from bs4 import BeautifulSoup
from datetime import datetime
import json
import os
import argparse
import re
import shutil
from pathlib import Path

def clean_value(value, replace_dict, is_temperature=False):
    for key, replacement in replace_dict.items():
        value = value.replace(key, replacement)
    cleaned_value = value.strip()
    if is_temperature:
        cleaned_value = re.sub(r'[^\d.]+', '', cleaned_value)  # Remove everything except digits and dot
    return '0' if cleaned_value in ['', '-', '�'] else cleaned_value

def get_html_content(file_path, url):
    if file_path and os.path.exists(file_path):
        with open(file_path, 'r') as f:
            html_content = f.read()
    else:
        r = requests.get(url)
        if r.status_code != 200:
            print('Error:', r.status_code)
            return None
        html_content = r.text
    return html_content

def parse_table(html_content):
    soup = BeautifulSoup(html_content, 'html.parser')
    table = soup.find('table')

    if table is None:
        print('No table found')
        return None

    rows = table.find_all('tr')
    power_data = {}

    latest_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    for row in rows[0:]:
        columns = row.find_all('td')
        if len(columns) == 2:
            omschrijving = columns[0].text.strip()
            power_data[omschrijving] = [clean_value(columns[1].text, {'kWh': '', 'W':'', 'kB': ''})]

    return power_data

def exist_file_power_data(file):

    filename = Path(file)

    if filename.exists():
        return True
    else:
        return False

def value_generation_of_current_day_greater_or_equal(power_data, file):
    """Controleer of de opgeslagen waarde groter of gelijk is dan de gemeten waarde"""

    x = power_data.get("Lifetime generation")
    #print(x)
    if exist_file_power_data(file):
        with open(file) as json_data:
            d = json.load(json_data)
        y = d['Lifetime generation']
        #print(y)
        if x >= y:
            return True
        else:
            return False
    else:
        return True

def save_power_data(power_data):
    with open('./www/power_data_ecu.json', 'w+') as outfile:
        json.dump(power_data, outfile, indent=5)
        outfile.close()
        shutil.copy("./www/power_data_ecu.json","./www/power_data_ecu_copy.json")

def main():
    parser = argparse.ArgumentParser(description='Process and collect solar data.')
    parser.add_argument('--file', type=str, help='Path to local HTML file')
    parser.add_argument('--url', type=str, help='URL to fetch the HTML content')
    parser.add_argument('--ecu_v4', action='store_true', help='Enable ECU v4 parsing mode')

    args = parser.parse_args()

    html_content = get_html_content(args.file, args.url)
    if html_content:
        power_data = parse_table(html_content)
        if power_data:
            if value_generation_of_current_day_greater_or_equal(power_data, './www/power_data_ecu.json'):
                save_power_data(power_data)
            else:
                print("fout")
                exit()

if __name__ == "__main__":
    main()
