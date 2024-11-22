import os
import re
import sys
import random

debug = False
path = ""
blocked_variables_file = ""
blocked_variables_enabled = False
instrument_loc = 1

loc_list = ['0xfffffffffffffff0','0xffffffffffffff0f','0xfffffffffffff0ff','0xffffffffffff0fff','0xfffffffffff0ffff','0xffffffffff0fffff','0xfffffffff0ffffff',\
    '0xffffffff0fffffff','0xfffffff0ffffffff','0xffffff0fffffffff','0xfffff0ffffffffff','0xffff0fffffffffff','0xfff0ffffffffffff','0xff0fffffffffffff',\
    '0xf0ffffffffffffff','0x0fffffffffffffff']

# Regex search: return the content
def search_content(regex, string):
    match = re.findall(regex, string, re.M)
    if len(match) > 0:
        return match
    return None

# Regex search: return the index
def search_index(regex, string):
    match = re.finditer(regex, string, re.M)
    return match

# Read file and filter out the lines according to the list
def filter_file(file_name, filter_list):
    with open(file_name, 'r', encoding="utf-8") as f:
        for line in f.readlines():
            linestr = line.strip()
            if linestr in filter_list:
                if debug:
                    print("-----------variable filting------")
                    print(linestr + " is removed.")
                filter_list.remove(linestr)
    return filter_list
    
def reduce_enum(enum_list, enum_len=15):
    enums = set()
    for root, dirs, files in os.walk(path):
        for file in files:
            if file.endswith(('.cpp', '.c', '.cc', '.h', '.hh', '.h.in')):
                with open(os.path.join(root, file), 'r+', encoding="utf-8", errors='ignore') as f:
                    content = f.read()
                    enum_index = 0
                    for name in enum_list:
                        result = search_index("^(?: |\t)*?(?:\w+\.|\w+->)*?" + name+" ?= ?\w+?;", content)
                        for it in result:
                            enums.add(name)
                    
    enum_list = list(enums)
    while True:
        tmp_list = list(enum_list)
        for enum in tmp_list:
            if len(enum_list) <= enum_len:
                return enum_list
            if random.randint(1, len(enum_list)) > enum_len:
                enum_list.remove(enum)
    
# Parse the enum definition string and return the enum type and the enum variable
def parse_enum(enum_string):
    enum_type = None
    enum_var = None

    enum_string = enum_string.replace('\n', '')
    enum_string = enum_string.replace('\t', '')

    # Check the after-bracket variable name
    enum_temp = enum_string.split('}')
    after_bracket = enum_temp[-1]
    after_bracket = after_bracket.replace(' ', '')
    after_bracket = after_bracket.replace(';', '')
    after_bracket = after_bracket.replace('*', '')
    enum_var = after_bracket.split('=')[0]
    
    # Check the before-bracket type name
    enum_temp = enum_string.split('{')
    before_bracket = enum_temp[0]
    before_bracket_list = before_bracket.split(' ')
    for item in reversed(before_bracket_list):
        if item != '' and not item.startswith('enum'):
            enum_type = item

    # Check the typedef
    if before_bracket_list[0].startswith('typedef'):
        enum_type = enum_var
        enum_var = None
    
    if enum_type == '':
        enum_type = None
    if enum_var == '':
        enum_var = None

    return enum_type, enum_var

# Parse the enum usage string
def parse_variable(variable_string):
    variable_string =variable_string.split(' ', 1)
    return variable_string[0], variable_string[-1].replace(' ', '').replace(';', '').replace('=', '')

def out_state_BBname(BBname):
    f = open('state_BBnames.txt', 'a+')
    f.write(BBname + '\n')
    f.close()


# package the instrument code into the file
def package_content(content, result, file, root, enum_index):
    global instrument_loc
    instrument_loc_start = instrument_loc
    last_index = 0
    new_content = ''
    for item in result:
        cur_range = item.span()
        variable_write_instruction = content[cur_range[0]:cur_range[1]]
        if debug:
            print("--------Instrument--------------")
            print(file)
            print(variable_write_instruction)
        enum_value = variable_write_instruction.split('=')[-1].strip()[:-1]
        new_content += content[last_index:cur_range[0]]
        new_content += '{__aflnet_go_instrument(' + str(enum_index) + ', ' + enum_value  + '+1, ' + loc_list[enum_index] + ');'
        new_content += content[cur_range[0]:cur_range[1]]
        new_content += '}'
        instrument_loc += 1
        last_index = cur_range[1]
    new_content += content[last_index:]
    if instrument_loc > instrument_loc_start:
        print(os.path.join(root, file) + " is instrumented" + " with " + str(instrument_loc - instrument_loc_start) + " locations")
        
        new_content = '#ifndef SFUZZ_INSTRUMENT\n#define SFUZZ_INSTRUMENT\n#ifdef __cplusplus\nextern "C" {\n#endif\n__attribute__((weak)) void __aflnet_go_instrument_call(unsigned long long enum_index, unsigned long long state_value, unsigned long long loc_flag, unsigned long long *state){*state = (*state&loc_flag)^((state_value&0xf)<<(enum_index*4));};\n__attribute__((weak)) void __aflnet_go_instrument(unsigned long long enum_index, unsigned long long state_value, unsigned long long loc_flag){};\n#ifdef __cplusplus\n}\n#endif /* __cplusplus */\n#endif /* SFUZZ_INSTRUMENT */\n' + new_content
        out_state_BBname(file + ':7')
    return new_content

# Step 1: get the enum definition
def lookfor_enum_definition():
    enum_definition = set()
    # filename, enum type, variable name
    enum_usage = []
    enum_variable_uniq = set()
    for root, dirs, files in os.walk(path):
        for file in files:
            if file.endswith(('.cpp', '.c', '.cc', '.h', '.hh', '.h.in')):
                with open(os.path.join(root, file), 'r', encoding="utf-8", errors='ignore') as f:
                    content = f.read()
                    result = search_content(r'(?s)(?:typedef)?\senum\s*?\w*\s*?{.*?}.*?;', content)
                    if result is not None:
                        for enum_string in result:
                            enum_type, enum_var = parse_enum(enum_string)
                            if debug:
                                print('---------Definition--------')
                                print(file)
                                print(enum_string)
                                print(enum_type)
                                print(enum_var)
                            if enum_type is not None and enum_type != 'bool' and enum_type != 'isc_boolean_t':
                                enum_definition.add(enum_type)
                            if enum_var is not None:
                                enum_usage.append((file, enum_type, enum_var))
                                enum_variable_uniq.add(enum_var)
    return enum_definition, enum_usage, enum_variable_uniq

# Step 2: get the enum usage
def lookfor_enum_usage(enum_definition, enum_usage, enum_variable_uniq):
    for root, dirs, files in os.walk(path):
        for file in files:
            if file.endswith(('.cpp', '.c', '.cc', '.h', '.hh', '.h.in')):
                with open(os.path.join(root, file), 'r', encoding="utf-8", errors='ignore') as f:
                    content = f.read()
                    for enum_type in enum_definition:
                        result = search_content(enum_type+" \w+ ?(?:;|=)", content)
                        if result is not None:
                            for enum_variable_string in result:
                                get_type, get_var = parse_variable(enum_variable_string)
                                if debug:
                                    print('-------Usage-------')
                                    print(file)
                                    print(enum_variable_string)
                                    print(get_type)
                                    print(get_var)
                                if get_var is not None:
                                    enum_usage.append((file, get_type, get_var))
                                    enum_variable_uniq.add(get_var)
    return enum_usage, enum_variable_uniq

# Step 3: instrument all enum usage
def instrument(enum_variable_uniq):
    enum_index = 0
    for root, dirs, files in os.walk(path):
        for file in files:
            if file.endswith(('.cpp', '.c', '.cc', '.h', '.hh', '.h.in')):
                with open(os.path.join(root, file), 'r+', encoding="utf-8", errors='ignore') as f:
                    content = f.read()
                    if not redundance_mode:
                        enum_index = 0
                    for name in enum_variable_uniq:
                        if enum_index >= 15:
                            break
                        result = search_index("^(?: |\t)*?(?:\w+\.|\w+->)*?" + name+" ?= ?\w+?;", content)
                        len_old = len(content)
                        content = package_content(content, result, file, root, enum_index)
                        if len(content) > len_old:
                            enum_index += 1
                    if not debug:
                        f.seek(0)
                        f.write(content)
                        f.truncate()
                      

if __name__ == '__main__':
    debug = False
    redundance_mode = False
    if debug:
        path = "/home/txf/SGFuzz-master/sanitizer/dcmtk_2"
        blocked_variables_file = "t.txt"
        blocked_variables_enabled = False
        instrument_loc = 23
    else:
        if len(sys.argv) > 1:
            path = sys.argv[1]
        else:
            print("Error: Please input the path of the source code.")
            print("Usage:")
            print("    python3 State_machine_instrument.py path [-b blocked_variable_file start_index]")
            exit(0)
        if len(sys.argv) > 3 and sys.argv[2] == '-b':
            blocked_variables_file = sys.argv[3]
            blocked_variables_enabled = True
        if len(sys.argv) > 4:
            instrument_loc = int(sys.argv[4])

    enum_definition, enum_usage, enum_variable_uniq = lookfor_enum_definition()
    enum_usage, enum_variable_uniq = lookfor_enum_usage(enum_definition, enum_usage, enum_variable_uniq)
    if blocked_variables_enabled:
        enum_variable_uniq = filter_file(blocked_variables_file, enum_variable_uniq)
    enum_variable_uniq = reduce_enum(enum_variable_uniq)
    instrument(enum_variable_uniq)
    if debug:
        print("--------------Final states----------------")
        print(enum_variable_uniq)
        print(len(enum_variable_uniq))
        for t in enum_variable_uniq:
            print(t)

