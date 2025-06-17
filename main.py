from fastapi import FastAPI, WebSocket
from fastapi.responses import StreamingResponse
import cv2
import numpy as np
import asyncio
from ultralytics import YOLO  # YOLOv8 ici

app = FastAPI()

latest_frame = None

# Charger le modèle YOLOv8n (pré-entrainé sur COCO)
model = YOLO("yolov8n.pt")  # Assurez-vous que le fichier est présent ou bien utilisez l'identifiant si installé via pip

@app.get("/")
async def root():
    return {"message": "Host OK"}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    global latest_frame
    await websocket.accept()
    print("✅ WebSocket accepté !")
    while True:
        try:
            data = await websocket.receive_bytes()
            np_arr = np.frombuffer(data, np.uint8)
            frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
            if frame is None:
                continue
            latest_frame = frame
        except Exception as e:
            print(f"❌ Erreur WebSocket : {e}")
            break

@app.get("/video_feed")
async def video_feed():
    boundary = "frame"

    async def generate():
        global latest_frame
        while True:
            await asyncio.sleep(0.05)
            if latest_frame is None:
                continue
            try:
                frame = latest_frame.copy()

                # Convertir en BGR numpy array si besoin
                if frame is None or not isinstance(frame, np.ndarray):
                    continue

                # ⚠️ YOLO attend une image RGB
                rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

                # YOLOv8 detection
                results = model(rgb_frame, imgsz=416, verbose=False)[0]

                if results.boxes is not None:
                    for box in results.boxes:
                        cls_id = int(box.cls[0].item())
                        conf = float(box.conf[0].item())
                        x1, y1, x2, y2 = map(int, box.xyxy[0].tolist())

                        class_name = model.names[cls_id]
                        label = f"{class_name} {conf:.2f}"

                        # 🟩 Dessin
                        cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 2)
                        cv2.putText(frame, label, (x1, max(y1 - 10, 0)),
                                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

                # Encode frame to JPEG
                ret, jpeg = cv2.imencode(".jpg", frame)
                if not ret:
                    continue

                frame_bytes = jpeg.tobytes()
                yield (
                    f"--{boundary}\r\n"
                    "Content-Type: image/jpeg\r\n"
                    f"Content-Length: {len(frame_bytes)}\r\n\r\n"
                ).encode() + frame_bytes + b"\r\n"

            except Exception as e:
                print(f"❌ Erreur stream: {e}")
                break

    headers = {"Content-Type": f"multipart/x-mixed-replace; boundary={boundary}"}
    return StreamingResponse(generate(), headers=headers)
