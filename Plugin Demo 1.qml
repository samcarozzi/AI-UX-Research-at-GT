import QtQuick 2.0
import MuseScore 3.0
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
MuseScore {
    menuPath: "Plugins.LMMPluginTestCurrScore"
    description: "Sends selection or full score to Flask server"
    pluginType: "dock"
    dockArea:   "right"
    version: "0.01"

    // CONSTANTS
    readonly property var _INSTRUMENT: "Instrument"
    readonly property var _NOTES: "Notes"
    readonly property var _START: "Start"
    readonly property var _DURATION_TICKS: "Duration Ticks"
    readonly property var _DURATION_STRING: "Duration String"
    readonly property var _REST: "Rest"
    readonly property var _TICKS_PER_BEAT: 480 // See: https://musescore.org/en/node/284239
    readonly property var _DEFAULT_TEMPO: 60

    readonly property var _SELECTION_START: "Selection Start"
    readonly property var _SELECTION_END: "Selection End"
    readonly property var _USE_FULL_SCORE: "Use Full Score"
    readonly property var _CURSOR: "Cursor"

    readonly property var _NULL : -1;

    // Tempo independent - for now we assume that a 64th note is the minimum note length we could possibly have.
    readonly property var _WHOLE_NOTE_DURATION: 1920
    readonly property var _HALF_NOTE_DURATION: 960
    readonly property var _QUARTER_NOTE_DURATION: 480
    readonly property var _EIGHTH_NOTE_DURATION: 240
    readonly property var _16TH_NOTE_DURATION: 120
    readonly property var _32ND_NOTE_DURATION: 60
    readonly property var _64TH_NOTE_DURATION: 30

    readonly property var durationMap:  {
        1: _WHOLE_NOTE_DURATION,
        2: _HALF_NOTE_DURATION,
        4: _QUARTER_NOTE_DURATION,
        8: _EIGHTH_NOTE_DURATION,
        16: _16TH_NOTE_DURATION,
        32: _32ND_NOTE_DURATION,
        64: _64TH_NOTE_DURATION,
    }

    function printMap(map) {
        var keys = Object.keys(map);
        for (var key in keys) {
            console.log(key + '|' + map[key]);
        }

    }

    // Helper functions
    function getSelection() {
        var cursor = curScore.newCursor();
        var useFullScore;
        var startTick;
        var endTick;
        var selectionMap = {}

        cursor.rewind(1);

        if (!cursor.segment) { // no selection
            useFullScore = true;
            startTick = 0;
            endTick = curScore.lastSegment.tick + 1;
            cursor.rewind(0) // if no selection, beginning of score
        } else {
            useFullScore = false;
            startTick = cursor.segment.tick;
            console.log("TEMPO", cursor.tempo);
            cursor.rewind(2);
            if (cursor.tick === 0) {
                // this happens when the selection includes
                // the last measure of the score.
                // rewind(2) goes behind the last segment (where
                // there's none) and sets tick=0
                endTick = curScore.lastSegment.tick + 1;
            } else {
                endTick = cursor.tick;
            }
        }

        selectionMap[_SELECTION_START] = startTick;
        selectionMap[_SELECTION_END] = endTick;
        selectionMap[_USE_FULL_SCORE] = useFullScore;
        selectionMap[_CURSOR] = cursor;

        return selectionMap;

    }

    // a more precise cursor positioning function (from the boilerplate)
    function setCursorToTick(cursor, tick) {
        cursor.rewind(0);
        while (cursor.segment) {
            var curTick = cursor.tick;
            if (curTick >= tick) return true;
            cursor.next();
        }
        cursor.rewind(0);
        return false;
    }

    // return active tracks
    function activeTracks() {
        var tracks = [];
        for (var i = 0; i < curScore.selection.elements.length; i++) {
            var e = curScore.selection.elements[i];
            if (i == 0) {
                tracks.push(e.track);
                var previousTrack = e.track;
            }
            if (i > 0) {
                if (e.track != previousTrack) {
                    tracks.push(e.track);
                    previousTrack = e.track;
                }
            }
        }
        return tracks;
    }


    function ticksToSeconds(ticks, tempo) {
        var secondsPerBeat = 1/tempo; // BPM is tempo * 60
        var beats = ticks / _TICKS_PER_BEAT;
        console.log("TEMPO", tempo);
        console.log("SPB", secondsPerBeat);
        console.log("BEATS", beats);
        console.log("SECONDS", beats * secondsPerBeat);
        return beats * secondsPerBeat;
    }

    function addNote(cursor, score, pitch, duration) {

        // Add pitch at cursor along with its duration.

    }

    function delay(duration) { // In milliseconds
        var timeStart = new Date().getTime();

        while (new Date().getTime() - timeStart < duration) {
            // Do nothing
        }

        // Duration has passed
    }


    function changeCurrentSelection(currentIndex) {
        // Ensure the taskType label is defined before trying to change its text.
        if (taskType) {
            if (currentIndex === 0) {
                taskType.text = qsTr('Inpainting')
                modelChoice.model = ["Allegro", "Jumble"]
                startSecondInputLabel.visible = true
                startSecondInputBox.visible = true
                endSecondInputLabel.visible = true
                endSecondInputBox.visible = true
                composerChoiceLayout.visible = false
                composerChoiceLabel.visible = false
                composerChoice.visible = false
            } else if (currentIndex === 1) {
                taskType.text = qsTr('Style Transfer')
                modelChoice.model = ["Coconet", "ST Model 2"]
                startSecondInputLabel.visible = false
                startSecondInputBox.visible = false
                endSecondInputLabel.visible = false
                endSecondInputBox.visible = false
                composerChoiceLayout.visible = true
                composerChoiceLabel.visible = true
                composerChoice.visible = true
            } else {
                taskType.text = qsTr('Harmonization')
                modelChoice.model = ["Model 1", "H Model 2"]
                startSecondInputLabel.visible = false
                startSecondInputBox.visible = false
                endSecondInputLabel.visible = false
                endSecondInputBox.visible = false
                composerChoiceLayout.visible = false
                composerChoiceLabel.visible = false
                composerChoice.visible = false
            }
        }
    }

    QtObject {
        id: verNum
        property int currVer: 1
    }

    // GUI
    Rectangle { // Main background
        color: "#F6F6F8"// White background
        width: parent.width
        height: parent.height
        radius: 5

        ColumnLayout {
            width: parent.width

            Rectangle { // Title bar
                color: "#ECECEC" // Background color as given
                width: 300 // Width as given
                height: 50 // Height as given
                radius: 5 // Border-radius equivalent in QML for top left and top right
                border.color: "#999999"
                border.width: 0.5
                Layout.alignment: Qt.AlignHCenter

                Label {
                    text: "LMM Plugin"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#4B4B57" // Text color
                    font.family: "Open Sans" // Font family
                    font.pixelSize: 18 // Font size
                    font.weight: Font.Bold // Font weight (700 corresponds to bold)

                }
            }

            RowLayout { // Container for the label and combo box, side by side
                width: 300
                height: 50
                Layout.margins: 10
                spacing: 75 // Gap between label and combo box
                Layout.alignment: Qt.AlignHCenter

                Label {
                    text: "Action"
                    // Other styling options for the label
                }

                ComboBox { // Action dropdown
                    id: taskTypeChoice
                    currentIndex: 0
                    model: ['Inpainting', 'Style Transfer', 'Harmonization']
                    onCurrentIndexChanged: { changeCurrentSelection(currentIndex) }
                    // Apply styles to the ComboBox if needed
                }
            }

            Item {
                Layout.preferredHeight: 5
                Layout.fillWidth: true
            }

            Rectangle { // Horizontal line
                width: 300 // Same as the width of the RowLayouts
                height: 1 // Thin line
                color: "#999999" // Grey color
                Layout.alignment: Qt.AlignCenter
            }

            // Spacer after the line
            Item {
                Layout.preferredHeight: 5
                Layout.fillWidth: true
            }

            RowLayout { // Container for the label and combo box, side by side
                width: 300
                height: 50
                Layout.margins: 10
                spacing: 75 // Gap between label and combo box
                Layout.alignment: Qt.AlignHCenter

                Label {
                    id: taskType
                    text: "Inpainting"
                    // Other styling options for the label
                }

                ComboBox { // Action dropdown
                    id: modelChoice
                    currentIndex: 0
                    model: ['Allegro', 'Jumble']
                    // Apply styles to the ComboBox if needed
                }
            }

            Item {
                Layout.preferredHeight: 5
                Layout.fillWidth: true
            }

            Rectangle { // Horizontal line
                width: 300 // Same as the width of the RowLayouts
                height: 1 // Thin line
                color: "#999999" // Grey color
                Layout.alignment: Qt.AlignCenter
            }

            // Spacer after the line
            Item {
                Layout.preferredHeight: 5
                Layout.fillWidth: true
            }

            Item {
                Layout.preferredHeight: 5
                Layout.fillWidth: true
            }

            RowLayout {
                id: composerChoiceLayout
                width: 300
                height: 50
                Layout.margins: 10
                spacing: 75 // Gap between label and combo box
                visible: false
                Layout.alignment: Qt.AlignHCenter

                Label {
                    id: composerChoiceLabel
                    text: "Composer"
                    visible: false
                }

                ComboBox {
                    id: composerChoice
                    model:
                    [
                        'Bach',
                        'Chopin'
                    ]
                    visible: false
                }
            }

            Item {
                Layout.preferredHeight: 5
                Layout.fillWidth: true
            }

            Button {
                id: generate
                Layout.preferredWidth: 250
                text: qsTr('Generate')
                Layout.alignment: Qt.AlignHCenter
                onClicked: {
                    // progress.value = 0
                    // progressTimer.start()
                    // progress.visible = true
                    spinner.running = true
                    var selectionMap = getSelection();
                    var tempo = selectionMap[_CURSOR].tempo
                    var startTick = selectionMap[_SELECTION_START];
                    var endTick = selectionMap[_SELECTION_END];
                    var cursor = selectionMap[_CURSOR];
                    var useFullScore = selectionMap[_USE_FULL_SCORE];
                    var startSecond = ticksToSeconds(startTick, tempo)
                    var endSecond = ticksToSeconds(endTick, tempo)
                    var prevTick = 0;
                    var nextTick = 0;
                    var tracks = activeTracks();
                    var nn = 0;
                    var prevTick = 0;
                    var nextTick = 0;

                    printMap(selectionMap);
                    console.log("START SECOND", startSecond);
                    console.log("END SECOND", endSecond);

                    writeScore(curScore, '/tmp/LMMScore', 'mxl')

                    var req = new XMLHttpRequest()
                    req.onreadystatechange = function() {
                        if (req.readyState == XMLHttpRequest.DONE) {
                            verNum.currVer += 1
                            var newVer = ["Version " + verNum.currVer]
                            historyDropdown.model = newVer.concat(historyDropdown.model)
                            
                            var response = JSON.parse(req.responseText);
                            console.log("RESPONSE", response);

                            // remove existing elements from selection (delete notes)
                            // From: https://github.com/ellejohara/newretrograde/blob/master/NewRetrograde.qml
                            curScore.startCmd();
                            for (var trackNum in tracks) {
                                cursor.track = 0;  // set to track 0 first, setting track will reset tick
                                setCursorToTick(cursor, startTick);
                                cursor.track = tracks[trackNum]; // now set track number
                                while (cursor.segment && cursor.tick < endTick) {
                                    var e = cursor.element;
                                    if (e == null) { // check if cursor.element is null
                                        console.log("FOUND A NULL ELEMENT");
                                        var meas = cursor.measure; // get the selected measure
                                        var durD = meas.timesigActual.denominator; // get the denominator
                                        cursor.setDuration(1, durD); // set duration to 1/denominator
                                        cursor.addRest(); // add a rest to fill empty voices
                                    } else { // if cursor.element is not null, do this
                                        if (e.type == Element.CHORD || e.type == Element.NOTE) {
                                            if (e.tuplet) {
                                                console.log("SHOULD BE DELETING A CHORD OR NOTE");
                                                cursor.setDuration(e.tuplet.duration.numerator, e.tuplet.duration.denominator);
                                                removeElement(e.tuplet);
                                            } else {
                                                console.log("SHOULD BE DELETING A TUPLET");
                                                cursor.setDuration(e.duration.numerator,e.duration.denominator);
                                                removeElement(e);
                                            }
                                        }
                                    }
                                    cursor.next(); // advance the cursor
                                }
                            }


                            // Rewind the cursor and emplace notes into the score
                            setCursorToTick(cursor, startTick);
                            console.log("RESPONSE LENGTH:", response.length);

                            for (var i = 0; i < response.length && prevTick < endTick; ++i) {
                                nn += 1;
                                console.log(response[i]);
                                var midi_note = response[i][0][0];
                                var duration_numerator = response[i][1][0];
                                var duration_denominator = response[i][1][1];

                                console.log(midi_note, duration_numerator, duration_denominator)

                                if (midi_note == -1) {
                                    console.log("REST TICK", cursor.tick, startTick);
                                    console.log(duration_numerator, duration_denominator, midi_note);
                                    cursor.setDuration(duration_numerator,duration_denominator);
                                    cursor.addRest();
                                    cursor.prev();

                                } else {
                                    console.log("NOTE TICK", cursor.tick, startTick);
                                    console.log(duration_numerator, duration_denominator, midi_note);
                                    cursor.setDuration(duration_numerator,duration_denominator);
                                    cursor.addNote(midi_note);
                                    cursor.prev();
                                }
                                if (nn > 4000) {
                                    console.log("INFINITE LOOP BREAK!");
                                    break;
                                }

                                prevTick = nextTick;
                                cursor.next();
                                nextTick = cursor.tick;
                                console.log(cursor.tick, endTick, prevTick,nextTick, "NEXT!")

                                if (prevTick == nextTick) {
                                    console.log("CURSOR HASN'T MOVED!! BREAK!!!");
                                    break;
                                }

                                console.log("COUNTS", i, nn);

                                if (i > 100) {
                                    break;
                                }

                            }
                            curScore.endCmd();
                            if (!useFullScore) {
                                curScore.selection.selectRange(startTick, endTick + 1, 0, 1); // keep selection selected
                            }
                            spinner.running = false
                        }
                    }
                    req.open('POST', 'http://127.0.0.1:5000/xml_data')
                    req.setRequestHeader("Content-Type", "application/json;charset=UTF-8")
                    req.send(JSON.stringify({
                        'file': '/tmp/LMMScore.mxl',
                        'selected_model': modelChoice.currentText,
                        'start_second': startSecond,
                        'end_second': endSecond,
                    }))
                }
            }

            Item {
    Layout.preferredHeight: 10 // Adds a small space between the Generate and Cancel buttons
}

Button {
    id: cancelButton
    Layout.preferredWidth: 250
    text: qsTr('Cancel')
    Layout.alignment: Qt.AlignHCenter
    enabled: spinner.running // Only enable this button when the spinner is running (i.e., during generation)
    onClicked: {
        spinner.running = false // Stop the spinner, effectively canceling the generation
        // Add any additional logic required to properly cancel the operation
    }
}

            Item {
                Layout.preferredHeight: 10
            }

            BusyIndicator {
            id: spinner
            Layout.alignment: Qt.AlignHCenter
            running: false
            width: 50  // Set the width of the spinner
            height: 50  // Set the height of the spinner
}

            // ProgressBar {
            //     id: progress
            //     Layout.preferredWidth: 250
            //     Layout.alignment: Qt.AlignHCenter
            //     value: 0
            //     visible: false
            // }

            Item {
                Layout.preferredHeight: 10
            }

            Rectangle { // Horizontal line
                width: 300 // Same as the width of the RowLayouts
                height: 1 // Thin line
                color: "#999999" // Grey color
                Layout.alignment: Qt.AlignCenter
            }
            
            Item {
                Layout.preferredHeight: 5
            }

            RowLayout { // Container for the label and combo box, side by side
                width: 300
                height: 50
                Layout.margins: 10
                spacing: 75 // Gap between label and combo box
                Layout.alignment: Qt.AlignHCenter

                Label {
                    text: "History"
                }

                ComboBox { // Action dropdown
                    id: historyDropdown
                    currentIndex: 0
                    model: ['Version 1']
                    onCurrentIndexChanged: {  }
                }
            }
            
            Item {
                Layout.preferredHeight: 5
            }

            Rectangle { // Horizontal line
                width: 300 // Same as the width of the RowLayouts
                height: 1 // Thin line
                color: "#999999" // Grey color
                Layout.alignment: Qt.AlignCenter
            }

            Item {
                Layout.preferredHeight: 10
            }

            Button {
                id: helpbutton
                text: "Help"
                Layout.preferredWidth: 100
                Layout.alignment: Qt.AlignHCenter
                anchors.bottom: window.bottom
                onClicked: {
                    Qt.openUrlExternally("https://github.gatech.edu/jcleveland35/LMM_Muescore_Demo");
                }
            }   

            // Timer {
            //     id: progressTimer
            //     interval: 500; running: false; repeat: true; triggeredOnStart: false
            //     onTriggered: progress.value += 0.1
            // }
        }
    }
}
