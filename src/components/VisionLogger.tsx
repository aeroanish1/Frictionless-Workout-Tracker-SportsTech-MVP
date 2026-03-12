import React, { useState, useRef } from 'react';
import { Camera, RefreshCw, Check, Loader2, AlertCircle, X, Image as ImageIcon } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { GoogleGenAI, Type } from "@google/genai";

interface VisionLoggerProps {
  onDataExtracted: (data: any) => void;
}

export const VisionLogger: React.FC<VisionLoggerProps> = ({ onDataExtracted }) => {
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [capturedImage, setCapturedImage] = useState<string | null>(null);
  const [status, setStatus] = useState<'idle' | 'camera' | 'processing' | 'success' | 'error'>('idle');
  const [error, setError] = useState<string | null>(null);
  
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  const startCamera = async () => {
    try {
      const mediaStream = await navigator.mediaDevices.getUserMedia({ 
        video: { facingMode: 'environment' } 
      });
      setStream(mediaStream);
      if (videoRef.current) {
        videoRef.current.srcObject = mediaStream;
      }
      setStatus('camera');
      setError(null);
    } catch (err) {
      console.error('Error accessing camera:', err);
      setError('Could not access camera. Please check permissions.');
      setStatus('error');
    }
  };

  const stopCamera = () => {
    if (stream) {
      stream.getTracks().forEach(track => track.stop());
      setStream(null);
    }
  };

  const capturePhoto = () => {
    if (videoRef.current && canvasRef.current) {
      const video = videoRef.current;
      const canvas = canvasRef.current;
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      const ctx = canvas.getContext('2d');
      if (ctx) {
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
        const imageData = canvas.toDataURL('image/jpeg');
        setCapturedImage(imageData);
        stopCamera();
        processImage(imageData);
      }
    }
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        const imageData = reader.result as string;
        setCapturedImage(imageData);
        processImage(imageData);
      };
      reader.readAsDataURL(file);
    }
  };

  const processImage = async (base64Image: string) => {
    setStatus('processing');
    try {
      const base64Data = base64Image.split(',')[1];
      const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
      
      const response = await ai.models.generateContent({
        model: "gemini-3-flash-preview",
        contents: [
          {
            parts: [
              { text: "Extract workout data from this machine summary image (treadmill, rower, etc.). Return a JSON object with 'date' (ISO string), 'notes' (string describing the machine type), and 'exercises' (array of objects with 'name', 'muscleGroup', 'sets', 'reps', 'weight', 'distance', 'duration', 'calories'). For cardio, use 'duration' in seconds and 'distance' in meters. If it's a strength machine, use sets/reps/weight. If no workout is found, return an empty exercises array." },
              {
                inlineData: {
                  mimeType: "image/jpeg",
                  data: base64Data
                }
              }
            ]
          }
        ],
        config: {
          responseMimeType: "application/json",
          responseSchema: {
            type: Type.OBJECT,
            properties: {
              date: { type: Type.STRING },
              notes: { type: Type.STRING },
              exercises: {
                type: Type.ARRAY,
                items: {
                  type: Type.OBJECT,
                  properties: {
                    name: { type: Type.STRING },
                    muscleGroup: { type: Type.STRING },
                    sets: { type: Type.NUMBER },
                    reps: { type: Type.NUMBER },
                    weight: { type: Type.NUMBER },
                    distance: { type: Type.NUMBER },
                    duration: { type: Type.NUMBER },
                    calories: { type: Type.NUMBER }
                  },
                  required: ["name"]
                }
              }
            },
            required: ["date", "exercises"]
          }
        }
      });

      const workoutData = JSON.parse(response.text);
      if (!workoutData.exercises || workoutData.exercises.length === 0) {
        throw new Error("No workout data detected in the image.");
      }

      onDataExtracted(workoutData);
      setStatus('success');
      setTimeout(() => {
        setStatus('idle');
        setCapturedImage(null);
      }, 3000);
    } catch (err: any) {
      console.error('Error processing image:', err);
      setError(err.message || 'Failed to analyze image. Try a clearer photo.');
      setStatus('error');
    }
  };

  const reset = () => {
    stopCamera();
    setCapturedImage(null);
    setStatus('idle');
    setError(null);
  };

  return (
    <div className="w-full max-w-md flex flex-col items-center justify-center p-8 bg-white rounded-3xl shadow-xl border border-black/5">
      <div className="w-full flex items-center justify-between mb-6">
        <h3 className="text-lg font-bold text-zinc-900 flex items-center gap-2">
          <Camera size={20} />
          Vision Log
        </h3>
        {status !== 'idle' && (
          <button onClick={reset} className="p-2 hover:bg-zinc-100 rounded-full transition-colors">
            <X size={20} className="text-zinc-500" />
          </button>
        )}
      </div>

      <div className="relative w-full aspect-square bg-zinc-50 rounded-2xl overflow-hidden border border-zinc-100 flex items-center justify-center">
        <AnimatePresence mode="wait">
          {status === 'idle' && (
            <motion.div 
              key="idle"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              className="flex flex-col items-center gap-4 p-6 text-center"
            >
              <div className="w-16 h-16 bg-zinc-100 rounded-2xl flex items-center justify-center text-zinc-400">
                <Camera size={32} />
              </div>
              <div>
                <p className="text-sm font-medium text-zinc-900">Scan Machine Summary</p>
                <p className="text-xs text-zinc-500 mt-1">Point at treadmill, rower, or any gym machine screen</p>
              </div>
              <div className="flex gap-2 w-full">
                <button 
                  onClick={startCamera}
                  className="flex-1 bg-black text-white py-3 rounded-xl font-bold text-sm flex items-center justify-center gap-2 hover:bg-zinc-800 transition-all"
                >
                  <Camera size={18} />
                  Open Camera
                </button>
                <label className="flex-1 bg-zinc-100 text-zinc-900 py-3 rounded-xl font-bold text-sm flex items-center justify-center gap-2 cursor-pointer hover:bg-zinc-200 transition-all">
                  <ImageIcon size={18} />
                  Upload
                  <input type="file" accept="image/*" className="hidden" onChange={handleFileUpload} />
                </label>
              </div>
            </motion.div>
          )}

          {status === 'camera' && (
            <motion.div 
              key="camera"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              className="relative w-full h-full"
            >
              <video 
                ref={videoRef} 
                autoPlay 
                playsInline 
                className="w-full h-full object-cover"
              />
              <div className="absolute bottom-6 left-0 right-0 flex justify-center">
                <button 
                  onClick={capturePhoto}
                  className="w-16 h-16 rounded-full border-4 border-white bg-black/20 backdrop-blur-sm flex items-center justify-center hover:scale-110 transition-transform"
                >
                  <div className="w-12 h-12 rounded-full bg-white" />
                </button>
              </div>
            </motion.div>
          )}

          {status === 'processing' && (
            <motion.div 
              key="processing"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              className="flex flex-col items-center gap-4"
            >
              {capturedImage && (
                <img src={capturedImage} alt="Captured" className="absolute inset-0 w-full h-full object-cover opacity-50 blur-sm" />
              )}
              <div className="relative z-10 flex flex-col items-center">
                <Loader2 size={48} className="animate-spin text-black" />
                <p className="mt-4 font-bold text-zinc-900">Analyzing Machine Data...</p>
                <p className="text-xs text-zinc-500">Gemini is parsing the screen</p>
              </div>
            </motion.div>
          )}

          {status === 'success' && (
            <motion.div 
              key="success"
              initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0 }}
              className="flex flex-col items-center gap-4"
            >
              <div className="w-20 h-20 bg-emerald-500 text-white rounded-full flex items-center justify-center shadow-lg">
                <Check size={40} />
              </div>
              <p className="font-bold text-zinc-900">Data Extracted!</p>
            </motion.div>
          )}

          {status === 'error' && (
            <motion.div 
              key="error"
              initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
              className="flex flex-col items-center gap-4 p-6 text-center"
            >
              <div className="w-16 h-16 bg-amber-100 text-amber-600 rounded-2xl flex items-center justify-center">
                <AlertCircle size={32} />
              </div>
              <div>
                <p className="text-sm font-bold text-zinc-900">Analysis Failed</p>
                <p className="text-xs text-zinc-500 mt-1">{error}</p>
              </div>
              <button 
                onClick={reset}
                className="bg-black text-white px-6 py-2 rounded-xl font-bold text-sm hover:bg-zinc-800 transition-all"
              >
                Try Again
              </button>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
      <canvas ref={canvasRef} className="hidden" />
    </div>
  );
};
