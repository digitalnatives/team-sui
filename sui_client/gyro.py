#!/usr/bin/python
import sys, time, math
from sense_hat import SenseHat

sense = SenseHat()
sense.clear()

SAMPLES = 7
NEUTRAL_RANGE_SIZE = 30

def tilt(orientation):
    if orientation > NEUTRAL_RANGE_SIZE/2:
        return 1
    elif orientation < -NEUTRAL_RANGE_SIZE/2:
        return -1
    else:
        return 0

def get_samples_value(samples):
    return math.degrees(sum(sorted(samples)[1:6])/5)

def get_orientation(sense):
    samples = map((lambda index: sense.get_orientation_radians()), range(SAMPLES))
    separate_samples = zip(*map((lambda sample: (sample['pitch'], sample['roll'])), samples))
    filtered_samples = map(get_samples_value, separate_samples)
    return {'pitch': filtered_samples[0], 'roll': filtered_samples[1]}

file_name = sys.argv[1]
moves_file = open(file_name, "a")

while True:
    orientation = get_orientation(sense)

    pitch = -tilt(orientation['pitch'])
    roll = tilt(orientation['roll'])
    with open(file_name, "a+") as moves_file:
        moves_file.write("[{pitch}, {roll}]\n".format(**{'pitch': pitch, 'roll': roll}))
    time.sleep(0.2)
