import os, json

here = r'c:\Users\Mohamed\Desktop\MDM3\ezoo-download-main\crates\app\lang'

# 1. Update ar_ui.py with missing translation
ar_path = os.path.join(here, 'ar_ui.py')
with open(ar_path, 'r', encoding='utf-8') as f:
    ar_content = f.read()

if 'High-speed multi-connection download manager for Windows.' not in ar_content:
    addition = '''AR = {
    "High-speed multi-connection download manager for Windows.": "برنامج عالي السرعة متعدد الاتصالات لإدارة التنزيلات لنظام ويندوز.",
    "Developed by Mohamed": "تطوير Mohamed",'''
    ar_content = ar_content.replace('AR = {', addition)
    with open(ar_path, 'w', encoding='utf-8') as f:
        f.write(ar_content)

# 2. Update ui/*.json
ui_dir = os.path.join(here, 'ui')
for fname in os.listdir(ui_dir):
    if fname.endswith('.json'):
        fpath = os.path.join(ui_dir, fname)
        with open(fpath, 'r', encoding='utf-8') as f:
            data = json.load(f)
        new_data = {}
        for k, v in data.items():
            k_new = k.replace('Ezoo Download', 'Mo Download Manager (MDM)').replace('EzooDownload.exe', 'MDM.exe')
            v_new = v.replace('Ezoo Download', 'Mo Download Manager (MDM)').replace('EzooDownload.exe', 'MDM.exe')
            new_data[k_new] = v_new
        new_data['Developed by Mohamed'] = 'Developed by Mohamed'
        new_data['High-speed multi-connection download manager for Windows.'] = 'High-speed multi-connection download manager for Windows.'
        with open(fpath, 'w', encoding='utf-8') as f:
            json.dump(new_data, f, ensure_ascii=False, indent=1)

# 3. Update rs/*.json
rs_dir = os.path.join(here, 'rs')
if os.path.exists(rs_dir):
    for fname in os.listdir(rs_dir):
        if fname.endswith('.json'):
            fpath = os.path.join(rs_dir, fname)
            with open(fpath, 'r', encoding='utf-8') as f:
                data = json.load(f)
            new_data = {}
            for k, v in data.items():
                k_new = k.replace('Ezoo Download', 'Mo Download Manager (MDM)').replace('EzooDownload.exe', 'MDM.exe')
                v_new = v.replace('Ezoo Download', 'Mo Download Manager (MDM)').replace('EzooDownload.exe', 'MDM.exe')
                new_data[k_new] = v_new
            with open(fpath, 'w', encoding='utf-8') as f:
                json.dump(new_data, f, ensure_ascii=False, indent=1)

print('Language files updated!')
