def get_piano_rolls(path):
   midi = MidiFile(path)
   ticks_per_beat = midi.ticks_per_beat
   div_16th = ticks_per_beat // 4  # Assuming a resolution of 4 16th notes per beat


   end_time, tempo = get_meta(midi.tracks)
   n_chunks = int(end_time / div_16th)
   output = np.zeros((n_chunks, 4))


   for track in midi.tracks:
       if is_control_track(track):
           continue
          
       curr_time = 0
       bank = NoteBank()
      
       for msg in track:
           curr_time += msg.time
           curr_chunk = int(curr_time / div_16th)
           if curr_chunk >= n_chunks:
               break
              
           if msg.type == 'note_on' and msg.velocity > 0:
               note = msg.note
               bank.noteOn(note, curr_time)
           if (msg.type == 'note_on' and msg.velocity == 0) or \
               msg.type == 'note_off':
               note = msg.note
               start, channel = bank.noteOff(note)
               if start != False:
                   start_chunk = int(start / div_16th)
                   end_chunk = int(curr_time / div_16th)
                   if start_chunk < n_chunks and end_chunk < n_chunks:
                       output[start_chunk:end_chunk, channel * 2] = note
                  
   return output
