import QtQuick 2.2
import Sailfish.Silica 1.0
import QtPositioning 5.0
import MapboxMap 1.0

Dialog {
    property bool edit: true
    property string name
    property double latitude: 0
    property double longitude: 0

    id: locationDialog

    canAccept: nameField.acceptableInput && latitudeField.acceptableInput && longitudeField.acceptableInput

    PositionSource {
        id: positionSource
        active: true
        onPositionChanged: {
            map.updateSourcePoint("gps", position.coordinate.latitude, position.coordinate.longitude, qsTrId("id-use-current-position"))

            if (position.latitudeValid) {
                map.addLayer("gps-uncertainty", {"type": "circle", "source": "gps"}, "gps-case")
                map.setPaintProperty("gps-uncertainty", "circle-radius", position.horizontalAccuracy && position.horizontalAccuracy < 100 ? position.horizontalAccuracy : 100)
                map.setPaintProperty("gps-uncertainty", "circle-color", "#87cefa")
                map.setPaintProperty("gps-uncertainty", "circle-opacity", 0.25)

                map.addLayer("gps-case", {"type": "circle", "source": "gps"}, "initial-point")
                map.setPaintProperty("gps-case", "circle-radius", 10)
                map.setPaintProperty("gps-case", "circle-color", "white")
            }
            else {
                map.addLayer("gps-case", {"type": "circle", "source": "gps"}, "initial-point")
                map.setPaintProperty("gps-case", "circle-radius", 10)
                map.setPaintProperty("gps-case", "circle-color", "grey")
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge

        DialogHeader {
            dialog: locationDialog
            title: edit ?
                       //% "Edit location"
                       qsTrId("id-edit-location") :
                       //% "Add location"
                       qsTrId("id-add-location")
            acceptText: edit ?
                            //% "Save"
                            qsTrId("id-save") :
                            //% "Add"
                            qsTrId("id-add")
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            wrapMode: Text.WordWrap

            color: Theme.highlightColor

            //% "Define a location by providing a coordinate with latitude and longitude."
            text: qsTrId("id-add-location-desc")
        }

        TextField {
            id: nameField
            width: parent.width
            //% "Enter location name"
            placeholderText: qsTrId("id-enter-location-name")
            //% "Location name"
            label: qsTrId("id-location-name")

            validator: RegExpValidator {
                regExp: /^[a-zA-Z0-9ÄÖÜäöü_\- ]+$/gm
            }

            focus: !edit

            text: name

            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: latitudeField.focus = true
        }

        Button {
            id: buttonCurrentPosition
            anchors.horizontalCenter: parent.horizontalCenter
            enabled: positionSource.position.latitudeValid
            //% "Use current position"
            text: qsTrId("id-use-current-position")

            onClicked: {
                latitudeField.text = positionSource.position.coordinate.latitude
                longitudeField.text = positionSource.position.coordinate.longitude

                map.fitView([
                                QtPositioning.coordinate(positionSource.position.coordinate.latitude, positionSource.position.coordinate.longitude)
                            ])
            }
        }

        TextField {
            id: latitudeField
            width: parent.width
            //% "Enter latitude (e.g. 52.518796)"
            placeholderText: qsTrId("id-enter-latitude")
            //% "Latitude"
            label: qsTrId("id-latitude")

            inputMethodHints: Qt.ImhDigitsOnly
            validator: DoubleValidator {
                bottom: -90.0
                top: 90.0
                decimals: 16
                locale: Qt.locale("en_EN").name
            }

            text: edit ? latitude : ""

            onTextChanged: {
                text = text.replace(',', '.')

                map.updateSourcePoint("userinput", latitudeField.text, longitudeField.text, name)
            }

            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: longitudeField.focus = true
        }

        TextField {
            id: longitudeField
            width: parent.width
            //% "Enter longitude (e.g. 13.376241)"
            placeholderText: qsTrId("id-enter-longitude")
            //% "id-longitude"
            label: qsTrId("id-longitude")

            inputMethodHints: Qt.ImhDigitsOnly
            validator: DoubleValidator {
                bottom: -180.0
                top: 180.0
                decimals: 16
                locale: Qt.locale("en_EN").name
            }

            text: edit ? longitude : ""

            onTextChanged: {
                text = text.replace(',', '.')
                map.updateSourcePoint("userinput", latitudeField.text, longitudeField.text, name)
            }

            EnterKey.iconSource: "image://theme/icon-m-enter-close"
            EnterKey.onClicked: longitudeField.focus = false
        }

        MapboxMap {

            id: map
            width: parent.width
            height: width

            minimumZoomLevel: 0
            maximumZoomLevel: 20
            pixelRatio: 3.0
            accessToken: settings.mapboxApiKey.length > 0 ? settings.mapboxApiKey : dbusService.getProperty("mapBoxApiKey")
            cacheDatabaseDefaultPath: true

            MapboxMapGestureArea {
                id: mouseArea
                map: map
                activeClickedGeo: true
                activeDoubleClickedGeo: true

                onClickedGeo: {
                    if (Math.abs(geocoordinate.latitude - latitude) < 10 * degLatPerPixel &&
                            Math.abs(geocoordinate.longitude - longitude) < 10 * degLonPerPixel) {
                        latitudeField.text = latitude
                        longitudeField.text = longitude
                    }
                    else if (Math.abs(geocoordinate.latitude - positionSource.position.coordinate.latitude) < 10 * degLatPerPixel &&
                                Math.abs(geocoordinate.longitude - positionSource.position.coordinate.longitude) < 10 * degLonPerPixel) {
                            latitudeField.text = positionSource.position.coordinate.latitude
                            longitudeField.text = positionSource.position.coordinate.longitude
                        }
                    else {
                        latitudeField.text = geocoordinate.latitude
                        longitudeField.text = geocoordinate.longitude
                    }

                    map.fitView([
                                    QtPositioning.coordinate(geocoordinate.latitude, geocoordinate.longitude),
                                ])
                }

            }

            Component.onCompleted: {
                setMargins(0.1, 0.1, 0.1, 0.1)

                map.addSourcePoint("initial", latitude, longitude, name)
                map.addSourcePoint("userinput", latitudeField.text, longitudeField.text, name)

                map.addLayer("initial-point", {"type": "circle", "source": "initial"}, "userinput-point")
                map.setPaintProperty("initial-point", "circle-radius", 5)
                map.setPaintProperty("initial-point", "circle-color", "green")

                map.addLayer("userinput-point", {"type": "circle", "source": "userinput"})
                map.setPaintProperty("userinput-point", "circle-radius", 5)
                map.setPaintProperty("userinput-point", "circle-color", "blue")

                map.addLayer("userinput-label", {"type": "symbol", "source": "userinput"})
                map.setLayoutProperty("userinput-label", "text-field", "{name}")
                map.setLayoutProperty("userinput-label", "text-justify", "left")
                map.setLayoutProperty("userinput-label", "text-anchor", "top-left")
                map.setLayoutPropertyList("userinput-label", "text-offset", [0.2, 0.2])
                map.setPaintProperty("userinput-label", "text-halo-color", "white")
                map.setPaintProperty("userinput-label", "text-halo-width", 1)

                map.fitView([
                                QtPositioning.coordinate(latitude - 0.5, longitude - 0.5),
                                QtPositioning.coordinate(latitude + 0.5, longitude + 0.5),
                            ])
            }
        }

    }

    onDone: {
        name = nameField.text
        latitude = latitudeField.text
        longitude = longitudeField.text
    }
}
