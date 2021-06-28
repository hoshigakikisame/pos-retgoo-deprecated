// +build windows

package main

import (
	"encoding/base64"
	"encoding/json"
	"log"

	prt "github.com/alexbrainman/printer"
	"github.com/go-flutter-desktop/go-flutter"
	"github.com/go-flutter-desktop/go-flutter/plugin"
	"github.com/go-gl/glfw/v3.3/glfw"
)

const printerChannelName = "id.retgoo.flutter/printer"

type printerPluginWindows struct{}

var _ flutter.Plugin = &printerPluginWindows{}
var _ flutter.PluginGLFW = &printerPluginWindows{}

func getPrinterPlugin() flutter.Plugin {
	return &printerPluginWindows{}
}

// InitPlugin .
func (p *printerPluginWindows) InitPlugin(messenger plugin.BinaryMessenger) error {
	// nothing to do
	channel := plugin.NewMethodChannel(messenger, printerChannelName, plugin.JSONMethodCodec{})
	channel.HandleFunc("getPrinters", handleGetPrinters)
	channel.HandleFunc("print", handlePrint)

	return nil
}

func handlePrint(arguments interface{}) (reply interface{}, err error) {
	if arguments == nil {
		return nil, nil
	}

	jsonBytes := arguments.(json.RawMessage)
	arg := struct {
		PrinterName string `json:"printer"`
		JobName     string `json:"job"`
		Payload     string `json:"payload"`
	}{}

	err = json.Unmarshal(jsonBytes, &arg)
	if err != nil {
		return nil, err
	}

	p, err := prt.Open(arg.PrinterName)
	if err != nil {
		log.Fatal(err)
	}

	payload, err := base64.StdEncoding.DecodeString(arg.Payload)
	if err != nil {
		return nil, err
	}

	err = p.StartRawDocument(arg.JobName)
	if err != nil {
		log.Fatal(err)
	}

	err = p.StartPage()
	if err != nil {
		log.Fatal(err)
	}

	_, err = p.Write(payload)
	if err != nil {
		log.Fatal(err)
	}

	err = p.EndPage()
	if err != nil {
		log.Fatal(err)
	}
	err = p.EndDocument()
	if err != nil {
		log.Fatal(err)
	}
	err = p.Close()
	if err != nil {
		log.Fatal(err)
	}

	return nil, nil
}

func handleGetPrinters(arguments interface{}) (reply interface{}, err error) {
	ps, err := prt.ReadNames()
	result := struct {
		Printers []string `json:"printers"`
	}{
		Printers: ps,
	}

	b, err := json.Marshal(result)
	if err != nil {
		return nil, err
	}

	var values json.RawMessage = b
	return values, nil
}

// InitPluginGLFW .
func (p *printerPluginWindows) InitPluginGLFW(window *glfw.Window) error {

	return nil
}
