/* GCompris - categorization.qml
*
* Copyright (C) 2016 Divyam Madaan <divyam3897@gmail.com>
*
* Authors:
*   Divyam Madaan <divyam3897@gmail.com>
*
*   This program is free software; you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation; either version 3 of the License, or
*   (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with this program; if not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.1
import QtQuick.Controls 1.1
import GCompris 1.0

import "../../core"
import "categorization.js" as Activity
import "qrc:/gcompris/src/core/core.js" as Core
import "."

ActivityBase {
    id: activity

    onStart: focus = true
    onStop: {}

    property bool vert: background.width < background.height
    property string type: "images"
    property int categoriesCount
    property string boardsUrl: ":/gcompris/src/activities/categorization/resource/board/"

    pageComponent:
    Image {
        id: background
        source: "qrc:/gcompris/src/activities/lang/resource/imageid-bg.svg"
        anchors.fill: parent
        sourceSize.width: parent.width
        signal start
        signal stop

        property string locale: "system"
        property bool englishFallback: false
        property bool categoriesFallback: (items.categoriesCount == 6) ? true : false

        Component.onCompleted: {
            activity.start.connect(start)
            activity.stop.connect(stop)
        }

        // Add here the QML items you need to access in javascript
        QtObject {
            id: items
            property Item main: activity.main
            property alias background: background
            property alias bar: bar
            property alias bonus: bonus
            property alias categoryReview: categoryReview
            property alias menuScreen: menuScreen
            property alias menuModel: menuScreen.menuModel
            property alias dialogActivityConfig: dialogActivityConfig
            property string mode: "easy"
            property bool instructionsVisible: true
            property bool categoryImageChecked: (mode === "easy" || mode === "medium")
            property bool scoreChecked: (mode === "easy")
            property bool iAmReadyChecked: (mode === "expert")
            property bool displayUpdateDialogAtStart: true
            property var details
            property bool categoriesFallback
            property alias file: file
            property var categories: (type == "images") ? directory.getFiles(boardsUrl) : directory.getFiles(boardsUrl + locale + "/")
            property alias locale: background.locale
            property alias hintDialog: hintDialog
            property var categoryTitle
            property var categoryLesson
            property bool hintDisplay
        }

        onStart: {
            Activity.init(items, boardsUrl,type,categoriesCount)
            dialogActivityConfig.getInitialConfiguration()
            Activity.start()
        }

        onStop: {
            dialogActivityConfig.saveDatainConfiguration()
        }

        MenuScreen {
            id: menuScreen

        File {
            id: file
            onError: console.error("File error: " + msg);
        }
        }

        Directory {
            id: directory
        }

        CategoryReview {
            id: categoryReview
        }

        ExclusiveGroup {
            id: configOptions
        }

        DialogActivityConfig {
            id: dialogActivityConfig
            content: Component {
                Column {
                    id: column
                    spacing: 5
                    width: dialogActivityConfig.width
                    height: dialogActivityConfig.height
                    property alias easyModeBox: easyModeBox
                    property alias mediumModeBox: mediumModeBox
                    property alias expertModeBox: expertModeBox
                    property alias localeBox: localeBox

                    property alias availableLangs: langs.languages
                    LanguageList {
                        id: langs
                    }

                    GCDialogCheckBox {
                        id: easyModeBox
                        width: column.width - 50
                        text: qsTr("Instructions and score visible")
                        checked: (items.mode == "easy") ? true : false
                        exclusiveGroup: configOptions
                        onCheckedChanged: {
                            if(easyModeBox.checked) {
                                items.mode = "easy"
                                menuScreen.iAmReady.visible = false
                            }
                        }
                    }

                    GCDialogCheckBox {
                        id: mediumModeBox
                        width: easyModeBox.width
                        text: qsTr("Instructions visible and score invisible")
                        checked: (items.mode == "medium") ? true : false
                        exclusiveGroup: configOptions
                        onCheckedChanged: {
                            if(mediumModeBox.checked) {
                                items.mode = "medium"
                                menuScreen.iAmReady.visible = false
                            }
                        }
                    }

                    GCDialogCheckBox {
                        id: expertModeBox
                        width: easyModeBox.width
                        text: qsTr("Instructions and score invisible")
                        checked: (items.mode == "expert") ? true : false
                        exclusiveGroup: configOptions
                        onCheckedChanged: {
                            if(expertModeBox.checked) {
                                items.mode = "expert"
                                menuScreen.iAmReady.visible = true
                            }
                        }
                    }

                    GCComboBox {
                        id: localeBox
                        model: langs.languages
                        background: dialogActivityConfig
                        width: dialogActivityConfig.width
                        label: qsTr("Select your locale")
                        visible: type == "words" ? true : false
                    }
                }
            }
            onLoadData: {
                if(dataToSave && dataToSave["mode"])
                    items.mode = dataToSave["mode"]
                if(dataToSave && dataToSave["displayUpdateDialogAtStart"])
                    items.displayUpdateDialogAtStart = (dataToSave["displayUpdateDialogAtStart"] == "true") ? true : false
                if(dataToSave && dataToSave['locale']) {
                    background.locale = dataToSave["locale"];
                }
            }

            onSaveData: {
                dataToSave["mode"] = items.mode
                var oldLocale = background.locale;
                var newLocale =
                        dialogActivityConfig.configItem.availableLangs[dialogActivityConfig.loader.item.localeBox.currentIndex].locale;
                // Remove .UTF-8
                if(newLocale.indexOf('.') != -1) {
                    newLocale = newLocale.substring(0, newLocale.indexOf('.'))
                }
                dataToSave = {"locale": newLocale}

                background.locale = newLocale;

                // Restart the activity with new information
                if(oldLocale !== newLocale) {
                    background.stop();
                    background.start();
                }
            }

            function setDefaultValues() {
                var localeUtf8 = background.locale;
                if(background.locale != "system") {
                    localeUtf8 += ".UTF-8";
                }

                for(var i = 0 ; i < dialogActivityConfig.configItem.availableLangs.length ; i ++) {
                    if(dialogActivityConfig.configItem.availableLangs[i].locale === localeUtf8) {
                        dialogActivityConfig.loader.item.localeBox.currentIndex = i;
                        break;
                    }
                }
            }
            onClose: home()
        }

        DialogHelp {
            id: dialogHelp
            onClose: home()
        }

        DialogBackground {
           id: hintDialog
            visible: false
            title: items.categoryTitle ? items.categoryTitle : ''
            textBody: items.categoryLesson ? items.categoryLesson : ''
            onClose: home()
        }

        Bar {
            id: bar
            content: menuScreen.started ? withConfig : (items.hintDisplay == true ? withoutConfigWithHint : withoutConfigWithoutHint)
            property BarEnumContent withConfig: BarEnumContent { value: help | home | config }
            property BarEnumContent withoutConfigWithHint: BarEnumContent { value: home | level | hint }
            property BarEnumContent withoutConfigWithoutHint: BarEnumContent { value: home | level }
            onPreviousLevelClicked: Activity.previousLevel()
            onNextLevelClicked: Activity.nextLevel()
            onHelpClicked: {
                displayDialog(dialogHelp)
            }
            onHomeClicked: {
                if(items.menuScreen.started)
                    activity.home()
                else if(items.categoryReview.started)
                    Activity.launchMenuScreen()
            }
            onConfigClicked: {
                dialogActivityConfig.active = true
                dialogActivityConfig.setDefaultValues()
                displayDialog(dialogActivityConfig)
            }
            onHintClicked: {
                displayDialog(hintDialog)
            }
        }

        Bonus {
            id: bonus
            Component.onCompleted: win.connect(Activity.nextLevel)
        }

        Loader {
            id: categoriesFallbackDialog
            sourceComponent: GCDialog {
                parent: activity.main
                message: qsTr("You don't have all the images for this activity. " +
                              "Press Update to get the complete dataset. " +
                              "Press the Cross to play with demo version or 'Never show this dialog later' if you want to never see again this dialog.")
                button1Text: qsTr("Update the image set")
                button2Text: qsTr("Never show this dialog later")
                onClose: items.categoriesFallback = false
                onButton1Hit: DownloadManager.downloadResource('data2/words/words.rcc')
                onButton2Hit: { items.displayUpdateDialogAtStart = false; dialogActivityConfig.saveDatainConfiguration() }
            }
            anchors.fill: parent
            focus: true
            active: items.categoriesFallback && items.displayUpdateDialogAtStart && type == "images"
            onStatusChanged: if (status == Loader.Ready) item.start()
        }

        Loader {
            id: englishFallbackDialog
            sourceComponent: GCDialog {
                parent: activity.main
                message: qsTr("We are sorry, we don't have yet a translation for your language.") + " " +
                         qsTr("GCompris is developed by the KDE community, you can translate GCompris by joining a translation team on <a href=\"%2\">%2</a>").arg("http://l10n.kde.org/") +
                         "<br /> <br />" +
                         qsTr("We switched to English for this activity but you can select another language in the configuration dialog.")
                onClose: { background.englishFallback = false; items.locale = "en_GB"; Activity.getCategoriesList(); }
            }
            anchors.fill: parent
            focus: true
            active: background.englishFallback
            onStatusChanged: if (status == Loader.Ready) item.start()
        }
    }
}
