// +build !windows

package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"os"
	"os/exec"

	"github.com/go-flutter-desktop/go-flutter"
	"github.com/go-flutter-desktop/go-flutter/plugin"
	"github.com/go-gl/glfw/v3.3/glfw"
)

const printerChannelName = "id.retgoo.flutter/printer"

type printerPluginLinux struct{}

var _ flutter.Plugin = &printerPluginLinux{}
var _ flutter.PluginGLFW = &printerPluginLinux{}

func getPrinterPlugin() flutter.Plugin {
	return &printerPluginLinux{}
}

// InitPlugin .
func (p *printerPluginLinux) InitPlugin(messenger plugin.BinaryMessenger) error {
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

	payload, err := base64.StdEncoding.DecodeString(arg.Payload)
	if err != nil {
		return nil, err
	}

	args := []string{"-J", arg.JobName, "-o", "raw", "-r"}
	cmd := exec.Command("lpr", args...)
	cmd.Stdin = bytes.NewReader(payload)
	cmd.Stderr = os.Stderr
	cmd.Stdout = os.Stdout
	err = cmd.Run()
	if err != nil {
		return nil, err
	}

	return nil, nil
}

func handleGetPrinters(arguments interface{}) (reply interface{}, err error) {
	ps := []string{"default"}

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
func (p *printerPluginLinux) InitPluginGLFW(window *glfw.Window) error {
	return nil
}
