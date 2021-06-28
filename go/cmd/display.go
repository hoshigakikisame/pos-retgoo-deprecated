package main

import (
	"encoding/json"
	"log"

	"github.com/go-flutter-desktop/go-flutter"
	"github.com/go-flutter-desktop/go-flutter/plugin"
	"github.com/go-gl/glfw/v3.3/glfw"
	"github.com/tarm/serial"
)

const displayChannelName = "id.retgoo.flutter/display"

type displayPlugin struct{}

var _ flutter.Plugin = &displayPlugin{}
var _ flutter.PluginGLFW = &displayPlugin{}

func getDisplayPlugin() flutter.Plugin {
	return &displayPlugin{}
}

// InitPlugin .
func (p *displayPlugin) InitPlugin(messenger plugin.BinaryMessenger) error {
	// nothing to do
	channel := plugin.NewMethodChannel(messenger, displayChannelName, plugin.JSONMethodCodec{})

	channel.HandleFunc("print", handlePrintDisplay)

	return nil
}

func handlePrintDisplay(arguments interface{}) (reply interface{}, err error) {
	if arguments == nil {
		return nil, nil
	}

	jsonBytes := arguments.(json.RawMessage)
	arg := struct {
		Port     string `json:"port"`
		Text     string `json:"text"`
		BaudRate int    `json:"baud_rate"`
	}{}

	err = json.Unmarshal(jsonBytes, &arg)
	if err != nil {
		return nil, err
	}

	c := &serial.Config{Name: arg.Port, Baud: arg.BaudRate}
	s, err := serial.OpenPort(c)
	if err != nil {
		log.Println(err)
		return
	}

	s.Write([]byte("\f"))
	s.Write([]byte(arg.Text))
	s.Flush()
	s.Close()

	return nil, nil
}

// InitPluginGLFW .
func (p *displayPlugin) InitPluginGLFW(window *glfw.Window) error {
	return nil
}
