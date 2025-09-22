import cv2
import numpy as np
import tflite_runtime.interpreter as tflite
import time
import os
from glob import glob
from flask import Flask, jsonify, send_from_directory, Response
import threading
import ipfshttpclient
import json
import subprocess


# =========================
# Parameters
# =========================
MODEL_PATH = "/home/pi/Desktop/surveillance_model.tflite"
CONF_THRESHOLD = 0.3
IMG_SIZE = 640

# COCO Classes (80)
CLASS_NAMES = [
    "person","bicycle","car","motorbike","aeroplane","bus","train","truck",
    "boat","traffic light","fire hydrant","stop sign","parking meter","bench",
    "bird","cat","dog","horse","sheep","cow","elephant","bear","zebra","giraffe",
    "backpack","umbrella","handbag","tie","suitcase","frisbee","skis","snowboard",
    "sports ball","kite","baseball bat","baseball glove","skateboard","surfboard",
    "tennis racket","bottle","wine glass","cup","fork","knife","spoon","bowl",
    "banana","apple","sandwich","orange","broccoli","carrot","hot dog","pizza",
    "donut","cake","chair","sofa","pottedplant","bed","diningtable","toilet",
    "tvmonitor","laptop","mouse","remote","keyboard","cell phone","microwave",
    "oven","toaster","sink","refrigerator","book","clock","vase","scissors",
    "teddy bear","hair drier","toothbrush"
]

# Classes considered as intrusion
ALLOWED_CLASSES = ["person", "car", "truck", "bus", "van"]

# Output directory for saved intrusions
OUT_DIR = "/home/pi/Desktop/intrusions"
os.makedirs(OUT_DIR, exist_ok=True)



np.random.seed(42)
COLORS = np.random.randint(0, 255, size=(len(CLASS_NAMES), 3), dtype=np.uint8)
COLORS[0] = np.array([0, 0, 255])

# Load TFLite Model

interpreter = tflite.Interpreter(model_path=MODEL_PATH)
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()
input_index = input_details[0]['index']
output_index = output_details[0]['index']

# Flask API
app = Flask(__name__)
system_running = False  # flag to control camera via API

@app.route("/")
def index():
    return jsonify({"status": "TrustCam API running", "controls": ["/control/start", "/control/stop"]})

# IPFS CLI helper functions

def add_to_ipfs(filename):
    """Add a file to IPFS using CLI and return the CID"""
    try:
        result = subprocess.run(["ipfs", "add", "-Q", filename], capture_output=True, text=True)
        cid = result.stdout.strip()
        print(f"[IPFS CLI] {filename} added with CID {cid}")
        return cid
    except Exception as e:
        print(f"[IPFS CLI] Failed to add {filename}: {e}")
        return None

def save_ipfs_cid(class_dir, filename, cid):
    """Save filename -> CID mapping locally"""
    cid_file = os.path.join(class_dir, "ipfs_cids.json")
    if os.path.exists(cid_file):
        with open(cid_file, "r") as f:
            cid_data = json.load(f)
    else:
        cid_data = {}
    cid_data[os.path.basename(filename)] = cid
    with open(cid_file, "w") as f:
        json.dump(cid_data, f)
        
        
def load_ipfs_cids(class_dir):
    cid_file = os.path.join(class_dir, "ipfs_cids.json")
    if os.path.exists(cid_file):
        with open(cid_file, "r") as f:
            return json.load(f)
    return {}

@app.route("/detections/<cls>")
def get_detections(cls):
    path = os.path.join(OUT_DIR, cls)
    if not os.path.exists(path):
        return jsonify({"error": "class not found"}), 404
    files = sorted(os.listdir(path))
    ipfs_cids = load_ipfs_cids(path)
    
    data = []
    for f in files:
        if f.endswith(".jpg"):
            filepath = os.path.join(path, f)
            ts = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(os.path.getmtime(filepath)))
            data.append({
                "url": f"http://192.168.1.136:5000/image/{cls}/{f}",
                "timestamp": ts,
                "ipfs_cid": ipfs_cids.get(f)
            })

    return jsonify({"class": cls, "detections": data})

@app.route("/image/<cls>/<filename>")
def get_image(cls, filename):
    path = os.path.join(OUT_DIR, cls)
    return send_from_directory(path, filename)

@app.route("/control/start")
def start_system():
    global system_running
    system_running = True
    return jsonify({"status": "system started"})

@app.route("/control/stop")
def stop_system():
    global system_running
    system_running = False
    return jsonify({"status": "system stopped"})

# Camera Detection Loop (thread)

frame_to_stream = None

def detection_loop():
    global system_running, frame_to_stream
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        raise RuntimeError("Camera not detected")

    save_counters = {cls: 1 for cls in ALLOWED_CLASSES}
    last_save_time = {cls: 0 for cls in ALLOWED_CLASSES}
    COOLDOWN = 5.0  

    while True:
        if not system_running:
            time.sleep(0.5)
            continue

        ret, frame = cap.read()
        if not ret:
            continue

        # Preprocessing
        img = cv2.resize(frame, (IMG_SIZE, IMG_SIZE))
        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        img_rgb = np.expand_dims(img_rgb, axis=0).astype(np.float32) / 255.0

        # Inference
        interpreter.set_tensor(input_index, img_rgb)
        interpreter.invoke()
        preds = interpreter.get_tensor(output_index)[0]

        for pred in preds:
            x1, y1, x2, y2, conf, cls = pred
            if conf < CONF_THRESHOLD:
                continue

            cls = int(cls)
            label = CLASS_NAMES[cls] if cls < len(CLASS_NAMES) else str(cls)

            # Convert to pixels
            x1 = int(x1 * frame.shape[1])
            y1 = int(y1 * frame.shape[0])
            x2 = int(x2 * frame.shape[1])
            y2 = int(y2 * frame.shape[0])
            color = COLORS[cls].tolist()

            # Draw bounding box
            cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
            cv2.putText(frame, f"{label} {conf:.2f}", (x1, y1 - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)

            # Save intrusion
            if label in ALLOWED_CLASSES:
                now = time.time()
                if now - last_save_time[label] >= COOLDOWN:
                    class_dir = os.path.join(OUT_DIR, label)
                    os.makedirs(class_dir, exist_ok=True)
                    filename = os.path.join(class_dir, f"{save_counters[label]}.jpg")
                    cv2.imwrite(filename, frame)
                    print(f"[SAVE] {label} -> {filename}")

                    cid = add_to_ipfs(filename)
                    if cid:
                        save_ipfs_cid(class_dir, filename, cid)

                    save_counters[label] += 1
                    last_save_time[label] = now

        # Add timestamp to frame
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        cv2.putText(frame, timestamp, (10, frame.shape[0] - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        frame_to_stream = frame.copy()

        cv2.imshow("TrustCam", frame)
        if cv2.waitKey(1) & 0xFF == ord("q"):
            break

    cap.release()
    cv2.destroyAllWindows()

@app.route("/video/live")
def video_live():
    def generate():
        global frame_to_stream
        while True:
            if frame_to_stream is None:
                time.sleep(0.1)
                continue
            ret, buffer = cv2.imencode('.jpg', frame_to_stream)
            frame_bytes = buffer.tobytes()
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')
    return Response(generate(), mimetype='multipart/x-mixed-replace; boundary=frame')

# Run Flask + Detection

if __name__ == "__main__":
    threading.Thread(target=detection_loop, daemon=True).start()
    app.run(host="0.0.0.0", port=5000)