#!/usr/bin/python
import sys
import time
import math
import json
from sense_hat import SenseHat

sense = SenseHat()
sense.clear()

# Example matrix, provide it through the command line as string:
# $ python render.py '[[0,1,2], [2, 3, 3], ...]'
#
# X = [255, 0, 0]  # Red
# O = [255, 255, 255]  # White
# question_mark = [
# O, O, O, X, X, O, O, O,
# O, O, X, O, O, X, O, O,
# O, O, O, O, O, X, O, O,
# O, O, O, O, X, O, O, O,
# O, O, O, X, O, O, O, O,
# O, O, O, X, O, O, O, O,
# O, O, O, O, O, O, O, O,
# O, O, O, X, O, O, O, O
# ]

matrix = json.loads(sys.argv[1])

sense.set_pixels(matrix)
