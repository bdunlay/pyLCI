#!/usr/bin/env python
import sys
from subprocess import Popen
from time import sleep

#Using I2C = apt-get python-smbus i2cdetect
##Using serial - python-serial
#Using pifacecad - pip pifacecad
#Using HID - python evdev
#Using GPIO - RPi.GPIO


#Translation of choices to apt-get and pip modules which need to be installed
#Choice names shouldn't be the same in different modules!
preassembled_modules ={
'pifacecad':{'apt-get':['python-pifacecad']},
'adafruit':{'apt-get':['python-smbus', 'i2c-tools']},
'chinafruit':{'apt-get':['python-smbus', 'i2c-tools']}
}

separate_modules ={
'serial':{'apt-get':['python-serial']},
'i2c':{'apt-get':['python-smbus', 'i2c-tools']},
'hid':{'apt-get':['python-dev'], 'pip':['evdev']},
'rpi_gpio':{'apt-get':['python-rpi.gpio']}
}
#Radio menu translations:
preassembled_module_names ={
"PiFaceCAD":'pifacecad',
"Adafruit I2C LCD&button shield based on MCP23017 (RGB or other bl)":'adafruit',
"\"LCD RGB KEYPAD ForRPi\", based on MCP23017 (with RGB LED)":'chinafruit'
}

preassembled_module_confs = {
'pifacecad':'{"input":[{"driver":"pfcad"}],"output":[{"driver":"pfcad"}]}',
'adafruit':'{"input":[{"driver":"adafruit_plate"}],"output":[{"driver":"adafruit_plate","kwargs":{"chinese":false}}]}',
'chinafruit':'{"input":[{"driver":"adafruit_plate"}],"output":[{"driver":"adafruit_plate"}]}'
}



def call_interactive(command):
    p = Popen(command, stdout=sys.stdout, stdin=sys.stdin, stderr=sys.stderr)
    while p.poll() is None:
        try:
            sleep(1)
        except KeyboardInterrupt:
            p.terminate()
            break


def uniq(list_to_uniq):
    seen = set()
    return [x for x in list_to_uniq if not (x in seen or seen.add(x))]


def yes_or_no(string, default=False):
    while True:
        answer = raw_input(string+" ").lower() #Adding whitespace for prompt to look better
        if answer == "":
            return default
        elif answer.startswith('y'):
            return True
        elif answer.startswith('n'):
            return False
        else:
            pass #Looping until a comprehensible answer is given

def radio_choice(strings, prompt="Choose one:"):
    while True:
        for index, string in enumerate(strings):
            print "{} - {}".format(index, string)
        try:
            choice_str = raw_input(prompt+" ")
        except KeyboardInterrupt:
            return None
        try:
            choice = int(choice_str)
        except ValueError:
            print("Choice should be an integer")
        else:
            break
    return choice

print("Hello! I'm glad that you've chosen pyLCI")
print("Let me help you out with installing necessary Python modules and utilities.")
print("Feel free to restart this script if you screwed up")

options = []
preassembled_module = None

if yes_or_no("Do you use any of pre-assembled I/O modules, such as PiFaceCAD, one of character LCD&button shields or others?"):
   print("Ctrl^C if your module is not found")
   pretty_names = preassembled_module_names.keys()
   answer = radio_choice(pretty_names)
   if answer is not None:
       module_pname = pretty_names[answer]
       module_name = preassembled_module_names[module_pname]
       preassembled_module = module_name
       options.append(module_name)
   else:
       print("You might still be able to use it. Do open an issue on GitHub, or, alternatively, try GPIO driver if it's based on GPIO")
if yes_or_no("Do you want to use I2C devices with pyLCI?"):
   options.append('i2c')
#if yes_or_no("Do you want to use UART devices with pyLCI?"): #No devices as such present in the driver folders now
#   options.append('serial')
if yes_or_no("Do you want to use HID devices with pyLCI (such as keyboards and keypads)?"):
   options.append('hid')
if yes_or_no("Do you want to use Raspberry Pi GPIO-connected devices with pyLCI (not I2C or SPI)?"):
   options.append('rpi_gpio')

#Joining both module dictionaries for convenience
both_dicts = {}
both_dicts.update(preassembled_modules)
both_dicts.update(separate_modules)

apt_get = []
pip = []
for option in options:
    option_desc = both_dicts[option]
    apt_get_packages = option_desc['apt-get'] if 'apt-get' in option_desc else []
    pip_modules = option_desc['pip'] if 'pip' in option_desc else []
    for package in apt_get_packages:
        apt_get.append(package)
    for module in pip_modules:
        pip.append(module)

apt_get = uniq(apt_get)
pip = uniq(pip)

if apt_get:
    call_interactive(['apt-get', 'update'])
    call_interactive(['apt-get', '--ignore-missing', 'install'] + apt_get)

if pip:
    call_interactive(['pip', 'install'] + pip)

print("")
print("-"*30)
print("")

if preassembled_module:
    f = open('config.json', 'w')
    f.write(preassembled_module_confs[preassembled_module])
    f.close()
    print("Your config.json is set. Run 'python main.py' to start the system and check your hardware.")
else:
    print("You'll need to change your config.json according to I/O devices you're using (refer to the documentation!)")
