package main

import (
	"github.com/go-flutter-desktop/go-flutter"
	"github.com/go-flutter-desktop/plugins/shared_preferences"
)

var options = []flutter.Option{
	flutter.WindowInitialDimensions(1280, 720),
	flutter.AddPlugin(&WindowMaximization{}),
	flutter.AddPlugin(getPrinterPlugin()),
	flutter.AddPlugin(getDisplayPlugin()),
	flutter.AddPlugin(&shared_preferences.SharedPreferencesPlugin{
		VendorName:      "id.retgoo",
		ApplicationName: "Point Of Sales",
	}),
	//flutter.ForcePixelRatio(0.9), // Setting this option is not advised.
	//flutter.OptionKeyboardLayout(flutter.KeyboardQwertyLayout),
	flutter.OptionVMArguments([]string{"--disable-dart-asserts", "--disable-observatory"}),
}
