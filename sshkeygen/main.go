package main

/*
#include <stdint.h>
*/
import "C"
import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/gokyle/sshkey"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"sync/atomic"
	"unsafe"

	bridge "bridge"
)

const (
	// Placeholder constants; adjust as needed
	Version = "v1.00.0.0001, SSHKeyGen"
)

var (
	// Placeholder for global state, if needed
	registeredPort int64
	portMu         sync.RWMutex
)

type taskRec struct {
	cancel context.CancelFunc
	done   chan struct{}
}

var (
	tasks    = map[int64]*taskRec{}
	tasksMu  sync.Mutex
	nextTask int64 // atomic increment
)

type simpleResp struct {
	Op      string      `json:"op"`
	Success bool        `json:"success"`
	Error   string      `json:"error,omitempty"`
	Data    interface{} `json:"data,omitempty"`
}

func addTask(cancel context.CancelFunc) int64 {
	id := atomic.AddInt64(&nextTask, 1)
	entry := &taskRec{
		cancel: cancel,
		done:   make(chan struct{}),
	}
	tasksMu.Lock()
	tasks[id] = entry
	tasksMu.Unlock()
	return id
}

func finishTask(id int64) {
	tasksMu.Lock()
	if e, ok := tasks[id]; ok {
		close(e.done)
		delete(tasks, id)
	}
	tasksMu.Unlock()
}

//export RegisterPort
func RegisterPort(port C.longlong) {
	portMu.Lock()
	registeredPort = int64(port)
	portMu.Unlock()
	bridge.SendStringToPort(int64(port), "registered")
}

//export UnregisterPort
func UnregisterPort() {
	portMu.Lock()
	p := registeredPort
	registeredPort = 0
	portMu.Unlock()
	if p != 0 {
		bridge.SendStringToPort(p, "unregistered")
	}
}

func getPortOrDefault(p C.longlong) int64 {
	if int64(p) != 0 {
		return int64(p)
	}
	portMu.RLock()
	defer portMu.RUnlock()
	return registeredPort
}

func sendToPort(port int64, r simpleResp) {
	b, _ := json.Marshal(r)
	bridge.SendStringToPort(port, string(b))
}

// ---- wrapper helpers ----
func safeOp(port int64, op string, fn func() (interface{}, error)) {
	defer func() {
		if r := recover(); r != nil {
			sendToPort(port, simpleResp{Op: op, Success: false, Error: fmt.Sprintf("panic: %v", r)})
		}
	}()
	res, err := fn()
	if err != nil {
		sendToPort(port, simpleResp{Op: op, Success: false, Error: err.Error()})
		return
	}
	sendToPort(port, simpleResp{Op: op, Success: true, Data: res})
}

//export BridgeInit
func BridgeInit(api unsafe.Pointer) {
	// panic-safe init
	defer func() {
		if r := recover(); r != nil {
			port := getPortOrDefault(0)
			if port != 0 {
				sendToPort(port, simpleResp{Op: "bridge_init", Success: false, Error: fmt.Sprintf("%v", r)})
			}
		}
	}()
	bridge.InitDartApi(api)
}

// ---- SSH Key Generation Exports ----

// Helper to check key type (as in original, but now part of exports)
func checkKeyType(keytype string) error {
	switch keytype {
	case "rsa", "ecdsa":
		return nil
	default:
		return fmt.Errorf("bad key type: %s", keytype)
	}
}

// Helper to get default comment (adapted from original, without exec if possible; fallback to static)
func getDefaultComment() string {
	cmd := exec.Command("whoami")
	out, err := cmd.Output()
	if err != nil {
		return "user@host" // Fallback if exec fails (e.g., in restricted env)
	}
	whoami := strings.TrimSpace(string(out))

	cmd = exec.Command("hostname")
	out, err = cmd.Output()
	if err != nil {
		return whoami + "@host"
	}
	hostname := strings.TrimSpace(string(out))

	return fmt.Sprintf("%s@%s", whoami, hostname)
}

// Helper to get default key path
func defaultKey(keytype string) string {
	home := os.Getenv("HOME")
	return filepath.Join(home, ".ssh", "id_"+keytype)
}

//export GenerateKey
func GenerateKey(keytypeStr *C.char, keyfileStr *C.char, commentStr *C.char, size C.int, passwordStr *C.char, port C.longlong) {
	p := getPortOrDefault(port)
	keytype := C.GoString(keytypeStr)
	keyfile := C.GoString(keyfileStr)
	comment := C.GoString(commentStr)
	password := C.GoString(passwordStr)
	intSize := int(size)

	safeOp(p, "generate_key", func() (interface{}, error) {
		// Validate key type
		if err := checkKeyType(keytype); err != nil {
			return nil, err
		}

		// Default comment if empty
		if comment == "" {
			comment = getDefaultComment()
		}

		// Adjust size for RSA
		if keytype == "rsa" && intSize == 256 {
			intSize = 2048
		}

		// Default keyfile
		if keyfile == "" {
			keyfile = defaultKey(keytype)
		}

		// Check if file exists and prompt for overwrite (but since no stdin, assume overwrite or error)
		if _, err := os.Stat(keyfile); !os.IsNotExist(err) {
			return nil, fmt.Errorf("key file %s already exists; overwrite not supported in library mode", keyfile)
		}

		// Validate password
		if password != "" && len(password) < 5 {
			return nil, fmt.Errorf("passphrase too short: have %d bytes, need > 4", len(password))
		}

		// Generate key
		var key interface{}
		var err error
		switch keytype {
		case "rsa":
			key, err = sshkey.GenerateKey(sshkey.KEY_RSA, intSize)
		case "ecdsa":
			key, err = sshkey.GenerateKey(sshkey.KEY_ECDSA, intSize)
		}
		if err != nil {
			return nil, fmt.Errorf("failed to generate %s key: %v", keytype, err)
		}

		// Marshal private key
		privout, err := sshkey.MarshalPrivate(key, password)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal private key: %v", err)
		}

		// Create and marshal public key
		pub := sshkey.NewPublic(key, comment)
		if pub == nil {
			return nil, fmt.Errorf("failed to create public key")
		}
		pubout := sshkey.MarshalPublic(pub)
		if pubout == nil {
			return nil, fmt.Errorf("failed to marshal public key")
		}

		// Write files
		err = ioutil.WriteFile(keyfile, privout, 0600)
		if err != nil {
			return nil, fmt.Errorf("failed to write private key: %v", err)
		}
		err = ioutil.WriteFile(keyfile+".pub", pubout, 0644)
		if err != nil {
			return nil, fmt.Errorf("failed to write public key: %v", err)
		}

		return map[string]string{
			"private_key_file": keyfile,
			"public_key_file":  keyfile + ".pub",
			"key_type":         keytype,
			"comment":          comment,
		}, nil
	})
}

//export GetFingerprint
func GetFingerprint(keyfileStr *C.char, keytypeStr *C.char, port C.longlong) {
	p := getPortOrDefault(port)
	keyfile := C.GoString(keyfileStr)
	keytype := C.GoString(keytypeStr)

	safeOp(p, "get_fingerprint", func() (interface{}, error) {
		// Validate key type
		if err := checkKeyType(keytype); err != nil {
			return nil, err
		}

		// Default keyfile
		if keyfile == "" {
			keyfile = defaultKey(keytype) + ".pub"
		}

		// Load public key
		pub, err := sshkey.LoadPublicKeyFile(keyfile, true)
		if err != nil {
			return nil, fmt.Errorf("failed to load public key from %s: %v", keyfile, err)
		}

		// Get fingerprint
		fpr, err := sshkey.FingerprintPretty(pub, 0)
		if err != nil {
			return nil, fmt.Errorf("failed to generate fingerprint: %v", err)
		}

		comment := pub.Comment
		if comment == "" {
			comment = keyfile
		}

		return map[string]interface{}{
			"size":       pub.Size(),
			"fingerprint": fpr,
			"comment":    comment,
			"key_type":   strings.ToUpper(keytype),
		}, nil
	})
}

//export StopTask
func StopTask(taskID C.longlong, port C.longlong) {
	id := int64(taskID)
	p := getPortOrDefault(port)
	tasksMu.Lock()
	entry, ok := tasks[id]
	if ok {
		delete(tasks, id)
	}
	tasksMu.Unlock()
	if !ok {
		sendToPort(p, simpleResp{Op: "stop", Success: false, Error: fmt.Sprintf("task %d not found", id)})
		return
	}
	entry.cancel()
	<-entry.done
	sendToPort(p, simpleResp{Op: "stop", Success: true, Data: id})
}

func main() {}