#!/usr/bin/python
import time
import math
from sense_hat import SenseHat

sense = SenseHat()
sense.clear()

prev_y = y = 4
prev_x = x = 4

SAMPLES = 7
NEUTRAL_RANGE_SIZE = 30

def tilt(orientation):
    if orientation > NEUTRAL_RANGE_SIZE/2:
        return 1
    elif orientation < -NEUTRAL_RANGE_SIZE/2:
        return -1
    else:
        return 0

def allowed_position(x, y):
    if x < 0 or x > 7:
        return False
    if y < 0 or y > 7:
        return False
    return True

def get_samples_value(samples):
    return math.degrees(sum(sorted(samples)[1:6])/5)

def get_orientation(sense):
    samples = map((lambda index: sense.get_orientation_radians()), range(SAMPLES))
    separate_samples = zip(*map((lambda sample: (sample['pitch'], sample['roll'])), samples))
    filtered_samples = map(get_samples_value, separate_samples)
    return {'pitch': filtered_samples[0], 'roll': filtered_samples[1]}

while True:
    orientation = get_orientation(sense)

    print("p: {pitch}, r: {roll}".format(**orientation))
    # print("x: {x}, y: {y}".format(**{'x': x, 'y': y}))

    x -= tilt(orientation['pitch'])
    y += tilt(orientation['roll'])

    if allowed_position(x, y):
        if x != prev_x or y != prev_y:
            sense.set_pixel(prev_x, prev_y, 0, 0, 0)
        sense.set_pixel(x, y, 0, 0, 255)

        prev_x = x
        prev_y = y
    else:
        x = prev_x
        y = prev_y
        sense.set_pixel(x, y, 255, 0, 0)


    time.sleep(0.3)
