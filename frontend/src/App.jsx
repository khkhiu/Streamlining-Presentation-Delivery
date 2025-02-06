import React, { useState, useEffect } from "react";
import axios from "axios";
import ReactPlayer from "react-player";

const API_URL = "http://localhost:5000"; // Replace with backend URL

function App() {
  const [text, setText] = useState("");
  const [videos, setVideos] = useState([]);
  const [chat, setChat] = useState("");
  const [response, setResponse] = useState("");

  useEffect(() => {
    axios.get(`${API_URL}/videos`).then((res) => setVideos(res.data));
  }, []);

  const handleUpload = async () => {
    await axios.post(`${API_URL}/upload`, { text });
    alert("Uploaded!");
  };

  const handleAsk = async () => {
    const res = await axios.post(`${API_URL}/ask`, { question: chat });
    setResponse(res.data.answer);
  };

  return (
    <div className="p-10 bg-gray-100 min-h-screen">
      <h1 className="text-2xl font-bold mb-4">Virtual Trainer</h1>

      {/* Upload Section */}
      <textarea
        className="w-full p-2 border rounded"
        rows="4"
        placeholder="Enter training script..."
        value={text}
        onChange={(e) => setText(e.target.value)}
      ></textarea>
      <button className="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded-l" onClick={handleUpload}>
        Upload & Generate Video
      </button>

      {/* Video Section */}
      <h2 className="text-xl font-semibold mt-6">Trainer Videos</h2>
      {videos.map((video) => (
        <div key={video.id} className="my-2">
          <ReactPlayer url={video.url} controls width="100%" />
        </div>
      ))}

      {/* Q&A Section */}
      <h2 className="text-xl font-semibold mt-6">Ask the Trainer</h2>
      <input
        className="w-full p-2 border rounded"
        placeholder="Type a question..."
        value={chat}
        onChange={(e) => setChat(e.target.value)}
      />
      <button className="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-4 rounded-l" onClick={handleAsk}>
        Ask
      </button>
      {response && <p className="mt-2 bg-gray-200 p-2">{response}</p>}
    </div>
  );
}

export default App;
