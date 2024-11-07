
from flask import Flask, request, make_response
import pydash
import json
import numpy as np
import matplotlib.pyplot as plt
import music21
import miditoolkit
import base64
import mido
from miditok import REMI, TokenizerConfig
from tokenizers import Tokenizer
import pickle
import torch
from music21 import converter, note, chord
from coconet_parser import CoconetParser
from jumble_parser import JumbleParser
from music_transformer_parser import MusicTransformerParser
from allegro_parser import AllegroParser
from symphonynet_parser import SymphonyNetParser
# logging.basicConfig(level=logging.DEBUG)

app = Flask(__name__)

pretrained = "/home/lmm/SymphonyNet/SymphonyNet/pretrained/checkpoint_last_linear_4096_chord_bpe_hardloss1_PI2.pt"
symphonynet_model = SymphonyNetModel()  
checkpoint = torch.load(pretrained) 
symphonynet_model.load_state_dict(checkpoint['model_state_dict'])  
symphonynet_model.eval()

handlers = {
    "CocoNet": CoconetParser.handle_file,
    "Jumble": JumbleParser.handle_file,
    "Music Transformer - Jazz": MusicTransformerParser.handle_file,
    "Music Transformer - Classical": MusicTransformerParser.handle_file,
    "Allegro": AllegroParser.handle_file,
    "SymphonyNet" : SymphonyNetParser.handle_file,
}

parameters = {
    "CocoNet": {},
    "Jumble": {},
    "Music Transformer - Jazz": {"type": "jazz"},
    "Music Transformer - Classical": {"type": "classical"},
    "Allegro": {"start_second": 0, "end_second": 15},
    "SymphonyNet": {"measures": 5, "constraints": 0, "model": symphonynet_model},
}


def quarter_length_to_musescore_duration(quarterLength):
    # Basic durations in terms of quarter notes
    basic_durations = {
        4.0: (1, 1),
        2.0: (1, 2),
        1.0: (1, 4),
        0.5: (1, 8),
        0.25: (1, 16),
    }
    dotted_durations = {
        3.0: (3, 4, True),
        1.5: (3, 8, True),
        0.75: (3, 16, True),
    }

    if quarterLength in basic_durations:
        return basic_durations[quarterLength]
    elif quarterLength in dotted_durations:
        numerator, denominator, isDotted = dotted_durations[quarterLength]
        # Handle dotted note representation as needed
        return (numerator, denominator)  # Simple representation, adjust as needed
    else:
        # For more complex durations, you may need a custom approach
        # This is a simplified example, real implementation may vary
        return (float(quarterLength * 4), 4)  # Convert to fraction of a whole note


def midi_to_json(midi_file_path):
    # Load MIDI file
    mid = mido.MidiFile(midi_file_path)

    # Prepare a list to hold data for all messages
    midi_data = []

    for i, track in enumerate(mid.tracks):
        # print(f"Track {i}: {track.name}")
        for msg in track:
            # Convert message to a dictionary, filtering out non-serializable fields
            msg_dict = msg.dict()
            # msg_dict.pop("time", None)  # Remove fields as necessary
            midi_data.append(msg_dict)

    # Convert the list to JSON
    midi_json = json.dumps(midi_data, indent=4)
    return midi_json


@app.route("/xml_data", methods=["POST"])
def xml_data():
    data = request.json
    xml_string = data["file"]
    selected_model = data["selected_model"]

    if selected_model in parameters:
        parameters[selected_model]["start_second"] = float(data["start_second"])
        parameters[selected_model]["end_second"] = float(data["end_second"]) - 0.01

    # Parse the music data directly from the XML string
    score = music21.converter.parseData(xml_string)
    midi_file_path = score.write("midi")
    print("RECEIVED SCORE SUCCESSFULLY")

    handler_method = handlers.get(selected_model)
    handler_options = parameters.get(selected_model)

    if handler_method is None:
        # Return Not Implemented Error
        error_message = f"{selected_model} not implemented"
        response = make_response(error_message, 501)
    else:
        output_file = handler_method(midi_file_path, handler_options)
        midi_json = midi_to_json(midi_file_path)
        midi21 = music21.converter.parse(output_file)

        notes_for_musescore = []
        for part in midi21.parts:
            for element in part.flat.notesAndRests:
                if isinstance(element, music21.note.Note):
                    midi_note = element.pitch.midi
                    duration = quarter_length_to_musescore_duration(
                        element.quarterLength
                    )
                    notes_for_musescore.append(([midi_note], duration))
                elif isinstance(element, music21.chord.Chord):
                    midi_notes = [p.midi for p in element.pitches]
                    duration = quarter_length_to_musescore_duration(
                        element.quarterLength
                    )
                    notes_for_musescore.append((midi_notes, duration))
                elif isinstance(element, music21.note.Rest):
                    midi_note = -1  # Rest
                    duration = quarter_length_to_musescore_duration(
                        element.quarterLength
                    )
                    notes_for_musescore.append(([midi_note], duration))

        print(notes_for_musescore)
        notes_for_musescore_js = json.dumps(notes_for_musescore)
        response = make_response(notes_for_musescore_js, 200)

    return response
