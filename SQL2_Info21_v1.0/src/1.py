import os
from re import search
address = os.path.dirname(__file__)
address_import = address + '/dataset_sql'
address_export = address_import + '/new'

with open ('part1.sql', 'r') as f:
    new_data = ""
    while True:
        old_data = f.readline()
        if old_data =="": break
        if search("declare adress_import varchar :=", old_data): 
            old_data = "declare adress_import varchar := '"+ address_import+"/';\n"
        if search("declare adress_export varchar :=", old_data): 
            old_data = "declare adress_export varchar := '"+ address_export+"/';\n"
        new_data = new_data +old_data
with open ('part1.sql', 'w') as f:
    f.write(new_data)