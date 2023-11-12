import json
import re
import click

def read_file(file_name:str) -> str:
    res = ""
    with open(file_name, "r", encoding="UTF-8") as f:
        res = f.read()
    return res

def str_to_json(s:str):
    return json.loads(s)

def get_script_from_json(jsn) -> str:
    res = ""
    for i in jsn["cells"]:
        if i["cell_type"] == 'code':
            for j in i["source"]:
                cleaned_line = ' '.join(j.split())
                cleaned_line = cleaned_line.split('--')[0]
                res += " " + cleaned_line
    return res

def get_drop_table_from_script(script:str) -> str:
    create_table_pattern = r'CREATE TABLE (\w+)'
    
    match = re.findall(create_table_pattern, script)
    match.reverse()
    queries = []

    for table_name in match:
        query = f"DROP TABLE {table_name}\n"
        queries.append(query)

    result = ''.join(queries)
    return result

def get_dict_data(code: str) -> str:
    res = {}
    a = code.split(";")
    
    a = [i[13::] if i.count("CREATE TABLE") else "" for i in a]
    d = {i[:i.find(" "):]:i[i.find(" ")+2:-1:] for i in a}
    for i in d:
        d[i] = re.split(r',(?![^()]*\))', d[i])
        res[i] = []
        for j in d[i]:
            l = j.split(' ')
            if l.count("")>0:
                l.remove("")
            if (j == "") or l[0] == "FOREIGN" or (l[0] == '' and len(l) == 1):
                continue
            res[i].append(l[:2])
    for i in res.keys():
        print(i)
        for j in res[i]:
            print(j[0], end="\n")
        print()
    for i in res.keys():
        print()
        for j in res[i]:
            print(j[1], end="\n")
        print()
    return res

def get_create_table_code(code:str) -> str:
    print("\n")
    pattern = re.compile(r'CREATE TABLE.*?;')
    matches = pattern.findall(code)
    res = ""
    for match in matches:
        res += match + "\n"
    return res

def get_insert_code(code:str) -> str:
    print("\n")
    pattern = re.compile(r'INSERT INTO.*?;')
    matches = pattern.findall(code)
    res = ""
    for match in matches:
        res += match + "\n"
    return res


@click.command()
@click.option('-m', '--main', is_flag=True, help='выводит весь код в консоль одной строкой')
@click.option('-d', '--drop', is_flag=True, help='выводит код удаление таблиц в консоль')
@click.option('-c', '--create', is_flag=True, help='выводит код создания таблиц в консоль')
@click.option('-i', '--insert', is_flag=True, help='выводит код вставки в таблицы в консоль')
@click.option('--create-file-bd', is_flag=True, help="создает файл с кодом для создания базы данных")
def main(main, drop, create, insert, dict, create_file):
    source = read_file("script.ipynb")    
    jsn = str_to_json(source)
    main_code = get_script_from_json(jsn)
    drop_script = get_drop_table_from_script(main_code)
    if main:
        print(main_code)
    if drop:
        print(drop_script)
    if create:
        s = get_create_table_code(main_code)
        print(s)
    if insert:
        s = get_insert_code(main_code)
        print(s)
    if dict:
        dict_data: dict = get_dict_data(main_code)
    if create_file:
        with open("CREATE_DATABASE.sql", 'w', encoding="UTF-8") as file:
            file.write("-- table\n")
            file.write(get_create_table_code(main_code))
            file.write("-- insert\n")
            file.write(get_insert_code(main_code))




    

if __name__ == '__main__':
    main()