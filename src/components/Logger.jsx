// src/components/Logger.jsx
function Logger({ logs }) {
    return (
      <div className="logger">
        {logs.map((log, index) => (
          <div key={index} className="log-entry">
            {log}
          </div>
        ))}
      </div>
    );
  }
  
  export default Logger;