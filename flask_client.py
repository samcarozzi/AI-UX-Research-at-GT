
import requests
import json
from music21 import converter
import sys
import os

def midi_file_to_musicxml_string(midi_file_path):
    try:
        score = converter.parse(midi_file_path)
        musicxml_string = score.write('musicxml')
        with open(musicxml_string, 'r') as file:
            xml_content = file.read()
        return xml_content
    except Exception as e:
        print(f"Error converting MIDI to MusicXML: {e}")
        return None


def send_midi_to_flask_server(midi_file_path, server_url, selected_model, start_second, end_second):
    xml_string = midi_file_to_musicxml_string(midi_file_path)
    if xml_string is None:
        print("Failed to convert MIDI to MusicXML. Aborting request.")
        return None

    payload = {
        "file": xml_string,
        "selected_model": selected_model,
        "start_second": start_second,
        "end_second": end_second
    }

    headers = {'Content-Type': 'application/json'}
    try:
        response = requests.post(f"{server_url}/xml_data", json=payload, headers=headers)
    except Exception as e:
        print(f"Error sending request to Flask server: {e}")
        return None

    if response.status_code == 200:
        notes_for_musescore_js = response.json()
        return notes_for_musescore_js
    else:
        print(f"Error: {response.status_code} - {response.text}")
        return None


def main():
    import os
    midi_file_path = os.path.expanduser("~/Downloads/ballade_op_23_no_1_a_(nc)smythe.mid")
    server_url = f"http://{server_ip}:5000"  
    selected_model = "Allegro" 
    start_second = 0
    end_second = 15

    result = send_midi_to_flask_server(
        midi_file_path,
        server_url,
        selected_model,
        start_second,
        end_second
    )

    if result:
        print("Received response from Flask server:")
        print(result)
    else:
        print("Failed to receive a valid response.")


if __name__ == "__main__":
    main()

def test_flask_server(server_url):
    try:
        response = requests.get(f"{server_url}/test")
        print(f"Test request status code: {response.status_code}")
        print(f"Response text: {response.text}")
    except Exception as e:
        print(f"Error testing Flask server: {e}")
