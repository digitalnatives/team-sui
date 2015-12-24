#!/usr/bin/python
import sys, time, math, json
from sense_hat import SenseHat

sense = SenseHat()
sense.clear()

file_name = sys.argv[1]

with open(file_name, "a+") as boards_file:
    boards_file.truncate()

colors = {
        0: [0, 0, 0],
        1: [255, 0, 0],
        2: [0, 0, 255],
        }

def to_color(cell):
    return colors[cell]

with open(file_name) as boards_file:
    while(True):
        pixels_json = boards_file.readline()
        if pixels_json != "":
            matrix = json.loads(pixels_json)
            sense.set_pixels(map(to_color, matrix))
        time.sleep(0.01)
