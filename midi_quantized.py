import mido
import os

def check_instrument_velocities(input_filepath):
   velocities = {}  # Dictionary to store velocities for each instrument
   mid = mido.MidiFile(input_filepath)

   # Iterate through each track in the MIDI file
   for track in mid.tracks:
   	for msg in track:
       	# Check if the message is a 'note_on' event
       	if msg.type == 'note_on':
           	# Add the velocity to the dictionary using the instrument number as the key
           	if msg.channel not in velocities:
               	velocities[msg.channel] = set()  # Initialize set for velocities if not exists
           	velocities[msg.channel].add(msg.velocity)

   # Check if any instrument has multiple velocities
   for channel, velocity_set in velocities.items():
   	velocity_set.remove(0)
   	if len(velocity_set) > 1:
       	print(velocity_set)# Instrument has different velocities
       	return True
   return False

def process_single_midi_file(midi_file_path):
   if midi_file_path.endswith('.mid'):
   	if check_instrument_velocities(midi_file_path):
       	with open(os.path.expanduser('~/Desktop/LIVELIVE'), 'a') as file:
           	file.write(f"Instruments in {midi_file_path} have different velocities.\n")
   	else:
       	print(f"No different velocities found in {midi_file_path}.")

# Example usage for processing a single MIDI file
midi_file_path = os.path.expanduser('~/Desktop/vishruthnl.mid')
process_single_midi_file(midi_file_path)
