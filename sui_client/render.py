#!/usr/bin/python
import sys, time, math, json
from sense_hat import SenseHat

sense = SenseHat()
sense.clear()

file_name = sys.argv[1]

with open(file_name, "a+") as boards_file:
    boards_file.truncate()

with open(file_name) as boards_file:
    while(True):
        pixels_json = boards_file.readline()
        if pixels_json != "":
            matrix = json.loads(pixels_json)
            sense.set_pixels(matrix)
        time.sleep(0.1)
