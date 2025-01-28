#import sys to get the arguments
import sys
import pandas as pd

# print to see the arguments
print(sys.argv)

# get the day from the arguments
day = sys.argv[1]

# some fancy stuff with pandas

print(f'Job finished succesfully = {day}')