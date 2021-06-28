package main

import (
	"os"

	"github.com/go-flutter-desktop/go-flutter"
	"github.com/go-flutter-desktop/go-flutter/plugin"
	"github.com/go-gl/glfw/v3.3/glfw"
)

const channelName = "id.retgoo.flutter/desktop"

// WindowMaximization .
type WindowMaximization struct{}

var _ flutter.Plugin = &WindowMaximization{}     // compile-time type check
var _ flutter.PluginGLFW = &WindowMaximization{} // compile-time type check
// WindowNotResizable struct must implement InitPlugin and InitPluginGLFW

// InitPlugin .
func (p *WindowMaximization) InitPlugin(messenger plugin.BinaryMessenger) error {
	// nothing to do
	channel := plugin.NewMethodChannel(messenger, channelName, plugin.JSONMethodCodec{})
	channel.HandleFunc("exitApp", handleExitApp)
	return nil
}

func handleExitApp(arguments interface{}) (reply interface{}, err error) {
	os.Exit(0)
	return true, nil
}

// InitPluginGLFW .
func (p *WindowMaximization) InitPluginGLFW(window *glfw.Window) error {
	window.Maximize()
	return nil
}
