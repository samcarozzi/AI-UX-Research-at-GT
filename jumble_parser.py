from file_parser import FileParser
from music21 import *
import numpy as np
import subprocess




class JumbleParser(FileParser):
   @staticmethod
   def handle_file(in_absolute_file_path: str, arguments: dict) -> str:
       stream = converter.parse(in_absolute_file_path)
       key = stream.analyze("key")
       i = interval.Interval(key.tonic, pitch.Pitch("F#"))
       stream = stream.transpose(i)
       output_file_path = "/tmp/jumble_parsed.mid"
       stream.write("midi", output_file_path)


       return output_file_path
